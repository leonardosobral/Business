<cfscript>
// Explicit operational setup: INSERT only the new paused job. No DDL or existing job edits.
store=new services.geocoding.Store();if(!store.isReady())throw(type="Test.Failed",message="Schema not ready");
queryExecute(fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "geocoding_job.sql"),[],{datasource="runner_dba"});
jobs=queryExecute("SELECT id_cron_job,ativo,interval_minutes FROM public.tb_cron_jobs WHERE endpoint_url=:url",{url={value="https://business.roadrunners.run/api/eventos/geolocalizar.cfm",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
if(jobs.recordCount NEQ 1 OR jobs.ativo[1] OR jobs.interval_minutes[1] NEQ 5)throw(type="Test.Failed",message="Paused job registration not confirmed");
writeOutput(serializeJSON({job_id=jobs.id_cron_job[1],active=jobs.ativo[1],interval_minutes=jobs.interval_minutes[1]}) & chr(10));writeOutput("GEO_INSTALL_JOB_PASSED");
</cfscript>
