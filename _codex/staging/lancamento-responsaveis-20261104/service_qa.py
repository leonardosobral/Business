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
cfquery(name='adminUser',datasource='runner_dba'){writeOutput("SELECT id,email FROM public.tb_usuarios WHERE is_admin=true AND id>0 ORDER BY id LIMIT 1");}
cfquery(name='readerUser',datasource='runner_dba'){writeOutput("SELECT id,email FROM public.tb_usuarios WHERE is_admin=false AND id>0 ORDER BY id LIMIT 1");}
componentPath='_codex.' & listLast(getDirectoryFromPath(getCurrentTemplatePath()),'/') & '.LaunchAccess';
service=createObject('component',componentPath).init('runner_dba');
REQUEST.businessIdentity={id=adminUser.id[1],email=adminUser.email[1],version=1,sub='qa-launch-details'};
actorId=adminUser.id[1];initial=service.adminLaunchChecklist(actorId);target=initial.steps[6];createdIds=[];
requireCheck(arrayLen(initial.steps)==8,'Expected 8 steps');
requireCheck(structKeyExists(target,'responsible') && structKeyExists(target,'notes') && structKeyExists(target,'details_version'),'Missing new state fields');
noteText="Pendência: confirmar kit" & chr(10) & "Revisão com Ana d'Ávila; <script>alert(1)</script>";
transaction {
 saved=service.adminUpdateLaunchStepDetails(actorId,target.key,'Equipe QA',noteText,target.details_version);step=saved.steps[6];arrayAppend(createdIds,step.details_version);
 requireCheck(compare(step.responsible,'Equipe QA')==0 && compare(step.notes,noteText)==0,'Text or line breaks lost');
 requireCheck(step.completed==target.completed && step.version==target.version,'Details changed validation');
 requireCheck(len(step.details_author)>0 && len(step.details_changed_at)>0,'Details author/time missing');
 requireCheck(find('<script>',encodeForHTML(step.notes))==0,'Unsafe output encoding');
 reloaded=createObject('component',componentPath).init('runner_dba').adminLaunchChecklist(actorId);
 requireCheck(reloaded.steps[6].details_version==step.details_version && reloaded.steps[6].notes==noteText,'Persistence failed');
 validated=service.adminValidateLaunchStep(actorId,target.key,!target.completed,target.version);arrayAppend(createdIds,validated.steps[6].version);
 requireCheck(validated.steps[6].details_version==step.details_version && validated.steps[6].notes==noteText,'Validation overwrote details');
 second=service.adminUpdateLaunchStepDetails(actorId,target.key,'Nova equipe',noteText & chr(10) & 'Outro bloqueio',step.details_version);arrayAppend(createdIds,second.steps[6].details_version);
 requireCheck(second.steps[6].completed==validated.steps[6].completed,'Editing details reset validation');
 cleared=service.adminUpdateLaunchStepDetails(actorId,target.key,'','',second.steps[6].details_version);arrayAppend(createdIds,cleared.steps[6].details_version);
 requireCheck(cleared.steps[6].responsible=='' && cleared.steps[6].notes=='','Clearing fields failed');
 noop=service.adminUpdateLaunchStepDetails(actorId,target.key,'','',cleared.steps[6].details_version);requireCheck(noop.steps[6].details_version==cleared.steps[6].details_version,'No-op created another audit');
 stale=false;try{service.adminUpdateLaunchStepDetails(actorId,target.key,'Stale owner','Stale note',target.details_version);}catch(any err){stale=listLast(err.type,'.')=='Conflict';}requireCheck(stale,'Stale metadata overwrite accepted');
 transaction action='rollback';
}
remaining=queryExecute('SELECT count(*) AS n FROM estudo.auditoria_comercial WHERE id IN (:ids)',{ids:{value:arrayToList(createdIds),cfsqltype:'cf_sql_bigint',list:true}},{datasource:'runner_dba'});
requireCheck(remaining.n[1]==0,'QA writes were not rolled back');
for (sample in [{owner:repeatString('a',121),notes:''},{owner:'',notes:repeatString('a',2001)}]) {
 invalid=false;try{service.adminUpdateLaunchStepDetails(actorId,target.key,sample.owner,sample.notes,target.details_version);}catch(any err){invalid=listLast(err.type,'.')=='Validation';}requireCheck(invalid,'Oversized field accepted');
}
invalid=false;try{service.adminUpdateLaunchStepDetails(actorId,'unknown','','','0');}catch(any err){invalid=listLast(err.type,'.')=='Validation';}requireCheck(invalid,'Unknown step accepted');
invalidVersion=false;try{service.adminUpdateLaunchStepDetails(actorId,target.key,'','','-1');}catch(any err){invalidVersion=listLast(err.type,'.')=='Validation';}requireCheck(invalidVersion,'Invalid revision accepted');
REQUEST.businessIdentity={id=readerUser.id[1],email=readerUser.email[1],version=1,sub='qa-launch-details'};
forbidden=false;try{service.adminUpdateLaunchStepDetails(readerUser.id[1],target.key,'Not allowed','','0');}catch(any err){forbidden=listLast(err.type,'.')=='Access';}requireCheck(forbidden,'Non-admin write accepted');
structDelete(REQUEST,'businessIdentity');unauth=false;try{service.adminLaunchChecklist(actorId);}catch(any err){unauth=listLast(err.type,'.')=='Access';}requireCheck(unauth,'Unauthenticated access accepted');
report={'steps':8,'save_and_reload':true,'multiline_unicode_quotes':true,'output_encoding':true,'author_and_time':true,'details_preserve_validation':true,'validation_preserves_details':true,'clear_fields':true,'no_op_no_new_revision':true,'stale_write_conflict':true,'length_limits':true,'invalid_step_and_version_rejected':true,'non_admin_write_rejected':true,'verified_identity_required':true,'qa_writes_rolled_back':true};
'''

r=remote(body,{'source':base64.b64encode(cfc).decode(),'body':cf});(W/'service-qa.json').write_text(json.dumps(r,indent=2));print(r)
