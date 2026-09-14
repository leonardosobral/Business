WITH scoped_imports AS MATERIALIZED (
    SELECT imp.*,
           nullif(regexp_replace(trim(imp.url_resultado), '[/#]+$', ''), '') AS data_url_key,
           nullif(regexp_replace(trim(imp.url_resultado_publica), '[/#]+$', ''), '') AS public_url_key
    FROM public.tb_resultados_importacoes imp
    WHERE :unscoped OR EXISTS (
        SELECT 1 FROM public.tb_conta_integracoes_resultados integration
        WHERE integration.id_conta = :account_id AND integration.ativo = true
          AND lower(trim(integration.client_id)) = lower(trim(imp.client_id))
          AND lower(trim(integration.cod_timer)) = lower(trim(imp.cod_timer))
          AND (integration.abrange_contas_externas = true OR
               nullif(trim(integration.external_account_id), '') IS NOT DISTINCT FROM nullif(trim(imp.external_account_id), ''))
    )
), identified_imports AS MATERIALIZED (
    SELECT s.*, md5(jsonb_build_array(lower(trim(client_id)), lower(trim(cod_timer)),
        nullif(trim(external_account_id), ''),
        -- Prefer immutable source URLs: the importer fills external_event_id later.
        CASE WHEN data_url_key ~ '^https://[^/]+/.*/data/[^/]+/event\.json$'
                   OR data_url_key ~ '^https://[^/]+/data/[^/]+/event\.json$' THEN 'data:' || data_url_key
             WHEN public_url_key ~ '^https://[^/]+/.*[^/#]$' THEN 'public:' || public_url_key
             WHEN nullif(trim(external_event_id), '') IS NOT NULL THEN 'external:' || trim(external_event_id)
             ELSE 'submission:' || public_id::text END)::text) AS event_group
    FROM scoped_imports s
), completed_imports AS (
    SELECT DISTINCT ON (event_group) event_group, id_resultado_importacao AS superseding_id,
           public_id::text AS superseding_submission_id, data_recebimento AS superseding_received,
           data_processamento AS last_processed_at
    FROM identified_imports WHERE status_processamento = 'processado'
    ORDER BY event_group, data_recebimento DESC, id_resultado_importacao DESC
), historical_links AS (
    SELECT event_group, count(DISTINCT i.id_evento) AS matches, min(i.id_evento) AS id_evento
    FROM identified_imports i JOIN public.tb_evento_corridas e ON e.id_evento=i.id_evento AND e.ativo=true
    WHERE i.status_processamento='processado' GROUP BY event_group
), source_urls AS (
    SELECT DISTINCT event_group, data_url_key AS url_key FROM identified_imports WHERE data_url_key IS NOT NULL
    UNION SELECT DISTINCT event_group, public_url_key FROM identified_imports WHERE public_url_key IS NOT NULL
), catalog_urls AS (
    SELECT id_evento, nullif(regexp_replace(trim(url_resultado), '[/#]+$', ''), '') AS url_key
    FROM public.tb_evento_corridas WHERE ativo=true AND nullif(trim(url_resultado), '') IS NOT NULL
    UNION ALL
    SELECT id_evento, nullif(regexp_replace(trim(url_wiclax), '[/#]+$', ''), '')
    FROM public.tb_evento_corridas WHERE ativo=true AND nullif(trim(url_wiclax), '') IS NOT NULL
), url_links AS (
    SELECT s.event_group, count(DISTINCT c.id_evento) AS matches, min(c.id_evento) AS id_evento
    FROM source_urls s JOIN catalog_urls c ON c.url_key=s.url_key GROUP BY s.event_group
), group_counts AS (
    SELECT event_group, count(*) AS group_total FROM identified_imports GROUP BY event_group
), resolved_imports AS (
    SELECT i.*, i.public_id::text AS submission_id, c.superseding_id, c.superseding_submission_id,
           c.last_processed_at, g.group_total,
           coalesce((i.data_recebimento,i.id_resultado_importacao) < (c.superseding_received,c.superseding_id),false) AS is_superseded,
           CASE WHEN i.status_processamento='cancelado' AND i.erro_codigo='superseded' THEN 'arquivado'
                WHEN i.status_processamento IN ('pendente','falhou')
                     AND (i.data_recebimento,i.id_resultado_importacao) < (c.superseding_received,c.superseding_id)
                     THEN 'arquivado' ELSE i.status_processamento END AS queue_status,
           CASE WHEN i.id_evento IS NOT NULL THEN i.id_evento
                WHEN h.matches=1 THEN h.id_evento
                WHEN coalesce(h.matches,0)=0 AND u.matches=1 THEN u.id_evento END AS suggested_event_id,
           CASE WHEN i.id_evento IS NOT NULL THEN 'submission'
                WHEN h.matches=1 THEN 'history'
                WHEN coalesce(h.matches,0)=0 AND u.matches=1 THEN 'url'
                WHEN h.matches>1 OR u.matches>1 THEN 'ambiguous' ELSE '' END AS link_source
    FROM identified_imports i
    LEFT JOIN completed_imports c USING(event_group)
    LEFT JOIN historical_links h USING(event_group)
    LEFT JOIN url_links u USING(event_group)
    JOIN group_counts g USING(event_group)
), result_import_context AS (
    SELECT r.*, e.nome_evento, e.tag AS event_tag, e.cidade AS event_city,
           e.estado AS event_state, e.data_inicial AS event_date
    FROM resolved_imports r LEFT JOIN public.tb_evento_corridas e ON e.id_evento=r.suggested_event_id
)
