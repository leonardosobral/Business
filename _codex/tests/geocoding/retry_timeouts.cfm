<cfscript>
// One-time, scoped recovery of exhausted v2 provider failures after the fix.
// Normal enqueue records permanent audit; no coordinates are changed here.
store=new services.geocoding.Store();options={datasource="runner_dba"};lease=store.acquireWorker();
if(!lease.allowed)throw(type="Test.Failed",message="A batch is active; retry timeout recovery when idle");
try {
    failed=queryExecute("SELECT g.id,g.id_evento,g.attempts,g.error_code FROM public.tb_evento_geocoding g JOIN public.tb_evento_corridas e ON e.id_evento=g.id_evento WHERE g.status='errors_exhausted' AND g.error_code='provider_unavailable' AND COALESCE(g.source_snapshot->>'VERSION',g.source_snapshot->>'version','1')='2' AND btrim(COALESCE(e.coordenadas,''))='' AND NOT EXISTS(SELECT 1 FROM public.tb_evento_geocoding newer WHERE newer.id_evento=g.id_evento AND newer.id>g.id) ORDER BY g.id LIMIT 20",[],options);
    ids=[];before=[];for(row in failed){arrayAppend(ids,row.id_evento);arrayAppend(before,{id=row.id,id_evento=row.id_evento,attempts=row.attempts,error_code=row.error_code});}
    queued=store.enqueue(ids,"maintenance:timeout-fix");
    writeOutput(serializeJSON({before=before,requeued=arrayLen(queued),work_ids=queued,provider_calls=0}) & chr(10));
}finally{store.releaseWorker(lease.token);}
writeOutput("GEO_RETRY_TIMEOUTS_PASSED");
</cfscript>
