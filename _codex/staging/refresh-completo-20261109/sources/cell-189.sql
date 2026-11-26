-- Performance — comparar editor com DBA
WITH q0 AS (
--5k 
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= '00:20:00'::time THEN '5k Sub 20'
      WHEN res.tempo_total > '00:20:00'::time AND  res.tempo_total <= '00:25:00'::time THEN '5k 20-25'
      WHEN res.tempo_total > '00:25:00'::time AND  res.tempo_total <= '00:30:00'::time THEN '5k 25-30'
      ELSE '5k 30+'
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    AND res.percurso = 5
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
    WHEN percurso_bucket = '5k Sub 20'  THEN 1
    WHEN percurso_bucket = '5k 20-25'   THEN 2
    WHEN percurso_bucket = '5k 25-30'   THEN 3
    ELSE 99
  END
),
q1 AS (
-- 5k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= '00:20:00'::time THEN '5k Sub 20'
      WHEN res.tempo_total > '00:20:00'::time AND  res.tempo_total <= '00:25:00'::time THEN '5k 20-25'
      WHEN res.tempo_total > '00:25:00'::time AND  res.tempo_total <= '00:30:00'::time THEN '5k 25-30'
      ELSE '5k 30+'
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    AND res.percurso = 5
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
    WHEN percurso_bucket = '5k Sub 20'  THEN 1
    WHEN percurso_bucket = '5k 20-25'   THEN 2
    WHEN percurso_bucket = '5k 25-30'   THEN 3
    ELSE 99
  END
),
q2 AS (
-- 10k
  WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= '00:40:00'::time THEN '10k Sub 40'
      WHEN res.tempo_total > '00:40:00'::time AND  res.tempo_total <= '00:50:00'::time THEN '10k 40-50'
      WHEN res.tempo_total > '00:50:00'::time AND  res.tempo_total <= '01:00:00'::time THEN '10k 50-60'
      ELSE '10k 60+'
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    AND res.percurso = 10
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
    WHEN percurso_bucket = '10k Sub 40'  THEN 5
    WHEN percurso_bucket = '10k 40-50'   THEN 6
    WHEN percurso_bucket = '10k 50-60'   THEN 7
    ELSE 8
  END
),
q3 AS (
-- 10k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= '00:40:00'::time THEN '10k Sub 40'
      WHEN res.tempo_total > '00:40:00'::time AND  res.tempo_total <= '00:50:00'::time THEN '10k 40-50'
      WHEN res.tempo_total > '00:50:00'::time AND  res.tempo_total <= '01:00:00'::time THEN '10k 50-60'
      ELSE '10k 60+'
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    AND res.percurso = 10
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
    WHEN percurso_bucket = '10k Sub 40'  THEN 5
    WHEN percurso_bucket = '10k 40-50'   THEN 6
    WHEN percurso_bucket = '10k 50-60'   THEN 7
    ELSE 8
  END
),
q4 AS (
-- 21k
  WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= '01:30:00'::time THEN '21k Sub 01:30'
      WHEN res.tempo_total > '01:30:00'::time AND  res.tempo_total <= '02:00:00'::time THEN '21k 1h30 - 2h'
      WHEN res.tempo_total > '02:00:00'::time AND  res.tempo_total <= '02:30:00'::time THEN '21k 2h - 2h30'
      ELSE '21k 2h30+'
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    AND res.percurso >= 21
    AND res.percurso <  22
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
    WHEN percurso_bucket = '21k Sub 01:30'  THEN 1
    WHEN percurso_bucket = '21k 1h30 - 2h'   THEN 2
    WHEN percurso_bucket = '21k 2h - 2h30'   THEN 3
    ELSE 4
  END
),
q5 AS (
-- 21k
WITH base AS (
SELECT
CASE
  WHEN res.tempo_total <= '01:30:00'::time THEN '21k Sub 01:30'
  WHEN res.tempo_total > '01:30:00'::time AND  res.tempo_total <= '02:00:00'::time THEN '21k 1h30 - 2h'
  WHEN res.tempo_total > '02:00:00'::time AND  res.tempo_total <= '02:30:00'::time THEN '21k 2h - 2h30'
  ELSE '21k 2h30+'
END AS percurso_bucket,
res.tempo_total,
res.id_resultado
FROM vw_resultados res
JOIN tb_evento_corridas evt
ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
AND evt.pais = 'BR'
AND res.percurso >= 21
AND res.percurso <  22
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
    WHEN percurso_bucket = '21k Sub 01:30'  THEN 1
    WHEN percurso_bucket = '21k 1h30 - 2h'   THEN 2
    WHEN percurso_bucket = '21k 2h - 2h30'   THEN 3
    ELSE 4
  END
),
q6 AS (
--42k 
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= '03:00:00'::time THEN '42k Sub 3h'
      WHEN res.tempo_total > '03:00:00'::time AND  res.tempo_total <= '03:30:00'::time THEN '42k 3h - 3h30'
      WHEN res.tempo_total > '03:30:00'::time AND  res.tempo_total <= '04:00:00'::time THEN '42k 3h30 - 4h'
      WHEN res.tempo_total > '04:00:00'::time AND  res.tempo_total <= '04:30:00'::time THEN '42k 4h - 4h30'
      ELSE '42k 4h30+'
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM tb_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    AND res.percurso >= 42
    AND res.percurso <  43
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
    WHEN percurso_bucket = '42k Sub 3h'  THEN 1
    WHEN percurso_bucket = '42k 3h - 3h30'   THEN 2
    WHEN percurso_bucket = '42k 3h30 - 4h'   THEN 3
    WHEN percurso_bucket = '42k 4h - 4h30'   THEN 4
    ELSE 5
  END
),
q7 AS (
-- 42k
WITH base AS (
  SELECT
    CASE
      WHEN res.tempo_total <= '03:00:00'::time THEN '42k Sub 3h'
      WHEN res.tempo_total > '03:00:00'::time AND  res.tempo_total <= '03:30:00'::time THEN '42k 3h - 3h30'
      WHEN res.tempo_total > '03:30:00'::time AND  res.tempo_total <= '04:00:00'::time THEN '42k 3h30 - 4h'
      WHEN res.tempo_total > '04:00:00'::time AND  res.tempo_total <= '04:30:00'::time THEN '42k 4h - 4h30'
      ELSE '42k 4h30+'
    END AS percurso_bucket,
    res.tempo_total,
    res.id_resultado
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    AND evt.pais = 'BR'
    AND res.percurso >= 42
    AND res.percurso <  43
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
    WHEN percurso_bucket = '42k Sub 3h'  THEN 1
    WHEN percurso_bucket = '42k 3h - 3h30'   THEN 2
    WHEN percurso_bucket = '42k 3h30 - 4h'   THEN 3
    WHEN percurso_bucket = '42k 4h - 4h30'   THEN 4
    ELSE 5
  END
)
SELECT 'editor / 5k' AS versao, percurso,total,perc FROM q0
UNION ALL
SELECT 'dba / 5k' AS versao, percurso,total,perc FROM q1
UNION ALL
SELECT 'editor / 10k' AS versao, percurso,total,perc FROM q2
UNION ALL
SELECT 'dba / 10k' AS versao, percurso,total,perc FROM q3
UNION ALL
SELECT 'editor / 21k' AS versao, percurso,total,perc FROM q4
UNION ALL
SELECT 'dba / 21k' AS versao, percurso,total,perc FROM q5
UNION ALL
SELECT 'editor / 42k' AS versao, percurso,total,perc FROM q6
UNION ALL
SELECT 'dba / 42k' AS versao, percurso,total,perc FROM q7;