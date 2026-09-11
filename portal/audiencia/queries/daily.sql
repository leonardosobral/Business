/* AUDIENCE_FILTER */
SELECT (occurred_at AT TIME ZONE 'America/Sao_Paulo')::date AS day,
    count(*) FILTER (WHERE event_kind = 'page_view') AS pageviews,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity') AS opportunities,
    count(*) FILTER (WHERE event_kind = 'slot_viewable') AS slot_views,
    count(*) FILTER (WHERE event_kind = 'ad_viewable') AS ad_views
FROM filtered GROUP BY day ORDER BY day
