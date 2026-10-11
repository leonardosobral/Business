<cfsavecontent variable="VARIABLES.funnelWebhookSQL">
webhook_events AS (
    SELECT CASE WHEN pg_input_is_valid(w.body,'jsonb') THEN CAST(w.body AS jsonb) ELSE CAST('{}' AS jsonb) END AS payload,w.call_date
    FROM public.tb_webhook w
    WHERE w.referencia='pagarme'
), webhook_reversed AS (
    SELECT DISTINCT coalesce(payload->'data'->'order'->>'code',payload->'data'->>'code') AS order_code
    FROM webhook_events
    WHERE payload->>'type' IN ('order.canceled','order.cancelled','charge.refunded','charge.canceled','charge.chargedback','charge.chargeback')
), webhook_raw AS (
    SELECT d.id_usuario AS user_id,
           coalesce(nullif(w.payload->'data'->>'id',''),nullif(w.payload->'data'->'order'->>'id',''),trim(d.num_pedido)) AS order_key,
           lower(d.produto) AS product_code,
           CAST(NULL AS timestamptz) AS paid_at
    FROM public.desafios d
    JOIN webhook_events w ON w.payload->>'type'='order.paid'
        AND w.payload->'data'->>'code'=trim(d.num_pedido)
        AND w.payload->'data'->>'status'='paid'
    LEFT JOIN webhook_reversed reversal ON reversal.order_code=trim(d.num_pedido)
    CROSS JOIN bounds b
    WHERE d.desafio='desafio365'
      AND lower(d.produto) IN ('desafio365','desafio365vip','inscricao365','inscricao365vip')
      AND d.id_usuario>0 AND nullif(trim(d.num_pedido),'') IS NOT NULL
      AND w.call_date < (b.until_at AT TIME ZONE 'America/Sao_Paulo')
      AND coalesce(w.payload->'data'->>'amount','') ~ '^[1-9][0-9]*$'
      AND reversal.order_code IS NULL
), webhook_paid AS (
    SELECT DISTINCT ON (order_key) user_id,order_key,product_code,paid_at,'webhook'::text AS payment_source
    FROM webhook_raw r
    WHERE NOT EXISTS (SELECT 1 FROM webhook_raw conflicting WHERE conflicting.order_key=r.order_key AND conflicting.user_id<>r.user_id)
    ORDER BY order_key,user_id
),
</cfsavecontent>
