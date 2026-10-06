<cfinclude template="../../../includes/backend/require_admin.cfm"/>
<cfinclude template="../../../includes/backend/require_real_platform_context.cfm"/>
<cfsavecontent variable="VARIABLES.funnelLegacySQL">
/* Legacy Desafio confirmations used by the Business and wallet screens.
   Do not infer a paid order from desafios.status, registrations or an email join.
   One order is one purchase, even if its webhook was delivered repeatedly. */
legacy_raw AS (
    SELECT t.id_usuario AS user_id,
           trim(t.codigo_transacao::text) AS order_code,
           coalesce(nullif(t.json_transacao->'data'->>'id',''),nullif(trim(t.codigo_transacao::text),'')) AS order_key,
           lower(coalesce(t.json_transacao->'data'->'items'->0->>'code',t.json_transacao->'data'->'order'->'items'->0->>'code','')) AS product_code,
           coalesce(nullif(t.json_transacao->'data'->'charges'->0->>'paid_at',''),nullif(t.json_transacao->>'created_at','')) AS paid_text
    FROM public.tb_transacoes t
    WHERE t.origem_transacao='pagarme'
      AND t.status_atual='order.paid'
      AND t.id_usuario>0
      AND t.valor_transacao>0
      AND NOT EXISTS (
          SELECT 1 FROM public.tb_transacoes reversal
          WHERE reversal.origem_transacao='pagarme'
            AND (
                (nullif(trim(t.codigo_transacao::text),'') IS NOT NULL AND reversal.codigo_transacao=t.codigo_transacao)
                OR reversal.json_transacao->'data'->'order'->>'id'=t.json_transacao->'data'->>'id'
            )
            AND reversal.status_atual IN ('order.canceled','order.cancelled','charge.refunded','charge.canceled','charge.chargedback','charge.chargeback')
      )
), legacy_dated AS (
    SELECT user_id,order_key,order_code,product_code,
           CASE WHEN paid_text ~ '^[0-9]{4}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])T[0-2][0-9]:[0-5][0-9]:[0-5][0-9](\.[0-9]+)?(Z|[+-][0-2][0-9]:[0-5][0-9])$'
                THEN paid_text::timestamptz ELSE NULL END AS paid_at
    FROM legacy_raw
    WHERE product_code IN ('todosantodia','todosantodiavip','todosantodiaupg') AND order_key IS NOT NULL
), legacy_paid AS (
    SELECT DISTINCT ON (order_key) user_id,order_key,product_code,paid_at,'legacy'::text AS payment_source
    FROM legacy_dated l CROSS JOIN bounds b
    WHERE (l.paid_at<b.until_at OR (l.paid_at IS NULL AND :is_today))
      AND NOT EXISTS (SELECT 1 FROM legacy_dated conflicting WHERE conflicting.order_key=l.order_key AND conflicting.user_id<>l.user_id)
      /* FUNNEL_LEGACY_AUDIT_GUARD */
    ORDER BY order_key,paid_at NULLS LAST,user_id
),
</cfsavecontent>
