<cfscript>
// Only this concurrency case's named fixture; never public/production Teams rows.
transaction {
 targets=queryExecute("SELECT id_team FROM rr_teams_test.team WHERE name='Concorrência acesso fixture' AND email='fixture@example.org'",{},{datasource='runner_dba'});
 for(target in targets){
  for(cleanTable in ['audit','funnel','exclusion','membership','admin_invite','admin'])queryExecute('DELETE FROM rr_teams_test.'&cleanTable&' WHERE team_id=:team',{team={value=target.id_team,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'});
  queryExecute('DELETE FROM rr_teams_test.team WHERE id_team=:team',{team={value=target.id_team,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'});
 }
 queryExecute("DELETE FROM rr_teams_test.mail_outbox WHERE subject='Convite para administrar Concorrência acesso fixture'",{},{datasource='runner_dba'});
}
writeOutput('TEAMS_EXISTING_CLEANUP_PASSED');
</cfscript>
