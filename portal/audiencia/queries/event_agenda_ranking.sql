WITH clock AS (
    SELECT now() AS until_at, (now() AT TIME ZONE 'America/Sao_Paulo')::date AS today
), bounds AS (
    SELECT *, (today - (:days - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo' AS since_at
    FROM clock
), saved AS MATERIALIZED (
    SELECT DISTINCT a.id_evento,a.id_usuario
    FROM public.tb_evento_corridas_checkin a
    JOIN public.tb_evento_corridas c ON c.id_evento=a.id_evento CROSS JOIN bounds b
    WHERE a.id_fornecedor IS NULL AND a.tipo_checkin IN ('calendario','inscricao')
      AND c.ativo AND c.data_final >= b.today
      AND coalesce(lower(btrim(c.status_evento)),'') <> 'cancelado'
      AND (:uf = '' OR upper(c.estado) = :uf)
      AND (:term = '' OR position(lower(:term) in lower(concat_ws(' ',c.id_evento,c.nome_evento,c.tag,c.cidade,c.estado))) > 0)
      AND (:event_id = '' OR c.id_evento::text = :event_id)
), counts AS (
    SELECT id_evento,count(*) AS athletes FROM saved GROUP BY id_evento
), catalog AS MATERIALIZED (
    SELECT c.id_evento::text AS content_id,n.athletes,
           coalesce(c.nome_evento,'Evento ' || c.id_evento) AS event_name,
           coalesce(c.tag,'') AS tag,coalesce(c.cidade,'Não informada') AS city,
           coalesce(c.estado,'') AS uf,to_char(c.data_inicial,'DD/MM/YYYY') AS event_date,
           extract(year FROM c.data_inicial)::integer AS event_year,c.data_inicial,
           array_remove(ARRAY[
               CASE WHEN nullif(btrim(c.cidade),'') IS NULL OR nullif(btrim(c.estado),'') IS NULL THEN 'Localização' END,
               CASE WHEN nullif(btrim(regexp_replace(coalesce(c.descricao,''),'<[^>]*>','','g')),'') IS NULL THEN 'Descrição' END,
               CASE WHEN nullif(btrim(c.imagem),'') IS NULL AND nullif(btrim(c.url_imagem),'') IS NULL THEN 'Imagem' END,
               CASE WHEN nullif(btrim(c.url_inscricao),'') IS NULL THEN 'Link de inscrição' END,
               CASE WHEN NOT EXISTS (SELECT 1 FROM public.tb_evento_corridas_percursos p WHERE p.id_evento=c.id_evento) THEN 'Percursos' END
           ],NULL) AS missing_fields
    FROM counts n JOIN public.tb_evento_corridas c USING(id_evento)
), selected AS MATERIALIZED (
    SELECT * FROM catalog ORDER BY athletes DESC,data_inicial,content_id LIMIT 50 OFFSET :offset
), measured AS MATERIALIZED (
    SELECT DISTINCT ON (e.page_view_id) e.page_view_id,e.content_id,e.visitor_id,e.session_id,e.page_family,e.content_type
    FROM audience.events e CROSS JOIN bounds b
    WHERE e.environment='prod' AND e.site_host IN ('roadrunners.run','www.roadrunners.run')
      AND (:include_internal OR NOT e.is_internal) AND e.event_kind='page_view'
      AND e.occurred_at >= b.since_at AND e.occurred_at <= b.until_at
    ORDER BY e.page_view_id,e.occurred_at,e.event_key
), audience_counts AS (
    SELECT e.content_id,count(*) AS pageviews,count(DISTINCT e.visitor_id) AS visitors,
           count(DISTINCT e.session_id) AS sessions
    FROM measured e JOIN selected s USING(content_id)
    WHERE e.page_family='event' AND e.content_type='event' GROUP BY e.content_id
), ranking AS (
    SELECT s.content_id,s.event_name,s.tag,s.city,s.uf,coalesce(s.event_date,'Sem data') AS event_date,
           coalesce(s.event_year,0) AS event_year,s.athletes,s.missing_fields,
           coalesce(a.pageviews,0) AS pageviews,coalesce(a.visitors,0) AS visitors,coalesce(a.sessions,0) AS sessions
    FROM selected s LEFT JOIN audience_counts a USING(content_id)
    ORDER BY s.athletes DESC,s.data_inicial,s.content_id
)
SELECT json_build_object(
    'meta',(SELECT json_build_object('since',to_char(since_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),
       'until',to_char(until_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),'days',:days) FROM bounds),
    'summary',(SELECT json_build_object('events',count(*),'athletes',(SELECT count(DISTINCT id_usuario) FROM saved),
       'gaps',count(*) FILTER (WHERE cardinality(missing_fields)>0)) FROM catalog),
    'ranking',coalesce((SELECT json_agg(r) FROM ranking r),'[]'::json)
)::text AS report
