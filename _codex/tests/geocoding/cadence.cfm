<cfscript>
function rows(required query q){var out=[];for(var r in q)arrayAppend(out,r);return out;}
options={datasource="runner_dba"};
due=queryExecute("SELECT id_cron_job,interval_minutes,next_run_at FROM public.tb_cron_jobs WHERE ativo=true AND next_run_at<=(clock_timestamp() AT TIME ZONE 'UTC') ORDER BY next_run_at,id_cron_job LIMIT 10",[],options);
locks=queryExecute("SELECT count(*) AS held_session_locks FROM pg_locks WHERE locktype='advisory' AND objid=930000025 AND granted",[],options);
running=queryExecute("SELECT id_cron_job_run,started_at,status FROM public.tb_cron_job_runs WHERE id_cron_job=25 AND status='running'",[],options);
clock=queryExecute("SELECT clock_timestamp()::text AS database_now",[],options);
writeOutput(serializeJSON({due=rows(due),locks=rows(locks),running=rows(running),clock=rows(clock)}) & chr(10));writeOutput("GEO_CADENCE_PASSED");
</cfscript>
