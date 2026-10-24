WITH regional AS (
    SELECT e.*, coalesce(nullif(CASE :region_dimension
        WHEN 'visitor' THEN visitor_uf WHEN 'profile' THEN profile_uf
        WHEN 'context' THEN context_uf ELSE market_uf END, ''), repeat('-', 2)) AS audience_uf
    FROM audience.events e
    WHERE e.occurred_at >= (date_trunc('day', now() AT TIME ZONE 'America/Sao_Paulo')
        - (CAST(:days AS integer) - 1) * interval '1 day') AT TIME ZONE 'America/Sao_Paulo'
      AND e.occurred_at <= now()
      AND e.environment = :environment
      AND (:include_internal = true OR e.is_internal = false)
), filtered AS (
    SELECT * FROM regional
    WHERE (:uf = '' OR audience_uf = :uf)
      AND (:page_family = '' OR page_family = :page_family)
      AND (:device_class = '' OR device_class = :device_class)
), page_identity AS (
    -- Only the original page opening identifies the page, never video modals.
    -- Resolve before UF filtering so later slot contexts keep that same identity.
    SELECT page_view_id, max(content_type) AS page_content_type,
           max(content_id) AS page_content_id
    FROM regional WHERE event_kind = 'page_view'
    GROUP BY page_view_id
), page_metrics AS (
    SELECT f.page_view_id, visitor_id, session_id, page_family, page_path,
           coalesce(i.page_content_type, '') AS page_content_type,
           coalesce(i.page_content_id, '') AS page_content_id,
           source, medium, campaign, creative,
           bool_or(event_kind = 'page_view') AS has_view,
           coalesce(max(active_ms) FILTER (WHERE event_kind = 'page_engagement'), 0) AS active_ms
    FROM filtered f LEFT JOIN page_identity i ON i.page_view_id = f.page_view_id
    GROUP BY f.page_view_id, visitor_id, session_id, page_family, page_path,
             i.page_content_type, i.page_content_id,
             source, medium, campaign, creative
)
