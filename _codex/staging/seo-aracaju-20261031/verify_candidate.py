from pathlib import Path
from html.parser import HTMLParser
import hashlib,json,shlex,subprocess,re
S=Path(__file__).resolve().parent
b=json.loads((S/'baseline.json').read_text())
projects={k:{'root':v['root'],'files':{str(p.relative_to(S/'candidate'/k)):p.read_text() for p in (S/'candidate'/k).rglob('*.cfm')}} for k,v in b.items()}
cases={
 'rr':{
  'city':('estado/index.cfm','URL.tag="SE";URL.cidade="aracaju";'),
  'state':('estado/index.cfm','URL.tag="SE";'),
  'filtered':('estado/index.cfm','URL.tag="SE";URL.cidade="aracaju";URL.distancia="5,5";'),
  'other-city':('estado/index.cfm','URL.tag="SE";URL.cidade="itabaiana";'),
  'other-state':('estado/index.cfm','URL.tag="PR";'),
  'edition':('evento/index.cfm','URL.tag="2026-maratona-de-aracaju-2026";'),
  'edition-en':('evento/index.cfm','URL.tag="2026-maratona-de-aracaju-2026";URL.i18n_lang="en";URL.i18n_route="event";REQUEST.lang="en";'),
  'edition-es':('evento/index.cfm','URL.tag="2026-maratona-de-aracaju-2026";URL.i18n_lang="es";URL.i18n_route="event";REQUEST.lang="es";'),
  'history':('maratona/index.cfm','URL.tag="maratona-de-aracaju";'),
  'other-history':('maratona/index.cfm','URL.tag="maratona-de-curitiba";')},
 'or':{
  'city':('estado/index.cfm','URL.tag="SE";URL.cidade="aracaju";'),
  'state':('estado/index.cfm','URL.tag="SE";'),
  'filtered':('estado/index.cfm','URL.tag="SE";URL.cidade="aracaju";URL.filtro="maratonas";'),
  'other-city':('estado/index.cfm','URL.tag="SE";URL.cidade="itabaiana";'),
  'other-state':('estado/index.cfm','URL.tag="SC";'),
  'edition':('evento/index.cfm','URL.tag="2026-maratona-de-aracaju-2026";'),
  'previous':('evento/index.cfm','URL.tag="2025-maratona-de-aracaju-2025";')}}
