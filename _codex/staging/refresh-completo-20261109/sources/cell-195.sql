-- Regiões — 2024/2025, geral/F/M
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, 'N/A') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
  AND evt.pais = 'BR'
  
GROUP BY COALESCE(uf.regiao, 'N/A')
ORDER BY total DESC
),
q1 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, 'N/A') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
  AND evt.pais = 'BR'
  AND res.sexo = 'F'
GROUP BY COALESCE(uf.regiao, 'N/A')
ORDER BY total DESC
),
q2 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, 'N/A') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
  AND evt.pais = 'BR'
  AND res.sexo = 'M'
GROUP BY COALESCE(uf.regiao, 'N/A')
ORDER BY total DESC
),
q3 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, 'N/A') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
  AND evt.pais = 'BR'
  
GROUP BY COALESCE(uf.regiao, 'N/A')
ORDER BY total DESC
),
q4 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, 'N/A') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
  AND evt.pais = 'BR'
  AND res.sexo = 'F'
GROUP BY COALESCE(uf.regiao, 'N/A')
ORDER BY total DESC
),
q5 AS (
-- TOTAL DE CONCLUINTES POR REGIAO
SELECT
  COALESCE(uf.regiao, 'N/A') AS regiao,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
LEFT JOIN tb_uf uf
  ON uf.uf = evt.estado
WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
  AND evt.pais = 'BR'
  AND res.sexo = 'M'
GROUP BY COALESCE(uf.regiao, 'N/A')
ORDER BY total DESC
)
SELECT '2024 / geral' AS versao, regiao,total,porcentagem FROM q0
UNION ALL
SELECT '2024 / F' AS versao, regiao,total,porcentagem FROM q1
UNION ALL
SELECT '2024 / M' AS versao, regiao,total,porcentagem FROM q2
UNION ALL
SELECT '2025 / geral' AS versao, regiao,total,porcentagem FROM q3
UNION ALL
SELECT '2025 / F' AS versao, regiao,total,porcentagem FROM q4
UNION ALL
SELECT '2025 / M' AS versao, regiao,total,porcentagem FROM q5;