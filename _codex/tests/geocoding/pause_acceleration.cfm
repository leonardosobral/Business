<cfscript>
// Scoped deployment window. Do not include in automated tests.
store=new services.geocoding.Store();options={datasource="runner_dba"};
transaction {
    job=queryExecute("SELECT id_cron_job,endpoint_url,ativo,interval_minutes,next_run_at,timeout_seconds,max_runtime_seconds FROM public.tb_cron_jobs WHERE id_cron_job=25 FOR UPDATE",[],options);
    if(job.recordCount NEQ 1 OR job.endpoint_url NEQ "https://business.roadrunners.run/api/eventos/geolocalizar.cfm" OR !job.ativo OR job.interval_minutes NEQ 5)throw(type="Test.Failed",message="Unexpected job state; refusing maintenance pause");
    running=queryExecute("SELECT count(*) AS total FROM public.tb_cron_job_runs WHERE id_cron_job=25 AND status='running'",[],options);
    if(running.total GT 0)throw(type="Test.Failed",message="Job still running; retry later");
    before={ativo=job.ativo,interval_minutes=job.interval_minutes,next_run_at=job.next_run_at,timeout_seconds=job.timeout_seconds,max_runtime_seconds=job.max_runtime_seconds};
    queryExecute("UPDATE public.tb_cron_jobs SET ativo=false,data_atualizacao=clock_timestamp() AT TIME ZONE 'UTC' WHERE id_cron_job=25",[],options);
}
writeOutput(serializeJSON({job_id=25,before=before,paused=true}) & chr(10));writeOutput("GEO_PAUSE_ACCELERATION_PASSED");
</cfscript>
