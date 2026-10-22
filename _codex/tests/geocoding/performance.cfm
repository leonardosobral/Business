<cfscript>
// Read-only throughput/quota diagnostics. No worker, provider calls or config writes.
options={datasource="runner_dba"};store=new services.geocoding.Store();
function rows(required query q){var out=[];for(var r in q)arrayAppend(out,r);return out;}
clock=queryExecute("SELECT to_char(clock_timestamp() AT TIME ZONE 'America/Sao_Paulo','YYYY-MM-DD HH24:MI:SS') AS brazil_now,to_char(clock_timestamp() AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS') AS utc_now",[],options);
versions=queryExecute("WITH latest AS(SELECT DISTINCT ON(id_evento) * FROM public.tb_evento_geocoding ORDER BY id_evento,id DESC) SELECT COALESCE(source_snapshot->>'VERSION',source_snapshot->>'version','1') AS pipeline_version,status,count(*) AS total,min(created_at)::text AS first_created,max(updated_at)::text AS last_updated FROM latest GROUP BY 1,2 ORDER BY 1,2",[],options);
usage=queryExecute("SELECT usage_date,calls FROM public.tb_geocoding_usage_daily WHERE provider='geoapify' ORDER BY usage_date DESC LIMIT 4",[],options);
jobs=queryExecute("SELECT id_cron_job,ativo,interval_minutes,last_run_at,next_run_at,last_status,last_http_status,last_duration_ms,timeout_seconds,request_body FROM public.tb_cron_jobs WHERE id_cron_job=25",[],options);
runRows=queryExecute("SELECT started_at,trigger_type,status,http_status,duration_ms,response_preview,extract(epoch FROM((clock_timestamp() AT TIME ZONE 'UTC')-started_at))/3600 AS age_hours FROM public.tb_cron_job_runs WHERE id_cron_job=25 AND started_at>=(clock_timestamp() AT TIME ZONE 'UTC')-interval '24 hours' ORDER BY id_cron_job_run DESC LIMIT 500",[],options);
windows=[];
for(hours in [1,6,24]) {
    summary={hours=hours,runs=0,scheduled=0,manual=0,successful_http=0,failed_http=0,json_results=0,completed_v2=0,legacy_invalidated=0,calls=0,source_documents=0,provider_cooldown=0,daily_limit=0,time_budget=0,execution_errors=0,total_duration_ms=0};
    for(row in runRows)if(row.age_hours GTE 0 AND row.age_hours LTE hours) {
        summary.runs++;summary.total_duration_ms+=isNumeric(row.duration_ms) ? row.duration_ms : 0;
        if(row.trigger_type EQ "scheduled")summary.scheduled++;else summary.manual++;
        if(row.status EQ "success")summary.successful_http++;else summary.failed_http++;
        if(isJSON(row.response_preview)) {
            data=deserializeJSON(row.response_preview);if(!isStruct(data))continue;summary.json_results++;
            if(structKeyExists(data,"calls") AND isNumeric(data.calls))summary.calls+=data.calls;
            if(structKeyExists(data,"source_documents") AND isNumeric(data.source_documents))summary.source_documents+=data.source_documents;
            if(structKeyExists(data,"status") AND listFind("provider_cooldown,daily_limit,time_budget,execution_error",data.status)) {
                if(data.status EQ "execution_error")summary.execution_errors++;else summary[data.status]++;
            }
            if(structKeyExists(data,"pipeline_version") AND data.pipeline_version EQ 2 AND structKeyExists(data,"results") AND isArray(data.results))for(item in data.results) {
                if(item.status EQ "conflict")summary.legacy_invalidated++;else summary.completed_v2++;
            }
        }
    }
    arrayAppend(windows,summary);
}
sourceCounts=queryExecute("WITH latest AS(SELECT DISTINCT ON(id_evento) * FROM public.tb_evento_geocoding ORDER BY id_evento,id DESC) SELECT count(*) FILTER(WHERE COALESCE(source_snapshot->>'VERSION',source_snapshot->>'version','1')='2') AS v2_total,count(*) FILTER(WHERE COALESCE(source_snapshot->>'VERSION',source_snapshot->>'version','1')='2' AND status IN('auto_applied','approved','city_suggestion','needs_review','insufficient_data','rejected')) AS v2_analyzed,count(*) FILTER(WHERE COALESCE(source_snapshot->>'VERSION',source_snapshot->>'version','1')='2' AND status IN('error','errors_exhausted')) AS v2_failed FROM latest",[],options);
provider=store.providerState();settings=store.settings();
writeOutput(serializeJSON({clock=rows(clock),stats=store.overview(),source_counts=rows(sourceCounts),versions=rows(versions),usage=rows(usage),jobs=rows(jobs),windows=windows,provider=provider,settings={enabled=settings.enabled,dailyLimit=settings.dailyLimit,blockedReason=settings.blockedReason}}) & chr(10));
writeOutput("GEO_PERFORMANCE_PASSED");
</cfscript>
