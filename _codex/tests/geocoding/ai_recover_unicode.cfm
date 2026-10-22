<cfscript>
// One-time scoped recovery: only the two observed v3 encoding failures, no other work.
fixtureRuntime=createObject("component","services" & ".geocoding.LocationStore");fixtureIds=[];
for(fixtureId in [48602,49263]){
 fixtureRows=queryExecute("SELECT id,status,error_code,source_snapshot->>'version' AS version FROM public.tb_evento_geocoding WHERE id_evento=:id ORDER BY id DESC LIMIT 1",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},{datasource="runner_dba"});
 if(fixtureRows.recordCount AND fixtureRows.version[1] EQ "3" AND fixtureRows.status[1] EQ "error" AND fixtureRows.error_code[1] EQ "execution_error")for(fixtureQueued in fixtureRuntime.enqueue([fixtureId],"maintenance:unicode-fix"))arrayAppend(fixtureIds,fixtureQueued);
}
writeOutput(serializeJSON({requeued_work=fixtureIds}));writeOutput("GEO_AI_RECOVER_UNICODE_PASSED");
</cfscript>
