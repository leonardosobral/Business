<cfscript>
// Explicit production maintenance; not part of the automated test suites.
// No provider calls, credentials, DDL or unrelated job changes.
store=new services.geocoding.Store();options={datasource="runner_dba"};
transaction {
    job=queryExecute("SELECT * FROM public.tb_cron_jobs WHERE id_cron_job=25 FOR UPDATE",[],options);
    if(job.recordCount NEQ 1 OR job.endpoint_url NEQ "https://business.roadrunners.run/api/eventos/geolocalizar.cfm" OR job.ativo OR job.interval_minutes NEQ 5)throw(type="Test.Failed",message="Unexpected maintenance state; refusing to modify");
    if(store.settings().dailyLimit NEQ 2000)throw(type="Test.Failed",message="Daily limit changed; refusing to modify");
    running=queryExecute("SELECT count(*) AS total FROM public.tb_cron_job_runs WHERE id_cron_job=25 AND status='running'",[],options);
    if(running.total GT 0)throw(type="Test.Failed",message="Job is running; retry after it finishes");
    before={interval_minutes=job.interval_minutes,next_run_at=job.next_run_at,ativo=job.ativo,timeout_seconds=job.timeout_seconds,max_runtime_seconds=job.max_runtime_seconds};
    queryExecute("UPDATE public.tb_cron_jobs SET ativo=true,interval_minutes=1,next_run_at=date_trunc('minute',clock_timestamp() AT TIME ZONE 'UTC')+interval '1 minute',data_atualizacao=clock_timestamp() AT TIME ZONE 'UTC' WHERE id_cron_job=25",[],options);
}
writeOutput(serializeJSON({job_id=25,before=before,interval_minutes=1,daily_limit=store.settings().dailyLimit,provider_rps=1}) & chr(10));
writeOutput("GEO_CONFIGURE_ACCELERATION_PASSED");
</cfscript>
