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
 pass # Real public page scenarios use the application bootstrap.
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
 'estacoes':('evento/index.cfm','URL.tag="2026-circuito-das-estacoes-2026-verao-goiania";'),
 'ribeirao':('evento/index.cfm','URL.tag="2026-live-run-xp-ribeirao-preto-ii-2026";'),
 'live-themed':('evento/index.cfm','URL.tag="2026-live-run-xp-brasilia-2026-iii";'),
 'marathon':('evento/index.cfm','URL.tag="2026-maratona-de-curitiba-santander-2026";'),
 'fortaleza':('evento/index.cfm','URL.tag="2026-live-run-xp-fortaleza-2026-ii";')}

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
  result['compile']={'ok':cp.returncode==0 and 'Error compiling' not in output and count==2,'templates':count,'error':output[-2000:] if 'Error compiling' in output or count!=2 else ''}
  performance={}
 for label,url in [('candidate','https://roadrunners.run'+prefix+'estacoes.cfm'),('baseline','https://roadrunners.run/evento/'+p['sampleTag']+'/')]:
  times=[]
  for _ in range(3):
   perf=subprocess.run(['curl','-sS','--max-time','60','--resolve','roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-o','/dev/null','-w','%{http_code} %{time_total}',url],capture_output=True,text=True,timeout=65)
   status,elapsed=perf.stdout.split();assert status=='200';times.append(float(elapsed))
  performance[label]=times
 result['_performance']=performance
 print(json.dumps(result))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files,'sampleTag':'2026-circuito-das-estacoes-2026-verao-goiania'}),capture_output=True,text=True,timeout=500)
assert cp.returncode==0,cp.stderr[-3000:]
r=json.loads(cp.stdout)
for k,v in r.items():
 if k in ('compile','_performance'):continue
 (S/('candidate-'+k+'.html')).write_text(v['body'])
 assert v['status']==200,(k,v['status'],v['body'][:2200])
assert r['compile']['ok'],r['compile']
from html import unescape
import re
for k in ['estacoes','ribeirao']:
 assert 'data-event-circuits' in r[k]['body'],k
for k in ['live-themed','marathon','fortaleza']:
 assert 'data-event-circuits' not in r[k]['body'],k
for k,v in r.items():
 if k in ['compile','_performance']:continue
 assert 'href="https://roadrunners.run/evento/' in unescape(v['body']),k
receipt={'scenarios':len(r)-2,'performance':r['_performance'],'compiledTemplates':r['compile']['templates'],'hashes':{n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()}}
(S/'candidate-verified.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps({k:v for k,v in receipt.items() if k!='hashes'}))
