"""Execute scoped CFML tests in an ephemeral, loopback-only application."""
from pathlib import Path
import io, json, shlex, subprocess, sys, tarfile
ROOT=Path(__file__).resolve().parents[2]
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
def run(mode='normalizer'):
    buf=io.BytesIO()
    files=list((ROOT/'portal/erros').rglob('*'))+[ROOT/'_codex/tests/error-triage-normalizer.cfm',ROOT/'_codex/tests/error-triage-service.cfm',ROOT/'_codex/sql/2026-09-26_error_triage.sql']
    with tarfile.open(fileobj=buf,mode='w') as tar:
        for p in files:
            if p.is_file():tar.add(p,arcname=str(p.relative_to(ROOT)),recursive=False)
    remote=r'''
import io,json,os,pathlib,secrets,shutil,subprocess,sys,tarfile,tempfile
root=pathlib.Path(tempfile.mkdtemp(prefix='error-triage-test-',dir='/var/www/business.roadrunners.run/_codex'))
os.chmod(root,0o755)
(root/'.htaccess').write_text('Require local\n')
try:
 with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read())) as tar:
  for member in tar.getmembers():
   p=pathlib.Path(member.name)
   assert member.isfile() and not p.is_absolute() and '..' not in p.parts
   dest=root/p;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(tar.extractfile(member).read());os.chmod(dest,0o644)
 token=secrets.token_hex(24)
 (root/'Application.cfc').write_text('component {this.name="'+root.name+'";this.datasource="runner_dba";this.mappings["/portal"]=getDirectoryFromPath(getCurrentTemplatePath()) & "portal";this.sessionManagement=true;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 mode=MODE
 body='<cfinclude template="_codex/tests/error-triage-normalizer.cfm"/>'
 if mode=='service':body+='<cfinclude template="_codex/tests/error-triage-service.cfm"/>'
 (root/'run.cfm').write_text('<cfsetting showdebugoutput="false" requesttimeout="120"/><cfcontent type="application/json" reset="true"/><cftry>'+body+'<cfoutput>#serializeJSON({ok=true,tests=triageTests})#</cfoutput><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({ok=false,message=cfcatch.message,detail=cfcatch.detail,type=cfcatch.type,line=cfcatch.tagContext[1].line,template=listLast(cfcatch.tagContext[1].template,"/")})#</cfoutput></cfcatch></cftry>')
 p=subprocess.run(['curl','-sS','--max-time','125','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+root.name+'/run.cfm'],capture_output=True,text=True,timeout=130)
 try:result=json.loads(p.stdout)
 except Exception:result={'ok':False,'message':'Non-JSON response','length':len(p.stdout)}
 if result.get('OK',result.get('ok')):
  guards=[]
  for target in ['portal/erros/includes/init.cfm','portal/erros/includes/actions.cfm','portal/erros/includes/workspace.cfm','portal/erros/includes/images.cfm','portal/erros/home.cfm']:
   check=subprocess.run(['curl','-sS','-o','/dev/null','-w','%{http_code}','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+root.name+'/'+target],capture_output=True,text=True,timeout=20)
   guards.append({'target':target,'status':check.stdout});assert check.stdout=='403'
  (root/'csrf.cfm').write_text('<cfset VARIABLES.requireAdminAllowed=true/><cfset etCsrf="expected"/><cfset FORM.triage_action="collect"/><cfset FORM.csrf="invalid"/><cfinclude template="portal/erros/includes/actions.cfm"/>')
  check=subprocess.run(['curl','-sS','-o','/dev/null','-w','%{http_code}','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+root.name+'/csrf.cfm'],capture_output=True,text=True,timeout=20)
  guards.append({'target':'invalid_csrf','status':check.stdout});assert check.stdout=='403'
  result['guards']=guards
 print(json.dumps(result));sys.exit(0 if result.get('OK',result.get('ok')) else 1)
finally:shutil.rmtree(root)
'''.replace('MODE',repr(mode))
    p=subprocess.run(SSH+['python3 -c '+shlex.quote(remote)],input=buf.getvalue(),capture_output=True,timeout=145)
    output=p.stdout.decode();print(output)
    (ROOT/'_codex/staging/error-triage'/('test-'+mode+'.json')).write_text(output)
    if p.stderr:print(p.stderr.decode()[-1500:])
    return p.returncode
if __name__=='__main__':sys.exit(run(sys.argv[1] if len(sys.argv)>1 else 'normalizer'))
