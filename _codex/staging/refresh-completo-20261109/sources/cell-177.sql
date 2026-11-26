-- Faixas de distância — população geral
-- TOTAL DE CONCLUINTES POR RANGES (< 6, 6-11, 11-30, 30+)
WITH base AS (
  SELECT
    CASE
      WHEN res.percurso < 6 THEN '< 6'
      WHEN res.percurso BETWEEN 6 AND 10.99 THEN '6-11'
      WHEN res.percurso BETWEEN 11 AND 29.99 THEN '11-30'
      WHEN res.percurso >= 30 THEN '30+'
      ELSE 'Outras'
    END AS percurso_bucket,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    --AND res.sexo = 'M'
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
    WHEN percurso_bucket = '< 6'  THEN 0
    WHEN percurso_bucket = '6-11'  THEN 1
    WHEN percurso_bucket = '11-30' THEN 2
    WHEN percurso_bucket = '30+' THEN 3
    ELSE 99
  END;