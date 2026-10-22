<cfscript>
// Read-only production acceptance. No HTTP/provider calls or state changes.
function rows(required query q){var out=[];for(var r in q)arrayAppend(out,r);return out;}
options={datasource="runner_dba"};store=new services.geocoding.Store();
job=queryExecute("SELECT id_cron_job,ativo,interval_minutes,timeout_seconds,max_runtime_seconds,last_status,last_http_status,next_run_at FROM public.tb_cron_jobs WHERE id_cron_job=25",[],options);
runs=queryExecute("SELECT id_cron_job_run,trigger_type,started_at,finished_at,duration_ms,status,http_status,response_preview FROM public.tb_cron_job_runs WHERE id_cron_job=25 ORDER BY id_cron_job_run DESC LIMIT 8",[],options);
out=[];
for(row in runs) {
    item={id=row.id_cron_job_run,trigger=row.trigger_type,start=row.started_at,finish=row.finished_at,duration_ms=row.duration_ms,http=row.http_status,status=row.status};
    if(isJSON(row.response_preview))item.result=deserializeJSON(row.response_preview);
    arrayAppend(out,item);
}
cache=queryExecute("SELECT count(*) FILTER(WHERE query_text<>'control' AND expires_at>clock_timestamp()) AS unexpired,count(*) FILTER(WHERE cache_key='__worker__' AND provider_lease_until>clock_timestamp()) AS running_batches FROM public.tb_geocoding_cache",[],options);
errors=queryExecute("SELECT error_code,status,count(*) AS total FROM public.tb_evento_geocoding WHERE status IN('error','errors_exhausted') GROUP BY 1,2",[],options);
writeOutput(serializeJSON({job=rows(job),settings={enabled=store.settings().enabled,dailyLimit=store.settings().dailyLimit,blockedReason=store.settings().blockedReason},stats=store.overview(),cache=rows(cache),errors=rows(errors),runs=out}) & chr(10));
writeOutput("GEO_ACCEPTANCE_PASSED");
</cfscript>
