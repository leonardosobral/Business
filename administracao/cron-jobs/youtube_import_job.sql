INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     next_run_at)
SELECT
    'Business - Importacao YouTube',
    'Importa videos dos canais e playlists configurados no Portal.',
    'business',
    'prod',
    'https://business.roadrunners.run/api/youtube-import.cfm',
    'POST',
    'application/json',
    '{"channel":"","maxResults":10,"maxPages":1,"dryRun":true}',
    '{}'::jsonb,
    'hmac_sha256',
    'business_youtube',
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
    WHERE endpoint_url IN (
        'https://runnerhub.run/api/youtube/',
        'https://runnerhub.run/api/youtube/index.cfm',
        'https://business.roadrunners.run/api/youtube/jobs/import.cfm',
        'https://business.roadrunners.run/api/youtube-import.cfm'
    )
);

UPDATE public.tb_cron_jobs
SET nome = 'Business - Importacao YouTube',
    descricao = 'Importa videos dos canais e playlists configurados no Portal.',
    projeto = 'business',
    endpoint_url = 'https://business.roadrunners.run/api/youtube-import.cfm',
    http_method = 'POST',
    content_type = 'application/json',
    request_body = '{"channel":"","maxResults":10,"maxPages":1,"dryRun":true}',
    headers_json = '{}'::jsonb,
    auth_mode = 'hmac_sha256',
    secret_ref = 'business_youtube',
    timeout_seconds = 120,
    retry_limit = 0,
    max_runtime_seconds = 120,
    ativo = false,
    data_atualizacao = now()
WHERE endpoint_url IN (
    'https://runnerhub.run/api/youtube/',
    'https://runnerhub.run/api/youtube/index.cfm',
    'https://business.roadrunners.run/api/youtube/jobs/import.cfm',
    'https://business.roadrunners.run/api/youtube-import.cfm'
);
