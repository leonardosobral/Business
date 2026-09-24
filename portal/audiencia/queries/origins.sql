/* AUDIENCE_FILTER */
, origin_pages AS (
    SELECT coalesce(nullif(btrim(source),''),'Não identificada') AS source,
           page_view_id, visitor_id, session_id, page_path, page_content_type, page_content_id,
           bool_or(has_view) AS has_view, max(active_ms) AS active_ms
    FROM page_metrics
    GROUP BY 1, page_view_id, visitor_id, session_id, page_path, page_content_type, page_content_id
), qualified_origins AS (
    SELECT source, count(*) AS engaged_sessions
    FROM (
        SELECT source, session_id FROM origin_pages
        GROUP BY source, session_id
        HAVING sum(active_ms) >= 30000
            OR count(DISTINCT (page_path, page_content_type, page_content_id)) >= 2
    ) sessions GROUP BY source
), origin_metrics AS (
    SELECT source,
           count(DISTINCT page_view_id) FILTER (WHERE has_view) AS pageviews,
           count(DISTINCT page_view_id) AS active_pages,
           count(DISTINCT visitor_id) AS visitors, count(DISTINCT session_id) AS sessions,
           sum(active_ms) AS active_ms
    FROM origin_pages GROUP BY source
)
SELECT m.*, coalesce(q.engaged_sessions,0) AS engaged_sessions
FROM origin_metrics m LEFT JOIN qualified_origins q USING (source)
ORDER BY m.active_pages DESC, m.source LIMIT 101
