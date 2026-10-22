<cfscript>
fixtureRows=queryExecute("SELECT id,id_evento,status,error_code,decision::text AS decision FROM public.tb_evento_geocoding WHERE source_snapshot->>'version'='3' AND status IN('error','errors_exhausted') ORDER BY id DESC LIMIT 5",[],{datasource="runner_dba"});fixtureOut=[];
for(fixtureRow in fixtureRows)arrayAppend(fixtureOut,{id=fixtureRow.id,event_id=fixtureRow.id_evento,status=fixtureRow.status,code=fixtureRow.error_code,decision=deserializeJSON(fixtureRow.decision)});
writeOutput(serializeJSON(fixtureOut));writeOutput("GEO_AI_FAILURES_PASSED");
</cfscript>
