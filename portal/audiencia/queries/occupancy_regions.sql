/* AUDIENCE_OCCUPANCY_REGIONS */
/* AUDIENCE_OCCUPANCY_BASE */
, observed_regions AS (
    SELECT DISTINCT audience_uf FROM regional_slots
), formats (format, sort_order) AS (
    VALUES ('all', 0), ('ads', 1), ('banners', 2), ('other', 3)
)
/* Regional observations can overlap; only occupancy.sql computes the global physical total. */
SELECT r.audience_uf, f.format, count(p.page_view_id) AS registered,
       count(p.page_view_id) FILTER (WHERE p.is_potential) AS potential,
       count(p.page_view_id) FILTER (WHERE p.is_potential AND p.has_fill) AS filled,
       count(p.page_view_id) FILTER (WHERE p.is_potential AND NOT p.has_fill AND p.is_empty) AS empty,
       count(p.page_view_id) FILTER (WHERE p.is_potential AND NOT p.has_fill AND NOT p.is_empty) AS unclassified
FROM observed_regions r CROSS JOIN formats f
LEFT JOIN regional_slots p ON p.audience_uf = r.audience_uf AND (f.format = 'all' OR p.format = f.format)
GROUP BY r.audience_uf, f.format, f.sort_order
ORDER BY r.audience_uf, f.sort_order
