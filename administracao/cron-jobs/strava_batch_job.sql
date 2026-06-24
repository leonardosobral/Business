INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     next_run_at)
SELECT
    'Road Runners - Fila Strava',
    'Processa em lote atletas com atividades Strava pendentes nos desafios Todo Santo Dia e Foco.',
    'roadrunners',
    'prod',
    'https://roadrunners.run/api/integrations/strava/batch-refresh.cfm',
    'POST',
    'application/json',
    '{"limit":5,"lookbackDays":2,"desafios":["todosantodia","desafiofoco"],"dryRun":false}',
    '{}'::jsonb,
    'hmac_sha256',
    'road_runners_handoff',
    5,
    120,
    0,
    false,
    true,
    120,
    now()
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tb_cron_jobs
    WHERE endpoint_url = 'https://roadrunners.run/api/integrations/strava/batch-refresh.cfm'
);
