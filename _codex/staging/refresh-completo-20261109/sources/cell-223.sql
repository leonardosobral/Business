-- Atividades por esporte — candidato DataGrip
-- ESPORTES MAIS PRATICADOS
SELECT
  act.type,
  COUNT(*) AS total,
  ROUND(
    COUNT(*) * 100.0
    / NULLIF(SUM(COUNT(*)) OVER (), 0),
    2
  ) AS porcentagem
FROM tb_strava_activities act
WHERE act.activity_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
  AND act.type IS NOT NULL
GROUP BY act.type
ORDER BY total DESC;