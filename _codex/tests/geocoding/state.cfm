<cfscript>
store=new services.geocoding.Store();jobs=queryExecute("SELECT id_cron_job,nome,ativo,interval_minutes,last_run_at,next_run_at,last_status,last_http_status,last_duration_ms,now() AS database_now FROM public.tb_cron_jobs WHERE endpoint_url=:url",{url={value="https://business.roadrunners.run/api/eventos/geolocalizar.cfm",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
rows=[];for(row in jobs)arrayAppend(rows,row);
history=queryExecute("SELECT started_at,status,http_status,duration_ms,trigger_type,left(response_preview,1500) AS result FROM public.tb_cron_job_runs WHERE id_cron_job IN (SELECT id_cron_job FROM public.tb_cron_jobs WHERE endpoint_url=:url) ORDER BY id_cron_job_run DESC LIMIT 5",{url={value="https://business.roadrunners.run/api/eventos/geolocalizar.cfm",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
runs=[];for(row in history)arrayAppend(runs,row);
coverage=queryExecute("SELECT count(*) AS total_missing,count(*) FILTER(WHERE ativo=true) AS active_missing,count(*) FILTER(WHERE ativo IS NOT TRUE) AS inactive_missing,count(*) FILTER(WHERE ativo=true AND btrim(COALESCE(endereco,''))<>'') AS active_with_address,count(*) FILTER(WHERE ativo=true AND btrim(COALESCE(descricao_original,descricao,''))<>'') AS active_with_description FROM public.tb_evento_corridas WHERE btrim(COALESCE(coordenadas,''))=''",[],{datasource="runner_dba"});
states=queryExecute("SELECT status,count(*) AS total FROM public.tb_evento_geocoding GROUP BY status ORDER BY status",[],{datasource="runner_dba"});
byStatus=[];for(row in states)arrayAppend(byStatus,row);
writeOutput(serializeJSON({ready=store.isReady(),settings=store.settings(),stats=store.overview(),coverage=coverage,statuses=byStatus,jobs=rows,runs=runs}) & chr(10));writeOutput("GEO_STATE_PASSED");
</cfscript>
