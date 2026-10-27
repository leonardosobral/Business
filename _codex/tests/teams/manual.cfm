<cfscript>
checks=0;function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
svc=new services.teams.Service().init('runner_dba','rr_teams_test');
users=queryExecute("SELECT id FROM public.tb_usuarios u WHERE NOT coalesce(is_admin,false) AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{},{datasource='runner_dba'});
staff=queryExecute("SELECT id FROM public.tb_usuarios u WHERE is_admin AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{},{datasource='runner_dba'});owner=users.id[1];globalId=staff.id[1];
data={name='Cadastro manual fixture',type='ASSESSORIA',document='52998224725',ownerName='Titular',technicalName='Técnico',cref='123456-G',crefUf='SC',email='manual@example.org',phone='48999998888',whatsapp='48999998888',city='Florianópolis',uf='SC',attendance='AMBOS',description='',website=''};
function scenario(required string label,required any body,boolean denied=false){var blocked=false;transaction{try{arguments.body();}catch(Teams.Validation e){if(!denied)rethrow;blocked=true;}catch(Teams.Forbidden e){if(!denied)rethrow;blocked=true;}finally{transaction action='rollback';}}check(!denied||blocked,label);check(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{},{datasource='runner_dba'}).n[1]==0,'Rollback ' & label);}
check(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{},{datasource='runner_dba'}).n[1]==0,'Fixture vazia');
scenario('Cadastro manual global',function(){
 var id=svc.registerGlobal(globalId,data);var t=svc.workspace(globalId,id).team;
 check(t.status=='PENDING'&&t.requested_by==globalId,'Estado e autoria');check(t.slug=='cadastro-manual-fixture-'&id,'Link único');
 check(queryExecute('SELECT count(*) n FROM rr_teams_test.admin',{},{datasource='runner_dba'}).n[1]==0,'Criador não vira titular');
 check(queryExecute('SELECT count(*) n FROM rr_teams_test.membership',{},{datasource='runner_dba'}).n[1]==0,'Nenhum atleta vinculado');
 check(queryExecute('SELECT count(*) n FROM rr_teams_test.mail_outbox',{},{datasource='runner_dba'}).n[1]==0,'Nenhum email criado');
 check(queryExecute("SELECT count(*) n FROM rr_teams_test.audit WHERE event='TEAM_REGISTER_MANUAL'",{},{datasource='runner_dba'}).n[1]==1,'Auditoria manual');check(svc.publicTeams().recordCount==0,'Pendente não aparece no diretório');
});
scenario('Titular não cadastra globalmente',function(){svc.registerGlobal(owner,data);},true);
scenario('CPF inválido',function(){var bad=duplicate(data);bad.document='11111111111';svc.registerGlobal(globalId,bad);},true);
scenario('CREF obrigatório',function(){var bad=duplicate(data);bad.cref='';svc.registerGlobal(globalId,bad);},true);
scenario('Duplicidade',function(){svc.registerGlobal(globalId,data);svc.registerGlobal(globalId,data);},true);
scenario('Status forjado ignorado',function(){var bad=duplicate(data);bad.status='ACTIVE';bad.ownerId=owner;var id=svc.registerGlobal(globalId,bad);check(svc.workspace(globalId,id).team.status=='PENDING','Não aprova via payload');check(svc.ownedTeams(owner).recordCount==0,'Não concede OWNER via payload');});
scenario('Carga administrativa sem quota pública',function(){for(var i=1;i<=6;i++){var next=duplicate(data);next.name='Manual volume '&i;svc.registerGlobal(globalId,next);}check(svc.globalTeams(globalId).total==6,'Mais de cinco registros manuais');});
scenario('Auto cadastro mantém titular',function(){var id=svc.register(owner,data);check(svc.workspace(owner,id).role=='OWNER','Titular do auto cadastro');});
check(queryExecute('SELECT count(*) n FROM rr_teams_test.mail_outbox',{},{datasource='runner_dba'}).n[1]==0,'Fila fixture vazia');
writeOutput('TEAMS_MANUAL_PASSED '&checks&'; rollback; no real records or emails');
</cfscript>
