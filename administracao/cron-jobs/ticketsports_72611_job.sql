INSERT INTO public.tb_cron_jobs
    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type,
     request_body, headers_json, auth_mode, secret_ref, interval_minutes,
     timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds,
     next_run_at)
SELECT
    'RunnerHub - Ticket Sports 72611',
    'Importa de forma incremental as inscricoes do evento Ticket Sports 72611.',
    'runnerhub',
    'prod',
    'https://runnerhub.run/api/ticketsports/jobs/import.cfm',
    'POST',
    'application/json',
    '{"eventId":72611,"pageSize":50,"pagesPerRun":1,"fullRescanHours":24,"dryRun":true}',
    '{}'::jsonb,
    'bearer',
    'runnerhub_ticketsports',
    10,
    120,
    0,
    false,
    true,
    120,
    now()
WHERE NOT EXISTS (
    SELECT 1
    FROM public.tb_cron_jobs
    WHERE endpoint_url = 'https://runnerhub.run/api/ticketsports/jobs/import.cfm'
      AND nome = 'RunnerHub - Ticket Sports 72611'
);
