<cfscript>
checks=0;
function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
function v(required numeric team){return queryExecute('SELECT version FROM rr_teams_test.team WHERE id_team=:id',{id={value=team,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'}).version[1];}
function elapsed(required numeric who){queryExecute("UPDATE rr_teams_test.athlete_clock SET next_change_at=CURRENT_TIMESTAMP-interval '1 second' WHERE user_id=:id",{id={value=who,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});}
function base(){
 var a=svc.register(owner,data);svc.review(globalId,a,'APPROVE',v(a),'','Consulta manual registrada');
 var second=duplicate(data);second.name='Outro Team';second.document='11222333000181';var b=svc.register(other,second);svc.review(globalId,b,'APPROVE',v(b),'','Consulta manual registrada');return {a=a,b=b};
}
// Expected domain exceptions roll back ColdFusion nested transactions. Every case therefore
// owns its entire fixture transaction; no test relies on state surviving a rejected operation.
function scenario(required string label,required any body,boolean rejection=false){
 var blocked=false;
 transaction {
  try {arguments.body();}
  catch(Teams.Validation e){if(!rejection)rethrow;blocked=true;}
  catch(Teams.Forbidden e){if(!rejection)rethrow;blocked=true;}
  finally {transaction action='rollback';}
 }
 check(!rejection||blocked,label);
 check(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{}, {datasource='runner_dba'}).n[1]==0,'Rollback integral: ' & label);
}
svc=new services.teams.Service().init('runner_dba','rr_teams_test');
check(svc.ready(),'DDL da fixture instalado');
prod=new services.teams.Service();check(prod.ready(),'DDL de produção instalado');
check(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{}, {datasource='runner_dba'}).n[1]==0,'Fixture vazia antes dos testes');
job=queryExecute("SELECT ativo FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/teams/mail-worker.cfm'",{}, {datasource='runner_dba'});check(job.recordCount==1&&!job.ativo[1],'Job instalado desativado');
users=queryExecute('SELECT id,email FROM public.tb_usuarios u WHERE NOT coalesce(is_admin,false) AND email IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 4',{}, {datasource='runner_dba'});
admins=queryExecute('SELECT id FROM public.tb_usuarios u WHERE is_admin=true AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1',{}, {datasource='runner_dba'});
check(users.recordCount==4&&admins.recordCount==1,'Identidades de referência ativas');owner=users.id[1];athlete=users.id[2];other=users.id[3];viewer=users.id[4];globalId=admins.id[1];
data={name='Team Teste',type='ASSESSORIA',document='52998224725',ownerName='Titular teste',technicalName='Responsável teste',cref='123456-G',crefUf='SC',email='contato@example.org',phone='48999998888',whatsapp='48999998888',city='Florianópolis',uf='SC',attendance='AMBOS',description='Grupo de teste',website='https://example.org'};
scenario('CPF inválido',function(){var bad=duplicate(data);bad.document='11111111111';svc.register(owner,bad);},true);
scenario('Cadastro e diretório',function(){var a=svc.register(owner,data);check(svc.publicTeams().recordCount==0,'Pendente não aparece');svc.review(globalId,a,'APPROVE',v(a),'','Consulta manual');check(svc.publicTeams().recordCount==1,'Aprovado aparece');check(svc.state(owner).teamId==0,'Titular não é atleta automaticamente');});
scenario('Titular não aprova',function(){var a=svc.register(owner,data);svc.review(owner,a,'APPROVE',v(a),'','Consulta manual');},true);
scenario('Aprovação exige evidência',function(){var a=svc.register(owner,data);svc.review(globalId,a,'APPROVE',v(a),'','');},true);
scenario('Versão obsoleta',function(){var a=svc.register(owner,data);var old=v(a);var changed=duplicate(data);changed.cref='654321-G';svc.updateTeam(owner,a,changed,old);svc.review(globalId,a,'APPROVE',old,'','Evidência antiga');},true);
scenario('Adesão exige consentimento',function(){var f=base();svc.join(athlete,f.a,false);},true);
scenario('Adesão, saída e troca após prazo',function(){var f=base();svc.join(athlete,f.a,true);check(svc.state(athlete).teamId==f.a,'Atleta aderiu');svc.leave(athlete);check(svc.state(athlete).teamId==0,'Saída imediata');elapsed(athlete);svc.join(athlete,f.b,true);check(svc.state(athlete).teamId==f.b,'Nova adesão após prazo');check(len(svc.state(athlete).nextChangeAt)>0,'Data de próxima troca');});
scenario('Troca antes do prazo',function(){var f=base();svc.join(athlete,f.a,true);svc.join(athlete,f.b,true);},true);
scenario('Saída não contorna prazo',function(){var f=base();svc.join(athlete,f.a,true);svc.leave(athlete);svc.join(athlete,f.b,true);},true);
scenario('Outro Team não remove',function(){var f=base();svc.join(athlete,f.a,true);svc.removeAthlete(other,f.a,athlete);},true);
scenario('Remoção, liberação e suspensão',function(){var f=base();svc.join(athlete,f.a,true);svc.removeAthlete(owner,f.a,athlete);check(svc.state(athlete).teamId==0,'Admin removeu vínculo');elapsed(athlete);svc.unblockAthlete(owner,f.a,athlete);svc.join(athlete,f.a,true);svc.review(globalId,f.a,'SUSPEND',v(f.a),'Suspensão de teste','');svc.join(athlete,f.b,true);check(svc.state(athlete).teamId==f.b,'Suspensão permite escolher outro');});
scenario('Removido não retorna',function(){var f=base();svc.join(athlete,f.a,true);svc.removeAthlete(owner,f.a,athlete);elapsed(athlete);svc.join(athlete,f.a,true);},true);
scenario('Outro Team não consulta',function(){var f=base();svc.workspace(other,f.a);},true);
scenario('Aceite administrativo e leitura',function(){var f=base();var i=svc.inviteAdmin(owner,f.a,users.email[4],'VIEWER');svc.acceptAdmin(viewer,i.token);check(svc.workspace(viewer,f.a).role=='VIEWER','Aceite libera leitura');check(svc.state(viewer).teamId==0,'Aceite não filia atleta');});
scenario('Convite exige destinatário',function(){var f=base();var i=svc.inviteAdmin(owner,f.a,users.email[4],'VIEWER');svc.acceptAdmin(other,i.token);},true);
scenario('Convite não aceita replay',function(){var f=base();var i=svc.inviteAdmin(owner,f.a,users.email[4],'VIEWER');svc.acceptAdmin(viewer,i.token);svc.acceptAdmin(viewer,i.token);},true);
scenario('Consulta não remove atleta',function(){var f=base();var i=svc.inviteAdmin(owner,f.a,users.email[4],'VIEWER');svc.acceptAdmin(viewer,i.token);svc.join(athlete,f.a,true);svc.removeAthlete(viewer,f.a,athlete);},true);
scenario('Último titular preservado',function(){var f=base();svc.removeAdmin(owner,f.a,owner);},true);
check(queryExecute('SELECT count(*) n FROM rr_teams_test.mail_outbox',{}, {datasource='runner_dba'}).n[1]==0,'Fila de email de teste vazia');
writeOutput('TEAMS_NATIVE_PASSED ' & checks & '; fixture writes rolled back; no emails sent');
</cfscript>
