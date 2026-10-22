<cfscript>
// Deployed code and scheduler only; no provider calls or data writes.
include "/services/geocoding/config.cfm";
fixtureRuntimeClient=createObject("component","services" & ".geocoding.AIClient").init(VARIABLES.geoConfig.aiKey,VARIABLES.geoConfig.aiModel);
fixtureBody=fixtureRuntimeClient.requestBody({},[],VARIABLES.geoConfig.aiModel);
if(fixtureBody.model NEQ "gpt-6-astra" OR fixtureBody.reasoning.effort NEQ "low")throw(type="Test.Failed",message="Deployed request is not configured for Astra");
fixtureRuntimeStore=createObject("component","services" & ".geocoding.LocationStore");
fixtureSettings=fixtureRuntimeStore.settings();
if(fixtureSettings.dailyLimit NEQ 2000 OR VARIABLES.geoConfig.aiDailyLimit NEQ 1000)throw(type="Test.Failed",message="Usage ceilings changed during model migration");
fixtureJob=queryExecute("SELECT ativo,interval_minutes,last_status,last_http_status FROM public.tb_cron_jobs WHERE id_cron_job=25",[],{datasource="runner_dba"});
fixtureRuns=queryExecute("SELECT started_at,http_status,response_preview FROM public.tb_cron_job_runs WHERE id_cron_job=25 ORDER BY id_cron_job_run DESC LIMIT 3",[],{datasource="runner_dba"});
if(!fixtureJob.ativo[1] OR fixtureJob.interval_minutes[1] NEQ 1)throw(type="Test.Failed",message="Existing one-minute scheduling changed");
fixtureOut=[];for(fixtureRun in fixtureRuns){fixtureEntry={at=fixtureRun.started_at,http=fixtureRun.http_status};if(isJSON(fixtureRun.response_preview)){fixtureSummary=deserializeJSON(fixtureRun.response_preview);fixtureEntry.model=fixtureSummary.model ?: "";fixtureEntry.status=fixtureSummary.status ?: "";fixtureEntry.errors=fixtureSummary.errors ?: 0;}arrayAppend(fixtureOut,fixtureEntry);}
writeOutput(serializeJSON({model=fixtureBody.model,reasoning=fixtureBody.reasoning.effort,existing_key_kept=VARIABLES.geoConfig.aiKey EQ APPLICATION.vickyKnowledge.apiKey,geo_daily_limit=fixtureSettings.dailyLimit,ai_daily_limit=VARIABLES.geoConfig.aiDailyLimit,cron_minutes=fixtureJob.interval_minutes[1],runs=fixtureOut}));
writeOutput("GEO_AI_ASTRA_ACCEPTANCE_PASSED");
</cfscript>
