<cfscript>
function geoAuditRows(required query value){var out=[];for(var item in value)arrayAppend(out,item);return out;}
transaction {
 queryExecute("SET TRANSACTION READ ONLY",[],{datasource="runner_dba"});
 opts={datasource="runner_dba",timeout=20};
 result={};
 control=new services.geocoding.Store().settings();result.paused=!control.enabled;result.geoapifyDailyLimit=control.dailyLimit;
 result.models=geoAuditRows(queryExecute("WITH a AS(SELECT updated_at,COALESCE(response->>'model',response->>'MODEL','unknown') AS model,COALESCE(response->'usage',response->'USAGE','{}'::jsonb) AS u FROM public.tb_geocoding_cache WHERE jsonb_exists(response,'facts') OR jsonb_exists(response,'FACTS')) SELECT model,count(*) AS cached_responses,sum(COALESCE(u->>'input_tokens',u->>'INPUT_TOKENS','0')::numeric) AS input_tokens,sum(COALESCE(u->>'output_tokens',u->>'OUTPUT_TOKENS','0')::numeric) AS output_tokens,round(avg(COALESCE(u->>'input_tokens',u->>'INPUT_TOKENS','0')::numeric)) AS avg_input,round(avg(COALESCE(u->>'output_tokens',u->>'OUTPUT_TOKENS','0')::numeric)) AS avg_output,max(COALESCE(u->>'output_tokens',u->>'OUTPUT_TOKENS','0')::numeric) AS max_output,min(updated_at)::text AS earliest,max(updated_at)::text AS latest FROM a GROUP BY model ORDER BY output_tokens DESC",[],opts));
 result.daily=geoAuditRows(queryExecute("SELECT usage_date::text AS day,provider,calls FROM public.tb_geocoding_usage_daily WHERE usage_date>=CURRENT_DATE-7 ORDER BY usage_date,provider",[],opts));
 result.work=geoAuditRows(queryExecute("SELECT status,count(*) AS records,sum(attempts) AS attempts FROM public.tb_evento_geocoding GROUP BY status ORDER BY records DESC",[],opts));
 result.enrichment=geoAuditRows(queryExecute("SELECT count(*) AS records,count(*) FILTER(WHERE decision->>'analysis_complete'='false') AS awaiting_research,count(*) FILTER(WHERE decision->>'analysis_retries' IS NOT NULL) AS has_research_retry,count(*) FILTER(WHERE decision->'enrichment'->'fields' IS NOT NULL) AS has_enrichment FROM public.tb_evento_geocoding",[],opts));
 result.documents=geoAuditRows(queryExecute("WITH docs AS(SELECT COALESCE(response->'documents',response->'DOCUMENTS','[]'::jsonb) AS docs FROM public.tb_geocoding_cache WHERE jsonb_exists(response,'documents') OR jsonb_exists(response,'DOCUMENTS')) SELECT count(*) AS cached_research,round(avg(jsonb_array_length(CASE WHEN jsonb_typeof(docs)='array' THEN docs ELSE '[]'::jsonb END))) AS avg_documents FROM docs",[],opts));
 runs=queryExecute("SELECT response_preview FROM public.tb_cron_job_runs WHERE id_cron_job IN(SELECT id_cron_job FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/eventos/geolocalizar.cfm') AND started_at>=CURRENT_DATE-7 ORDER BY id_cron_job_run DESC LIMIT 12000",[],opts);
 result.runs={rows=runs.recordCount,parsed=0,ai_calls=0,ai_cache_hits=0,processed=0,source_documents=0,statuses={}};
 for(run in runs)if(isJSON(run.response_preview & "")){
  parsed=deserializeJSON(run.response_preview & "");if(!isStruct(parsed))continue;
  result.runs.parsed++;for(k in ["ai_calls","ai_cache_hits","processed","source_documents"])if(structKeyExists(parsed,k) AND isNumeric(parsed[k]))result.runs[k]+=parsed[k];
  if(structKeyExists(parsed,"status") AND isSimpleValue(parsed.status)){statusKey=parsed.status;if(!structKeyExists(result.runs.statuses,statusKey))result.runs.statuses[statusKey]=0;result.runs.statuses[statusKey]++;}
 }
 writeOutput(serializeJSON(result));
}
writeOutput("GEO_COST_AUDIT_PASSED");
</cfscript>
