"""Build bounded, static WebP variants for the public home spotlight.

No requests run during page rendering. Unknown sources retain the original image.
The refresh publishes JSON and immutable image files, never executable templates.
"""
from __future__ import annotations
import argparse, fcntl, hashlib, http.client, io, ipaddress, json, os, re
import socket, ssl, tempfile, time, warnings
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import parse_qs, urljoin, urlsplit
from PIL import Image, ImageCms, ImageOps

MAX_BYTES=8*1024*1024
MAX_PIXELS=20_000_000
MAX_IMAGES=12
RECIPE="webp-v1-q88-480-960"
ASSET_PATTERN=re.compile(r"^[a-f0-9]{24}-[a-f0-9]{16}-[0-9]{2,4}\.webp$")
Image.MAX_IMAGE_PIXELS=MAX_PIXELS

def digest(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()

def validate_url(source: str, home: bool=False):
    if not isinstance(source,str) or len(source)>2048 or re.search(r"[\x00-\x20\x7f\\]",source):
        raise ValueError("invalid_url")
    u=urlsplit(source)
    if u.scheme!="https" or u.port not in (None,443) or u.username or u.password or u.fragment:
        raise ValueError("https_required")
    host=u.hostname or ""
    if home:
        if host!="roadrunners.run" or u.path!="/" or u.query:
            raise ValueError("home_not_allowed")
        return u
    prefixes={
        "cdn.ticketsports.com.br":"/ticketagora/images/",
        "www.yescom.com.br":"/",
        "magento.runningland.com.br":"/media/catalog/product/",
        "library.sportingnews.com":"/styles/",
        "minhasinscricoes.cdn.cl9.cloud":"/Gerenciador/Content/Images/Eventos/Logos/",
    }
    if host=="www.ticketsports.com.br":
        query=parse_qs(u.query,strict_parsing=True)
        if u.path!="/_next/image" or set(query)!={"url","w","q"} or any(len(v)!=1 for v in query.values()):
            raise ValueError("image_transform_not_allowed")
        if not query["w"][0].isdigit() or not 1<=int(query["w"][0])<=2048 or not query["q"][0].isdigit() or not 1<=int(query["q"][0])<=100:
            raise ValueError("image_transform_bounds")
        inner=validate_url(query["url"][0])
        if inner.hostname!="cdn.ticketsports.com.br":
            raise ValueError("image_transform_origin")
        return u
    if host not in prefixes or not u.path.startswith(prefixes[host]) or not re.search(r"\.(?:png|jpe?g|webp)$",u.path,re.I):
        raise ValueError("image_source_not_allowed")
    if any(part in (".","..") for part in u.path.split("/")) or "%" in u.path:
        raise ValueError("invalid_image_path")
    query=parse_qs(u.query,strict_parsing=True) if u.query else {}
    if host=="magento.runningland.com.br":
        if set(query)-{"auto","format","width"} or any(len(v)!=1 for v in query.values()):
            raise ValueError("image_query_not_allowed")
        if query.get("auto",["webp"])[0]!="webp" or query.get("format",["pjpg"])[0] not in ("pjpg","webp","jpg"):
            raise ValueError("image_format_not_allowed")
        width=query.get("width",["320"])[0]
        if not width.isdigit() or not 1<=int(width)<=2048:
            raise ValueError("image_width_bounds")
    elif query:
        raise ValueError("image_query_not_allowed")
    return u

def public_addresses(host):
    addresses=list(dict.fromkeys(info[4][0] for info in socket.getaddrinfo(host,443,type=socket.SOCK_STREAM)))
    if not addresses or any(not ipaddress.ip_address(address).is_global for address in addresses):
        raise ValueError("non_public_address")
    return sorted(addresses,key=lambda address: ":" in address)

class PinnedHTTPS(http.client.HTTPSConnection):
    def __init__(self,host,address):
        super().__init__(host,timeout=15,context=ssl.create_default_context())
        self.address=address
    def connect(self):
        sock=socket.create_connection((self.address,443),self.timeout)
        try:self.sock=self._context.wrap_socket(sock,server_hostname=self.host)
        except BaseException:sock.close();raise

def download(source, *, home=False, etag="", modified="", deadline=None):
    deadline=deadline or time.monotonic()+120
    current=source
    for redirect in range(4):
        u=validate_url(current,home)
        addresses=public_addresses(u.hostname)
        headers={"User-Agent":"RunnerHub-Event-Covers/1.0","Accept":"text/html" if home else "image/webp,image/png,image/jpeg"}
        for name,value in [("If-None-Match",etag),("If-Modified-Since",modified)]:
            if value and len(value)<=256 and not re.search(r"[\x00-\x1f\x7f]",value):headers[name]=value
        last_error=None
        for address in addresses:
            connection=PinnedHTTPS(u.hostname,address)
            try:
                if time.monotonic()>=deadline:raise TimeoutError("refresh_deadline")
                target=u.path+("?"+u.query if u.query else "")
                connection.request("GET",target,headers=headers)
                response=connection.getresponse()
                if response.status in (301,302,303,307,308):
                    current=urljoin(current,response.getheader("Location", ""));etag=modified=""
                    break
                if response.status==304:return None,{"etag":etag,"modified":modified}
                if response.status!=200:raise ValueError("http_"+str(response.status))
                content_type=response.getheader("Content-Type","").split(";",1)[0].lower()
                # Some image CDNs return bare "png" or a binary MIME type.
                # Pillow still verifies the actual format and image limits below.
                if home and content_type!="text/html" or not home and content_type not in ("image/png","image/jpeg","image/webp","png","jpg","jpeg","webp","application/octet-stream","binary/octet-stream"):
                    raise ValueError("unexpected_content_type")
                declared=response.getheader("Content-Length","")
                if declared.isdigit() and int(declared)>MAX_BYTES:raise ValueError("image_too_large")
                chunks=[];length=0
                while True:
                    if time.monotonic()>=deadline:raise TimeoutError("refresh_deadline")
                    chunk=response.read(65536)
                    if not chunk:break
                    length+=len(chunk)
                    if length>MAX_BYTES:raise ValueError("image_too_large")
                    chunks.append(chunk)
                return b"".join(chunks),{"etag":response.getheader("ETag","")[:256],"modified":response.getheader("Last-Modified","")[:256]}
            except (OSError,ssl.SSLError,http.client.HTTPException) as error:last_error=error
            finally:connection.close()
        else:
            if last_error:raise last_error
        if redirect==3:raise ValueError("too_many_redirects")
    raise ValueError("download_failed")

class HomeImages(HTMLParser):
    def __init__(self):super().__init__();self.images=[]
    def handle_starttag(self,tag,attrs):
        attributes=dict(attrs)
        if tag=="img" and "home-spotlight-media" in attributes.get("class","").split():
            self.images.append({"source":attributes.get("src","")})

def variants(raw):
    with warnings.catch_warnings():
        warnings.simplefilter("error",Image.DecompressionBombWarning)
        with Image.open(io.BytesIO(raw)) as check:
            if check.format not in ("PNG","JPEG","WEBP") or getattr(check,"n_frames",1)!=1:
                raise ValueError("unsupported_image")
            check.verify()
        with Image.open(io.BytesIO(raw)) as opened:
            picture=ImageOps.exif_transpose(opened)
            if picture.width*picture.height>MAX_PIXELS or min(picture.size)<32:
                raise ValueError("image_dimensions")
            alpha="A" in picture.getbands() or "transparency" in picture.info
            mode="RGBA" if alpha else "RGB"
            profile=picture.info.get("icc_profile")
            if profile:
                picture=ImageCms.profileToProfile(picture,ImageCms.ImageCmsProfile(io.BytesIO(profile)),ImageCms.createProfile("sRGB"),outputMode=mode)
            else:picture=picture.convert(mode)
            output=[]
            for width in sorted({min(480,picture.width),min(960,picture.width)}):
                height=max(1,round(picture.height*width/picture.width))
                resized=picture.resize((width,height),Image.Resampling.LANCZOS)
                buffer=io.BytesIO();resized.save(buffer,format="WEBP",quality=88,method=6,exact=True)
                data=buffer.getvalue()
                with Image.open(io.BytesIO(data)) as validated:
                    assert validated.format=="WEBP" and validated.size==(width,height)
                output.append({"width":width,"height":height,"bytes":len(data),"sha256":digest(data),"data":data})
            return picture.size,output

def write_atomic(path,data):
    if path.is_symlink():raise ValueError("symlink_target")
    descriptor,name=tempfile.mkstemp(prefix=".cover-",dir=path.parent)
    try:
        with os.fdopen(descriptor,"wb") as output:output.write(data);output.flush();os.fsync(output.fileno())
        os.chmod(name,0o644);os.replace(name,path)
    finally:
        if os.path.exists(name):os.unlink(name)

def output_folder(root):
    folder=root/"assets/event-covers"
    if (root/"assets").is_symlink() or folder.is_symlink():raise ValueError("symlink_output")
    folder.mkdir(parents=True,exist_ok=True)
    return folder

def valid_existing(entry,folder):
    if not isinstance(entry,dict) or entry.get("recipe")!=RECIPE or not isinstance(entry.get("variants"),list) or not 1<=len(entry["variants"])<=2:return False
    for variant in entry["variants"]:
        if not isinstance(variant,dict) or type(variant.get("width")) is not int or not 32<=variant["width"]<=960 or not re.fullmatch(r"[a-f0-9]{64}",str(variant.get("sha256",""))):return False
        path=Path(variant.get("path",""))
        if path.parent.as_posix()!="/assets/event-covers" or not ASSET_PATTERN.fullmatch(path.name):return False
        local=folder/path.name
        if local.is_symlink() or not local.is_file() or digest(local.read_bytes())!=variant.get("sha256"):return False
    return True

def refresh(root,images,fetch=download,now=None,originals=None):
    now=int(now or time.time());folder=output_folder(root)
    manifest_path=folder/"manifest.json"
    previous={}
    if manifest_path.is_file() and not manifest_path.is_symlink() and manifest_path.stat().st_size<=262144:
        try:previous=json.loads(manifest_path.read_text()).get("entries",{})
        except (ValueError,OSError):pass
    if not isinstance(previous,dict):previous={}
    entries={key:value for key,value in previous.items() if isinstance(value,dict) and type(value.get("expiresEpoch")) is int and type(value.get("fetchedEpoch")) is int and value["expiresEpoch"]>now}
    report={"generatedEpoch":now,"attempted":0,"updated":0,"unchanged":0,"skipped":0,"errors":[],"sourceBytes":0,"smallVariantBytes":0,"largeVariantBytes":0}
    deadline=time.monotonic()+180
    seen=set()
    for item in images[:MAX_IMAGES]:
        source=str(item.get("source","")).strip();key=digest(source.encode())
        if key in seen:continue
        seen.add(key);report["attempted"]+=1;old=previous.get(key,{})
        try:
            validate_url(source)
            existing=valid_existing(old,folder) and old.get("original")==source
            raw,cache=fetch(source,etag=old.get("etag","") if existing else "",modified=old.get("modified","") if existing else "",deadline=deadline)
            if raw is None:
                if not existing:raise ValueError("unexpected_not_modified")
                entry=dict(old);entry.update(fetchedEpoch=now,expiresEpoch=now+7*86400,**cache);entries[key]=entry;report["unchanged"]+=1
                continue
            if originals:
                originals.mkdir(parents=True,exist_ok=True);(originals/(key+".image")).write_bytes(raw)
            source_sha=digest(raw)
            if existing and old.get("sourceSha256")==source_sha:
                entry=dict(old);entry.update(fetchedEpoch=now,expiresEpoch=now+7*86400,**cache);entries[key]=entry;report["unchanged"]+=1
                continue
            dimensions,converted=variants(raw)
            if max(image["bytes"] for image in converted)>=len(raw)*.9:
                entries.pop(key,None);report["skipped"]+=1;continue
            metadata=[]
            for image in converted:
                filename=key[:24]+"-"+image["sha256"][:16]+"-"+str(image["width"])+".webp"
                target=folder/filename
                if target.is_symlink():raise ValueError("symlink_asset")
                if not target.is_file() or digest(target.read_bytes())!=image["sha256"]:write_atomic(target,image["data"])
                metadata.append({k:v for k,v in image.items() if k!="data"}|{"path":"/assets/event-covers/"+filename})
            entries[key]={"original":source,"sourceSha256":source_sha,"sourceBytes":len(raw),"sourceWidth":dimensions[0],"sourceHeight":dimensions[1],"recipe":RECIPE,"fetchedEpoch":now,"expiresEpoch":now+7*86400,"variants":metadata,**cache}
            report["updated"]+=1;report["sourceBytes"]+=len(raw);report["smallVariantBytes"]+=metadata[0]["bytes"];report["largeVariantBytes"]+=metadata[-1]["bytes"]
        except (OSError,ValueError,TimeoutError,ImageCms.PyCMSError,Image.DecompressionBombError,Image.DecompressionBombWarning) as error:
            report["errors"].append({"key":key,"type":type(error).__name__,"reason":str(error)[:120]})
    if not report["attempted"]:raise ValueError("empty_inventory")
    # Cap metadata independently of the number of historical immutable files.
    entries=dict(sorted(entries.items(),key=lambda item:item[1].get("fetchedEpoch",0),reverse=True)[:128])
    manifest={"schema":1,"generatedEpoch":now,"entries":entries}
    encoded=json.dumps(manifest,separators=(",",":"),ensure_ascii=True).encode()
    if len(encoded)>262144:raise ValueError("manifest_too_large")
    write_atomic(manifest_path,encoded);report["entries"]=len(entries)
    return report

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root",type=Path,default=Path(__file__).resolve().parents[2])
    parser.add_argument("--reviewed-inventory",type=Path)
    parser.add_argument("--originals",type=Path,help="QA only; never place source originals in the public asset directory")
    options=parser.parse_args();root=options.root.resolve();folder=output_folder(root)
    lock_path=folder/".refresh.lock"
    descriptor=os.open(lock_path,os.O_WRONLY|os.O_CREAT|os.O_APPEND|os.O_NOFOLLOW,0o644)
    with os.fdopen(descriptor,"a") as lock:
        try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:print(json.dumps({"status":"busy"}));return
        if options.reviewed_inventory:images=json.loads(options.reviewed_inventory.read_text())["images"]
        else:
            html,_=download("https://roadrunners.run/",home=True);document=HomeImages();document.feed(html.decode("utf-8"));images=document.images
        if not isinstance(images,list) or not 1<=len(images)<=MAX_IMAGES:raise ValueError("inventory_bounds")
        report=refresh(root,images,originals=options.originals)
        print(json.dumps(report,separators=(",",":")))
        if report["errors"]:raise SystemExit(1)

if __name__=="__main__":main()
