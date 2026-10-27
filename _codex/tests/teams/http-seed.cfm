<cfscript>
if(queryExecute('SELECT count(*) n FROM rr_teams_test.team',{}, {datasource='runner_dba'}).n[1])throw(type='Teams.Test',message='Fixture não está vazia');
for(seedIndex in [1,2]){
 seedTeam=10000+seedIndex;seedOwner=seedIndex==1?APPLICATION.testActors.owner:APPLICATION.testActors.other;
 queryExecute("INSERT INTO rr_teams_test.team(id_team,slug,name,type,document,owner_name,technical_name,cref,cref_uf,email,phone,whatsapp,city,uf,attendance,status,requested_by) VALUES(:id,:slug,:name,'GRUPO',:doc,'Titular fixture','Responsável fixture','123456-G','SC','fixture@example.org','48999998888','48999998888','Florianópolis','SC','AMBOS','ACTIVE',:owner)",{id={value=seedTeam,cfsqltype='cf_sql_bigint'},slug={value='crew-fixture-' & seedIndex,cfsqltype='cf_sql_varchar'},name={value='Crew fixture ' & seedIndex,cfsqltype='cf_sql_varchar'},doc={value=seedIndex==1?'52998224725':'11222333000181',cfsqltype='cf_sql_varchar'},owner={value=seedOwner,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
 queryExecute("INSERT INTO rr_teams_test.admin(team_id,user_id,role) VALUES(:team,:owner,'OWNER')",{team={value=seedTeam,cfsqltype='cf_sql_bigint'},owner={value=seedOwner,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
}
queryExecute("INSERT INTO rr_teams_test.admin(team_id,user_id,role) VALUES(10001,:viewer,'VIEWER')",{viewer={value=APPLICATION.testActors.viewer,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
if(structKeyExists(REQUEST,'testScenario')&&REQUEST.testScenario=='linked'){
 queryExecute("INSERT INTO rr_teams_test.athlete_clock(user_id,next_change_at) VALUES(:user,CURRENT_TIMESTAMP+interval '14 days')",{user={value=APPLICATION.testActors.athlete,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
 queryExecute('INSERT INTO rr_teams_test.membership(team_id,user_id) VALUES(10001,:user)',{user={value=APPLICATION.testActors.athlete,cfsqltype='cf_sql_integer'}},{datasource='runner_dba'});
}
</cfscript>
