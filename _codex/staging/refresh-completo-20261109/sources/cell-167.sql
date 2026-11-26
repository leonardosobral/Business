-- Gerações históricas: mesmos ranges e sexos, com pré-agregação.
WITH intervalos AS (
 SELECT extract(year FROM e.data_final)::integer AS ano,r.idade_range,count(*) AS n
 FROM public.vw_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais='BR' AND e.data_final>=DATE '2023-01-01' AND e.data_final<DATE '2026-01-01'
 AND (extract(year FROM e.data_final)=2023 OR extract(year FROM e.data_final)=2024 AND r.sexo='M'
 OR extract(year FROM e.data_final)=2025 AND r.sexo='F')
 GROUP BY extract(year FROM e.data_final),r.idade_range
), faixas AS (
SELECT 2025 AS ano, f.* FROM (
  SELECT 1 AS ordem, 'Alfa' AS faixa, int4range(0, 15, '[)') AS r UNION ALL
  SELECT 2, 'Z', int4range(16, 28, '[)') UNION ALL
  SELECT 3, 'Y', int4range(29, 44, '[)') UNION ALL
  SELECT 4, 'X', int4range(45, 60, '[)') UNION ALL
  SELECT 12, '60+',   int4range(60, NULL, '[)')
) f
UNION ALL
SELECT 2024 AS ano, f.* FROM (
  SELECT 1 AS ordem, 'Alfa' AS faixa, int4range(0, 15, '[)') AS r UNION ALL
  SELECT 2, 'Z', int4range(16, 28, '[)') UNION ALL
  SELECT 3, 'Y', int4range(29, 44, '[)') UNION ALL
  SELECT 4, 'X', int4range(45, 60, '[)') UNION ALL
  SELECT 12, 'Boomers',   int4range(60, NULL, '[)')
) f
UNION ALL
SELECT 2023 AS ano, f.* FROM (
  SELECT 1 AS ordem, 'Alfa' AS faixa, int4range(0, 14, '[)') AS r UNION ALL
  SELECT 2, 'Z', int4range(15, 28, '[)') UNION ALL
  SELECT 3, 'Y', int4range(29, 44, '[)') UNION ALL
  SELECT 4, 'X', int4range(45, 60, '[)') UNION ALL
  SELECT 12, 'Boomers',   int4range(60, NULL, '[)')
) f
), agregados AS (
 SELECT f.ano,f.ordem,f.faixa,coalesce(sum(i.n),0) AS total
 FROM faixas f LEFT JOIN intervalos i ON i.ano=f.ano AND i.idade_range && f.r
 GROUP BY f.ano,f.ordem,f.faixa
)
SELECT CASE ano WHEN 2025 THEN 'DataGrip 2025 / F' WHEN 2024 THEN 'DataGrip 2024 / M' ELSE 'DataGrip 2023 / geral' END AS versao,
 faixa,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY ano),0),1) AS porcentagem
FROM agregados ORDER BY ano,ordem;