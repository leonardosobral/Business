WITH bounds AS (
    SELECT CAST(:from_day AS date)::timestamp AT TIME ZONE 'America/Sao_Paulo' AS starts_at,
           (CAST(:to_day AS date) + 1)::timestamp AT TIME ZONE 'America/Sao_Paulo' AS until_at
), audience_signals AS MATERIALIZED (
    SELECT e.page_view_id, e.visitor_id, e.session_id, e.event_kind, e.occurred_at,
           CASE WHEN e.content_type='verified_offer' THEN coalesce(nullif(e.content_id,''),'unknown') ELSE 'unknown' END AS entry,
           CASE WHEN lower(e.source)='referral' THEN coalesce(nullif(lower(e.referrer_host),''),'referral')
                ELSE coalesce(nullif(lower(e.source),''),'unknown') END AS channel
    FROM audience.events e CROSS JOIN bounds b
    WHERE e.environment = 'prod' AND NOT e.is_internal
      AND e.page_family = 'other' AND e.page_path = '/verificado/'
      AND e.occurred_at >= greatest(b.starts_at, now() - interval '90 days')
      AND e.occurred_at < b.until_at AND e.occurred_at <= now()
      AND (e.event_kind = 'page_view' OR (e.event_kind = 'content_open' AND e.event_key = 'content_open:verified_buy' AND e.content_type='verified_offer'))
), openings AS (
    SELECT DISTINCT ON (page_view_id) page_view_id, visitor_id, session_id, channel, entry, occurred_at
    FROM audience_signals WHERE event_kind='page_view'
    ORDER BY page_view_id, occurred_at
), sessions AS (
    SELECT DISTINCT ON (visitor_id,session_id) visitor_id,session_id,channel,entry
    FROM openings ORDER BY visitor_id,session_id,occurred_at,page_view_id
), clicks AS (
    SELECT c.visitor_id,c.session_id,min(c.occurred_at) AS clicked_at
    FROM audience_signals c JOIN openings v USING (page_view_id,visitor_id,session_id)
    WHERE c.event_kind='content_open' GROUP BY c.visitor_id,c.session_id
), selo_paid AS (
    SELECT o.id,o.user_id,o.paid_at
    FROM rr_verified.orders o CROSS JOIN bounds b
    WHERE o.product_code='rr_selo_verificado_anual' AND o.state='paid'
      AND o.paid_at>=b.starts_at AND o.paid_at<b.until_at AND o.paid_at<=now()
      AND NOT EXISTS (SELECT 1 FROM rr_verified.payment_events p WHERE p.order_id=o.id AND p.event_type='refunded')
), /* ORDER_SOURCES */
, sales AS (
    SELECT p.id,p.user_id,
           CASE WHEN c.clicked_at IS NOT NULL THEN s.channel ELSE coalesce(nullif(p.channel,''),'unknown') END AS channel,
           CASE WHEN c.clicked_at IS NOT NULL THEN s.entry ELSE coalesce(nullif(p.entry,''),'unknown') END AS entry,
           c.visitor_id, c.session_id
    FROM selo_order_sources p
    LEFT JOIN openings v ON v.page_view_id::text = p.page_key AND v.occurred_at<=p.paid_at
    LEFT JOIN sessions s USING (visitor_id,session_id)
    LEFT JOIN clicks c ON c.visitor_id=v.visitor_id AND c.session_id=v.session_id AND c.clicked_at<=p.paid_at
    WHERE NOT p.internal
), traffic AS (
    SELECT s.channel,s.entry,s.visitor_id,s.session_id,c.clicked_at IS NOT NULL AS clicked
    FROM sessions s LEFT JOIN clicks c USING (visitor_id,session_id)
), traffic_metrics AS (
    SELECT grp.dimension,grp.value,count(*) AS visits,count(*) FILTER (WHERE clicked) AS clicks
    FROM traffic t CROSS JOIN LATERAL (VALUES ('channel',t.channel),('entry',t.entry)) grp(dimension,value)
    GROUP BY grp.dimension,grp.value
), sale_metrics AS (
    SELECT grp.dimension,grp.value,count(*) AS orders,
           count(DISTINCT (visitor_id,session_id)) FILTER (WHERE session_id IS NOT NULL) AS paid_sessions
    FROM sales s CROSS JOIN LATERAL (VALUES ('channel',s.channel),('entry',s.entry)) grp(dimension,value)
    GROUP BY grp.dimension,grp.value
), channels AS (
    SELECT dimension,value AS channel,coalesce(t.visits,0) AS visits,coalesce(t.clicks,0) AS clicks,
           coalesce(s.paid_sessions,0) AS paid_sessions,coalesce(s.orders,0) AS orders
    FROM traffic_metrics t FULL JOIN sale_metrics s USING (dimension,value)
)
SELECT (SELECT row_to_json(t) FROM (
            SELECT count(DISTINCT visitor_id) AS visitors,
                   count(DISTINCT visitor_id) FILTER (WHERE clicked) AS clickers,
                   count(*) AS visits,count(*) FILTER (WHERE clicked) AS clicks,
                   (SELECT count(DISTINCT user_id) FROM sales) AS buyers,
                   (SELECT count(*) FROM sales) AS orders,
                   (SELECT count(*) FROM sales WHERE session_id IS NULL) AS outside_journey,
                   (SELECT coalesce(sum(paid_sessions),0) FROM channels WHERE dimension='channel') AS paid_sessions,
                   (SELECT until_at>greatest(now()-interval '90 days',DATE '2026-11-26'::timestamp AT TIME ZONE 'America/Sao_Paulo') FROM bounds) AS traffic_available,
                   (SELECT to_char(greatest(starts_at,now()-interval '90 days',DATE '2026-11-26'::timestamp AT TIME ZONE 'America/Sao_Paulo') AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY') FROM bounds) AS traffic_from
            FROM traffic
       ) t) AS totals,
       (SELECT coalesce(json_agg(row_to_json(c) ORDER BY dimension,orders DESC,paid_sessions DESC,visits DESC,channel),'[]'::json) FROM channels c) AS channels
