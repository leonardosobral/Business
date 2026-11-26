-- Gênero — comparar editor, DataGrip e BI
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR GENERO

SELECT
  COALESCE(res.sexo, 'N/A') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM tb_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
  AND evt.pais = 'BR'
GROUP BY COALESCE(res.sexo, 'N/A')
ORDER BY total DESC
),
q1 AS (
-- TOTAL DE CONCLUINTES POR GENERO 2025
SELECT
  COALESCE(res.sexo, 'N/A') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
  AND evt.pais = 'BR'
  and res.tempo_total is not null and res.tempo_total > '00:00:00'
  --and pcd = false and (evt.ranking is null OR evt.ranking = '1')
GROUP BY COALESCE(res.sexo, 'N/A')
ORDER BY total DESC
),
q2 AS (
-- TOTAL DE CONCLUINTES POR GENERO (TABELA FLAT)
SELECT
  COALESCE(res.sexo, 'N/A') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vwbi_fat_perfil_br_2025 res
GROUP BY COALESCE(res.sexo, 'N/A')
ORDER BY total DESC
),
q3 AS (
-- TOTAL DE CONCLUINTES POR GENERO 2024

SELECT
  COALESCE(res.sexo, 'N/A') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM tb_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
  AND evt.pais = 'BR'
GROUP BY COALESCE(res.sexo, 'N/A')
ORDER BY total DESC
),
q4 AS (
-- TOTAL DE CONCLUINTES POR GENERO 2024
SELECT
  COALESCE(res.sexo, 'N/A') AS genero,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    2
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
  AND evt.pais = 'BR'
GROUP BY COALESCE(res.sexo, 'N/A')
ORDER BY total DESC
)
SELECT 'Editor 2025' AS versao, genero,total,porcentagem FROM q0
UNION ALL
SELECT 'DataGrip 2025 (tempo positivo)' AS versao, genero,total,porcentagem FROM q1
UNION ALL
SELECT 'BI 2025 (fonte DBA)' AS versao, genero,total,porcentagem FROM q2
UNION ALL
SELECT 'Editor 2024' AS versao, genero,total,porcentagem FROM q3
UNION ALL
SELECT 'DataGrip 2024' AS versao, genero,total,porcentagem FROM q4;