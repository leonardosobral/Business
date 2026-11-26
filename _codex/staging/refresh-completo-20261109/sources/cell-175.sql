-- Distâncias padrão — editor versus DataGrip
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR DISTANCIA (RUA)

WITH base AS (
  SELECT
    CASE
      WHEN res.percurso IN (21, 21.1) THEN '21'
      WHEN res.percurso IN (42, 42.2) THEN '42'
      WHEN res.percurso IN (5, 5.00) THEN '5'
      WHEN res.percurso IN (10, 10.00) THEN '10'
      WHEN res.percurso IN (15) THEN '15'
      WHEN res.percurso IN (30) THEN '30'
      ELSE 'Outras'
    END AS percurso_bucket,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    --AND res.sexo = 'F'
    and tipo_corrida = 'rua'
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 2) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = '5'  THEN 1
    WHEN percurso_bucket = '10' THEN 2
    WHEN percurso_bucket = '15' THEN 3
    WHEN percurso_bucket = '21' THEN 4
    WHEN percurso_bucket = '30' THEN 5
    WHEN percurso_bucket = '42' THEN 6
    ELSE 99
  END
),
q1 AS (
-- TOTAL DE CONCLUINTES POR DISTANCIA PADRAO (5,10,15,21,30.42)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso IN (21, 21.1) THEN '21'
      WHEN res.percurso IN (42, 42.2) THEN '42'
      WHEN res.percurso IN (5, 5.00) THEN '5'
      WHEN res.percurso IN (10, 10.00) THEN '10'
      WHEN res.percurso IN (15) THEN '15'
      WHEN res.percurso IN (30) THEN '30'
      ELSE 'Outras'
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    --AND res.sexo = 'F'
    and tipo_corrida = 'rua'
),
agg AS (
  SELECT
    percurso_bucket,
    COUNT(id_resultado) AS total
  FROM base
  GROUP BY percurso_bucket
)
SELECT
  percurso_bucket AS percurso,
  total,
  ROUND(total * 100.0 / NULLIF(SUM(total) OVER (), 0), 1) AS perc
FROM agg
ORDER BY
  CASE
    WHEN percurso_bucket = '5'  THEN 1
    WHEN percurso_bucket = '10' THEN 2
    WHEN percurso_bucket = '15' THEN 3
    WHEN percurso_bucket = '21' THEN 4
    WHEN percurso_bucket = '30' THEN 5
    WHEN percurso_bucket = '42' THEN 6
    ELSE 99
  END
)
SELECT 'Editor' AS versao, percurso,total,perc FROM q0
UNION ALL
SELECT 'DataGrip / DBA' AS versao, percurso,total,perc FROM q1;