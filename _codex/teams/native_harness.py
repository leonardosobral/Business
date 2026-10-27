"""Private localhost CF test harness, retained independently for Teams."""
REMOTE = r'''
import json,os,pathlib,secrets,subprocess,sys,tempfile
p=json.load(sys.stdin);mode=p.pop('mode');root=pathlib.Path('/var/www/business.roadrunners.run')
name='user_acquisition_'+secrets.token_hex(8);stage=root/'_codex'/name
archive=pathlib.Path(tempfile.mkdtemp(prefix='business-user-acquisition-test-',dir='/var/backups'));os.chmod(archive,0o700)
nonce=secrets.token_hex(24);result={'ok':False}
try:
 stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n')
 (stage/'Application.cfc').write_text('component {this.name="'+name+'";this.datasource="runner_dba";this.sessionManagement=true;this.setClientCookies=false;}')
 for rel,body in p.items():
  dest=stage/rel;dest.parent.mkdir(parents=True,exist_ok=True)
  body=body.replace('new services.UserAcquisitionMetrics','new _codex.'+name+'.services.UserAcquisitionMetrics')
  dest.write_text(body,encoding='utf-8-sig');os.chmod(dest,0o644)
 wrapper='<cfsetting showdebugoutput="false" requesttimeout="40"><cfscript>if(!listFind("127.0.0.1,::1",CGI.remote_addr) OR (CGI.http_x_acquisition_test ?: "") NEQ "'+nonce+'") {cfheader(statuscode=404);abort;}cfcontent(type="text/plain; charset=utf-8",reset=true);cfheader(name="Cache-Control",value="no-store");try{include "tests/'+mode+'.cfm";}catch(any failed){writeOutput("TEST_FAILED " & encodeForHTML(failed.type & ": " & failed.message & " " & left(failed.detail ?: "",600)));if(structKeyExists(failed,"tagContext"))for(frame in failed.tagContext)writeOutput(chr(10) & encodeForHTML(listLast(frame.template,"/") & ":" & frame.line));}</cfscript>'
 (stage/'run.cfm').write_text(wrapper,encoding='utf-8-sig');os.chmod(stage/'run.cfm',0o644)
 run=subprocess.run(['curl','--silent','--show-error','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Acquisition-Test: '+nonce,'https://business.roadrunners.run/_codex/'+name+'/run.cfm'],capture_output=True,timeout=50)
 raw=run.stdout.decode(errors='replace');(archive/'result.txt').write_text(raw);os.chmod(archive/'result.txt',0o600)
 result={'ok':not run.returncode and 'USER_ACQUISITION_'+mode.upper()+'_PASSED' in raw and 'TEST_FAILED' not in raw,'output':raw[-5000:] if '<!doctype' not in raw.lower() else 'Unexpected HTML; inspect private archive'}
 if mode=='preview' and result['ok']:
  import base64
  result['html']=base64.b64encode(raw.encode()).decode();result['output']='Aggregate preview compiled successfully'
finally:
 if stage.exists():stage.rename(archive/'fixture')
 result.update({'archive':str(archive),'stage_removed':not stage.exists()})
print(json.dumps(result))
'''
