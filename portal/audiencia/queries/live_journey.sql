/* AUDIENCE_FILTER */
, journey_events AS (
    SELECT * FROM filtered
    WHERE campaign <> ''
      AND (:live_source = '' OR lower(source) = lower(:live_source))
      AND (:live_campaign = '' OR position(lower(:live_campaign) in lower(campaign)) > 0)
), journey_pages AS (
    SELECT * FROM page_metrics
    WHERE campaign <> ''
      AND (:live_source = '' OR lower(source) = lower(:live_source))
      AND (:live_campaign = '' OR position(lower(:live_campaign) in lower(campaign)) > 0)
), campaign_sessions AS (
    SELECT source, medium, campaign, session_id,
           count(DISTINCT page_view_id) FILTER (WHERE has_view) AS pageviews,
           sum(active_ms) >= 30000 OR count(DISTINCT (page_path,page_content_type,page_content_id)) FILTER (WHERE has_view) >= 2 AS qualified
    FROM journey_pages GROUP BY source,medium,campaign,session_id
), live_outbounds AS (
    SELECT source,medium,campaign,session_id,content_id,
           min(received_at) AS first_outbound,max(received_at) AS last_outbound
    FROM journey_events
    WHERE event_kind = 'outbound_click' AND content_type = 'event'
      AND content_id ~ '^[1-9][0-9]{0,9}$'
      AND event_key = 'outbound_click:live_registration:' || content_id
    GROUP BY source,medium,campaign,session_id,content_id
), event_catalog AS (
    SELECT evt.id_evento::text AS content_id,evt.nome_evento AS event_name,
           evt.tag AS event_tag,evt.cidade AS event_city,evt.estado AS event_uf,
           circuit.tag = 'live-run-xp' AS is_live
    FROM public.tb_evento_corridas evt
    LEFT JOIN public.tb_agrega_eventos circuit ON circuit.id_agrega_evento = evt.id_agrega_evento
), live_visits AS (
    SELECT e.source,e.medium,e.campaign,e.session_id,e.content_id,
           count(DISTINCT e.page_view_id) AS pageviews
    FROM journey_events e LEFT JOIN event_catalog c ON c.content_id = e.content_id
    WHERE e.event_kind = 'page_view' AND e.page_family = 'event' AND e.content_type = 'event'
      AND (c.is_live OR EXISTS (SELECT 1 FROM live_outbounds o WHERE o.content_id = e.content_id))
    GROUP BY e.source,e.medium,e.campaign,e.session_id,e.content_id
), event_sessions AS (
    -- A page can be reloaded and several CTAs can be clicked. One session/event remains one journey.
    SELECT source,medium,campaign,session_id,content_id,
           coalesce(v.pageviews,0) AS pageviews,v.pageviews IS NOT NULL AS has_visit,
           o.first_outbound IS NOT NULL AS has_outbound,o.first_outbound,o.last_outbound
    FROM live_visits v FULL JOIN live_outbounds o USING(source,medium,campaign,session_id,content_id)
), campaign_arrivals AS (
    SELECT source,medium,campaign,sum(pageviews) AS pageviews,count(*) AS sessions,
           count(*) FILTER (WHERE qualified) AS qualified_sessions
    FROM campaign_sessions WHERE pageviews > 0 GROUP BY source,medium,campaign
), campaign_progress AS (
    SELECT source,medium,campaign,
           count(DISTINCT session_id) FILTER (WHERE has_visit) AS event_sessions,
           count(DISTINCT session_id) FILTER (WHERE has_outbound) AS outbound_sessions,
           count(DISTINCT session_id) FILTER (WHERE has_visit AND has_outbound) AS matched_outbound_sessions,
           count(DISTINCT session_id) FILTER (WHERE NOT has_visit AND has_outbound) AS unmatched_outbound_sessions,
           min(first_outbound) AS first_outbound,max(last_outbound) AS last_outbound
    FROM event_sessions GROUP BY source,medium,campaign
), receipts AS (
    SELECT source,medium,campaign,max(received_at) AS last_received
    FROM journey_events GROUP BY source,medium,campaign
), campaign_rows AS (
    SELECT 'campaign'::text AS row_type,source,medium,campaign,''::text AS content_id,
           ''::text AS event_name,''::text AS event_tag,''::text AS event_city,''::text AS event_uf,
           coalesce(a.pageviews,0) AS pageviews,coalesce(a.sessions,0) AS sessions,
           coalesce(a.qualified_sessions,0) AS qualified_sessions,
           coalesce(p.event_sessions,0) AS event_sessions,coalesce(p.outbound_sessions,0) AS outbound_sessions,
           coalesce(p.matched_outbound_sessions,0) AS matched_outbound_sessions,
           coalesce(p.unmatched_outbound_sessions,0) AS unmatched_outbound_sessions,
           p.first_outbound,p.last_outbound,r.last_received
    FROM campaign_arrivals a FULL JOIN campaign_progress p USING(source,medium,campaign)
    LEFT JOIN receipts r USING(source,medium,campaign)
), event_rows AS (
    SELECT 'event'::text AS row_type,e.source,e.medium,e.campaign,e.content_id,
           coalesce(c.event_name,'Evento ' || e.content_id) AS event_name,
           coalesce(c.event_tag,'') AS event_tag,coalesce(c.event_city,'') AS event_city,coalesce(c.event_uf,'') AS event_uf,
           sum(e.pageviews) AS pageviews,count(*) FILTER (WHERE e.has_visit) AS sessions,
           0::bigint AS qualified_sessions,count(*) FILTER (WHERE e.has_visit) AS event_sessions,
           count(*) FILTER (WHERE e.has_outbound) AS outbound_sessions,
           count(*) FILTER (WHERE e.has_visit AND e.has_outbound) AS matched_outbound_sessions,
           count(*) FILTER (WHERE NOT e.has_visit AND e.has_outbound) AS unmatched_outbound_sessions,
           min(e.first_outbound) AS first_outbound,max(e.last_outbound) AS last_outbound,r.last_received
    FROM event_sessions e LEFT JOIN event_catalog c ON c.content_id = e.content_id
    LEFT JOIN receipts r USING(source,medium,campaign)
    -- City/event narrow detail only: campaign arrivals retain their full, deduplicated denominator.
    WHERE (:live_city = '' OR position(lower(:live_city) in lower(coalesce(c.event_city,''))) > 0)
      AND (:live_event = '' OR e.content_id = :live_event)
    GROUP BY e.source,e.medium,e.campaign,e.content_id,c.event_name,c.event_tag,c.event_city,c.event_uf,r.last_received
), limited_campaigns AS (
    SELECT * FROM campaign_rows ORDER BY sessions DESC,source,medium,campaign LIMIT 101
), limited_events AS (
    SELECT * FROM event_rows ORDER BY event_sessions DESC,source,medium,campaign,content_id LIMIT 201
)
SELECT * FROM limited_campaigns UNION ALL SELECT * FROM limited_events
ORDER BY row_type,source,medium,campaign,content_id
