-- Cadastra a importacao automatica do Jornal da Corrida no painel Business.
--
-- Pre-requisitos:
--   1. endpoint /api/admin/importers/jornalcorrida.cfm publicado no News;
--   2. cronSecrets.conteudo_internal com o mesmo valor do importerHandoffSecret;
--   3. runner de /cron-jobs/runner.cfm ativo.

BEGIN;

INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     notificacao_novos_itens_destino, next_run_at)
SELECT
    'Conteudo - Importador Jornal da Corrida',
    'Importa o feed atual do Jornal da Corrida e envia novos conteudos para a curadoria editorial.',
    'conteudo',
    'prod',
    'https://conteudo.roadrunners.run/api/admin/importers/jornalcorrida.cfm',
    'POST',
    'application/json',
    '{"import_mode":"latest","import_status":"review","max_pages":1,"start_page":1,"pages_per_run":1,"default_responsible_editor_id":28,"download_featured_media":true}',
    '{}'::jsonb,
    'hmac_sha256',
    'conteudo_internal',
    60,
    120,
    0,
    true,
    true,
    900,
    '/portal/conteudos/?status=pendentes&canal=jornal-da-corrida',
    now()
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tb_cron_jobs
    WHERE endpoint_url = 'https://conteudo.roadrunners.run/api/admin/importers/jornalcorrida.cfm'
);

UPDATE public.tb_cron_jobs
SET nome = 'Conteudo - Importador Jornal da Corrida',
    descricao = 'Importa o feed atual do Jornal da Corrida e envia novos conteudos para a curadoria editorial.',
    projeto = 'conteudo',
    ambiente = 'prod',
    endpoint_url = 'https://conteudo.roadrunners.run/api/admin/importers/jornalcorrida.cfm',
    http_method = 'POST',
    content_type = 'application/json',
    request_body = '{"import_mode":"latest","import_status":"review","max_pages":1,"start_page":1,"pages_per_run":1,"default_responsible_editor_id":28,"download_featured_media":true}',
    headers_json = '{}'::jsonb,
    auth_mode = 'hmac_sha256',
    secret_ref = 'conteudo_internal',
    interval_minutes = 60,
    timeout_seconds = 120,
    retry_limit = 0,
    ativo = true,
    executar_em_atraso = true,
    max_runtime_seconds = 900,
    notificacao_novos_itens_destino = '/portal/conteudos/?status=pendentes&canal=jornal-da-corrida',
    next_run_at = CASE WHEN next_run_at < now() THEN now() ELSE next_run_at END,
    data_atualizacao = now()
WHERE endpoint_url = 'https://conteudo.roadrunners.run/api/admin/importers/jornalcorrida.cfm';

COMMIT;

SELECT id_cron_job,
       nome,
       ativo,
       interval_minutes,
       auth_mode,
       secret_ref,
       next_run_at,
       last_status
FROM public.tb_cron_jobs
WHERE endpoint_url = 'https://conteudo.roadrunners.run/api/admin/importers/jornalcorrida.cfm';
