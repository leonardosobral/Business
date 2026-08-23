-- Registra a reconciliacao periodica de pagamentos de publicidade.
--
-- Pre-requisitos:
--   1. migration de pagamentos Ads e contract tests aprovados;
--   2. endpoint /api/ads/payments/reconcile.cfm publicado;
--   3. config/pagarme.local.cfm e Bearer business_internal configurados;
--   4. runner de /cron-jobs/runner.cfm ativo.
--
-- O job nasce inativo. Ative somente depois do smoke manual e configure no
-- painel ao menos um administrador para notificacao de erros consecutivos.

BEGIN;

INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     next_run_at)
SELECT
    'Business - Reconciliacao de pagamentos Ads',
    'Reconsulta em batch pagamentos Ads nao terminais e recupera webhooks perdidos.',
    'business',
    'prod',
    'https://business.roadrunners.run/api/ads/payments/reconcile.cfm',
    'POST',
    'application/json',
    '{}',
    '{}'::jsonb,
    'bearer',
    'business_internal',
    5,
    120,
    1,
    false,
    true,
    120,
    now()
WHERE NOT EXISTS (
    SELECT 1
      FROM public.tb_cron_jobs
     WHERE endpoint_url =
           'https://business.roadrunners.run/api/ads/payments/reconcile.cfm'
);

UPDATE public.tb_cron_jobs
   SET nome = 'Business - Reconciliacao de pagamentos Ads',
       descricao = 'Reconsulta em batch pagamentos Ads nao terminais e recupera webhooks perdidos.',
       projeto = 'business',
       ambiente = 'prod',
       http_method = 'POST',
       content_type = 'application/json',
       request_body = '{}',
       headers_json = '{}'::jsonb,
       auth_mode = 'bearer',
       secret_ref = 'business_internal',
       interval_minutes = 5,
       timeout_seconds = 120,
       retry_limit = 1,
       executar_em_atraso = true,
       max_runtime_seconds = 120,
       data_atualizacao = now()
 WHERE endpoint_url =
       'https://business.roadrunners.run/api/ads/payments/reconcile.cfm';

COMMIT;

SELECT id_cron_job,
       nome,
       ativo,
       interval_minutes,
       retry_limit,
       next_run_at,
       last_status
  FROM public.tb_cron_jobs
 WHERE endpoint_url =
       'https://business.roadrunners.run/api/ads/payments/reconcile.cfm';
