-- Processa a fila de resumos automáticos do projeto Conteúdo/News.
-- Reutiliza cronSecrets.conteudo_internal; no News, articleSummaryWorkerSecret
-- pode ser omitido para usar o mesmo importerHandoffSecret.

BEGIN;

INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     next_run_at)
SELECT
    'Conteúdo - Resumos automáticos de notícias',
    'Gera e valida resumos por IA para canais configurados como resumo com link para a fonte.',
    'conteudo',
    'prod',
    'https://conteudo.roadrunners.run/api/admin/jobs/article_summary.cfm?limit=1',
    'POST',
    'application/json',
    '{}',
    '{}'::jsonb,
    'api_key_header',
    'conteudo_internal',
    2,
    120,
    1,
    true,
    true,
    600,
    now()
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tb_cron_jobs
    WHERE endpoint_url LIKE 'https://conteudo.roadrunners.run/api/admin/jobs/article_summary.cfm%'
);

UPDATE public.tb_cron_jobs
SET nome = 'Conteúdo - Resumos automáticos de notícias',
    descricao = 'Gera e valida resumos por IA para canais configurados como resumo com link para a fonte.',
    projeto = 'conteudo',
    ambiente = 'prod',
    endpoint_url = 'https://conteudo.roadrunners.run/api/admin/jobs/article_summary.cfm?limit=1',
    http_method = 'POST',
    content_type = 'application/json',
    request_body = '{}',
    headers_json = '{}'::jsonb,
    auth_mode = 'api_key_header',
    secret_ref = 'conteudo_internal',
    interval_minutes = 2,
    timeout_seconds = 120,
    retry_limit = 1,
    ativo = true,
    executar_em_atraso = true,
    max_runtime_seconds = 600,
    next_run_at = CASE WHEN next_run_at < now() THEN now() ELSE next_run_at END,
    data_atualizacao = now()
WHERE endpoint_url LIKE 'https://conteudo.roadrunners.run/api/admin/jobs/article_summary.cfm%';

COMMIT;

SELECT id_cron_job,nome,ativo,interval_minutes,auth_mode,secret_ref,next_run_at,last_status
FROM public.tb_cron_jobs
WHERE endpoint_url LIKE 'https://conteudo.roadrunners.run/api/admin/jobs/article_summary.cfm%';
