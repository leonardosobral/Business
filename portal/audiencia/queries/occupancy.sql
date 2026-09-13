/* AUDIENCE_OCCUPANCY */
/* AUDIENCE_OCCUPANCY_BASE */
, physical_slots AS (
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
