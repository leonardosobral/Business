/* AUDIENCE_FILTER */
SELECT slot_key, placement_key, page_family, device_class,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity') AS opportunities,
    count(*) FILTER (WHERE event_kind = 'slot_request') AS requests,
    count(*) FILTER (WHERE event_kind = 'slot_served') AS served,
    count(*) FILTER (WHERE event_kind = 'slot_render') AS renders,
    count(*) FILTER (WHERE event_kind = 'ad_render') AS ad_renders,
    count(*) FILTER (WHERE event_kind = 'slot_viewable') AS slot_views,
    count(*) FILTER (WHERE event_kind = 'ad_viewable') AS ad_views,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity' AND slot_state = 'filled') AS filled_slots,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity' AND slot_state = 'house') AS house_slots,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity' AND slot_state = 'empty') AS empty_slots,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity' AND slot_state = 'pending') AS pending_slots,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity' AND slot_state IN ('hidden','not_applicable','disabled')) AS unavailable_slots,
    count(*) FILTER (WHERE event_kind = 'slot_opportunity' AND slot_state = 'error') AS errors
FROM filtered WHERE slot_key <> ''
GROUP BY slot_key, placement_key, page_family, device_class
ORDER BY opportunities DESC, slot_key, page_family, device_class
LIMIT 201