remote=r'''from pathlib import Path
import json,os,sys,shutil,tempfile,subprocess,re,posixpath,secrets,pwd
p=json.load(sys.stdin);result={}
for project,config in p['projects'].items():
 root=Path(config['root']);files=dict(config['files']);work=Path(tempfile.mkdtemp(prefix='seo-aracaju-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
 try:
  (work/'.htaccess').write_text('Require local\n')
  if project=='rr':
   for n in ['maratona/index.cfm','includes/permanent_race_overview.cfm']:files[n]=(root/n).read_text()
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
  guard='<cfsetting showdebugoutput="false" requesttimeout="70"/><cfif NOT listFind("127.0.0.1,::1",cgi.remote_addr) OR compare(cgi.http_x_seo_verify ?: "","'+key+'") NEQ 0><cfheader statuscode="404"/><cfabort/></cfif>'
  host='roadrunners.run' if project=='rr' else 'openresults.run';result[project]={}
  for label,(target,setup) in p['cases'][project].items():
   wrapper=guard+'<cftry><cfscript>'+setup+'</cfscript><cfinclude template="'+target+'"/><cfcatch><cfcontent reset="true" type="application/json"/><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail,tag=cfcatch.tagContext[1].template,line=cfcatch.tagContext[1].line})#</cfoutput></cfcatch></cftry>'
   (work/(label+'.cfm')).write_text(wrapper)
   cp=subprocess.run(['curl','-sS','--max-time','75','--resolve',host+':443:127.0.0.1','-H','X-SEO-Verify: '+key,'-w','\n%{http_code}','https://'+host+prefix+label+'.cfm'],capture_output=True,text=True,timeout=80)
   body,status=cp.stdout.rsplit('\n',1);result[project][label]={'status':int(status),'body':body}
   if status not in ['200','400','404']:break
  with tempfile.TemporaryDirectory(prefix='seo-aracaju-compile-',dir='/var/tmp') as d:
   src=Path(d)/'src';src.mkdir();os.chmod(d,0o755)
   for n,c in config['files'].items():
    f=src/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c)
   out=Path(d)/'out';out.mkdir();os.chmod(out,0o777);exe=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'))[0];user=pwd.getpwuid((exe.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
   cp=subprocess.run([str(exe),'-deploy','-cfruntimeuser',user,'-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
   output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
   result[project]['compile']={'ok':cp.returncode==0 and 'Error compiling' not in output and count==len(config['files']),'templates':count,'output':output[-1800:]}
 finally:shutil.rmtree(work)
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'projects':projects,'cases':cases}),capture_output=True,text=True,timeout=650)
assert cp.returncode==0,cp.stderr[-2500:]
data=json.loads(cp.stdout)
(S/'candidate-results.json').write_text(json.dumps(data,ensure_ascii=False)+'\n')
for project,rows in data.items():
 for name,v in rows.items():
  if name=='compile':continue
  (S/('candidate-'+project+'-'+name+'.html')).write_text(v['body'])
  assert v['status']==200,(project,name,v['status'],v['body'][:2000])
 assert rows['compile']['ok'],(project,rows['compile'])
class Page(HTMLParser):
 def __init__(self):super().__init__();self.h1=0;self.links=[];self.canonical=[];self.ids=[];self.ld=False;self.json=[]
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='h1':self.h1+=1
  if a.get('id'):self.ids.append(a['id'])
  if t=='a':self.links.append(a.get('href',''))
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if t=='script' and a.get('type')=='application/ld+json':self.ld=True
 def handle_endtag(self,t):
  if t=='script':self.ld=False
 def handle_data(self,d):
  if self.ld:self.json.append(json.loads(d))
for project,rows in data.items():
 for name,v in rows.items():
  if name=='compile':continue
  h=v['body'];p=Page();p.feed(h)
  assert p.h1==1,(project,name,'h1',p.h1)
  assert len(p.ids)==len(set(p.ids)),(project,name,'duplicate HTML ids')
  assert len(p.canonical)==1,(project,name,'canonical')
  expected=name in ['city','state','edition','history'] or (project=='or' and name=='filtered')
  assert ('data-aracaju-2026' in h)==expected,(project,name,'feature scope')
  if expected:
   assert 'ainda não' in h and '2026' in h,(project,name,'honest publication state')
   if project=='rr':assert 'https://openresults.run/evento/2026-maratona-de-aracaju-2026/' in p.links
  if project=='or' and name in ['city','filtered']:assert p.canonical==['https://openresults.run/estado/se/?cidade=aracaju']
  if project=='rr' and name=='edition':
   assert any('focoradical.com.br' in u for u in p.links),'existing gallery exposed'
   assert any('20261031-maratona-de-aracaju-2026-1o-dia' in u for u in p.links),'Saturday gallery must be reachable separately'
   assert '31/10, sábado' in h and '01/11, domingo' in h
  if project=='or' and name=='previous':assert 'id="nav-resultados"' in h and 'data-aracaju-2026' not in h
  assert not any('##maratona' in u for u in p.links),(project,name,'bad anchor')
receipt={'projects':2,'scenarios':sum(len(c) for c in cases.values()),'compiledTemplates':sum(d['compile']['templates'] for d in data.values()),'hashes':{k:{n:hashlib.sha256(c.encode()).hexdigest() for n,c in p['files'].items()} for k,p in projects.items()}}
(S/'candidate-verified.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt))
