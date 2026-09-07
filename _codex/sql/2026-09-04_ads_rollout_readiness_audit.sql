-- SOMENTE LEITURA. Nao e migration e nao chama funcoes de mutacao.
-- Executar como uma unica instrucao no banco RunnerHub.
-- A amostra de campanha usa Avai; substituir o UUID em p para outro canario.
-- Globais: saldo/ledger, duplicidade, pagamentos, jobs e migrations recentes.
-- Resultado nao substitui testes de autorizacao, concorrencia ou fraude.

WITH p AS (
    SELECT '31512d2e-f0bb-40e3-9600-dd1ddfcaca37'::uuid AS id
)
SELECT 'avai_aggregate' AS section,
       jsonb_build_object(
           'served', sum(served_count),
           'viewable', sum(viewable_impression_count),
           'clicks', sum(valid_click_count),
           'cost', sum(cost)
       )::text AS result
FROM ads.daily_metrics, p
WHERE campaign_id = p.id
UNION ALL
SELECT 'avai_events',
       jsonb_build_object(
           'served', count(*) FILTER (WHERE event_type = 'SERVED' AND valid),
           'viewable', count(*) FILTER (WHERE event_type = 'VIEWABLE_IMPRESSION' AND valid),
           'clicks', count(*) FILTER (WHERE event_type = 'CLICK' AND valid),
           'billable', count(*) FILTER (WHERE event_type = 'CLICK' AND billable),
           'last_event', max(received_at)
       )::text
FROM ads.events, p
WHERE campaign_id = p.id
UNION ALL
SELECT 'avai_ledger',
       jsonb_build_object(
           'debits', count(*) FILTER (WHERE entry_type = 'DEBIT'),
           'debit_total', sum(-amount) FILTER (WHERE entry_type = 'DEBIT'),
           'reversals', count(*) FILTER (WHERE entry_type = 'REVERSAL')
       )::text
FROM ads.credit_ledger, p
WHERE campaign_id = p.id
UNION ALL
SELECT 'runner_activate',
       has_function_privilege('runner', 'ads.activate_campaign(uuid,integer,text)', 'EXECUTE')::text
UNION ALL
SELECT 'review_definition',
       jsonb_build_object(
           'activate_references_review',
           position('campaign_review_requests' IN pg_get_functiondef(
               'ads.activate_campaign(uuid,integer,text)'::regprocedure
           )) > 0
       )::text
UNION ALL
SELECT 'balance_discrepancies', count(*)::text
FROM ads.account_balances b
WHERE b.available_balance IS DISTINCT FROM (
    SELECT coalesce(sum(l.amount), 0)
    FROM ads.credit_ledger l
    WHERE l.account_id = b.account_id AND l.currency = b.currency
)
UNION ALL
SELECT 'duplicate_click_debits', count(*)::text
FROM (
    SELECT delivery_id
    FROM ads.credit_ledger
    WHERE source_type = 'CLICK' AND entry_type = 'DEBIT'
    GROUP BY delivery_id
    HAVING count(*) > 1
) x
UNION ALL
SELECT 'paid_without_ledger', count(*)::text
FROM ads.payment_intents
WHERE status = 'PAID' AND ledger_entry_id IS NULL
UNION ALL
SELECT 'payment_statuses', coalesce(jsonb_object_agg(status, n), '{}'::jsonb)::text
FROM (
    SELECT status, count(*) n
    FROM ads.payment_intents
    GROUP BY status
) x
UNION ALL
SELECT 'ads_jobs',
       coalesce(jsonb_agg(jsonb_build_object(
           'id', id_cron_job, 'name', nome, 'active', ativo,
           'minutes', interval_minutes, 'last_status', last_status,
           'next_run', next_run_at
       )), '[]'::jsonb)::text
FROM public.tb_cron_jobs
WHERE endpoint_url LIKE '%/api/ads/%'
UNION ALL
SELECT 'migrations',
       coalesce(jsonb_agg(migration_key ORDER BY migration_key), '[]'::jsonb)::text
FROM ads.schema_migrations
WHERE migration_key >= '2026-08-24';
