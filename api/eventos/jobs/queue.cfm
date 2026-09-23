<cfscript>
// One read-only definition serves both the runner and the administration counters.
function eventDescriptionQueueSql() {
    return "WITH work AS (
        SELECT evt.id_evento, evt.descricao_original AS source_text, 'pt-BR' AS language,
            0 AS language_rank, CASE WHEN COALESCE(evt.data_final,evt.data_inicial) >= CURRENT_DATE THEN 0 ELSE 1 END AS date_rank,
            '' AS target_text, true AS target_is_null, 0 AS attempt_count,
            CAST(0 AS bigint) AS cached_id, '' AS cached_html, '' AS cached_model,
            CASE WHEN pt_history.id IS NULL THEN 'ready'
                WHEN pt_history.status='rejected' THEN 'rejected'
                WHEN pt_history.status='error' AND pt_history.error_code='provider_error' THEN 'ready'
                WHEN pt_history.status='error' THEN 'errors_exhausted'
                WHEN pt_history.status='running' THEN 'running'
                ELSE 'already_processed' END AS queue_status
        FROM public.tb_evento_corridas evt
        LEFT JOIN public.tb_evento_descricao_rewrites pt_history
            ON pt_history.id_evento=evt.id_evento AND pt_history.source_hash=md5(evt.descricao_original)
        WHERE length(COALESCE(evt.descricao_original,'')) > 200 AND btrim(COALESCE(evt.descricao,'')) = ''
          AND (:event_id=0 OR evt.id_evento=:event_id) AND :language IN ('auto','pt-BR')
        UNION ALL
        SELECT evt.id_evento, evt.descricao AS source_text, lang.language, lang.language_rank,
            CASE WHEN COALESCE(evt.data_final,evt.data_inicial) >= CURRENT_DATE THEN 0 ELSE 1 END AS date_rank,
            COALESCE(lang.target_text,'') AS target_text, lang.target_text IS NULL AS target_is_null,
            CASE WHEN history.status='error' AND history.error_code='provider_error'
                THEN 0 ELSE COALESCE(history.attempt_count,0) END AS attempt_count,
            COALESCE(cached.id,0) AS cached_id, COALESCE(cached.description_after,'') AS cached_html, COALESCE(cached.model,'') AS cached_model,
            CASE WHEN EXISTS (
                SELECT 1 FROM public.tb_evento_descricao_translations rejected
                WHERE rejected.id_evento=evt.id_evento AND rejected.language=lang.language
                  AND rejected.source_hash=md5(evt.descricao) AND rejected.source_text=evt.descricao AND rejected.status='rejected'
                ) THEN 'rejected'
                WHEN cached.id IS NOT NULL THEN 'ready'
                WHEN history.status='running' THEN 'running'
                WHEN history.status='error' AND history.error_code='provider_error' THEN 'ready'
                WHEN history.status='error' AND history.attempt_count >= 3 THEN 'errors_exhausted'
                WHEN history.status='error' AND (history.next_retry_at IS NULL OR history.next_retry_at > now()) THEN 'waiting_retry'
                ELSE 'ready' END AS queue_status
        FROM public.tb_evento_corridas evt
        CROSS JOIN LATERAL (VALUES ('en',evt.descricao_en,1), ('es',evt.descricao_es,2)) lang(language,target_text,language_rank)
        LEFT JOIN LATERAL (
            SELECT audit.source_text, audit.description_after
            FROM public.tb_evento_descricao_translations audit
            WHERE audit.id_evento=evt.id_evento AND audit.language=lang.language AND audit.status='updated'
            ORDER BY audit.id DESC LIMIT 1
        ) owner ON true
        LEFT JOIN LATERAL (
            SELECT audit.status, audit.error_code, audit.attempt_count, audit.next_retry_at
            FROM public.tb_evento_descricao_translations audit
            WHERE audit.id_evento=evt.id_evento AND audit.language=lang.language
              AND audit.source_hash=md5(evt.descricao) AND audit.source_text=evt.descricao
            ORDER BY audit.id DESC LIMIT 1
        ) history ON true
        LEFT JOIN LATERAL (
            SELECT audit.id, audit.description_after, audit.model
            FROM public.tb_evento_descricao_translations audit
            WHERE audit.id_evento=evt.id_evento AND audit.language=lang.language
              AND audit.source_hash=md5(evt.descricao) AND audit.source_text=evt.descricao
              AND audit.status IN ('updated','source_changed') AND btrim(COALESCE(audit.description_after,'')) <> ''
            ORDER BY audit.id DESC LIMIT 1
        ) cached ON true
        WHERE btrim(COALESCE(evt.descricao,'')) <> ''
          AND (:event_id=0 OR evt.id_evento=:event_id) AND :language IN ('auto',lang.language)
          AND (btrim(COALESCE(lang.target_text,'')) = ''
            OR (lang.target_text=owner.description_after AND owner.source_text IS DISTINCT FROM evt.descricao))
    ) ";
}
</cfscript>
