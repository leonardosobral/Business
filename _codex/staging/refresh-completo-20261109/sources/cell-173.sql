-- Distâncias detalhadas — DataGrip/DBA
-- TOTAL DE CONCLUINTES POR DISTANCIA (TODAS)
SELECT
  FLOOR(res.percurso) AS percurso,
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
AND tipo_corrida = 'rua'
GROUP BY FLOOR(res.percurso)
ORDER BY total DESC;