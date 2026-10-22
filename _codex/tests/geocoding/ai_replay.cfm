<cfscript>
fixtureErrors=queryExecute("SELECT id FROM public.tb_evento_geocoding WHERE source_snapshot->>'version'='3' AND status='error' AND error_code='execution_error' AND id_evento=48602 ORDER BY id DESC LIMIT 1",[],{datasource="runner_dba"});
if(!fixtureErrors.recordCount)throw(type="Test.Failed",message="No replay target");
// Reserve the maximum one live AI call OUTSIDE rollback so it remains counted.
fixtureReserve=new services.geocoding.LocationStore().reserveAI(1000);if(!fixtureReserve.allowed)throw(type="Test.Failed",message=fixtureReserve.reason);
transaction {
 queryExecute("UPDATE public.tb_evento_geocoding SET attempts=0,next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=fixtureErrors.id[1],cfsqltype="cf_sql_bigint"}},{datasource="runner_dba"});
 fixtureReplay=new ReplayAIWorker(fixtureErrors.id[1],application.vickyKnowledge.apiKey).run(1);writeOutput(serializeJSON(fixtureReplay));transaction action="rollback";
}
writeOutput("GEO_AI_REPLAY_PASSED");
</cfscript>
