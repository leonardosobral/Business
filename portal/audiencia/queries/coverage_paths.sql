/* AUDIENCE_COVERAGE_PATHS */
/* AUDIENCE_FILTER */
, folder_events AS (
    /* page_path is the persisted template route; never reconstruct a browser URL. */
    SELECT f.*,
           CASE WHEN page_path ~ '^/[a-zA-Z0-9/_-]{1,255}$'
                     AND page_path NOT LIKE '%//%'
                THEN '/' || split_part(page_path, '/', 2) || '/'
                ELSE '' END AS page_folder
    FROM filtered f
    WHERE page_family = 'other'
)
SELECT page_folder,
    count(*) FILTER (WHERE event_kind = 'page_view') AS pageviews,
    count(DISTINCT page_view_id) FILTER (WHERE event_kind = 'slot_opportunity') AS pages_with_slots,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity') AS opportunities,
    count(*) FILTER (WHERE event_kind = 'slot_viewable') AS slot_views,
    max(received_at) AS last_received
FROM folder_events
GROUP BY page_folder
ORDER BY pageviews DESC, page_folder
