<cfscript>
svc=new services.teams.Service().init('runner_dba','rr_teams_test');
if(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{},{datasource='runner_dba'}).n[1]!=0)throw(type='Teams.Test',message='Fixture não está vazia');
users=queryExecute("SELECT id,email FROM public.tb_usuarios u WHERE NOT coalesce(is_admin,false) AND email IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 2",{},{datasource='runner_dba'});
staff=queryExecute("SELECT id FROM public.tb_usuarios u WHERE is_admin AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{},{datasource='runner_dba'});
data={name='Concorrência acesso fixture',type='GRUPO',document='52998224725',ownerName='Titular',technicalName='Técnico',cref='123456-G',crefUf='SC',email='fixture@example.org',phone='48999998888',whatsapp='48999998888',city='Florianópolis',uf='SC',attendance='AMBOS',description='',website=''};
try {
 id=svc.register(users.id[1],data);invite=svc.inviteAdmin(users.id[1],id,users.email[2],'VIEWER');APPLICATION.existingDirectLocked=false;
 thread name='existingDirect' action='run' actor=staff.id[1] teamId=id member=users.id[2] {
  try{var s=createObject('component','__TEAMS_COMPONENT__').init('runner_dba','rr_teams_test');s.addExistingAdmin(attributes.actor,attributes.teamId,attributes.member,'ADMIN');thread.code=200;}
  catch(Teams.Validation rejected){thread.code=409;}
  catch(any failed){thread.code=500;thread.error=failed.type;}
 }
 thread name='existingAccept' action='run' member=users.id[2] inviteToken=invite.token {
  try{var until=getTickCount()+5000;while(!APPLICATION.existingDirectLocked&&getTickCount()<until)sleep(10);var s=createObject('component','__TEAMS_COMPONENT__').init('runner_dba','rr_teams_test');s.acceptAdmin(attributes.member,attributes.inviteToken);thread.code=200;}
  catch(Teams.Validation rejected){thread.code=409;}
  catch(any failed){thread.code=500;thread.error=failed.type;}
 }
 thread action='join' name='existingDirect,existingAccept' timeout=15000;
 if(!structKeyExists(CFTHREAD.existingDirect,'code')||!structKeyExists(CFTHREAD.existingAccept,'code'))throw(type='Teams.Test',message='Concorrência não terminou');
 if(CFTHREAD.existingDirect.code!=200||CFTHREAD.existingAccept.code!=409)throw(type='Teams.Test',message='Conflito inesperado: direto='&CFTHREAD.existingDirect.code&', aceite='&CFTHREAD.existingAccept.code);
 if(svc.workspace(users.id[2],id).role!='ADMIN')throw(type='Teams.Test',message='Papel direto não preservado');
}finally{include 'existing_cleanup.cfm';}
if(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{},{datasource='runner_dba'}).n[1]!=0)throw(type='Teams.Test',message='Fixture não foi limpa');
writeOutput('TEAMS_EXISTING_CONCURRENCY_PASSED; concurrent direct grant and stale invite serialized; fixture cleaned; no deliveries');
</cfscript>
