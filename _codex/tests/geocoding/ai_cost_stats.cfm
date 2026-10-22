<cfscript>
// Read-only aggregate evidence for the cost/throughput estimate. No names, keys or source bodies.
transaction {
 queryExecute("SET TRANSACTION READ ONLY",[],{datasource="runner_dba"});
 fixtureOptions={datasource="runner_dba",timeout=25};
 fixtureUsage=queryExecute("WITH replies AS(SELECT COALESCE(response->>'model',response->>'MODEL') AS model,COALESCE(response->'usage',response->'USAGE') AS usage FROM public.tb_geocoding_cache WHERE jsonb_exists(response,'facts') OR jsonb_exists(response,'FACTS')), tokens AS(SELECT model,COALESCE(usage->>'input_tokens',usage->>'INPUT_TOKENS')::numeric AS input_tokens,COALESCE(usage->>'output_tokens',usage->>'OUTPUT_TOKENS')::numeric AS output_tokens FROM replies) SELECT model,count(*) AS samples,round(avg(input_tokens),1) AS avg_input,round(avg(output_tokens),1) AS avg_output,min(input_tokens) AS min_input,max(input_tokens) AS max_input,percentile_cont(0.5) WITHIN GROUP(ORDER BY input_tokens) AS median_input,percentile_cont(0.9) WITHIN GROUP(ORDER BY input_tokens) AS p90_input FROM tokens WHERE input_tokens>0 AND output_tokens>=0 GROUP BY model",[],fixtureOptions);
 fixtureModels=[];for(fixtureRow in fixtureUsage)arrayAppend(fixtureModels,fixtureRow);
 fixtureCatalog=queryExecute("SELECT count(*) AS total,count(*) FILTER(WHERE btrim(COALESCE(coordenadas,''))='') AS missing_race,count(*) FILTER(WHERE NOT(jsonb_exists(localizacoes,'kit'))) AS missing_kit FROM public.tb_evento_corridas",[],fixtureOptions);
 fixtureQueue=queryExecute("SELECT status,count(*) AS n FROM public.tb_evento_geocoding WHERE source_snapshot->>'version'='3' GROUP BY status",[],fixtureOptions);fixtureStates=[];for(fixtureRow in fixtureQueue)arrayAppend(fixtureStates,fixtureRow);
 fixtureCalls=queryExecute("SELECT provider,calls FROM public.tb_geocoding_usage_daily WHERE usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date",[],fixtureOptions);fixtureToday=[];for(fixtureRow in fixtureCalls)arrayAppend(fixtureToday,fixtureRow);
 fixtureRuns=queryExecute("SELECT started_at,http_status,response_preview FROM public.tb_cron_job_runs WHERE id_cron_job=25 AND trigger_type='scheduled' AND started_at>=(clock_timestamp() AT TIME ZONE 'UTC')-interval '1 hour' AND started_at<=(clock_timestamp() AT TIME ZONE 'UTC') ORDER BY started_at",[],fixtureOptions);
 fixtureHour={runs=fixtureRuns.recordCount,processed=0,ai_calls=0,geo_calls=0,errors=0,statuses={},models={}};
 for(fixtureRun in fixtureRuns)if(isJSON(fixtureRun.response_preview)){
  fixtureResult=deserializeJSON(fixtureRun.response_preview);if(!isStruct(fixtureResult))continue;
  fixtureHour.processed+=val(fixtureResult.processed ?: 0);fixtureHour.ai_calls+=val(fixtureResult.ai_calls ?: 0);fixtureHour.geo_calls+=val(fixtureResult.calls ?: 0);fixtureHour.errors+=val(fixtureResult.errors ?: 0);
  fixtureStatus=fixtureResult.status ?: "unknown";fixtureHour.statuses[fixtureStatus]=(fixtureHour.statuses[fixtureStatus] ?: 0)+1;
  fixtureModel=fixtureResult.model ?: "unknown";fixtureHour.models[fixtureModel]=(fixtureHour.models[fixtureModel] ?: 0)+1;
 }
 writeOutput(serializeJSON({utc=now(),models=fixtureModels,catalog=fixtureCatalog.getRow(1),work_states=fixtureStates,today=fixtureToday,last_hour=fixtureHour}));
}
writeOutput("GEO_AI_COST_STATS_PASSED");
</cfscript>
