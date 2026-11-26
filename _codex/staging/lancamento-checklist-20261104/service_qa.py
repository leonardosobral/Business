from pathlib import Path
import json,base64
from inspect import remote,ROOT,W
cfc=(W/'runtime/estudos/includes/StudyAccess.cfc').read_bytes()
body=r'''
source=base64.b64decode(payload['source']).decode()
# Isolated local-only CF test component. The bridge owns/removes its temporary folder.
qaBridgeSource=bridge.__code__
import inspect as python_inspect
# The standard bridge is intentionally copied here only to add a candidate CFC.
def candidateBridge(root,body):
 import secrets
 work=Path(tempfile.mkdtemp(prefix='launch-checklist-qa-',dir=root/'_codex'));os.chmod(work,0o755);token=secrets.token_hex(24)
 try:
  (work/'.htaccess').write_text('Require local\n')
  (work/'LaunchAccess.cfc').write_text(source)
  (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
  (work/'run.cfm').write_text('<cfsetting requesttimeout="90" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>'+body+'writeOutput(serializeJSON(report));</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>')
  p=subprocess.run(['curl','-sS','--max-time','95','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=100)
  result=json.loads(p.stdout)
  if any(k.lower()=='error'for k in result):raise RuntimeError(json.dumps(result))
  return result
 finally:shutil.rmtree(work)
print(json.dumps(candidateBridge(ROOT,payload['body'])))
'''
cf=r'''
function requireCheck(required boolean test,required string message){if(!test)throw(message=message);}
cfquery(name='before',datasource='runner_dba'){writeOutput("SELECT count(*) AS n FROM estudo.auditoria_comercial WHERE entidade='launch_checklist'");}
cfquery(name='adminUser',datasource='runner_dba'){writeOutput("SELECT id,email FROM public.tb_usuarios WHERE is_admin=true ORDER BY id LIMIT 1");}
cfquery(name='readerUser',datasource='runner_dba'){writeOutput("SELECT id,email FROM public.tb_usuarios WHERE is_admin=false AND id>0 ORDER BY id LIMIT 1");}
service=createObject('component','_codex.' & listLast(getDirectoryFromPath(getCurrentTemplatePath()),'/') & '.LaunchAccess').init('runner_dba');
REQUEST.businessIdentity={id=adminUser.id[1],email=adminUser.email[1],version=1,sub='qa-launch-checklist'};
actorId=adminUser.id[1];
initial=service.adminLaunchChecklist(actorId);requireCheck(arrayLen(initial.steps)==8,'Expected 8 steps');
requireCheck(initial.steps[3].key=='contrato-abraceo','ABRACEO contract missing');
transaction {
 target=initial.steps[6];
 changed=service.adminValidateLaunchStep(actorId,target.key,!target.completed,target.version);
 requireCheck(changed.steps[6].completed!=target.completed,'Validation not saved');
 requireCheck(changed.steps[6].version!=target.version,'Revision not advanced');
 requireCheck(len(changed.steps[6].author)>0 && len(changed.steps[6].changed_at)>0,'Author/time missing');
 persisted=service.adminLaunchChecklist(actorId);requireCheck(persisted.steps[6].version==changed.steps[6].version,'Read did not preserve state');
 reopened=service.adminValidateLaunchStep(actorId,target.key,target.completed,changed.steps[6].version);requireCheck(reopened.steps[6].completed==target.completed,'Reopen failed');
 invalid=false;try{service.adminValidateLaunchStep(actorId,'unknown',true,'0');}catch(any err){invalid=listLast(err.type,'.')=='Validation';}requireCheck(invalid,'Unknown step accepted');
 stale=false;try{service.adminValidateLaunchStep(actorId,target.key,target.completed,target.version);}catch(any err){stale=listLast(err.type,'.')=='Conflict';}requireCheck(stale,'Stale writes must conflict');
 transaction action='rollback';
}
cfquery(name='after',datasource='runner_dba'){writeOutput("SELECT count(*) AS n FROM estudo.auditoria_comercial WHERE entidade='launch_checklist'");}
requireCheck(before.n[1]==after.n[1],'QA audit writes were not rolled back');
REQUEST.businessIdentity={id=readerUser.id[1],email=readerUser.email[1],version=1,sub='qa-launch-checklist'};
forbidden=false;forbiddenError='none';try{service.adminLaunchChecklist(readerUser.id[1]);}catch(any err){forbiddenError=err.type & ': ' & err.message;forbidden=listLast(err.type,'.')=='Access';}requireCheck(forbidden,'Non-admin read check: ' & forbiddenError);
forbiddenWrite=false;try{service.adminValidateLaunchStep(readerUser.id[1],'organizar',true,'0');}catch(any err){forbiddenWrite=listLast(err.type,'.')=='Access';}requireCheck(forbiddenWrite,'Non-admin write accepted');
structDelete(REQUEST,'businessIdentity');unauth=false;try{service.adminLaunchChecklist(actorId);}catch(any err){unauth=listLast(err.type,'.')=='Access';}requireCheck(unauth,'Unauthenticated read accepted');
report={'steps':8,'save_and_reload':true,'reopen':true,'stale_write_conflict':true,'unknown_step_rejected':true,'non_admin_read_write_rejected':true,'verified_identity_required':true,'qa_writes_rolled_back':true,'saved_steps':after.n[1]};
'''
r=remote(body,{'source':base64.b64encode(cfc).decode(),'body':cf});(W/'service-qa.json').write_text(json.dumps(r,indent=2));print(r)
