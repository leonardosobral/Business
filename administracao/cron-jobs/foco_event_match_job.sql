INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     next_run_at)
SELECT
    'Business - Vinculacao Foco Radical',
    'Vincula automaticamente candidatos fortes da Foco Radical e envia casos medios para revisao.',
    'business',
    'prod',
    'https://business.roadrunners.run/api/foco/jobs/match-events.cfm',
    'POST',
    'application/json',
    '{"limit":20,"pageSize":20,"fromDate":"2023-01-01","minReviewScore":60,"autoLinkScore":85,"autoLink":true,"dryRun":false}',
    '{}'::jsonb,
    'bearer',
    'business_foco_eventos',
    15,
    120,
    0,
    false,
    true,
    120,
    now()
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tb_cron_jobs
    WHERE endpoint_url IN (
        'https://runnerhub.run/api/foco/jobs/match-events.cfm',
        'https://business.roadrunners.run/api/foco/jobs/match-events.cfm'
    )
);

UPDATE public.tb_cron_jobs
SET nome = 'Business - Vinculacao Foco Radical',
    descricao = 'Vincula automaticamente candidatos fortes da Foco Radical e envia casos medios para revisao.',
    projeto = 'business',
    endpoint_url = 'https://business.roadrunners.run/api/foco/jobs/match-events.cfm',
    secret_ref = 'business_foco_eventos',
    request_body = '{"limit":20,"pageSize":20,"fromDate":"2023-01-01","minReviewScore":60,"autoLinkScore":85,"autoLink":true,"dryRun":false}',
    data_atualizacao = now()
WHERE endpoint_url IN (
    'https://runnerhub.run/api/foco/jobs/match-events.cfm',
    'https://business.roadrunners.run/api/foco/jobs/match-events.cfm'
);
