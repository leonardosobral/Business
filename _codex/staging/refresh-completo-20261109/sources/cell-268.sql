-- Auditoria das gerações: não produz uma nova classificação editorial.
-- Preserva as faixas legadas de P05; mede as lacunas e a atribuição múltipla por &&.
-- População: BR, status 0/homologado; 2025 anual e 2026 até 26/09 com concluinte.
-- As faixas etárias abaixo são de 2025; 2026 aparece só como diagnóstico, não como evolução.
WITH intervalos AS (
 SELECT extract(year FROM e.data_final)::integer AS ano,r.idade_range,count(*) AS n
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-09-27'
 AND r.status_final=0 AND r.homologado IS TRUE
 AND (e.data_final<DATE '2026-01-01' OR r.concluinte IS TRUE)
 GROUP BY extract(year FROM e.data_final),r.idade_range
), faixas AS (
 SELECT column1 AS geracao,column2 AS faixa FROM (VALUES
 ('Alfa',int4range(0,15,'[)')),('Z',int4range(16,28,'[)')),
 ('Millennials',int4range(29,44,'[)')),('X',int4range(45,60,'[)')),
 ('Boomers',int4range(60,NULL,'[)'))) t
), atribuicoes AS (
 SELECT i.*, (SELECT count(*) FROM faixas f WHERE i.idade_range && f.faixa) AS correspondencias,
 (SELECT count(*) FROM faixas f WHERE i.idade_range<@f.faixa AND i.idade_range<>'empty'::int4range) AS contencoes
 FROM intervalos i
), qualidade AS (
 SELECT ano,CASE WHEN idade_range IS NULL THEN 'Idade nula'
 WHEN idade_range='empty'::int4range THEN 'Intervalo vazio'
 WHEN correspondencias=0 THEN 'Sem geração nas faixas legadas'
 WHEN correspondencias>1 THEN 'Mais de uma geração por sobreposição'
 WHEN contencoes=0 THEN 'Uma sobreposição, mas faixa ultrapassa limites'
 ELSE 'Contida em uma faixa legada' END AS qualidade,
 sum(n) AS participacoes,sum(n*correspondencias) AS atribuicoes
 FROM atribuicoes GROUP BY 1,2
), exemplos AS (
 SELECT ano,idade_range::text AS faixa,n AS participacoes,correspondencias,contencoes,
 row_number() OVER(PARTITION BY ano ORDER BY n DESC) AS posicao
 FROM atribuicoes WHERE correspondencias>1 OR (correspondencias=0 AND idade_range IS NOT NULL)
)
SELECT 'qualidade' AS bloco,to_jsonb(q) AS dados FROM qualidade q
UNION ALL SELECT 'exemplos',to_jsonb(e) FROM exemplos e WHERE posicao<=12
