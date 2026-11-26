-- Capital/interior — candidato pelo ID da fato BI
WITH contagens AS (
 SELECT coalesce(l.regiao,'Não classificada') AS regiao,
 CASE WHEN l.capital IS TRUE THEN 'Capital' WHEN l.capital IS FALSE THEN 'Interior' ELSE 'Não classificada' END AS tipo,
 count(*) AS total
 FROM public.tbbi_fat_perfil_br_2025 f LEFT JOIN public.tbbi_dim_localidade l ON l.id_localidade=f.id_localidade
 WHERE f.data_evento>=DATE '2025-01-01' AND f.data_evento<DATE '2026-01-01'
 GROUP BY coalesce(l.regiao,'Não classificada'),l.capital
)
SELECT regiao,tipo,total,
 round(total*100.0/nullif(sum(total) OVER(PARTITION BY regiao),0),2) AS percentual_dentro_regiao,
 round(total*100.0/nullif(sum(total) OVER(),0),2) AS percentual_nacional
FROM contagens ORDER BY regiao,tipo;