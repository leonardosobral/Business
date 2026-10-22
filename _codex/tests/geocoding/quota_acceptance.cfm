<cfscript>
// Read-only deployed-code acceptance. No API calls or state changes.
include "/services/geocoding/config.cfm";
runtimeStore=createObject("component","services" & ".geocoding.LocationStore");settings=runtimeStore.settings();
if(settings.dailyLimit NEQ 3000 OR !settings.enabled)throw(type="Test.Failed",message="Production geocoding is not active with the approved daily budget");
if(VARIABLES.geoConfig.aiDailyLimit NEQ 1000 OR VARIABLES.geoConfig.aiModel NEQ 'gpt-6-astra')throw(type="Test.Failed",message="The independent OpenAI configuration changed");
job=queryExecute("SELECT ativo,interval_minutes FROM public.tb_cron_jobs WHERE id_cron_job=25",[],{datasource="runner_dba"});
if(!job.ativo[1] OR job.interval_minutes[1] NEQ 1)throw(type="Test.Failed",message="One-minute scheduling changed");
usage=queryExecute("SELECT calls FROM public.tb_geocoding_usage_daily WHERE provider='geoapify' AND usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date",[],{datasource="runner_dba"});
runs=queryExecute("SELECT id_cron_job_run,status,http_status,response_preview FROM public.tb_cron_job_runs WHERE id_cron_job=25 ORDER BY id_cron_job_run DESC LIMIT 3",[],{datasource="runner_dba"});results=[];
for(run in runs){entry={id=run.id_cron_job_run,status=run.status,http=run.http_status};if(isJSON(run.response_preview)){body=deserializeJSON(run.response_preview);entry.result=body.status ?: '';entry.errors=body.errors ?: 0;entry.calls=body.calls ?: 0;}arrayAppend(results,entry);}
writeOutput(serializeJSON({geo_daily_limit=settings.dailyLimit,geo_used=usage.recordCount ? usage.calls[1] : 0,ai_daily_limit=VARIABLES.geoConfig.aiDailyLimit,model=VARIABLES.geoConfig.aiModel,cron_minutes=job.interval_minutes[1],runs=results}));
writeOutput("GEO_QUOTA_ACCEPTANCE_PASSED");
</cfscript>
