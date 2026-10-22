<cfscript>
// Read-only checks of actual deployed components and real cron state.
fixtureRuntime=createObject("component","services" & ".geocoding.LocationStore");
fixtureJob=queryExecute("SELECT ativo,interval_minutes,last_status,last_http_status FROM public.tb_cron_jobs WHERE id_cron_job=25",[],{datasource="runner_dba"});
fixtureRuns=queryExecute("SELECT started_at,http_status,response_preview FROM public.tb_cron_job_runs WHERE id_cron_job=25 ORDER BY id_cron_job_run DESC LIMIT 3",[],{datasource="runner_dba"});
fixtureOut=[];for(fixtureRun in fixtureRuns){fixtureEntry={at=fixtureRun.started_at,http=fixtureRun.http_status};if(isJSON(fixtureRun.response_preview))fixtureEntry.result=deserializeJSON(fixtureRun.response_preview);arrayAppend(fixtureOut,fixtureEntry);}
fixtureQueue=queryExecute("SELECT id,id_evento,status,attempts,decision::text AS decision FROM public.tb_evento_geocoding WHERE source_snapshot->>'version'='3' ORDER BY id DESC LIMIT 5",[],{datasource="runner_dba"});
fixtureWorks=[];for(fixtureWork in fixtureQueue){fixtureDecision=deserializeJSON(fixtureWork.decision);arrayAppend(fixtureWorks,{id=fixtureWork.id,event_id=fixtureWork.id_evento,status=fixtureWork.status,attempts=fixtureWork.attempts,analysis_complete=fixtureDecision.analysis_complete ?: false,targets=structKeyExists(fixtureDecision,"targets") ? arrayLen(fixtureDecision.targets) : 0});}
if(!fixtureRuntime.aiReady() OR !fixtureJob.ativo[1] OR fixtureJob.interval_minutes[1] NEQ 1)throw(type="Test.Failed",message="Runtime or cron not ready");
writeOutput(serializeJSON({ready=true,geo_calls=fixtureRuntime.overview().calls,ai=fixtureRuntime.aiStats(),job_status=fixtureJob.last_status[1],last_http=fixtureJob.last_http_status[1],runs=fixtureOut,work=fixtureWorks}));writeOutput("GEO_AI_ACCEPTANCE_PASSED");
</cfscript>
