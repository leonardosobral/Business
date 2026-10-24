from pathlib import Path
import hashlib, json, shlex, subprocess
S=Path(__file__).resolve().parent
files={str(p.relative_to(S/'candidate')):p.read_text() for p in (S/'candidate').rglob('*.cfm')}
remote='''
from pathlib import Path
import hashlib,json,os,pwd,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);result={}
with tempfile.TemporaryDirectory(prefix='seo-impact-compile-',dir='/var/tmp') as d:
 work=Path(d);os.chmod(work,0o755);src=work/'source';src.mkdir();out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
 for n,v in p.items():
  target=src/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(v)
 executables=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'))
 assert len(executables)==1,[str(x) for x in executables]
 executable=executables[0]
 runtime_user=pwd.getpwuid((executable.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
 cp=subprocess.run([str(executable),'-deploy','-cfruntimeuser',runtime_user,'-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
 output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
 if cp.returncode or 'Error compiling' in output or count!=len(p):raise RuntimeError('Compilation failed: '+output[-3000:])
 result['compiled_templates']=count
root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-impact-proxy-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 original=p['or/api/runner_apps_menu.cfm']
 assert (Path('/var/www/openresults.run/api')/'../../roadrunners.com.br/api/runner_apps_menu.cfm').resolve().is_file()
 fixture_relative=os.path.relpath('/var/www/roadrunners.com.br',work)+'/'
 (work/'run.cfm').write_text('<cfsetting showdebugoutput="false"/><cftry>'+original.replace('../../roadrunners.com.br/',fixture_relative)+'<cfcatch><cfcontent type="application/json" reset="true"/><cfoutput>##serializeJSON({error=cfcatch.message,detail=cfcatch.detail})##</cfoutput></cfcatch></cftry>'.replace('##','#'))
 tests=[]
 for method in ['GET','GET','POST']:
  cp=subprocess.run(['curl','-sS','--max-time','25','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-X',method,'-w','\\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=30)
  if cp.returncode:raise RuntimeError(cp.stderr)
  body,status=cp.stdout.rsplit('\\n',1)
  try:data=json.loads(body)
  except ValueError:raise RuntimeError('Proxy status '+status+' body: '+body[:1800])
  lower={k.lower():v for k,v in data.items()}
  if 'error' in lower:raise RuntimeError(json.dumps(lower))
  tests.append({'method':method,'status':int(status),'success':lower.get('success'),'items':len(lower.get('items',[])),'groups':len(lower.get('groups',[]))})
 result['proxy_tests']=tests
 assert tests[0]['status']==200 and tests[0]['success'] is True and tests[0]['items']>0,tests
 assert tests[1]==tests[0],tests
 assert tests[2]['status']==405 and tests[2]['success'] is False,tests
finally:shutil.rmtree(work)
result['tested_hashes']={n:hashlib.sha256(v.encode()).hexdigest() for n,v in p.items()}
print(json.dumps(result))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=250)
assert cp.returncode==0,cp.stderr[-3500:]
r=json.loads(cp.stdout);(S/'preflight-passed.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
