-- Gerações × distâncias — os dois denominadores
WITH q0 AS (
-- TOTAL DE PROVAS POR RANGES x GENEROS STACKED 100% (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN '< 6'
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN '6-11'
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN '11-30'
      WHEN res.percurso >= 30 THEN '30+'
      ELSE 'Outras'
    END AS percurso_bucket,
    res.id_resultado,
    (CASE

        WHEN res.idade_range IS NULL OR 2025 IS NULL THEN 0
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(1946, 1965, '[)') THEN 1
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(1965, 1981, '[)') THEN 2
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(1981, 1996, '[)') THEN 3
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(1996, 2011, '[)') THEN 4
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(2010, NULL, '[)') THEN 0
        ELSE 0
    END) as id_geracao
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    and tipo_corrida = 'rua'
    and res.idade_range is not null
),
agg AS (
  SELECT
    id_geracao,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao,percurso_bucket
),
agg_percurso AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total_percurso
  FROM base
  where id_geracao > 0
  GROUP BY percurso_bucket
)
SELECT
  nome_geracao AS geracao,
  agg.percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / (select sum(total_percurso) from agg_percurso where percurso_bucket = agg.percurso_bucket), 1) AS perc
FROM agg
inner join tbbi_dim_geracoes dg on dg.id_geracao = agg.id_geracao
ORDER BY
  CASE
    WHEN agg.percurso_bucket = '< 6'  THEN 0
    WHEN agg.percurso_bucket = '6-11'  THEN 1
    WHEN agg.percurso_bucket = '11-30' THEN 2
    WHEN agg.percurso_bucket = '30+' THEN 3
    ELSE 99
  END
),
q1 AS (
-- DISTRIBUICAO DAS GERACOES NAS DISTANCIAS (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN '< 6'
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN '6-11'
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN '11-30'
      WHEN res.percurso >= 30 THEN '30+'
      ELSE 'Outras'
    END AS percurso_bucket,
    res.id_resultado,
    (CASE

        WHEN res.idade_range IS NULL OR 2025 IS NULL THEN 0
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(1946, 1965, '[)') THEN 1
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(1965, 1981, '[)') THEN 2
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(1981, 1996, '[)') THEN 3
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(1996, 2011, '[)') THEN 4
        WHEN int4range(
                 2025 - upper(res.idade_range),
                 2025 - lower(res.idade_range),
                 '[)'
             ) && int4range(2010, NULL, '[)') THEN 0
        ELSE 0
    END) as id_geracao
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    and tipo_corrida = 'rua'
    and res.idade_range is not null
),
agg AS (
  SELECT
    id_geracao,
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao,percurso_bucket
),
agg_percurso AS (
  SELECT
    id_geracao,
    COUNT(id_resultado) AS total_percurso
  FROM base
  where id_geracao > 0
  GROUP BY id_geracao
)
SELECT
  nome_geracao AS geracao,
  agg.percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / (select sum(total_percurso) from agg_percurso where id_geracao = agg.id_geracao), 1) AS perc
FROM agg
inner join tbbi_dim_geracoes dg on dg.id_geracao = agg.id_geracao
ORDER BY
  geracao,
  CASE
    WHEN agg.percurso_bucket = '< 6'  THEN 0
    WHEN agg.percurso_bucket = '6-11'  THEN 1
    WHEN agg.percurso_bucket = '11-30' THEN 2
    WHEN agg.percurso_bucket = '30+' THEN 3
    ELSE 99
  END
)
SELECT 'Geração dentro da distância' AS versao, geracao,percurso,total,perc FROM q0
UNION ALL
SELECT 'Distância dentro da geração' AS versao, geracao,percurso,total,perc FROM q1;