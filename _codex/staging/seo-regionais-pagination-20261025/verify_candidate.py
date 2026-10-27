from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent
b=json.loads((S/'baseline.json').read_text());files={n:(S/'candidate'/n).read_text() for n in b['names']}
remote=r'''from pathlib import Path
import json,os,sys,shutil,tempfile,subprocess,re,posixpath,secrets,pwd
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');files=dict(p['files']);work=Path(tempfile.mkdtemp(prefix='seo-pace-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\n')
 # Inherit the real application/bootstrap; only the candidate includes are redirected.
 files['calendar-data.cfm']=p['test'];files['home-test.cfm']=(root/'index.cfm').read_text().replace('template="includes/','template="/includes/')
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
 'pr1':('estado/index.cfm','URL.tag="PR";'),
 'pr2':('estado/index.cfm','URL.tag="PR";URL.pagina="2";'),
 'pr3':('estado/index.cfm','URL.tag="PR";URL.pagina="3";'),
 'curitiba':('estado/index.cfm','URL.tag="PR";URL.cidade="curitiba";'),
 'df':('estado/index.cfm','URL.tag="DF";'),
 'exact':('estado/index.cfm','URL.tag="PR";URL.periodo_inicio="2026-11-01";URL.periodo_fim="2026-11-30";'),
 'api':('api/eventos.cfm','URL.tag="PR";URL.cidade="curitiba";URL.distancia="5,5";URL.periodo_inicio="2026-11-01";URL.periodo_fim="2026-11-30";'),
 'next':('api/eventos.cfm','URL.tag="PR";URL.page=1;'),
 'empty':('estado/index.cfm','URL.tag="PR";URL.cidade="curitiba";URL.cupom=true;'),
 'missing':('estado/index.cfm','URL.tag="PR";URL.pagina="99999";'),
 'invalid':('estado/index.cfm','URL.tag="PR";URL.pagina="-1";'),
 'invalid-date':('estado/index.cfm','URL.tag="PR";URL.periodo_inicio="2026-11-31";URL.periodo_fim="2026-12-01";'),
 'reverse':('estado/index.cfm','URL.tag="PR";URL.periodo_inicio="2026-12-01";URL.periodo_fim="2026-11-01";'),
 'data1':('calendar-data.cfm','URL.tag="PR";URL.page=0;'),
 'data2':('calendar-data.cfm','URL.tag="PR";URL.page=1;'),
 'data3':('calendar-data.cfm','URL.tag="PR";URL.page=2;'),
 'data-exact':('calendar-data.cfm','URL.tag="PR";URL.periodo_inicio="2026-11-01";URL.periodo_fim="2026-11-30";'),
 'sc':('estado/index.cfm','URL.tag="SC";'),
 'rs':('estado/index.cfm','URL.tag="RS";'),
 'sp':('estado/index.cfm','URL.tag="SP";'),
 'home':('home-test.cfm','')}

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
   f=src/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c)
  out=Path(d)/'out';out.mkdir();os.chmod(out,0o777);exe=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'))[0];user=pwd.getpwuid((exe.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
  cp=subprocess.run([str(exe),'-deploy','-cfruntimeuser',user,'-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  result['compile']={'ok':cp.returncode==0 and 'Error compiling' not in output and count==10,'templates':count,'error':output[-2000:] if 'Error compiling' in output or count!=10 else ''}
  performance={}
 for label,url in [('candidate','https://roadrunners.run'+prefix+'pr1.cfm'),('baseline','https://roadrunners.run/estado/pr/')]:
  times=[]
  for _ in range(3):
   perf=subprocess.run(['curl','-sS','--max-time','60','--resolve','roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-o','/dev/null','-w','%{http_code} %{time_total}',url],capture_output=True,text=True,timeout=65)
   status,elapsed=perf.stdout.split();assert status=='200';times.append(float(elapsed))
  performance[label]=times
 result['_performance']=performance
 print(json.dumps(result))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files,'test':(S/'calendar-data.cfm').read_text()}),capture_output=True,text=True,timeout=500)
assert cp.returncode==0,cp.stderr[-3000:]
r=json.loads(cp.stdout)
expected={'missing':404,'invalid':400,'invalid-date':400,'reverse':400}
for k,v in r.items():
 if k in ('compile','_performance'):continue
 if v['status']!=expected.get(k,200):
  print(k,v['status'],v['body'][:2500]);raise SystemExit(1)
 (S/('candidate-'+k+'.html')).write_text(v['body'])
assert r['compile']['ok'],r['compile']
from html import unescape
import re
for k in ['pr1','pr2','pr3','curitiba','df','exact','api','empty']:
 assert 'data-regional-summary' in r[k]['body'],k
assert 'data-regional-summary' not in r['next']['body']
for k,page in [('pr1',1),('pr2',2),('pr3',3)]:
 h=unescape(r[k]['body']);assert 'data-page="'+str(page)+'"' in h,k
 canonical=re.search(r'<link rel="canonical" href="([^"]+)',h)[1]
 assert canonical=='https://roadrunners.run/estado/pr/'+('' if page==1 else '?pagina='+str(page)),canonical
 assert 'name="robots" content="noindex' not in h
assert 'name="robots" content="noindex,follow"' in r['exact']['body']
d=[json.loads(r['data'+str(i)]['body']) for i in [1,2,3]]
# Adobe preserves struct key casing variably.
d=[{k.lower():v for k,v in x.items()} for x in d]
assert [x['rows'] for x in d]==[50,50,d[0]['total']-100]
ids=[item for x in d for item in x['ids']];assert len(ids)==len(set(ids))==d[0]['total']
exact={k.lower():v for k,v in json.loads(r['data-exact']['body']).items()};assert exact['rows']<=50 and exact['periodvalid']
receipt={'scenarios':len(r)-2,'performance':r['_performance'],'compiledTemplates':r['compile']['templates'],'totalPR':d[0]['total'],'disjointIds':len(ids),'exactRows':exact['rows'],'hashes':{n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()}}
(S/'candidate-verified.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({k:v for k,v in receipt.items() if k!='hashes'}))
