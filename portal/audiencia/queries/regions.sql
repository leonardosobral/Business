/* AUDIENCE_FILTER */
SELECT audience_uf,
    count(DISTINCT page_view_id) FILTER (WHERE event_kind = 'page_view') AS pageviews,
    count(DISTINCT page_view_id) AS active_pages,
    count(DISTINCT visitor_id) AS visitors,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity') AS opportunities,
    count(*) FILTER (WHERE event_kind = 'slot_viewable') AS slot_views,
    count(*) FILTER (WHERE event_kind = 'ad_viewable') AS ad_views
FROM filtered GROUP BY audience_uf ORDER BY active_pages DESC, audience_uf
