<cfscript>
params={athlete={value=APPLICATION.testActors.athlete,cfsqltype='cf_sql_integer'},email={value=APPLICATION.testRecruitAddress,cfsqltype='cf_sql_varchar'},owner={value=APPLICATION.testActors.owner,cfsqltype='cf_sql_integer'},other={value=APPLICATION.testActors.other,cfsqltype='cf_sql_integer'}};
transaction{
 queryExecute('DELETE FROM rr_teams_test.mail_outbox WHERE destination=:email',params,{datasource='runner_dba'});
 queryExecute('DELETE FROM rr_teams_test.audit WHERE team_id IN (10001,10002) OR (team_id IS NULL AND actor_id IN (:owner,:other))',params,{datasource='runner_dba'});
 queryExecute('DELETE FROM rr_teams_test.notice WHERE user_id=:athlete',params,{datasource='runner_dba'});
 queryExecute("DELETE FROM rr_teams_test.funnel WHERE team_id IN (10001,10002) OR (event='INVITE' AND user_id IN (:owner,:other))",params,{datasource='runner_dba'});
 for(table in ['exclusion','membership','admin_invite','admin'])queryExecute('DELETE FROM rr_teams_test.' & table & ' WHERE team_id IN (10001,10002)',{}, {datasource='runner_dba'});
 queryExecute('DELETE FROM rr_teams_test.recruit_invite WHERE destination=:email',params,{datasource='runner_dba'});
 queryExecute('DELETE FROM rr_teams_test.athlete_clock WHERE user_id=:athlete',params,{datasource='runner_dba'});
 queryExecute('DELETE FROM rr_teams_test.team WHERE id_team IN (10001,10002)',{}, {datasource='runner_dba'});
}
leftover=0;for(table in ['team','admin','athlete_clock','membership','exclusion','admin_invite','recruit_invite','audit','funnel','notice','mail_outbox'])leftover+=queryExecute('SELECT count(*) n FROM rr_teams_test.' & table,{}, {datasource='runner_dba'}).n[1];
if(leftover)throw(type='Teams.Test',message='Fixture requer inspeção de limpeza.');writeOutput('FIXTURE_CLEAN');
</cfscript>
