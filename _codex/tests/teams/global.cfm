<cfscript>
checks=0;
function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
svc=new services.teams.Service().init('runner_dba','rr_teams_test');
users=queryExecute("SELECT id FROM public.tb_usuarios u WHERE NOT coalesce(is_admin,false) AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 2",{},{datasource='runner_dba'});
staff=queryExecute("SELECT id FROM public.tb_usuarios u WHERE is_admin=true AND NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao g WHERE g.id_usuario=u.id AND (NOT coalesce(g.ativo,true) OR coalesce(g.excluido,false))) ORDER BY id LIMIT 1",{},{datasource='runner_dba'});
owner=users.id[1];other=users.id[2];globalId=staff.id[1];
check(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{}, {datasource='runner_dba'}).n[1]==0,'Fixture vazia');
// Direct fixture inserts avoid registration daily limits and leave real account rows untouched.
transaction {
 try {
  for(i=1;i<=27;i++) {
   inserted=queryExecute("INSERT INTO rr_teams_test.team(name,type,document,owner_name,technical_name,cref,cref_uf,email,phone,whatsapp,city,uf,attendance,requested_by,status,slug) VALUES(:name,:type,'52998224725','Titular','Técnico','123456-G','SC','fixture@example.org','48999998888','48999998888',:city,:uf,'AMBOS',:owner,:status,:slug) RETURNING id_team",{name='Equipe ' & numberFormat(i,'00'),type=i==27?'CLUBE':'ASSESSORIA',city=i==27?'Curitiba':'Florianópolis',uf=i==27?'PR':'SC',owner={value=owner,cfsqltype='cf_sql_integer'},status=i==27?'ACTIVE':'PENDING',slug='global-fixture-' & i},{datasource='runner_dba'}).id_team[1];
   if(i==1){firstTeam=inserted;queryExecute("INSERT INTO rr_teams_test.admin(team_id,user_id,role) VALUES(:team,:user,'OWNER')",{team={value=inserted,cfsqltype='cf_sql_bigint'},user={value=owner,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});}
  }
  all=svc.globalTeams(globalId);check(all.total==27&&all.teams.recordCount==25&&all.pages==2,'Paginação global');check(all.stats.pending==26&&all.stats.active==1&&all.stats.total==27,'Indicadores globais');
  filtered=svc.globalTeams(globalId,'Curitiba','ACTIVE','CLUBE','PR');check(filtered.total==1&&filtered.teams.name[1]=='Equipe 27','Filtros combinados');
  check(svc.globalTeams(globalId,"' OR 1=1 --").total==0,'Busca parametrizada');
  check(svc.globalTeams(globalId,'ausente','','','',99).teams.recordCount==0,'Busca vazia');
  last=svc.globalTeams(globalId,'','','','',999);check(last.page==2&&last.teams.recordCount==2,'Página excedente limitada');
  check(svc.ownedTeams(owner).recordCount==1&&svc.ownedTeams(other).recordCount==0&&svc.ownedTeams(globalId).recordCount==0,'Painel pessoal limitado aos próprios acessos');
 }finally{transaction action='rollback';}
}
blocked=false;try{svc.globalTeams(owner);}catch(Teams.Forbidden e){blocked=true;}check(blocked,'Titular não consulta lista global');
blocked=false;try{svc.globalTeams(globalId,'','INVENTED');}catch(Teams.Validation e){blocked=true;}check(blocked,'Situação inválida rejeitada');
blocked=false;try{svc.globalTeams(globalId,'','','CLUBE','XX');}catch(Teams.Validation e){blocked=true;}check(blocked,'UF inválida rejeitada');
check(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{}, {datasource='runner_dba'}).n[1]==0,'Rollback integral');
writeOutput('TEAMS_GLOBAL_PASSED ' & checks & '; no real data changed; no emails');
</cfscript>
