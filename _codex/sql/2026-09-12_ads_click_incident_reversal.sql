-- REPARO FINANCEIRO: estorna somente os 11 DEBIT/CLICK confirmados pelo usuario.
-- Nao e migration. Usa ads.reverse_click_debit, sem DML direto nas tabelas ads.
-- EXECUTAR O ARQUIVO INTEIRO em sessao dedicada, apos revisar os alvos.
-- Valor maximo: BRL 6,90 (conta 2 Live!: 5,96; conta 1 Grupo STC/Avai: 0,94).
-- Reexecutavel: chave por recibo e contrato canonico impedem credito duplicado.
-- Preserva cliques/impressões historicos; corrige saldo, orcamento e custo via
-- funcao canonica. NAO inventa impressoes e NAO invalida contagens de clique.
BEGIN;
SET LOCAL statement_timeout = '45s';
SET LOCAL lock_timeout = '5s';

CREATE TEMP TABLE ads_click_incident_reversal_targets (
    ledger_id uuid PRIMARY KEY,
    delivery_id uuid NOT NULL,
    click_event_id uuid NOT NULL UNIQUE,
    campaign_id uuid NOT NULL,
    account_id bigint NOT NULL,
    expected_amount numeric(14,2) NOT NULL CHECK (expected_amount > 0),
    reversal_id uuid,
    result_status text
) ON COMMIT DROP;

INSERT INTO ads_click_incident_reversal_targets
    (ledger_id, delivery_id, click_event_id, campaign_id, account_id, expected_amount)
VALUES
    ('a479d0b2-6062-4b02-8f96-e0ee45a6aa90', 'e5699a24-563d-4a2d-a9d0-f75a656e9942', 'bb4c7bfe-0656-729c-c5ca-84fc71229ec9', 'caf0e94e-38fe-4034-8b80-e8aa6de872d4', 2, 0.51),
    ('1ab408f2-8857-4a61-879b-a19bebf19972', '83d12c05-1c23-4158-81cf-29fb9ca17e7f', 'bb579e60-d86a-fc36-88ce-9a1a3aa6332b', '09f7f099-ffb9-40fc-853a-70e919b62c4d', 2, 0.51),
    ('b1b46ff8-63ec-473b-8a62-be4c80ff3dd3', '8ef3acfd-23bb-40f4-9a7a-c43ca9014669', 'bb60f764-00b5-3a84-dc8c-92a7bfe79d12', 'eb1f4059-f349-495d-a113-0985620a3c6e', 2, 0.51),
    ('5ed166cc-8f15-4e83-b27e-80316d3b66d0', 'e024349c-329c-436d-9e95-de5e006f3ebd', 'bb7fa377-0184-2a6a-6601-c61666ccd813', 'ee964865-2370-4a34-b07d-687477aeb6eb', 2, 0.51),
    ('7e29a336-3b6f-42ea-b98a-82e9a02f1dce', '81fb6e6a-fa2a-4009-b38f-b55cfa1d56d5', 'bb8626fc-a99d-d8df-b3b7-18b203d563ab', '540b7d81-9d6e-4880-93e8-15ea4ff2ccc6', 2, 0.51),
    ('dc544033-d529-4c3d-9c84-05ff7eb6d56f', '89c61be9-4bd8-4dbf-befb-64dbae3ea5fd', 'bb9cbe85-034a-d9f6-a671-f2e8fa7aa5e1', '1c5dd89f-7d76-4172-b3cb-e964da2fe128', 2, 0.51),
    ('9203de7a-0d6b-4ee1-aeff-124a0ba1ebd5', 'b2b79bd2-6e46-4a05-a360-2957fcb8568b', 'bba76874-a344-e873-df14-e0958fc55250', 'c55094a0-833e-4d8f-a35a-37c6d1c6e091', 2, 0.51),
    ('f019998d-6ba1-4d0a-97ce-9858afa4367b', '0bc3ffdd-af5e-413a-99ec-e653053c7ebf', 'bbade406-c4a8-1de6-c600-f8be1d8188ef', '885c0d04-84e6-4739-adbb-66e8319f415c', 2, 0.94),
    ('6b27ab26-d82b-44cd-a76c-c06b60bf2c98', '3a0b6cbd-751e-4d76-a3ce-d48069042b58', 'bbc06590-a48f-df9b-2ea1-b0af332924b5', '1892c7b5-da4c-4e65-9616-a25f78c6eb6b', 2, 0.51),
    ('ebd5baf9-e00b-4cf9-8fa6-1a52e7873248', 'f0e4cd37-6718-4987-a86e-d510dcb71a51', 'bbc78582-9fc8-2cc5-2d89-c56fc3ffab62', '31512d2e-f0bb-40e3-9600-dd1ddfcaca37', 1, 0.94),
    ('23d40220-de29-4ff5-9fa9-c7d1c3416ea7', 'd42f33d2-b6e5-48d9-8307-ea4bcd693c5a', 'bbd30c14-f53c-c5fc-51b2-4632f8408312', '577ce639-2181-4e44-86bf-366f198bf077', 2, 0.94);

