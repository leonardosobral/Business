-- Executar inteiro no runnerhub, em uma nova console, com acesso de leitura
-- ja existente a public.tb_log e audience.events. Retorna UMA linha JSON.
-- Somente leitura: nao altera dados, permissoes, configuracao ou coleta.
-- Janela fixa: 09/09 00h ate 13/09 00h de Brasilia (fim exclusivo).
-- UTC na sessao do DBA nao comprova o fuso historico da conexao do site.
-- Por isso o legado e calculado nas duas hipoteses, sem escolher uma como fato.
-- Sem sinal de automacao NAO significa humano. Origens NAO sao pessoas.
-- Deduplicar origem+evento+minuto e apenas uma medida de repeticao, nao uma
-- definicao de page_view nem um filtro seguro de bots. Chaves vazias ficam fora.
-- O legado nao guarda a rota: site=RR/log_item=evento pode incluir hotsites.

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
SET LOCAL statement_timeout = '30s';
SET LOCAL lock_timeout = '2s';

WITH params AS (
    SELECT timestamptz '2026-09-09 03:00:00+00' AS inicio,
           timestamptz '2026-09-13 03:00:00+00' AS fim
), fusos(fuso) AS (
    VALUES ('UTC'::text), ('America/Sao_Paulo'::text)
), legado_base AS MATERIALIZED (
    SELECT log_timestamp,
           nullif(nullif(btrim(log_user), ''), '-') AS origem,
           nullif(btrim(log_item_id), '') AS evento,
           coalesce(log_user_agent, '') AS ua
    FROM public.tb_log
    WHERE log_item = 'evento' AND site = 'RR'
      -- Envelope que contem as duas interpretacoes da janela fixa.
      AND log_timestamp >= timestamp '2026-09-09 00:00:00'
      AND log_timestamp < timestamp '2026-09-13 03:00:00'
), legado_normalizado AS MATERIALIZED (
    SELECT f.fuso,
           l.log_timestamp AT TIME ZONE f.fuso AS instante,
           l.origem, l.evento,
           CASE
               WHEN btrim(l.ua) IN ('', '-') THEN 'sem_user_agent'
               WHEN l.ua ~* '(bot|crawler|spider|slurp|bingpreview|facebookexternalhit|twitterbot|linkedinbot|duckduckbot|baiduspider|yandex|headless|phantomjs|lighthouse|pagespeed|curl/|wget/|python-requests|meta-externalagent|meta-externalfetcher|whatsapp|bytespider|semrush|ahrefs|scrapy|go-http-client|httpclient|axios|node-fetch)'
                   THEN 'sinal_automacao'
               ELSE 'sem_sinal_automacao'
           END AS classe,
           CASE
               WHEN l.ua ~* '(iphone|ipad|android|mobile|tablet)' THEN 'mobile_tablet_declarado'
               WHEN l.ua ~* '(mozilla/|chrome/|safari/|firefox/|edg/|opera/)' THEN 'navegador_desktop_declarado'
               ELSE 'outro_nao_classificado'
           END AS familia_ua
    FROM legado_base l CROSS JOIN fusos f CROSS JOIN params p
    WHERE l.log_timestamp AT TIME ZONE f.fuso >= p.inicio
      AND l.log_timestamp AT TIME ZONE f.fuso < p.fim
), legado AS MATERIALIZED (
    SELECT *, (instante AT TIME ZONE 'America/Sao_Paulo')::date AS dia_brasilia
    FROM legado_normalizado
), legado_resumo AS (
    SELECT fuso, dia_brasilia,
           CASE WHEN grouping(dia_brasilia) = 1 THEN 'periodo' ELSE 'dia' END AS recorte,
           count(*) AS registros,
           count(*) FILTER (WHERE classe = 'sinal_automacao') AS sinal_automacao,
           count(*) FILTER (WHERE classe = 'sem_user_agent') AS sem_user_agent,
           count(*) FILTER (WHERE classe = 'sem_sinal_automacao') AS sem_sinal_automacao,
           count(DISTINCT origem) FILTER (WHERE classe = 'sem_sinal_automacao') AS origens_distintas_sem_sinal,
           count(*) FILTER (WHERE classe = 'sem_sinal_automacao' AND origem IS NULL) AS sem_sinal_sem_origem,
           count(*) FILTER (WHERE classe = 'sem_sinal_automacao' AND (origem IS NULL OR evento IS NULL)) AS sem_sinal_sem_chave_dedup,
           count(DISTINCT (origem, evento, date_trunc('minute', instante AT TIME ZONE 'UTC')))
               FILTER (WHERE classe = 'sem_sinal_automacao' AND origem IS NOT NULL AND evento IS NOT NULL) AS combinacoes_origem_evento_minuto
    FROM legado
    GROUP BY GROUPING SETS ((fuso), (fuso, dia_brasilia))
), legado_ua AS (
    SELECT fuso, familia_ua, count(*) AS registros
    FROM legado WHERE classe = 'sem_sinal_automacao'
    GROUP BY fuso, familia_ua
), por_origem AS (
    SELECT fuso, origem, count(*) AS registros, count(DISTINCT evento) AS eventos_distintos
    FROM legado WHERE classe = 'sem_sinal_automacao' AND origem IS NOT NULL
    GROUP BY fuso, origem
), origens_ranqueadas AS (
    SELECT fuso, registros, eventos_distintos,
           row_number() OVER (PARTITION BY fuso ORDER BY registros DESC, eventos_distintos DESC, origem) AS posicao
    FROM por_origem
), audiencia_base AS MATERIALIZED (
    SELECT e.page_view_id, e.site_host, e.page_family, e.content_type, e.is_internal,
           (e.occurred_at AT TIME ZONE 'America/Sao_Paulo')::date AS dia_brasilia
    FROM audience.events e CROSS JOIN params p
    WHERE e.occurred_at >= p.inicio AND e.occurred_at < p.fim
      AND e.environment = 'prod' AND e.event_kind = 'page_view'
), audiencia_resumo AS (
    SELECT site_host, page_family, content_type, is_internal, dia_brasilia,
           CASE WHEN grouping(dia_brasilia) = 1 THEN 'periodo' ELSE 'dia' END AS recorte,
           count(DISTINCT page_view_id) AS aberturas
    FROM audiencia_base
    GROUP BY GROUPING SETS (
        (site_host, page_family, content_type, is_internal),
        (site_host, page_family, content_type, is_internal, dia_brasilia)
    )
)
SELECT jsonb_build_object(
    'contexto', jsonb_build_object(
        'banco', current_database(),
        'fuso_sessao_consulta', current_setting('TimeZone'),
        'consultado_em', now(),
        'inicio_utc', '2026-09-09T03:00:00Z',
        'fim_utc_exclusivo', '2026-09-13T03:00:00Z',
        'legado', 'RR; duas hipoteses de fuso; nao somar hipoteses nem totais com dias',
        'audiencia', 'page_view; producao; internos separados; todas as familias e hosts para detectar classificacao inesperada'
    ),
    'legado', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY fuso, dia_brasilia NULLS FIRST) FROM legado_resumo r), '[]'::jsonb),
    'ua_sem_sinal', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY fuso, registros DESC) FROM legado_ua r), '[]'::jsonb),
    -- Apenas volumes por posicao no ranking: nao expoe IP, origem ou User-Agent.
    'top20_origens_sem_identificadores', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY fuso, posicao) FROM origens_ranqueadas r WHERE posicao <= 20), '[]'::jsonb),
    'audiencia', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY site_host, page_family, content_type, is_internal, dia_brasilia NULLS FIRST) FROM audiencia_resumo r), '[]'::jsonb)
) AS diagnostico;

ROLLBACK;
