-- Estados — editor versus DataGrip
WITH q0 AS (
-- TOTAL DE CONCLUINTES POR ESTADO

SELECT
  COALESCE(evt.estado, 'N/A') AS estado,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM tb_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
  AND evt.pais = 'BR'
GROUP BY COALESCE(evt.estado, 'N/A')
ORDER BY total DESC
),
q1 AS (
-- TOTAL DE CONCLUINTES POR ESTADO
SELECT
  COALESCE(evt.estado, 'N/A') AS estado,
  COUNT(res.id_resultado) AS total,
  ROUND(
    COUNT(res.id_resultado) * 100.0
    / NULLIF(SUM(COUNT(res.id_resultado)) OVER (), 0),
    1
  ) AS porcentagem
FROM vw_resultados res
JOIN tb_evento_corridas evt
  ON evt.id_evento = res.id_evento
WHERE evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
  AND evt.pais = 'BR'
GROUP BY COALESCE(evt.estado, 'N/A')
ORDER BY total DESC
)
SELECT 'Editor' AS versao, estado,total,porcentagem FROM q0
UNION ALL
SELECT 'DataGrip' AS versao, estado,total,porcentagem FROM q1;