DO $repair$
DECLARE
    target record;
    receipt record;
    reversal record;
    previous_count integer;
    previous_amount numeric;
    repair_reason text := 'ads-click-incident-2026-09-11: estorno dos acessos Firefox/x.x correlacionados aos logs; operador SQL=' || session_user;
BEGIN
    -- Serializa somente este lote. A funcao canonica mantem seus proprios locks.
    PERFORM pg_advisory_xact_lock(hashtextextended('ads-click-incident-2026-09-11', 91005));

    IF (SELECT count(*) FROM pg_temp.ads_click_incident_reversal_targets) <> 11
       OR (SELECT sum(expected_amount) FROM pg_temp.ads_click_incident_reversal_targets) <> 6.90
       OR (SELECT sum(expected_amount) FROM pg_temp.ads_click_incident_reversal_targets WHERE account_id = 2) IS DISTINCT FROM 5.96
       OR (SELECT sum(expected_amount) FROM pg_temp.ads_click_incident_reversal_targets WHERE account_id = 1) IS DISTINCT FROM 0.94 THEN
        RAISE EXCEPTION 'Escopo do lote divergente; nenhum estorno permitido';
    END IF;

    -- Valida TODOS os alvos antes da primeira chamada financeira.
    FOR target IN SELECT * FROM pg_temp.ads_click_incident_reversal_targets ORDER BY account_id, ledger_id LOOP
        SELECT l.* INTO receipt
          FROM ads.credit_ledger l
         WHERE l.ledger_entry_id = target.ledger_id
           AND l.delivery_id = target.delivery_id
           AND l.event_id = target.click_event_id
           AND l.campaign_id = target.campaign_id
           AND l.account_id = target.account_id
           AND l.currency = 'BRL' AND l.billing_model = 'CPC' AND l.ad_type = 'EVENT'
           AND l.entry_type = 'DEBIT' AND l.source_type = 'CLICK'
           AND l.amount = -target.expected_amount
           AND l.price_snapshot = target.expected_amount;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Recibo % ausente ou divergente; lote cancelado', target.ledger_id;
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM ads.events e
             WHERE e.event_id = target.click_event_id AND e.delivery_id = target.delivery_id
               AND e.campaign_id = target.campaign_id AND e.account_id = target.account_id
               AND e.event_type = 'CLICK' AND e.valid AND e.billable
        ) THEN
            RAISE EXCEPTION 'Evento do recibo % divergente; lote cancelado', target.ledger_id;
        END IF;
        SELECT count(*), coalesce(sum(l.amount),0) INTO previous_count, previous_amount
          FROM ads.credit_ledger l WHERE l.reference_entry_id = target.ledger_id
           AND l.entry_type = 'REVERSAL';
        IF previous_count > 1 OR (previous_count = 1 AND previous_amount <> target.expected_amount) THEN
            RAISE EXCEPTION 'Estorno anterior parcial/inconsistente para %; revisar manualmente', target.ledger_id;
        END IF;
    END LOOP;

    FOR target IN SELECT * FROM pg_temp.ads_click_incident_reversal_targets ORDER BY account_id, ledger_id LOOP
        SELECT * INTO reversal
          FROM ads.reverse_click_debit(
              target.ledger_id,
              'ads-click-incident-2026-09-11:' || target.ledger_id::text,
              NULL::integer,
              repair_reason
          );
        IF NOT FOUND OR reversal.result_status NOT IN ('reversed','already_recorded','already_reversed') THEN
            RAISE EXCEPTION 'Resposta inesperada para %; lote cancelado', target.ledger_id;
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM ads.credit_ledger l
             WHERE l.ledger_entry_id = reversal.ledger_entry_id
               AND l.reference_entry_id = target.ledger_id
               AND l.account_id = target.account_id AND l.currency = 'BRL'
               AND l.entry_type = 'REVERSAL' AND l.source_type = 'REVERSAL'
               AND l.amount = target.expected_amount
        ) THEN
            RAISE EXCEPTION 'Estorno sem recibo valido para %; lote cancelado', target.ledger_id;
        END IF;
        UPDATE pg_temp.ads_click_incident_reversal_targets
           SET reversal_id = reversal.ledger_entry_id, result_status = reversal.result_status
         WHERE ledger_id = target.ledger_id;
    END LOOP;
END;
$repair$;

SELECT account_id, ledger_id AS recibo_original, reversal_id AS recibo_estorno,
       expected_amount AS valor_brl, result_status,
       coalesce(sum(expected_amount) FILTER (WHERE result_status = 'reversed') OVER (), 0) AS creditado_nesta_execucao_brl
  FROM pg_temp.ads_click_incident_reversal_targets
 ORDER BY account_id, ledger_id;

COMMIT;
