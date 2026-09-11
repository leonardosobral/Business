/* AUDIENCE_FILTER */
SELECT page_family,
    count(*) FILTER (WHERE event_kind = 'page_view') AS pageviews,
    count(DISTINCT page_view_id) FILTER (WHERE event_kind = 'slot_opportunity') AS pages_with_slots,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity') AS opportunities,
    count(*) FILTER (WHERE event_kind = 'slot_viewable') AS slot_views,
    max(received_at) AS last_received
FROM filtered GROUP BY page_family ORDER BY pageviews DESC, page_family
