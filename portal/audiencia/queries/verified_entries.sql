/* AUDIENCE_FILTER */
, offer_openings AS (
    SELECT DISTINCT ON (page_view_id) page_view_id, visitor_id, session_id, referrer_host,
           CASE WHEN content_type = 'verified_offer' THEN content_id END AS entry_code
    FROM filtered
    WHERE event_kind = 'page_view' AND page_family = 'other' AND page_path = '/verificado/'
    ORDER BY page_view_id, occurred_at, received_at, event_key
), entries AS (
    SELECT visitor_id, session_id,
           CASE entry_code
               WHEN 'home' THEN 'Home'
               WHEN 'search_ai' THEN 'Busca com IA'
               WHEN 'results' THEN 'Meus resultados'
               WHEN 'profile' THEN 'Perfil do atleta'
               WHEN 'perfilrun' THEN 'Perfil.run público'
               WHEN 'perfilrun_editor' THEN 'Editor do Perfil.run'
               WHEN 'settings' THEN 'Configurações'
               WHEN 'menu' THEN 'Menu'
               WHEN 'creator' THEN 'Página de criadores'
               WHEN 'login' THEN 'Login'
               WHEN 'other_internal' THEN 'Outra página interna'
               WHEN 'external' THEN 'Site externo'
               ELSE 'Sem identificação'
           END AS entry_label
    FROM offer_openings
)
SELECT 'entry' AS breakdown, entry_label, count(*) AS pageviews, count(DISTINCT visitor_id) AS visitors,
       count(DISTINCT session_id) AS sessions
FROM entries
GROUP BY entry_label
UNION ALL
(SELECT 'host', referrer_host, count(*) AS pageviews, count(DISTINCT visitor_id), count(DISTINCT session_id)
 FROM offer_openings WHERE referrer_host <> ''
 GROUP BY referrer_host ORDER BY pageviews DESC, referrer_host LIMIT 25)
ORDER BY breakdown, pageviews DESC, entry_label
