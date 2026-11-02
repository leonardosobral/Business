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
 cases={
 'aracaju':('evento/index.cfm','URL.tag="2026-maratona-de-aracaju-2026";'),
 'aracaju-en':('evento/index.cfm','URL.tag="2026-maratona-de-aracaju-2026";URL.i18n_lang="en";URL.i18n_route="event";REQUEST.lang="en";'),
 'aracaju-es':('evento/index.cfm','URL.tag="2026-maratona-de-aracaju-2026";URL.i18n_lang="es";URL.i18n_route="event";REQUEST.lang="es";'),
 'floripa':('evento/index.cfm','URL.tag="2026-maratona-internacional-de-floripa-2026";'),
 'location-only':('evento/index.cfm','URL.tag="2026-live-run-xp-porto-seguro-2026";')}


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
from html import unescape
from html.parser import HTMLParser
class Scripts(HTMLParser):
 def __init__(self):super().__init__();self.items=[]
 def handle_starttag(self,tag,attrs):
  if tag=='script':self.items.append(dict(attrs))
for name in ['aracaju','aracaju-en','aracaju-es','floripa','location-only']:
 v=r[name];assert v['status']==200,(name,v['status'],v['body'][:1800])
 h=unescape(v['body']);parser=Scripts();parser.feed(h)
 lazy=[a for a in parser.items if 'event-maps-lazy.min.js' in a.get('src','')];assert len(lazy)==1,name
 assert lazy[0].get('data-mapbox-src')=='https://api.mapbox.com/mapbox-gl-js/v3.25.0/mapbox-gl.js'
 assert lazy[0].get('data-location-src','').startswith('/assets/js/event-location-mapbox.min.js?')
 assert not any('api.mapbox.com/mapbox-gl-js/' in a.get('src','') for a in parser.items),name
 assert not any('event-route-mapbox.min.js' in a.get('src','') or 'event-location-mapbox.min.js' in a.get('src','') for a in parser.items),name
 assert len(re.findall(r'<h1[ >]',h))==1 and 'application/ld+json' in h,name
 assert 'data-event-location-component' in h,name
 if name.startswith('aracaju'):
  assert lazy[0].get('data-route-src','').startswith('/assets/js/event-route-mapbox.min.js?')
  assert 'data-event-route-component' in h and 'data-event-route-index' in h
 if name=='floripa':assert 'data-post-race' in h and '2027-maratona-internacional-de-floripa-fibra-2027' in h
 if name=='aracaju-en':assert 'lang="en"' in h and '/en/event/' in h
 if name=='aracaju-es':assert 'lang="es"' in h and '/es/evento/' in h
assert r['compile']['ok'],r['compile']
receipt={'scenarios':5,'compiledTemplates':1,'nodeTests':14,'hashes':{n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()}}
(S/'candidate-verified.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt,indent=2))
