<cfscript>
function auditRows(required query q){var rows=[];for(var row in q)arrayAppend(rows,row);return rows;}
transaction {
 queryExecute("SET TRANSACTION READ ONLY",[],{datasource="runner_dba"});
 auditOptions={datasource="runner_dba",timeout=20};
 auditResult={observed_at=queryExecute("SELECT current_timestamp::text AS observed_at",[],auditOptions).observed_at,period_start="2026-10-17T00:00:00Z"};
 auditResult.geolocation=auditRows(queryExecute("WITH replies AS(SELECT updated_at,COALESCE(response->>'model',response->>'MODEL') AS model,COALESCE(response->'usage',response->'USAGE') AS usage FROM public.tb_geocoding_cache WHERE jsonb_exists(response,'facts') OR jsonb_exists(response,'FACTS')), tokens AS(SELECT updated_at,model,COALESCE(usage->>'input_tokens',usage->>'INPUT_TOKENS')::numeric AS input_tokens,COALESCE(usage->>'output_tokens',usage->>'OUTPUT_TOKENS')::numeric AS output_tokens FROM replies) SELECT model,count(*) AS cached_responses,sum(input_tokens) AS input_tokens,sum(output_tokens) AS output_tokens,min(updated_at)::text AS first_seen,max(updated_at)::text AS last_seen FROM tokens WHERE updated_at>='2026-10-17T00:00:00Z' AND input_tokens>0 GROUP BY model",[],auditOptions));
 auditResult.ai_mails=auditRows(queryExecute("SELECT model,status,count(*) AS requests,sum(input_tokens) AS input_tokens,sum(output_tokens) AS output_tokens FROM public.tb_ai_mail_usage WHERE created_at>='2026-10-17T00:00:00Z' GROUP BY model,status",[],auditOptions));
 auditResult.vicky=auditRows(queryExecute("SELECT model,status,count(*) AS requests,sum(input_tokens) AS input_tokens,sum(output_tokens) AS output_tokens FROM public.tb_vicky_execucao WHERE created_at AT TIME ZONE 'America/Sao_Paulo'>='2026-10-17T00:00:00Z' GROUP BY model,status",[],auditOptions));
 auditResult.rewrite=auditRows(queryExecute("SELECT 'pt-BR' AS language,model,status,count(*) AS records,sum(length(source_text)) AS source_characters FROM public.tb_evento_descricao_rewrites WHERE created_at>='2026-10-17T00:00:00Z' GROUP BY model,status UNION ALL SELECT language,model,status,count(*) AS records,sum(length(source_text)) AS source_characters FROM public.tb_evento_descricao_translations WHERE created_at>='2026-10-17T00:00:00Z' GROUP BY language,model,status ORDER BY language,model,status",[],auditOptions));
 auditResult.news=auditRows(queryExecute("SELECT COALESCE(model,'unknown') AS model,status,count(*) AS jobs,sum(attempts) AS attempts FROM news.tb_article_summary_jobs WHERE updated_at AT TIME ZONE 'America/Sao_Paulo'>='2026-10-17T00:00:00Z' GROUP BY model,status",[],auditOptions));
 auditResult.geolocation_daily=auditRows(queryExecute("SELECT usage_date::text AS day,calls FROM public.tb_geocoding_usage_daily WHERE provider='openai-geolocation' AND usage_date>='2026-10-17' ORDER BY usage_date",[],auditOptions));
 auditResult.configured_models=auditRows(queryExecute("SELECT 'vicky' AS module,model FROM public.tb_vicky_config UNION ALL SELECT 'ai-mails',model FROM public.tb_ai_mail_config",[],auditOptions));
 writeOutput(serializeJSON(auditResult));
}
writeOutput("GEO_OPENAI_USAGE_TOTALS_PASSED");
</cfscript>
