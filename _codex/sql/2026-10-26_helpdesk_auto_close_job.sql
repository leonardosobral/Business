-- Additive DML; install disabled and validate authenticated dry run before activation.
INSERT INTO public.tb_cron_jobs
(nome,descricao,projeto,ambiente,endpoint_url,http_method,content_type,request_body,headers_json,auth_mode,secret_ref,interval_minutes,timeout_seconds,retry_limit,ativo,executar_em_atraso,max_runtime_seconds,next_run_at)
SELECT 'Help Desk · Encerrar chamados por inatividade',
 'Fecha chamados cuja última mensagem pública seja da equipe há mais de 48 horas; preserva Em atendimento e Fechado. Aviso e status são gravados atomicamente.',
 'business','prod','https://business.roadrunners.run/api/helpdesk/auto-close.cfm','POST','application/json','{"limit":50}','{}'::jsonb,
 'bearer','business_helpdesk_auto_close',15,45,0,false,true,60,(now() AT TIME ZONE 'UTC')
WHERE NOT EXISTS(SELECT 1 FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/helpdesk/auto-close.cfm');
