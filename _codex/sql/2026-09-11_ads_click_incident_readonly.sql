-- DIAGNOSTICO SOMENTE LEITURA. NAO E MIGRATION, NAO ESTORNA E NAO AJUSTA METRICAS.
-- Executar o arquivo inteiro no banco operacional com permissao SELECT em ads.
-- IDs extraidos dos logs em 2026-09-12T01:22:14.287473+00:00.
-- Uma linha por GET suspeito; reversoes agregadas separadamente evitam duplicar debitos.
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
SET LOCAL statement_timeout = '25s';
SET LOCAL lock_timeout = '3s';

WITH incident(delivery_id, click_event_id, expected_campaign_id, http_at) AS (
    VALUES
        ('e5699a24-563d-4a2d-a9d0-f75a656e9942'::uuid, 'bb4c7bfe-0656-729c-c5ca-84fc71229ec9'::uuid, 'caf0e94e-38fe-4034-8b80-e8aa6de872d4'::uuid, '2026-09-11T23:08:42Z'::timestamptz),
        ('83d12c05-1c23-4158-81cf-29fb9ca17e7f'::uuid, 'bb579e60-d86a-fc36-88ce-9a1a3aa6332b'::uuid, '09f7f099-ffb9-40fc-853a-70e919b62c4d'::uuid, '2026-09-11T23:09:55Z'::timestamptz),
        ('8ef3acfd-23bb-40f4-9a7a-c43ca9014669'::uuid, 'bb60f764-00b5-3a84-dc8c-92a7bfe79d12'::uuid, 'eb1f4059-f349-495d-a113-0985620a3c6e'::uuid, '2026-09-11T23:10:56Z'::timestamptz),
        ('e024349c-329c-436d-9e95-de5e006f3ebd'::uuid, 'bb7fa377-0184-2a6a-6601-c61666ccd813'::uuid, 'ee964865-2370-4a34-b07d-687477aeb6eb'::uuid, '2026-09-11T23:14:18Z'::timestamptz),
        ('81fb6e6a-fa2a-4009-b38f-b55cfa1d56d5'::uuid, 'bb8626fc-a99d-d8df-b3b7-18b203d563ab'::uuid, '540b7d81-9d6e-4880-93e8-15ea4ff2ccc6'::uuid, '2026-09-11T23:15:00Z'::timestamptz),
        ('89c61be9-4bd8-4dbf-befb-64dbae3ea5fd'::uuid, 'bb9cbe85-034a-d9f6-a671-f2e8fa7aa5e1'::uuid, '1c5dd89f-7d76-4172-b3cb-e964da2fe128'::uuid, '2026-09-11T23:17:28Z'::timestamptz),
        ('b2b79bd2-6e46-4a05-a360-2957fcb8568b'::uuid, 'bba76874-a344-e873-df14-e0958fc55250'::uuid, 'c55094a0-833e-4d8f-a35a-37c6d1c6e091'::uuid, '2026-09-11T23:18:38Z'::timestamptz),
        ('0bc3ffdd-af5e-413a-99ec-e653053c7ebf'::uuid, 'bbade406-c4a8-1de6-c600-f8be1d8188ef'::uuid, '885c0d04-84e6-4739-adbb-66e8319f415c'::uuid, '2026-09-11T23:19:20Z'::timestamptz),
        ('3a0b6cbd-751e-4d76-a3ce-d48069042b58'::uuid, 'bbc06590-a48f-df9b-2ea1-b0af332924b5'::uuid, '1892c7b5-da4c-4e65-9616-a25f78c6eb6b'::uuid, '2026-09-11T23:21:22Z'::timestamptz),
        ('f0e4cd37-6718-4987-a86e-d510dcb71a51'::uuid, 'bbc78582-9fc8-2cc5-2d89-c56fc3ffab62'::uuid, '31512d2e-f0bb-40e3-9600-dd1ddfcaca37'::uuid, '2026-09-11T23:22:08Z'::timestamptz),
        ('d42f33d2-b6e5-48d9-8307-ea4bcd693c5a'::uuid, 'bbd30c14-f53c-c5fc-51b2-4632f8408312'::uuid, '577ce639-2181-4e44-86bf-366f198bf077'::uuid, '2026-09-11T23:23:24Z'::timestamptz)
), reconciled AS (
    SELECT i.delivery_id, i.click_event_id, i.expected_campaign_id,
           i.http_at AT TIME ZONE 'America/Sao_Paulo' AS http_horario_sp,
           d.account_id, d.campaign_id, c.name AS nome_campanha, d.currency, d.price_snapshot,
           d.delivery_id IS NOT NULL AS entrega_encontrada,
           d.campaign_id = i.expected_campaign_id AS campanha_confere,
           e.event_id IS NOT NULL AS clique_encontrado,
           e.valid AS clique_valido, e.billable AS clique_cobravel,
           e.rejection_reason AS motivo_rejeicao,
           e.occurred_at AT TIME ZONE 'America/Sao_Paulo' AS clique_horario_sp,
           abs(extract(epoch FROM e.occurred_at - i.http_at)) AS diferenca_segundos,
           v.total AS impressoes_validas_da_entrega,
           v.before_click AS impressoes_validas_antes_do_clique,
           l.total AS debitos_encontrados, l.ids AS ids_debito,
           l.amount AS valor_debitado, l.reversed AS valor_estornado,
           l.amount - l.reversed AS debito_liquido,
           CASE
               WHEN d.delivery_id IS NULL THEN 'ENTREGA_NAO_ENCONTRADA'
               WHEN d.campaign_id IS DISTINCT FROM i.expected_campaign_id THEN 'DIVERGENCIA_DE_CAMPANHA'
               WHEN e.event_id IS NULL THEN 'CLIQUE_NAO_ENCONTRADO'
               WHEN abs(extract(epoch FROM e.occurred_at - i.http_at)) > 60 THEN 'REVISAR_HORARIO_DO_CLIQUE'
               WHEN l.total > 1 THEN 'REVISAR_MULTIPLOS_DEBITOS'
               WHEN NOT e.valid OR NOT e.billable THEN 'CLIQUE_NAO_COBRAVEL'
               WHEN l.total = 0 THEN 'CLIQUE_SEM_DEBITO_NO_EXTRATO'
               WHEN l.reversed >= l.amount THEN 'DEBITO_JA_ESTORNADO'
               ELSE 'DEBITO_PARA_REVISAO'
           END AS resultado
      FROM incident i
      LEFT JOIN ads.deliveries d ON d.delivery_id = i.delivery_id
      LEFT JOIN ads.campaigns c ON c.campaign_id = d.campaign_id AND c.account_id = d.account_id
      LEFT JOIN ads.events e ON e.event_id = i.click_event_id
          AND e.delivery_id = i.delivery_id AND e.event_type = 'CLICK'
      LEFT JOIN LATERAL (
          SELECT count(*) AS total,
                 count(*) FILTER (WHERE ev.occurred_at <= e.occurred_at) AS before_click
            FROM ads.events ev
           WHERE ev.delivery_id = i.delivery_id
             AND ev.event_type = 'VIEWABLE_IMPRESSION' AND ev.valid
      ) v ON true
      LEFT JOIN LATERAL (
          SELECT count(*) AS total, array_agg(debit.ledger_entry_id) AS ids,
                 coalesce(-sum(debit.amount), 0) AS amount,
                 coalesce(sum(reversal.amount), 0) AS reversed
            FROM ads.credit_ledger debit
            LEFT JOIN LATERAL (
                SELECT coalesce(sum(r.amount), 0) AS amount
                  FROM ads.credit_ledger r
                 WHERE r.reference_entry_id = debit.ledger_entry_id
                   AND r.account_id = debit.account_id AND r.currency = debit.currency
                   AND r.entry_type = 'REVERSAL' AND r.source_type = 'REVERSAL'
            ) reversal ON true
           WHERE debit.delivery_id = i.delivery_id AND debit.event_id = i.click_event_id
             AND debit.entry_type = 'DEBIT' AND debit.source_type = 'CLICK'
      ) l ON true
)
SELECT reconciled.*,
       sum(valor_debitado) OVER (PARTITION BY currency) AS total_debitado_na_moeda,
       sum(valor_estornado) OVER (PARTITION BY currency) AS total_estornado_na_moeda,
       sum(debito_liquido) OVER (PARTITION BY currency) AS total_liquido_na_moeda
  FROM reconciled
 ORDER BY http_horario_sp, delivery_id;

ROLLBACK;
