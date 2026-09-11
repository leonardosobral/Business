/* AUDIENCE_FILTER */
 , qualified_acquisition AS (
    SELECT source, medium, campaign, creative, count(*) AS engaged_sessions
    FROM (
        SELECT source, medium, campaign, creative, session_id
        FROM page_metrics GROUP BY source, medium, campaign, creative, session_id
        HAVING sum(active_ms) >= 30000
            OR count(DISTINCT (page_path, page_content_type, page_content_id)) >= 2
    ) sessions GROUP BY source, medium, campaign, creative
), acquisition_metrics AS (
SELECT source, medium, campaign, creative,
    count(DISTINCT page_view_id) FILTER (WHERE has_view) AS pageviews,
    count(DISTINCT page_view_id) AS active_pages, count(DISTINCT visitor_id) AS visitors,
    count(DISTINCT session_id) AS sessions, sum(active_ms) AS active_ms
FROM page_metrics
GROUP BY source, medium, campaign, creative
)
SELECT m.*, coalesce(q.engaged_sessions,0) AS engaged_sessions
FROM acquisition_metrics m LEFT JOIN qualified_acquisition q USING (source,medium,campaign,creative)
ORDER BY m.active_pages DESC, m.source, m.campaign, m.creative LIMIT 101
