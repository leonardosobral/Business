-- Registra o refresh recorrente do agregado legado de publicidade.
--
-- Pre-requisitos:
--   1. endpoint /api/ads/refresh-metrics.cfm publicado;
--   2. APPLICATION.cronJobs.secrets.business_internal configurado;
--   3. runner de /cron-jobs/runner.cfm ativo.
--
-- O job nasce inativo para permitir smoke test manual antes da ativacao.

BEGIN;

INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     next_run_at)
SELECT
    'Business - Metricas de publicidade',
    'Recalcula a janela movel de tres dias de ads.tb_ad_evento_metricas_dia.',
    'business',
    'prod',
    'https://business.roadrunners.run/api/ads/refresh-metrics.cfm',
    'POST',
    'application/json',
    '{"lookbackDays":2}',
    '{}'::jsonb,
    'bearer',
    'business_internal',
    60,
    120,
    0,
    false,
    true,
    120,
    now()
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tb_cron_jobs
    WHERE endpoint_url = 'https://business.roadrunners.run/api/ads/refresh-metrics.cfm'
);

UPDATE public.tb_cron_jobs
SET nome = 'Business - Metricas de publicidade',
    descricao = 'Recalcula a janela movel de tres dias de ads.tb_ad_evento_metricas_dia.',
    projeto = 'business',
    ambiente = 'prod',
    http_method = 'POST',
    content_type = 'application/json',
    request_body = '{"lookbackDays":2}',
    headers_json = '{}'::jsonb,
    auth_mode = 'bearer',
    secret_ref = 'business_internal',
    interval_minutes = 60,
    timeout_seconds = 120,
    retry_limit = 0,
    executar_em_atraso = true,
    max_runtime_seconds = 120,
    data_atualizacao = now()
WHERE endpoint_url = 'https://business.roadrunners.run/api/ads/refresh-metrics.cfm';

COMMIT;

SELECT id_cron_job,
       nome,
       ativo,
       interval_minutes,
       next_run_at,
       last_status
FROM public.tb_cron_jobs
WHERE endpoint_url = 'https://business.roadrunners.run/api/ads/refresh-metrics.cfm';
