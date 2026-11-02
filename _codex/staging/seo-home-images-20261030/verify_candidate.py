from pathlib import Path
import hashlib,json,shlex,subprocess,re
S=Path(__file__).resolve().parent
b=json.loads((S/'baseline.json').read_text());files={n:(S/'candidate'/n).read_text() for n in b['names']}
remote=r'''from pathlib import Path
import json,os,sys,shutil,tempfile,subprocess,re,posixpath,secrets,pwd
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');files=dict(p['files']);work=Path(tempfile.mkdtemp(prefix='seo-pace-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\n')
 # Inherit the real application/bootstrap; only the candidate includes are redirected.
 prefix='/_codex/'+work.name+'/'
 def redirect(name,content):
  def sub(m):
   target=m.group(1)
   if '#' in target:return m.group(0)
   dest=posixpath.normpath(posixpath.join(posixpath.dirname(name),target)) if not target.startswith('/') else target.lstrip('/')
   return '<cfinclude template="'+(prefix if dest in files else '/')+dest+'"'
  return re.sub(r'<cfinclude\s+template="([^"]+)"',sub,content,flags=re.I)
 for n,c in files.items():
  f=work/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(redirect(n,c))
 # Model cases render the exact media fragment from the candidate with edge-case data.
 index=files['index.cfm'];start=index.index('<cfif len(VARIABLES.homeSpotlightImage)>');end=index.index('\n                                        </div>',start);fragment=index[start:end]
 for label,rows in [('three',[{'nome_evento':'Primeira','image':'https://example.test/one.jpg'},{'nome_evento':'Segunda','image':'https://example.test/two.jpg'},{'nome_evento':'Terceira','image':'https://example.test/three.jpg'}]),('missing',[{'nome_evento':'Sem imagem','image':''},{'nome_evento':'Segunda','image':'https://example.test/two.jpg'}]),('empty',[])]:
  data=json.dumps(rows,separators=(',',':'));data=data.replace("'","''")
  (work/('model-'+label+'.cfm')).write_text('<cfsetting showdebugoutput="false"/><cfset qEventosDestaqueHome=queryNew("nome_evento,image","varchar,varchar",deserializeJSON(\''+data+'\'))/><cfoutput query="qEventosDestaqueHome"><cfset VARIABLES.homeSpotlightImage=image/>'+fragment+'</cfoutput>')
 cases={
 'pt':('index.cfm',''),
 'en':('index.cfm','URL.i18n_lang="en";URL.i18n_route="home";REQUEST.lang="en";'),
 'es':('index.cfm','URL.i18n_lang="es";URL.i18n_route="home";REQUEST.lang="es";'),
 'three':('model-three.cfm',''),
 'missing':('model-missing.cfm',''),
 'empty':('model-empty.cfm','')}


 # Each wrapper has a second localhost/token check and suppresses diagnostic pages.
 guard='<cfsetting showdebugoutput="false" requesttimeout="60"/><cfif NOT listFind("127.0.0.1,::1",cgi.remote_addr) OR compare(cgi.http_x_seo_verify ?: "","'+key+'") NEQ 0><cfheader statuscode="404"/><cfabort/></cfif>'
 result={}
 for name,(target,setup) in cases.items():
  wrapper=guard+'<cftry><cfscript>'+setup+'</cfscript><cfinclude template="'+target+'"/><cfcatch><cfcontent reset="true" type="application/json"/><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail,tag=cfcatch.tagContext[1].template,line=cfcatch.tagContext[1].line})#</cfoutput></cfcatch></cftry>'
  (work/(name+'.cfm')).write_text(wrapper)
  cp=subprocess.run(['curl','-sS','--max-time','65','--resolve','roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-w','\n%{http_code}','https://roadrunners.run'+prefix+name+'.cfm'],capture_output=True,text=True,timeout=70)
  body,status=cp.stdout.rsplit('\n',1);result[name]={'status':int(status),'body':body}
  if status not in ('200','400','404'):break
 # Compile the actual, unmodified candidate sources (includes compile independently).
 with tempfile.TemporaryDirectory(prefix='seo-pace-compile-',dir='/var/tmp') as d:
  src=Path(d)/'src';src.mkdir();os.chmod(d,0o755)
  for n,c in p['files'].items():
   if not n.endswith('.cfm'):continue
   f=src/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c)
  out=Path(d)/'out';out.mkdir();os.chmod(out,0o777);exe=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'))[0];user=pwd.getpwuid((exe.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
  cp=subprocess.run([str(exe),'-deploy','-cfruntimeuser',user,'-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  result['compile']={'ok':cp.returncode==0 and 'Error compiling' not in output and count==1,'templates':count,'error':output[-2000:] if 'Error compiling' in output or count!=1 else ''}
 print(json.dumps(result))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files}),capture_output=True,text=True,timeout=500)
assert cp.returncode==0,cp.stderr[-3000:]
r=json.loads(cp.stdout)
from html.parser import HTMLParser
class Images(HTMLParser):
 def __init__(self):super().__init__();self.images=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='img' and 'home-spotlight-media' in a.get('class','').split():self.images.append(a)
counts={}
for label,item in r.items():
 if label=='compile':continue
 assert item['status']==200,(label,item['status'],item['body'][:2000])
 parser=Images();parser.feed(item['body']);imgs=parser.images;counts[label]=len(imgs)
 if label=='empty':assert imgs==[];continue
 assert imgs,label
 if label=='missing':assert all(a.get('loading')=='lazy' and a.get('fetchpriority')=='low' for a in imgs)
 else:
  assert imgs[0].get('loading')=='eager' and imgs[0].get('fetchpriority')=='high',label
  assert all(a.get('loading')=='lazy' and a.get('fetchpriority')=='low' and a.get('decoding')=='async' for a in imgs[1:]),label
 assert all('this.onerror=null' in a.get('onerror','') and a.get('src') and a.get('alt') for a in imgs),label
 if label in ['pt','en','es']:
  assert 'data-spotlight-next' in item['body'] and 'data-spotlight-prev' in item['body']
  assert 'data-spotlight-track' in item['body']
  if label!='pt':assert 'lang="'+label+'"' in item['body']
assert counts['three']==3 and counts['missing']==1 and counts['empty']==0
assert r['compile']['ok'],r['compile']
receipt={'scenarios':6,'compiledTemplates':1,'imageCounts':counts,'hashes':{n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()}}
(S/'candidate-verified.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt,indent=2))
