WITH clock AS (
    SELECT now() AS until_at, (now() AT TIME ZONE 'America/Sao_Paulo')::date AS today,
           CASE WHEN :days >= 30 THEN 30 ELSE 7 END AS trend_days
), bounds AS (
    SELECT *, (today - (:days - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo' AS since_at,
           (today - (trend_days - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo' AS recent_at,
           (today - (2 * trend_days - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo' AS previous_at,
           ((until_at AT TIME ZONE 'America/Sao_Paulo') - trend_days * interval '1 day')
               AT TIME ZONE 'America/Sao_Paulo' AS previous_until
    FROM clock
), measured AS MATERIALIZED (
    SELECT DISTINCT ON (e.page_view_id) e.*
    FROM audience.events e CROSS JOIN bounds b
    WHERE e.environment = 'prod' AND e.site_host IN ('roadrunners.run','www.roadrunners.run')
      AND (:include_internal OR NOT e.is_internal)
      AND e.event_kind = 'page_view'
      AND e.occurred_at >= least(b.since_at,b.previous_at - interval '1 day')
      AND e.occurred_at <= b.until_at
    ORDER BY e.page_view_id,e.occurred_at,e.event_key
), coverage AS (
    SELECT min(e.occurred_at) AS first_observed,
           coalesce(min(e.occurred_at) < max(b.previous_at)
             AND count(DISTINCT (e.occurred_at AT TIME ZONE 'America/Sao_Paulo')::date)
                 FILTER (WHERE e.occurred_at >= b.previous_at) = 2 * max(b.trend_days),false) AS comparison_ready
    FROM measured e CROSS JOIN bounds b
), event_pages AS MATERIALIZED (
    SELECT * FROM measured WHERE page_family = 'event' AND content_type = 'event'
), catalog AS MATERIALIZED (
    SELECT ids.content_id, c.nome_evento,c.tag,c.cidade,c.estado,c.data_inicial,c.data_final,c.ativo,
           c.id_evento IS NULL AS catalog_missing,
           CASE WHEN c.id_evento IS NULL THEN ARRAY['Cadastro não encontrado']::text[] ELSE
           array_remove(ARRAY[
               CASE WHEN nullif(btrim(c.cidade),'') IS NULL OR nullif(btrim(c.estado),'') IS NULL THEN 'Localização' END,
               CASE WHEN nullif(btrim(regexp_replace(coalesce(c.descricao,''),'<[^>]*>','','g')),'') IS NULL THEN 'Descrição' END,
               CASE WHEN nullif(btrim(c.imagem),'') IS NULL AND nullif(btrim(c.url_imagem),'') IS NULL THEN 'Imagem' END,
               CASE WHEN c.data_final >= b.today AND nullif(btrim(c.url_inscricao),'') IS NULL THEN 'Link de inscrição' END,
               CASE WHEN NOT EXISTS (SELECT 1 FROM public.tb_evento_corridas_percursos p WHERE p.id_evento=c.id_evento) THEN 'Percursos' END
           ],NULL) END AS missing_fields
    FROM (SELECT DISTINCT content_id FROM event_pages) ids
    LEFT JOIN public.tb_evento_corridas c ON c.id_evento =
        CASE WHEN ids.content_id ~ '^[1-9][0-9]{0,9}$'
             THEN CASE WHEN ids.content_id::bigint <= 2147483647 THEN ids.content_id::integer END END
    CROSS JOIN bounds b
), filtered AS MATERIALIZED (
    SELECT e.* FROM event_pages e JOIN catalog c USING(content_id) CROSS JOIN bounds b
    WHERE (:term = '' OR position(lower(:term) in lower(concat_ws(' ',e.content_id,c.nome_evento,c.tag,c.cidade,c.estado))) > 0)
      AND (:uf = '' OR upper(c.estado) = :uf)
      AND (:event_id = '' OR e.content_id = :event_id)
      AND (:stage = 'all' OR (:stage = 'future' AND c.data_final >= b.today) OR (:stage = 'past' AND c.data_final < b.today))
), period_pages AS MATERIALIZED (
    SELECT e.* FROM filtered e CROSS JOIN bounds b WHERE e.occurred_at >= b.since_at
), counts AS (
    SELECT e.content_id,count(*) FILTER (WHERE e.occurred_at >= b.since_at) AS pageviews,
           count(DISTINCT e.visitor_id) FILTER (WHERE e.occurred_at >= b.since_at) AS visitors,
           count(DISTINCT e.session_id) FILTER (WHERE e.occurred_at >= b.since_at) AS sessions,
           count(DISTINCT e.visitor_id) FILTER (WHERE e.occurred_at >= b.recent_at) AS recent_visitors,
           count(DISTINCT e.visitor_id) FILTER (WHERE e.occurred_at >= b.previous_at AND e.occurred_at <= b.previous_until) AS previous_visitors,
           to_char(max(e.occurred_at) AT TIME ZONE 'America/Sao_Paulo','DD/MM HH24:MI') AS last_view
    FROM filtered e CROSS JOIN bounds b GROUP BY e.content_id
), event_rows AS MATERIALIZED (
    SELECT n.*, coalesce(c.nome_evento,'Evento ' || nullif(n.content_id,''),'Evento não identificado') AS event_name,
           coalesce(c.tag,'') AS tag,coalesce(c.cidade,'Não informada') AS city,coalesce(c.estado,'') AS uf,
           coalesce(to_char(c.data_inicial,'DD/MM/YYYY'),'Sem data') AS event_date,
           coalesce(extract(year FROM c.data_inicial)::integer,0) AS event_year,
           c.catalog_missing,coalesce(c.ativo,false) AS active,c.missing_fields,
           coalesce(c.data_final >= b.today,false) AS upcoming,
           CASE WHEN v.comparison_ready AND n.previous_visitors > 0
                THEN round(100.0 * (n.recent_visitors - n.previous_visitors) / n.previous_visitors,1) END AS growth_pct
    FROM counts n JOIN catalog c USING(content_id) CROSS JOIN coverage v CROSS JOIN bounds b
), ranking AS (
    SELECT * FROM event_rows WHERE pageviews > 0 ORDER BY pageviews DESC,visitors DESC,content_id LIMIT 50 OFFSET :offset
), hot AS (
    SELECT * FROM event_rows WHERE upcoming AND active AND recent_visitors >= 3
    ORDER BY recent_visitors DESC,pageviews DESC,content_id LIMIT 20
), gaps AS (
    SELECT * FROM event_rows WHERE pageviews > 0 AND cardinality(missing_fields) > 0
    ORDER BY upcoming DESC,pageviews DESC,visitors DESC,content_id LIMIT 20
), daily AS (
    SELECT to_char(d.day,'DD/MM') AS day,count(p.page_view_id) AS pageviews
    FROM bounds b CROSS JOIN LATERAL generate_series(b.today - (:days - 1),b.today,interval '1 day') d(day)
    LEFT JOIN period_pages p ON (p.occurred_at AT TIME ZONE 'America/Sao_Paulo')::date = d.day::date
    GROUP BY d.day ORDER BY d.day
), sources AS (
    SELECT coalesce(nullif(source,''),nullif(referrer_host,''),'Não identificada') AS source,
           coalesce(medium,'') AS medium,coalesce(campaign,'') AS campaign,
           count(*) AS pageviews,count(DISTINCT visitor_id) AS visitors,count(DISTINCT session_id) AS sessions
    FROM period_pages GROUP BY 1,2,3 ORDER BY pageviews DESC,source,medium,campaign LIMIT 30
), devices AS (
    SELECT coalesce(nullif(device_class,''),'UNKNOWN') AS device,count(*) AS pageviews
    FROM period_pages GROUP BY 1 ORDER BY pageviews DESC,device
), regions AS (
    SELECT coalesce(nullif(visitor_uf,''),'Não identificada') AS uf,count(*) AS pageviews
    FROM period_pages GROUP BY 1 ORDER BY pageviews DESC,uf
), sequenced AS (
    SELECT e.content_id,e.session_id,
           lag(e.content_id) OVER (PARTITION BY e.session_id ORDER BY e.occurred_at,e.page_view_id) AS previous_id
    FROM event_pages e CROSS JOIN bounds b WHERE e.occurred_at >= b.since_at
), flow_counts AS (
    SELECT coalesce(a.nome_evento,'Evento ' || s.previous_id) AS from_event,
           coalesce(z.nome_evento,'Evento ' || s.content_id) AS to_event,
           count(*) AS transitions,count(DISTINCT s.session_id) AS sessions
    FROM sequenced s JOIN catalog a ON a.content_id=s.previous_id JOIN catalog z ON z.content_id=s.content_id
    WHERE s.previous_id <> s.content_id
      AND EXISTS (SELECT 1 FROM period_pages f WHERE f.session_id=s.session_id AND f.content_id=s.content_id)
    GROUP BY s.previous_id,s.content_id,a.nome_evento,z.nome_evento
    ORDER BY transitions DESC,s.previous_id,s.content_id
), flows AS (
    SELECT * FROM flow_counts LIMIT 20
)
SELECT json_build_object(
    'meta', (SELECT json_build_object('since',to_char(since_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),
       'until',to_char(until_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),
       'trend_days',trend_days,
       'recent',to_char(recent_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') || ' a ' || to_char(until_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),
       'previous',to_char(previous_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') || ' a ' || to_char(previous_until AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),
       'comparison_ready',v.comparison_ready,
       'first_observed',coalesce(to_char(v.first_observed AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),'Sem registros'),
       'last_received',coalesce((SELECT to_char(max(received_at) AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI') FROM period_pages),'Sem registros')) FROM bounds CROSS JOIN coverage v),
    'summary',(SELECT json_build_object('pageviews',count(*),'visitors',count(DISTINCT visitor_id),'sessions',count(DISTINCT session_id),
       'events',count(DISTINCT content_id),'gaps',(SELECT count(*) FROM event_rows WHERE pageviews>0 AND cardinality(missing_fields)>0),
       'hot',(SELECT count(*) FROM event_rows WHERE upcoming AND active AND recent_visitors>=3),
       'flow_transitions',(SELECT coalesce(sum(transitions),0) FROM flow_counts)) FROM period_pages),
    'ranking',coalesce((SELECT json_agg(r) FROM ranking r),'[]'::json),
    'hot',coalesce((SELECT json_agg(r) FROM hot r),'[]'::json),
    'gaps',coalesce((SELECT json_agg(r) FROM gaps r),'[]'::json),
    'daily',coalesce((SELECT json_agg(r) FROM daily r),'[]'::json),
    'sources',coalesce((SELECT json_agg(r) FROM sources r),'[]'::json),
    'devices',coalesce((SELECT json_agg(r) FROM devices r),'[]'::json),
    'regions',coalesce((SELECT json_agg(r) FROM regions r),'[]'::json),
    'flows',coalesce((SELECT json_agg(r) FROM flows r),'[]'::json)
)::text AS report
