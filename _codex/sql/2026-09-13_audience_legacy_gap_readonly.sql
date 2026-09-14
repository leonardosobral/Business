-- Diagnostico somente leitura: decompor o contador antigo de eventos por site/dia.
-- Nao apaga logs, nao reativa gravacao, nao altera permissoes ou configuracao.
-- Executar conectado ao runnerhub, com um usuario que ja possa ler tb_log.
-- Devolver os dois resultados; nao sao exportados IPs, nomes ou User-Agents.
--
-- O periodo replica o predicado do card antigo no momento desta execucao.
-- Portanto, nao reproduz necessariamente os 191.126 de uma captura anterior.
-- A equivalencia tambem exige o mesmo tb_log resolvido e o mesmo TimeZone da
-- sessao ColdFusion: outro fuso pode deslocar o limite implicito do predicado.
-- log_timestamp nao carrega fuso: dia_gravado e o dia tal como foi armazenado.
-- O fuso da sessao abaixo NAO comprova o fuso historico de gravacao. Confirmar
-- essa convencao antes de cruzar horas exatas com audience.events (timestamptz).
--
-- A classificacao usa sinais de automacao no User-Agent. Nao autentica robos,
-- e ausencia de sinal NAO comprova visita humana. Nao ha limite de amostra.

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
SET LOCAL statement_timeout = '30s';
SET LOCAL lock_timeout = '2s';

SELECT current_database() AS banco,
       current_schema() AS schema_da_sessao,
       to_regclass('tb_log') AS tabela_resolvida,
       to_regclass('public.tb_log') AS tabela_public,
       current_setting('TimeZone') AS fuso_da_sessao,
       now() AS consulta_em,
       now() - interval '7 days' AS limite_inferior_do_card;

WITH base AS (
    SELECT coalesce(nullif(btrim(site), ''), '(sem site)') AS site_normalizado,
           log_timestamp::date AS dia_gravado,
           coalesce(log_user_agent, '') AS ua
    FROM tb_log
    WHERE log_item = 'evento'
      AND log_timestamp >= now() - interval '7 days'
), classified AS (
    SELECT site_normalizado, dia_gravado,
           CASE
               WHEN btrim(ua) IN ('', '-') THEN 'sem_user_agent'
               WHEN ua ~* '(bot|crawler|spider|slurp|bingpreview|facebookexternalhit|twitterbot|linkedinbot|duckduckbot|baiduspider|yandex|headless|phantomjs|lighthouse|pagespeed|curl/|wget/|python-requests|meta-externalagent|meta-externalfetcher|whatsapp|bytespider|semrush|ahrefs|scrapy|go-http-client|httpclient|axios|node-fetch)'
                   THEN 'automacao_declarada'
               ELSE 'sem_sinal_de_automacao'
           END AS classe
    FROM base
)
SELECT CASE
           WHEN grouping(site_normalizado) = 1 THEN 'total'
           WHEN grouping(dia_gravado) = 1 THEN 'site'
           ELSE 'site_dia'
       END AS recorte,
       site_normalizado AS site,
       dia_gravado,
       count(*) AS registros,
       count(*) FILTER (WHERE classe = 'automacao_declarada') AS com_sinal_automacao,
       round(100.0 * count(*) FILTER (WHERE classe = 'automacao_declarada')
             / nullif(count(*), 0), 1) AS percentual_sinal_automacao,
       count(*) FILTER (WHERE classe = 'sem_sinal_de_automacao') AS sem_sinal_nao_comprova_humano,
       count(*) FILTER (WHERE classe = 'sem_user_agent') AS sem_user_agent
FROM classified
GROUP BY GROUPING SETS ((), (site_normalizado), (site_normalizado, dia_gravado))
ORDER BY grouping(site_normalizado) DESC,
         site_normalizado NULLS FIRST,
         grouping(dia_gravado) DESC,
         dia_gravado;

ROLLBACK;
