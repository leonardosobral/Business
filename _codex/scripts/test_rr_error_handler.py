"""Run isolated handler tests on Adobe CF; never send real mail or alter production logs."""
from pathlib import Path
import io,json,shlex,subprocess,tarfile,sys
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/error-handler'
buf=io.BytesIO()
with tarfile.open(fileobj=buf,mode='w') as tar:
 for base,prefix in [(STAGE/'candidate/RoadRunners',''),(STAGE/'tests','tests/')]:
  for p in base.rglob('*'):
   if p.is_file():tar.add(p,arcname=prefix+str(p.relative_to(base)),recursive=False)
remote=r'''
import io,json,os,pathlib,secrets,shutil,subprocess,sys,tarfile,tempfile
root=pathlib.Path(tempfile.mkdtemp(prefix='rr-handler-test-',dir='/var/www/business.roadrunners.run/_codex'));os.chmod(root,0o755)
try:
 with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read())) as tar:
  for m in tar.getmembers():
   name=pathlib.Path(m.name);assert m.isfile() and not name.is_absolute() and '..' not in name.parts
   p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(tar.extractfile(m).read());os.chmod(p,0o644)
 token=secrets.token_hex(24)
 (root/'.htaccess').write_text('Require local\n')
 (root/'Application.cfc').write_text('component {this.name="'+root.name+'";this.mappings["/services"]=getDirectoryFromPath(getCurrentTemplatePath()) & "services";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 (root/'run.cfm').write_text('<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfinclude template="tests/reporter.cfm"/><cfcatch><cfcontent reset="true"/><cfoutput>#serializeJSON({ok=false,message=cfcatch.message,type=cfcatch.type,line=cfcatch.tagContext[1].line})#</cfoutput></cfcatch></cftry>')
 p=subprocess.run(['curl','-sS','--max-time','25','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+root.name+'/run.cfm'],capture_output=True,text=True,timeout=30)
 try:r=json.loads(p.stdout)
 except Exception:r={'ok':False,'message':'Non-JSON test result','length':len(p.stdout)}
 print(json.dumps(r));sys.exit(0 if r.get('OK',r.get('ok')) else 1)
finally:shutil.rmtree(root)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
p=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=buf.getvalue(),capture_output=True,timeout=45)
print(p.stdout.decode());(STAGE/'test-reporter.json').write_bytes(p.stdout)
if p.stderr:print(p.stderr.decode()[-1000:])
sys.exit(p.returncode)
