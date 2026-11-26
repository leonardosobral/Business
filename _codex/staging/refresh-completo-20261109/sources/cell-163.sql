-- Idades: mesmas faixas e populações; agregar intervalos antes do cruzamento.
WITH intervalos AS (
 SELECT r.idade_range,coalesce(r.sexo,'N/A') AS sexo,
 count(r.id_resultado) AS editor,
 count(r.id_resultado) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS datagrip
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais='BR' AND e.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
 GROUP BY r.idade_range,r.sexo
), popula AS (
 SELECT 'Editor / geral' AS versao,idade_range,sum(editor) AS n FROM intervalos GROUP BY idade_range
 UNION ALL SELECT 'DataGrip / geral',idade_range,sum(datagrip) FROM intervalos GROUP BY idade_range
 UNION ALL SELECT 'Editor / '||sexo,idade_range,editor FROM intervalos WHERE sexo IN ('F','M')
 UNION ALL SELECT 'DataGrip / '||sexo,idade_range,datagrip FROM intervalos WHERE sexo IN ('F','M')
), versoes AS (
 SELECT 'Editor / geral' AS versao UNION ALL SELECT 'DataGrip / geral'
 UNION ALL SELECT 'Editor / F' UNION ALL SELECT 'Editor / M'
 UNION ALL SELECT 'DataGrip / F' UNION ALL SELECT 'DataGrip / M'
), faixas AS (
SELECT 1 AS ordem, '13–19' AS faixa, int4range(13,20,'[)') AS r
UNION ALL
SELECT 2 AS ordem, '20–24' AS faixa, int4range(20,25,'[)') AS r
UNION ALL
SELECT 3 AS ordem, '25–29' AS faixa, int4range(25,30,'[)') AS r
UNION ALL
SELECT 4 AS ordem, '30–34' AS faixa, int4range(30,35,'[)') AS r
UNION ALL
SELECT 5 AS ordem, '35–39' AS faixa, int4range(35,40,'[)') AS r
UNION ALL
SELECT 6 AS ordem, '40–44' AS faixa, int4range(40,45,'[)') AS r
UNION ALL
SELECT 7 AS ordem, '45–49' AS faixa, int4range(45,50,'[)') AS r
UNION ALL
SELECT 8 AS ordem, '50–54' AS faixa, int4range(50,55,'[)') AS r
UNION ALL
SELECT 9 AS ordem, '55–59' AS faixa, int4range(55,60,'[)') AS r
UNION ALL
SELECT 10 AS ordem, '60–64' AS faixa, int4range(60,65,'[)') AS r
UNION ALL
SELECT 11 AS ordem, '65–69' AS faixa, int4range(65,70,'[)') AS r
UNION ALL
SELECT 12 AS ordem, '70+' AS faixa, int4range(70,NULL,'[)') AS r
), agregados AS (
 SELECT v.versao,f.ordem,f.faixa,coalesce(sum(p.n),0) AS total
 FROM versoes v CROSS JOIN faixas f
 LEFT JOIN popula p ON p.versao=v.versao AND p.idade_range && f.r
 GROUP BY v.versao,f.ordem,f.faixa
)
SELECT versao,faixa,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY versao),0),2) AS porcentagem
FROM agregados ORDER BY versao,ordem;