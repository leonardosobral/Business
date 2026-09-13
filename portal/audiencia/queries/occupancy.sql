/* AUDIENCE_OCCUPANCY */
WITH clock AS (
    SELECT now() AS as_of, (now() AT TIME ZONE 'America/Sao_Paulo')::date AS today
), slot_formats (slot_key, format) AS (
    VALUES ('rr-home-upcoming-native', 'ads'),
           ('rr-home-upcoming-native-secondary', 'ads'),
           ('rr-search-events-native', 'ads'),
           ('rr-state-events-native', 'ads'),
           ('rr-sidebar-event-native', 'ads'),
           ('rr-sidebar-banner-desktop', 'banners'),
           ('rr-sidebar-banner-mobile', 'banners'),
           ('rr-home-banner-mobile', 'banners'),
           ('rr-search-banner-mobile', 'banners'),
           ('rr-state-banner-mobile', 'banners'),
           ('rr-feed-banner-desktop', 'banners'),
           ('rr-legacy-sidebar-promo', 'banners'),
           ('rr-legacy-sidebar-marathons', 'banners'),
           ('rr-channel-sidebar-promo', 'banners'),
           ('rr-challenge-detail-promo', 'banners'),
           ('rr-profile-sidebar-promo', 'banners')
), placement_formats (placement_key, format) AS (
    VALUES ('rr-home-upcoming-native', 'ads'),
           ('rr-home-upcoming-native-secondary', 'ads'),
           ('rr-search-events-native', 'ads'),
           ('rr-state-events-native', 'ads'),
           ('rr-sidebar-event-native', 'ads'),
           ('rr-sidebar-banner-300x250', 'banners'),
           ('rr-sidebar-static-promo', 'banners'),
           ('rr-content-static-promo', 'banners')
), slot_events AS (
    SELECT e.page_view_id, e.event_key, e.event_kind, e.occurred_at, e.received_at,
           coalesce(nullif(CASE :region_dimension
               WHEN 'visitor' THEN e.visitor_uf WHEN 'profile' THEN e.profile_uf
               WHEN 'context' THEN e.context_uf ELSE e.market_uf END, ''), repeat('-', 2)) AS audience_uf,
           e.slot_key, e.placement_key, e.page_family, e.device_class,
           e.slot_state, e.delivery_id, e.campaign_id
    FROM audience.events e CROSS JOIN clock c
    WHERE e.environment = :environment
      AND (:include_internal = true OR e.is_internal = false)
      AND e.occurred_at >= (c.today - (CAST(:days AS integer) - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo'
      AND e.occurred_at <= c.as_of
      AND e.slot_key <> ''
      AND e.event_kind IN ('slot_opportunity', 'slot_served', 'slot_render', 'slot_viewable', 'ad_render', 'ad_viewable')
), opportunity_identity AS (
    /* The first opportunity fixes metadata per regional physical observation, as in capacity. */
    SELECT DISTINCT ON (page_view_id, slot_key, audience_uf)
           page_view_id, slot_key, audience_uf, placement_key, page_family, device_class
    FROM slot_events
    WHERE event_kind = 'slot_opportunity'
    ORDER BY page_view_id, slot_key, audience_uf, occurred_at, received_at, event_key
), ordered_signals AS (
    /* Event keys identify signals, not chronology; equal timestamps share the same evidence order. */
    SELECT e.*, dense_rank() OVER (
        PARTITION BY page_view_id, slot_key, audience_uf
        ORDER BY occurred_at, received_at
    ) AS signal_order
    FROM slot_events e
), slot_signals AS (
    SELECT page_view_id, slot_key, audience_uf,
           coalesce(bool_or(slot_state IN ('filled', 'house') AND (
               event_kind IN ('slot_opportunity', 'slot_served', 'slot_render', 'slot_viewable')
               OR (delivery_id IS NOT NULL AND campaign_id IS NOT NULL)
           )), false) AS has_fill,
           coalesce(bool_or(slot_state = 'empty' AND event_kind NOT IN ('ad_render', 'ad_viewable')), false) AS has_empty,
           /* Empty requires explicit slot evidence; malformed ads and operational conflicts stay unresolved. */
           bool_and(event_kind NOT IN ('ad_render', 'ad_viewable')
               AND coalesce(slot_state IN ('empty', 'pending'), false)) AS only_empty_or_pending,
           bool_and(event_kind NOT IN ('ad_render', 'ad_viewable')
               AND coalesce(slot_state IN ('hidden', 'not_applicable', 'pending'), false)) AS only_inactive_or_pending,
           coalesce(bool_or(slot_state IN ('hidden', 'not_applicable')), false) AS has_inactive,
           /* Pending may precede a final decision, but a later pending observation remains unresolved. */
           coalesce(max(signal_order) FILTER (WHERE slot_state = 'pending'), 0)
               > coalesce(max(signal_order) FILTER (WHERE slot_state IN ('empty', 'hidden', 'not_applicable', 'filled', 'house')
                   AND event_kind NOT IN ('ad_render', 'ad_viewable')), 0) AS unresolved_pending
    FROM ordered_signals
    GROUP BY page_view_id, slot_key, audience_uf
), regional_slots AS (
    SELECT o.page_view_id, o.slot_key, s.has_fill,
           /* Applicability is established per selected UF before physical deduplication. */
           NOT (NOT s.has_fill AND s.has_inactive AND s.only_inactive_or_pending AND NOT s.unresolved_pending) AS is_potential,
           s.has_empty AND s.only_empty_or_pending AND NOT s.unresolved_pending AS is_empty,
           CASE WHEN sf.format IS NOT NULL AND pf.format IS NOT NULL AND sf.format <> pf.format
                THEN 'other' ELSE coalesce(sf.format, pf.format, 'other') END AS format
    FROM opportunity_identity o
    JOIN slot_signals s USING (page_view_id, slot_key, audience_uf)
    LEFT JOIN slot_formats sf ON sf.slot_key = o.slot_key
    LEFT JOIN placement_formats pf ON pf.placement_key = o.placement_key
    WHERE (:uf = '' OR o.audience_uf = :uf)
      AND (:page_family = '' OR o.page_family = :page_family)
      AND (:device_class = '' OR o.device_class = :device_class)
), physical_slots AS (
    /* Collapse selected UFs after filters; rotations never add another physical position. */
    SELECT page_view_id, slot_key, bool_or(is_potential) AS is_potential, bool_or(has_fill) AS has_fill,
           coalesce(bool_and(is_empty) FILTER (WHERE is_potential), false) AS is_empty,
           CASE WHEN min(format) = max(format) THEN min(format) ELSE 'other' END AS format
    FROM regional_slots
    GROUP BY page_view_id, slot_key
), formats (format, sort_order) AS (
    VALUES ('all', 0), ('ads', 1), ('banners', 2), ('other', 3)
)
SELECT f.format, count(p.page_view_id) AS registered,
       count(p.page_view_id) FILTER (WHERE p.is_potential) AS potential,
       count(p.page_view_id) FILTER (WHERE p.is_potential AND p.has_fill) AS filled,
       count(p.page_view_id) FILTER (WHERE p.is_potential AND NOT p.has_fill AND p.is_empty) AS empty,
       count(p.page_view_id) FILTER (WHERE p.is_potential AND NOT p.has_fill AND NOT p.is_empty) AS unclassified
FROM formats f
LEFT JOIN physical_slots p ON f.format = 'all' OR p.format = f.format
GROUP BY f.format, f.sort_order
ORDER BY f.sort_order
