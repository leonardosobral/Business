-- Register paused. Rerunning preserves activation and cadence of an existing job.
INSERT INTO public.tb_cron_jobs
    (nome,descricao,projeto,ambiente,endpoint_url,http_method,content_type,request_body,headers_json,auth_mode,secret_ref,interval_minutes,timeout_seconds,retry_limit,ativo,executar_em_atraso,max_runtime_seconds,next_run_at)
SELECT 'Business - Geolocalização de eventos','Preenche somente locais confiáveis; cidades ficam como sugestões privadas.','business','prod',
    'https://business.roadrunners.run/api/eventos/geolocalizar.cfm','POST','application/json','{"limit":5,"dryRun":false}','{}'::jsonb,
    'hmac_sha256','business_internal',5,60,0,false,true,75,now() AT TIME ZONE 'UTC'
WHERE NOT EXISTS(SELECT 1 FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/eventos/geolocalizar.cfm');
