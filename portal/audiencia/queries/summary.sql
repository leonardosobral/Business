/* AUDIENCE_FILTER */
SELECT
    (SELECT count(DISTINCT page_view_id) FROM page_metrics WHERE has_view) AS pageviews,
    count(DISTINCT page_view_id) AS active_pages,
    count(DISTINCT visitor_id) AS visitors,
    count(DISTINCT session_id) AS sessions,
    (SELECT count(*) FROM (
        SELECT session_id FROM page_metrics
        GROUP BY session_id HAVING sum(active_ms) >= 30000
            OR count(DISTINCT (page_path, page_content_type, page_content_id)) >= 2
    ) engaged) AS engaged_sessions,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity') AS opportunities,
    count(*) FILTER (WHERE event_kind = 'slot_render') AS renders,
    count(*) FILTER (WHERE event_kind = 'slot_viewable') AS slot_views,
    count(*) FILTER (WHERE event_kind = 'ad_render') AS ad_renders,
    count(*) FILTER (WHERE event_kind = 'ad_viewable') AS ad_views,
    count(*) FILTER (WHERE event_kind = 'page_view' AND coalesce(visitor_uf, '') = '') AS unknown_location,
    count(*) FILTER (WHERE event_kind = 'page_view' AND coalesce(market_uf, '') = '') AS unknown_market,
    min(occurred_at) AS first_event, max(received_at) AS last_received
FROM filtered
