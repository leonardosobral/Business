-- Cadastra a importacao automatica de releases SixComm no painel Business.
--
-- Pre-requisitos:
--   1. endpoint /api/admin/importers/sixcomm.cfm publicado no News;
--   2. senha de aplicativo POP validada em /admin/importer_sixcomm_email;
--   3. cronSecrets.conteudo_internal com o mesmo importerHandoffSecret do News;
--   4. runner de /cron-jobs/runner.cfm ativo.

BEGIN;

INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     notificacao_novos_itens_destino, next_run_at)
SELECT
    'Conteudo - Importador SixComm',
    'Importa releases SixComm recebidos por email e envia novos conteudos para a curadoria editorial.',
    'conteudo',
    'prod',
    'https://conteudo.roadrunners.run/api/admin/importers/sixcomm.cfm',
    'POST',
    'application/json',
    '{"max_messages":5,"import_status":"review"}',
    '{}'::jsonb,
    'hmac_sha256',
    'conteudo_internal',
    15,
    120,
    0,
    true,
    true,
    1200,
    '/portal/conteudos/?status=pendentes&canal=sixcomm',
    now()
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tb_cron_jobs
    WHERE endpoint_url = 'https://conteudo.roadrunners.run/api/admin/importers/sixcomm.cfm'
);

UPDATE public.tb_cron_jobs
SET nome = 'Conteudo - Importador SixComm',
    descricao = 'Importa releases SixComm recebidos por email e envia novos conteudos para a curadoria editorial.',
    projeto = 'conteudo',
    ambiente = 'prod',
    endpoint_url = 'https://conteudo.roadrunners.run/api/admin/importers/sixcomm.cfm',
    http_method = 'POST',
    content_type = 'application/json',
    request_body = '{"max_messages":5,"import_status":"review"}',
    headers_json = '{}'::jsonb,
    auth_mode = 'hmac_sha256',
    secret_ref = 'conteudo_internal',
    interval_minutes = 15,
    timeout_seconds = 120,
    retry_limit = 0,
    ativo = true,
    executar_em_atraso = true,
    max_runtime_seconds = 1200,
    notificacao_novos_itens_destino = '/portal/conteudos/?status=pendentes&canal=sixcomm',
    next_run_at = CASE WHEN next_run_at < now() THEN now() ELSE next_run_at END,
    data_atualizacao = now()
WHERE endpoint_url = 'https://conteudo.roadrunners.run/api/admin/importers/sixcomm.cfm';

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
WHERE endpoint_url = 'https://conteudo.roadrunners.run/api/admin/importers/sixcomm.cfm';
