-- Executar inteiro em uma nova console conectada ao runnerhub.
-- Somente leitura: nao chama ingestao/expurgo, nao altera permissoes ou dados.
-- O video e a janela correspondem ao teste interno de 12/09, nao a audiencia comercial.
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '10s';
SET LOCAL lock_timeout = '2s';

WITH por_pagina AS (
    SELECT page_view_id,
        bool_or(event_kind = 'video_start' AND event_key = 'video_start:video:jKaRQ7uJEFo') AS inicio,
        bool_or(event_kind = 'video_progress' AND event_key = 'video_progress:video:jKaRQ7uJEFo:25') AS marco_25,
        bool_or(event_kind = 'video_progress' AND event_key = 'video_progress:video:jKaRQ7uJEFo:50') AS marco_50,
        bool_or(event_kind = 'video_progress' AND event_key = 'video_progress:video:jKaRQ7uJEFo:75') AS marco_75,
        bool_or(event_kind = 'video_complete' AND event_key = 'video_complete:video:jKaRQ7uJEFo') AS fim
    FROM audience.events
    WHERE site_host IN ('roadrunners.run', 'www.roadrunners.run')
      AND environment = 'prod' AND is_internal = true
      AND page_family = 'videos' AND content_type = 'video' AND content_id = 'jKaRQ7uJEFo'
      AND occurred_at >= timestamptz '2026-09-12 19:40:00+00'
      AND occurred_at < timestamptz '2026-09-12 19:50:00+00'
      AND event_kind IN ('video_start', 'video_progress', 'video_complete')
    GROUP BY page_view_id
)
SELECT 'video_teste' AS verificacao,
    jsonb_build_object(
        'video', 'jKaRQ7uJEFo',
        'janela_brasilia', '12/09/2026 16:40 ate 16:50 (fim exclusivo)',
        'paginas_com_registros', count(*),
        'paginas_com_inicio', count(*) FILTER (WHERE inicio),
        'paginas_com_marco_25', count(*) FILTER (WHERE marco_25),
        'paginas_com_marco_50', count(*) FILTER (WHERE marco_50),
        'paginas_com_marco_75', count(*) FILTER (WHERE marco_75),
        'paginas_com_fim', count(*) FILTER (WHERE fim),
        'paginas_com_todos_os_sinais', count(*) FILTER (WHERE inicio AND marco_25 AND marco_50 AND marco_75 AND fim)
    ) AS resultado
FROM por_pagina
UNION ALL
SELECT 'retencao', jsonb_build_object(
    'registro_presente', count(*) = 1,
    'dias', max(retention_days),
    'status', max(last_status),
    'ultima_tentativa', max(last_run_at),
    'ultimo_sucesso', max(last_success_at),
    'codigo_erro', max(last_error_code),
    'removidos_na_ultima_execucao', max(last_deleted_count),
    'ainda_ha_expirados', bool_or(has_more)
)
FROM audience.maintenance_state
WHERE task_name = 'events_retention';

ROLLBACK;
