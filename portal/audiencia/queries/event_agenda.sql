SELECT coalesce(json_agg(r),'[]'::json)::text AS report FROM (
    SELECT a.id_evento::text AS content_id,count(DISTINCT a.id_usuario) AS athletes,
           count(DISTINCT a.id_usuario) FILTER (WHERE a.tipo_checkin='calendario') AS saved,
           count(DISTINCT a.id_usuario) FILTER (WHERE a.tipo_checkin='inscricao') AS registered
    FROM public.tb_evento_corridas_checkin a
    WHERE a.id_fornecedor IS NULL AND a.tipo_checkin IN ('calendario','inscricao')
      AND a.id_evento IN (
          SELECT CASE WHEN v.id ~ '^[1-9][0-9]{0,9}$'
                      THEN CASE WHEN v.id::bigint <= 2147483647 THEN v.id::integer END END
          FROM jsonb_array_elements_text(CAST(:ids AS jsonb)) AS v(id)
      )
    GROUP BY a.id_evento
) r
