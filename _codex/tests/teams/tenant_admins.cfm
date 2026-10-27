<cfscript>
checks=0;function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
svc=new services.teams.Service().init('runner_dba','rr_teams_test');
users=queryExecute("SELECT id,email FROM public.tb_usuarios u WHERE NOT coalesce(is_admin,false) AND email IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 4",{},{datasource='runner_dba'});
staff=queryExecute("SELECT id FROM public.tb_usuarios u WHERE is_admin AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{},{datasource='runner_dba'});owner=users.id[1];admin=users.id[2];viewer=users.id[3];candidate=users.id[4];globalId=staff.id[1];
data={name='Responsáveis fixture',type='GRUPO',document='52998224725',ownerName='Titular',technicalName='Técnico',cref='123456-G',crefUf='SC',email='fixture@example.org',phone='48999998888',whatsapp='48999998888',city='Florianópolis',uf='SC',attendance='AMBOS',description='',website=''};
function base(){var id=svc.register(owner,data);svc.addExistingAdmin(globalId,id,admin,'ADMIN');svc.addExistingAdmin(globalId,id,viewer,'VIEWER');return id;}
function scenario(required string label,required any body,boolean denied=false){var blocked=false;transaction{try{arguments.body();}catch(Teams.Validation e){if(!denied)rethrow;blocked=true;}catch(Teams.Forbidden e){if(!denied)rethrow;blocked=true;}finally{transaction action='rollback';}}check(!denied||blocked,label);check(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{},{datasource='runner_dba'}).n[1]==0,'Rollback '&label);}
scenario('Titular busca e inclui administrador',function(){var id=base();var found=svc.adminCandidates(owner,id,users.email[4]);check(found.recordCount>0,'Busca autorizada');svc.addExistingAdmin(owner,id,candidate,'ADMIN');check(svc.workspace(candidate,id).role=='ADMIN','Inclusão pelo titular');});
scenario('Administrador inclui consulta',function(){var id=base();svc.addExistingAdmin(admin,id,candidate,'VIEWER');check(svc.workspace(candidate,id).role=='VIEWER','Inclusão limitada');});
scenario('Política por papel',function(){var id=base();check(svc.workspace(owner,id).adminPolicy.roles=='ADMIN,VIEWER','Titular');check(svc.workspace(admin,id).adminPolicy.roles=='VIEWER','Administrador');check(svc.workspace(viewer,id).adminPolicy.roles=='','Consulta');check(svc.workspace(globalId,id).adminPolicy.roles=='OWNER,ADMIN,VIEWER','Global');});
scenario('Titular altera consulta para administrador',function(){var id=base();svc.changeAdminRole(owner,id,viewer,'ADMIN','VIEWER');check(svc.workspace(viewer,id).role=='ADMIN','Mudança autorizada');});
scenario('Administrador não inclui par',function(){var id=base();svc.addExistingAdmin(admin,id,candidate,'ADMIN');},true);
scenario('Administrador não inclui titular',function(){var id=base();svc.addExistingAdmin(admin,id,candidate,'OWNER');},true);
scenario('Titular não atribui titularidade',function(){var id=base();svc.addExistingAdmin(owner,id,candidate,'OWNER');},true);
scenario('Consulta não busca',function(){var id=base();svc.adminCandidates(viewer,id,'Teste');},true);
scenario('Consulta não adiciona',function(){var id=base();svc.addExistingAdmin(viewer,id,candidate,'VIEWER');},true);
scenario('Administrador não altera pares',function(){var id=base();svc.changeAdminRole(admin,id,viewer,'ADMIN','VIEWER');},true);
scenario('Titular não altera titularidade',function(){var id=base();svc.changeAdminRole(owner,id,owner,'ADMIN','OWNER');},true);
scenario('Titular não promove a titular',function(){var id=base();svc.changeAdminRole(owner,id,viewer,'OWNER','VIEWER');},true);
scenario('Outro Team não concede acesso',function(){var id=base();svc.addExistingAdmin(candidate,id,admin,'VIEWER');},true);
scenario('Convites respeitam limites',function(){var id=base();svc.inviteAdmin(owner,id,'owner-fixture@example.org','ADMIN');svc.inviteAdmin(admin,id,'admin-fixture@example.org','VIEWER');check(queryExecute('SELECT count(*) n FROM rr_teams_test.admin_invite',{},{datasource='runner_dba'}).n[1]==2,'Convites permitidos');});
scenario('Administrador não convida par',function(){var id=base();svc.inviteAdmin(admin,id,'peer-fixture@example.org','ADMIN');},true);
scenario('Administrador não substitui convite superior',function(){var id=base();svc.inviteAdmin(owner,id,users.email[4],'ADMIN');svc.inviteAdmin(admin,id,users.email[4],'VIEWER');},true);
scenario('Administrador não inclui destinatário de convite superior',function(){var id=base();svc.inviteAdmin(owner,id,users.email[4],'ADMIN');svc.addExistingAdmin(admin,id,candidate,'VIEWER');},true);
scenario('Administrador não revoga convite superior',function(){var id=base();var invite=svc.inviteAdmin(owner,id,'peer-fixture@example.org','ADMIN');var row=queryExecute('SELECT id_invite FROM rr_teams_test.admin_invite',{},{datasource='runner_dba'});svc.revokeInvite(admin,id,row.id_invite[1]);},true);
scenario('Administrador revoga consulta',function(){var id=base();svc.inviteAdmin(admin,id,'read-fixture@example.org','VIEWER');var row=queryExecute('SELECT id_invite FROM rr_teams_test.admin_invite',{},{datasource='runner_dba'});svc.revokeInvite(admin,id,row.id_invite[1]);check(queryExecute('SELECT count(*) n FROM rr_teams_test.admin_invite WHERE revoked_at IS NOT NULL',{},{datasource='runner_dba'}).n[1]==1,'Revogação permitida');});
scenario('Convite não altera membro existente',function(){var id=base();svc.inviteAdmin(admin,id,users.email[2],'VIEWER');},true);
scenario('Consulta não revoga convite',function(){var id=base();svc.inviteAdmin(owner,id,'read-fixture@example.org','VIEWER');var row=queryExecute('SELECT id_invite FROM rr_teams_test.admin_invite',{},{datasource='runner_dba'});svc.revokeInvite(viewer,id,row.id_invite[1]);},true);
scenario('Titular não remove titular',function(){var id=base();svc.addExistingAdmin(globalId,id,candidate,'OWNER');svc.removeAdmin(owner,id,candidate);},true);
check(queryExecute('SELECT count(*) n FROM rr_teams_test.mail_outbox',{},{datasource='runner_dba'}).n[1]==0,'Fila fixture limpa');
writeOutput('TEAMS_TENANT_ADMINS_PASSED '&checks&'; rollback; no real access changed');
</cfscript>
