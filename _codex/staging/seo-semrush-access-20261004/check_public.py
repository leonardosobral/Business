from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from html.parser import HTMLParser
import json,subprocess,sys,re
stage=Path(__file__).resolve().parent
import importlib.util
spec=importlib.util.spec_from_file_location('editorial_public',stage.parent/'seo-semrush-fixes-20261004/check_public.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);Meta=mod.Meta
class Assets(HTMLParser):
 def __init__(self):super().__init__();self.broken=[];self.video=[];self.email=0;self.decode=False
 def handle_starttag(self,t,attrs):
  a=dict(attrs)
  if t=='img' and 'avatar/athlete' in a.get('src',''):self.broken.append(a['src'])
  if a.get('data-audience-content-type')=='video' and 'videos-item' in a.get('class',''):self.video.append(a.get('data-audience-content-id'))
  if 'data-youtube-id' in a:self.video.append(a['data-youtube-id'])
  if t=='a' and '/cdn-cgi/l/email-protection' in a.get('href',''):self.email+=1
  if t=='script' and 'email-decode' in a.get('src',''):self.decode=True

def fetch(u):
 p=subprocess.run(['curl','-sS','--max-time','45','-w','\n%{http_code}\n%{time_total}\n%{content_type}',u],capture_output=True,text=True,timeout=50)
 if p.returncode:return {'url':u,'error':p.stderr}
 body,code,time,content=p.stdout.rsplit('\n',3);m=Meta();m.feed(body);a=Assets();a.feed(body)
 return {'url':u,'status':int(code),'seconds':float(time),'content_type':content,'canonical':m.canonical,'title':m.title,'robots':m.robots,'bad_avatar_srcs':list(set(a.broken)),'bad_avatar_count':len(a.broken),'video_ids':a.video,'email_protection_links':a.email,'email_decode_script':a.decode,'cf_error':'Error Occurred While Processing Request' in body}
if __name__=='__main__':
 issues=json.loads((stage/'issues.json').read_text());urls=sorted({r[k] for i in issues.values() for r in i['data']['data'] for k in ['source_url','target_url'] if r[k]})
 with ThreadPoolExecutor(max_workers=3) as pool:r=list(pool.map(fetch,urls))
 (stage/(sys.argv[1]+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
 for x in r:print(json.dumps(x,ensure_ascii=False))
