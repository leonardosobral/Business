/* AUDIENCE_CAPACITY */
WITH clock AS (
    SELECT now() AS as_of, (now() AT TIME ZONE 'America/Sao_Paulo')::date AS today
), slot_events AS (
    SELECT e.page_view_id, e.event_key, e.event_kind, e.occurred_at, e.received_at,
           coalesce(nullif(e.market_uf, ''), repeat('-', 2)) AS audience_uf,
           e.slot_key, e.page_family, e.device_class
    FROM audience.events e CROSS JOIN clock c
    WHERE :region_dimension = 'market' AND :environment = 'prod' AND :include_internal = false
      AND e.environment = 'prod' AND e.is_internal = false
      AND e.occurred_at >= (c.today - (CAST(:days AS integer) - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo'
      AND e.occurred_at <= c.as_of
      AND e.slot_key <> ''
      AND e.event_kind IN ('slot_opportunity', 'slot_render', 'slot_viewable')
), opportunity_identity AS (
    -- Placement/campaign changes and logical resends do not create a new physical position.
    -- Opportunity metadata wins over later events, including viewability after midnight.
    SELECT DISTINCT ON (page_view_id, slot_key, audience_uf)
           page_view_id, slot_key, audience_uf, page_family, device_class,
           (occurred_at AT TIME ZONE 'America/Sao_Paulo')::date AS opportunity_day
    FROM slot_events
    WHERE event_kind = 'slot_opportunity'
    ORDER BY page_view_id, slot_key, audience_uf, occurred_at, received_at, event_key
), slot_signals AS (
    SELECT page_view_id, slot_key, audience_uf,
           bool_or(event_kind = 'slot_render') AS has_render,
           bool_or(event_kind = 'slot_viewable') AS has_view,
           max(received_at) AS last_received
    FROM slot_events
    GROUP BY page_view_id, slot_key, audience_uf
), regional_slots AS (
    SELECT o.*, s.has_render, s.has_view, s.last_received
    FROM opportunity_identity o
    JOIN slot_signals s USING (page_view_id, slot_key, audience_uf)
    WHERE (:uf = '' OR o.audience_uf = :uf)
      AND (:page_family = '' OR o.page_family = :page_family)
      AND (:device_class = '' OR o.device_class = :device_class)
), physical_slots AS (
    -- A page/slot can be observed under several commercial UFs; count it once after selection.
    SELECT page_view_id, slot_key, min(opportunity_day) AS opportunity_day,
           bool_or(has_render) AS has_render, bool_or(has_view) AS has_view,
           max(last_received) AS last_received
    FROM regional_slots
    GROUP BY page_view_id, slot_key
), daily AS (
    SELECT audience_uf, slot_key, page_family, device_class, opportunity_day,
           count(*) AS opportunities,
           count(*) FILTER (WHERE has_render) AS renders,
           count(*) FILTER (WHERE has_view) AS slot_views,
           max(last_received) AS last_received
    FROM regional_slots
    GROUP BY audience_uf, slot_key, page_family, device_class, opportunity_day
), history AS (
    SELECT audience_uf, slot_key, page_family, device_class,
           min(opportunity_day) AS first_day, max(last_received) AS last_received,
           sum(opportunities)::bigint AS opportunities,
           sum(renders)::bigint AS renders, sum(slot_views)::bigint AS slot_views
    FROM daily
    GROUP BY audience_uf, slot_key, page_family, device_class
), coverage AS (
    SELECT h.*,
           count(*) FILTER (WHERE d.opportunity_day > h.first_day AND d.opportunity_day < c.today) AS days_observed,
           14 - count(*) FILTER (WHERE d.opportunity_day > h.first_day
               AND d.opportunity_day >= c.today - 14 AND d.opportunity_day < c.today) AS missing_days_14,
           CASE WHEN count(*) FILTER (WHERE d.opportunity_day > h.first_day
                    AND d.opportunity_day >= c.today - 28 AND d.opportunity_day < c.today) = 28 THEN 28
                WHEN count(*) FILTER (WHERE d.opportunity_day > h.first_day
                    AND d.opportunity_day >= c.today - 14 AND d.opportunity_day < c.today) = 14 THEN 14
                ELSE 0 END AS baseline_days
    FROM history h
    JOIN daily d USING (audience_uf, slot_key, page_family, device_class)
    CROSS JOIN clock c
    GROUP BY h.audience_uf, h.slot_key, h.page_family, h.device_class,
             h.first_day, h.last_received, h.opportunities, h.renders, h.slot_views
), weekly AS (
    -- Only signaled dates enter the arithmetic. A signaled day with no view is measured zero.
    -- The installation date and today are conservatively excluded because either may be partial.
    SELECT h.audience_uf, h.slot_key, h.page_family, h.device_class,
           (c.today - 1 - d.opportunity_day) / 7 AS week_index,
           sum(d.slot_views) AS week_views
    FROM coverage h
    JOIN daily d USING (audience_uf, slot_key, page_family, device_class)
    CROSS JOIN clock c
    WHERE h.baseline_days > 0
      AND d.opportunity_day > h.first_day
      AND d.opportunity_day >= c.today - h.baseline_days
      AND d.opportunity_day < c.today
    GROUP BY h.audience_uf, h.slot_key, h.page_family, h.device_class,
             (c.today - 1 - d.opportunity_day) / 7
), scenarios AS (
    SELECT audience_uf, slot_key, page_family, device_class,
           sum(week_views)::bigint AS baseline_views, min(week_views) AS weakest_week_views
    FROM weekly
    GROUP BY audience_uf, slot_key, page_family, device_class
), detail_rows AS (
    SELECT 'detail'::text AS row_type, h.audience_uf, h.slot_key, h.page_family, h.device_class,
           h.opportunities, h.renders, h.slot_views, to_char(h.first_day, 'YYYY-MM-DD') AS first_day,
           h.last_received, h.days_observed, h.missing_days_14, h.baseline_days,
           coalesce(s.baseline_views, 0)::bigint AS baseline_views,
           -- Directional scenarios at the observed pace, not confidence bounds or promised delivery.
           CASE WHEN h.baseline_days > 0 AND s.baseline_views > 0
                THEN floor(s.weakest_week_views / 7.0 * 30)::bigint END AS low_30,
           CASE WHEN h.baseline_days > 0 AND s.baseline_views > 0
                THEN floor(s.baseline_views::numeric / h.baseline_days * 30)::bigint END AS base_30,
           NULL::bigint AS total_rows
    FROM coverage h
    LEFT JOIN scenarios s USING (audience_uf, slot_key, page_family, device_class)
), physical_history AS (
    SELECT count(*) AS opportunities, count(*) FILTER (WHERE has_render) AS renders,
           count(*) FILTER (WHERE has_view) AS slot_views,
           min(opportunity_day) AS first_day, max(last_received) AS last_received
    FROM physical_slots
), total_row AS (
    SELECT 'total'::text AS row_type, ''::text AS audience_uf, ''::text AS slot_key,
           ''::text AS page_family, ''::text AS device_class,
           h.opportunities, h.renders, h.slot_views,
           coalesce(to_char(h.first_day, 'YYYY-MM-DD'), '') AS first_day, h.last_received,
           count(DISTINCT p.opportunity_day) FILTER (WHERE p.opportunity_day > h.first_day
               AND p.opportunity_day < c.today) AS days_observed,
           14 - count(DISTINCT p.opportunity_day) FILTER (WHERE p.opportunity_day > h.first_day
               AND p.opportunity_day >= c.today - 14 AND p.opportunity_day < c.today) AS missing_days_14,
           0 AS baseline_days, 0::bigint AS baseline_views,
           NULL::bigint AS low_30, NULL::bigint AS base_30,
           (SELECT count(*) FROM detail_rows) AS total_rows
    FROM physical_history h CROSS JOIN clock c
    LEFT JOIN physical_slots p ON true
    GROUP BY h.opportunities, h.renders, h.slot_views, h.first_day, h.last_received
), bounded_details AS (
    -- Totals and group count above include all observations; only the detail presentation is bounded.
    SELECT * FROM detail_rows
    ORDER BY opportunities DESC, audience_uf, slot_key, page_family, device_class
    LIMIT 201
)
SELECT * FROM total_row
UNION ALL
SELECT * FROM bounded_details
ORDER BY row_type DESC, opportunities DESC, audience_uf, slot_key, page_family, device_class
