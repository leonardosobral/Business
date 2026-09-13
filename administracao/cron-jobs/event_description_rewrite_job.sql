-- Safe initial registration. Enable the job only after validating a preview.
-- Rerunning this script preserves the current schedule and activation state.
INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     next_run_at)
SELECT
    'Business - Reescrita de descricoes de eventos',
    'Preenche descricao vazia a partir de descricao_original, preservando os fatos e registrando a verificacao.',
    'business', 'prod',
    'https://business.roadrunners.run/api/event-description-rewrite.cfm',
    'POST', 'application/json', '{"limit":1,"dryRun":true}', '{}'::jsonb,
    'hmac_sha256', 'business_internal', 5, 120, 0, false, true, 150, now()
WHERE NOT EXISTS (
    SELECT 1 FROM public.tb_cron_jobs
    WHERE endpoint_url = 'https://business.roadrunners.run/api/event-description-rewrite.cfm'
);
