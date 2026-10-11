<!--- Reviewed aliases: MIF channel_mapping.csv, ROADRUNNERS row. No fuzzy coupon or person matching. --->
<cfsavecontent variable="VARIABLES.funnelCouponSQL">
coupon_raw AS (
    SELECT p.cod_evento,p.numero_inscricao,p.data_pedido,
           lower(nullif(trim(p.body->>'email'),'')) AS payload_email,
           lower(nullif(trim(p.email),'')) AS column_email,
           trim(regexp_replace(upper(coalesce(p.body->>'codigoCupom','')),'[^A-Z0-9]+',' ','g')) AS coupon_code,
           trim(regexp_replace(upper(coalesce(p.body->>'tituloCupom','')),'[^A-Z0-9]+',' ','g')) AS coupon_title,
           left(coalesce(nullif(trim(o.body->'evento'->>'tituloEvento'),''),'TicketSports ' || CAST(p.cod_evento AS text)),180) AS event_name,
           left(coalesce(nullif(trim(p.body->>'modalidade'),''),p.modalidade,''),100) AS modality
    FROM public.tb_ticketsports_participantes p
    JOIN public.tb_ticketsports_pedidos o ON o.cod_evento=p.cod_evento AND o.numero_pedido=p.numero_pedido
    CROSS JOIN bounds b
    WHERE lower(trim(o.body->>'status'))='pago'
      AND p.data_pedido < (b.until_at AT TIME ZONE 'America/Sao_Paulo')
), coupon_owned AS (
    SELECT r.*,coalesce(payload_email,column_email) AS email_key
    FROM coupon_raw r
    WHERE coupon_code='ROADRUNNERS'
       OR (coupon_code='' AND coupon_title IN ('ROADRUNNERS','ROADRUNNERS INFLU X 10 CASHBACK'))
), coupon_keys AS (
    SELECT lower(trim(u.email)) AS email_key,u.id AS matched_id,u.data_criacao AS created_at,
           CAST(NULL AS integer) AS cod_evento,CAST(NULL AS integer) AS numero_inscricao,
           CAST(NULL AS timestamp) AS data_pedido,CAST(NULL AS text) AS payload_email,
           CAST(NULL AS text) AS column_email,CAST(NULL AS text) AS event_name,CAST(NULL AS text) AS modality,false AS participant
    FROM public.tb_usuarios u
    WHERE u.id>0 AND trim(u.email) ~ '^[^\s@]+@[^\s@]+[.][^\s@]+$'
    UNION ALL
    SELECT email_key,CAST(NULL AS integer),CAST(NULL AS timestamp),cod_evento,numero_inscricao,
           data_pedido,payload_email,column_email,event_name,modality,true
    FROM coupon_owned
), coupon_identities AS (
    SELECT k.*,count(matched_id) OVER identity AS users,min(matched_id) OVER identity AS user_id,
           min(created_at) OVER identity AS matched_created
    FROM coupon_keys k WINDOW identity AS (PARTITION BY email_key)
), coupon_matches AS MATERIALIZED (
    SELECT r.cod_evento,r.numero_inscricao,r.data_pedido,r.event_name,r.modality,r.user_id,CASE
        WHEN payload_email IS NOT NULL AND column_email IS NOT NULL AND payload_email<>column_email THEN 'conflicting'
        WHEN r.email_key IS NULL OR r.email_key !~ '^[^\s@]+@[^\s@]+[.][^\s@]+$' THEN 'invalid'
        WHEN r.users>1 THEN 'ambiguous'
        WHEN r.user_id IS NULL THEN 'unmatched'
        WHEN NOT (r.matched_created<b.until_at AND (NOT :coupon_cohort OR r.matched_created>=b.starts_at)) THEN 'outside_base'
        ELSE 'matched' END AS match_status
    FROM coupon_identities r CROSS JOIN bounds b WHERE r.participant
), coupon_linked AS (
    SELECT * FROM coupon_matches WHERE match_status='matched'
), coupon_people AS MATERIALIZED (
    SELECT c.user_id,count(*) AS registrations,count(DISTINCT c.cod_evento) AS events,
           (array_agg(c.event_name ORDER BY c.data_pedido DESC,c.cod_evento,c.numero_inscricao))[1] AS last_event,
           (array_agg(c.modality ORDER BY c.data_pedido DESC,c.cod_evento,c.numero_inscricao))[1] AS last_modality,
           max(c.data_pedido) AS last_at
    FROM coupon_linked c GROUP BY c.user_id
), coupon_stats AS (
    SELECT count(*) AS registrations,count(*) FILTER(WHERE match_status='matched') AS matched,
           count(*) FILTER(WHERE match_status='unmatched') AS unmatched,
           count(*) FILTER(WHERE match_status='ambiguous') AS ambiguous,
           count(*) FILTER(WHERE match_status='conflicting') AS conflicting,
           count(*) FILTER(WHERE match_status='invalid') AS invalid,
           count(*) FILTER(WHERE match_status='outside_base') AS outside_base
    FROM coupon_matches
),
</cfsavecontent>
