/* AUDIENCE_FILTER */
SELECT content_type, content_id,
    coalesce(max(page_path) FILTER (WHERE event_kind IN ('page_view','content_open')), '') AS page_path,
    count(*) FILTER (WHERE event_kind = 'page_view') AS pageviews,
    count(*) FILTER (WHERE event_kind = 'content_open') AS opens,
    count(DISTINCT visitor_id) FILTER (WHERE event_kind IN ('page_view','content_open')) AS visitors,
    count(DISTINCT page_view_id) FILTER (WHERE event_kind = 'content_viewable') AS card_views,
    count(DISTINCT visitor_id) FILTER (WHERE event_kind = 'content_viewable') AS exposed_visitors,
    count(*) FILTER (WHERE event_kind = 'video_start') AS video_starts,
    count(*) FILTER (WHERE event_kind = 'video_complete') AS video_completions,
    count(DISTINCT page_view_id) FILTER (WHERE event_kind = 'content_progress' AND view_ratio >= 0.25) AS depth_25,
    count(DISTINCT page_view_id) FILTER (WHERE event_kind = 'content_progress' AND view_ratio >= 0.50) AS depth_50,
    count(DISTINCT page_view_id) FILTER (WHERE event_kind = 'content_progress' AND view_ratio >= 0.75) AS depth_75,
    count(DISTINCT page_view_id) FILTER (WHERE event_kind = 'content_progress' AND view_ratio >= 1.00) AS depth_100,
    coalesce(sum(active_ms) FILTER (WHERE event_kind = 'page_engagement'), 0) AS active_ms
FROM filtered WHERE content_id <> '' AND content_type IN ('news','video','event','profile')
GROUP BY content_type, content_id
ORDER BY count(DISTINCT page_view_id) FILTER (
    WHERE event_kind IN ('page_view','content_open','content_viewable')
) DESC, content_type, content_id
LIMIT 101
