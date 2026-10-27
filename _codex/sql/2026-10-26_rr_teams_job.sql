-- Install disabled. Existing scheduler reference; no credential/config changes.
INSERT INTO public.tb_cron_jobs
(nome,descricao,projeto,ambiente,endpoint_url,http_method,content_type,request_body,headers_json,auth_mode,secret_ref,interval_minutes,timeout_seconds,retry_limit,ativo,executar_em_atraso,max_runtime_seconds,next_run_at)
SELECT 'Road Runners Teams · Convites por email',
 'Entrega apenas convites transacionais explicitamente solicitados por atletas ou administradores de Teams.',
 'business','prod','https://business.roadrunners.run/teams/mail-worker.cfm','POST','application/json','{"limit":10,"dryRun":false}','{}'::jsonb,
 'bearer','business_ai_mails',5,45,0,false,true,60,(now() AT TIME ZONE 'UTC')
WHERE NOT EXISTS(SELECT 1 FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/teams/mail-worker.cfm');
