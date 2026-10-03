-- P04/P05/P07 — regra revisada v1; idade em 31/12 do ano da prova (decisão do usuário em 01/10/2026).
-- BR pela data final; status 0 e homologado; 2026 exige concluinte e termina em 26/09.
-- 2023–2025 mantêm a população da view atual, sem filtro adicional de conclusão.
-- Nascimento plausível (não futuro; 0–120 em 31/12) tem prioridade. Sem ele, faixa textual válida.
-- Nunca usa sobreposição nem reparte faixa ampla. Cada participação tem um único destino, inclusive desconhecido.
-- Coortes fixas por nascimento, alinhadas aos rótulos 2025 do PDF: Alfa >=2010; Z 1997–2009;
-- Millennials 1981–1996; X 1965–1980; Boomers 1946–1964; anteriores separados. Menores de 14 separados.
-- Faixas da categoria interpretadas sob a referência 31/12; inferência explícita, não idade individual certificada.
WITH base AS (
 SELECT coalesce(r.sexo,'N/A') AS sexo,r.idade_range,
 2026-extract(year FROM r.data_nascimento)::integer AS idade_31dez,
 coalesce(r.data_nascimento<=e.data_final AND 2026-extract(year FROM r.data_nascimento)::integer BETWEEN 0 AND 120,false) AS nascimento_plausivel,
 CASE WHEN e.tipo_corrida='rua' AND r.percurso>0 THEN
 CASE WHEN r.percurso<6 THEN 'Até 5 km' WHEN r.percurso<11 THEN '6 a 10 km'
 WHEN r.percurso<30 THEN '11 a 29 km' ELSE '+30 km' END END AS distancia
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-09-27'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
), agrupados AS (
 SELECT sexo,idade_range,idade_31dez,nascimento_plausivel,distancia,count(*) AS n FROM base
 GROUP BY sexo,idade_range,idade_31dez,nascimento_plausivel,distancia
), normalizados AS (
 SELECT *,CASE WHEN nascimento_plausivel THEN int4range(idade_31dez,idade_31dez+1,'[)')
 WHEN idade_range IS NOT NULL AND idade_range<>'empty'::int4range
 AND lower(idade_range)>=0 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN idade_range END AS faixa,
 CASE WHEN nascimento_plausivel THEN 'Nascimento plausível'
 WHEN idade_range IS NULL THEN 'Sem idade informada'
 WHEN idade_range<>'empty'::int4range AND lower(idade_range)>=0
 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN 'Faixa da categoria'
 ELSE 'Dado inválido' END AS origem
 FROM agrupados
), faixas_idade AS (
 SELECT column1 AS ordem,column2 AS categoria,column3 AS faixa FROM (VALUES
 (0,'Menos de 14',int4range(0,14,'[)')),
 (1,'14–19',int4range(14,20,'[)')),(2,'20–24',int4range(20,25,'[)')),
 (3,'25–29',int4range(25,30,'[)')),(4,'30–34',int4range(30,35,'[)')),
 (5,'35–39',int4range(35,40,'[)')),(6,'40–44',int4range(40,45,'[)')),
 (7,'45–49',int4range(45,50,'[)')),(8,'50–54',int4range(50,55,'[)')),
 (9,'55–59',int4range(55,60,'[)')),(10,'60–64',int4range(60,65,'[)')),
 (11,'65–69',int4range(65,70,'[)')),(12,'70+',int4range(70,NULL,'[)'))) t
), faixas_geracao AS (
 SELECT column1 AS ordem,column2 AS categoria,column3 AS faixa FROM (VALUES
 (0,'Menos de 14',int4range(0,14,'[)')),
 (1,'Alfa',int4range(14,2026-2010+1,'[)')),
 (2,'Geração Z',int4range(2026-2010+1,2026-1997+1,'[)')),
 (3,'Millennials',int4range(2026-1997+1,2026-1981+1,'[)')),
 (4,'Geração X',int4range(2026-1981+1,2026-1965+1,'[)')),
 (5,'Boomers',int4range(2026-1965+1,2026-1946+1,'[)')),
 (6,'Anteriores a 1946',int4range(2026-1946+1,NULL,'[)'))) t
), classificados AS (
 SELECT n.*,
 coalesce((SELECT f.categoria FROM faixas_idade f WHERE n.faixa<@f.faixa),
 CASE WHEN origem='Sem idade informada' THEN 'Sem idade informada' ELSE 'Idade indeterminada' END) AS idade,
 coalesce((SELECT f.categoria FROM faixas_geracao f WHERE n.faixa<@f.faixa),
 CASE WHEN origem='Sem idade informada' THEN 'Sem idade informada' ELSE 'Geração indeterminada' END) AS geracao
 FROM normalizados n
),
sexos AS (SELECT 'geral' AS sexo UNION ALL SELECT 'F' UNION ALL SELECT 'M'),
idades AS (SELECT ordem,categoria FROM faixas_idade UNION ALL SELECT 13,'Idade indeterminada' UNION ALL SELECT 14,'Sem idade informada'),
geracoes AS (SELECT ordem,categoria FROM faixas_geracao UNION ALL SELECT 7,'Geração indeterminada' UNION ALL SELECT 8,'Sem idade informada'),
origens AS (SELECT 1 AS ordem,'Nascimento plausível' AS categoria UNION ALL SELECT 2,'Faixa da categoria' UNION ALL SELECT 3,'Sem idade informada' UNION ALL SELECT 4,'Dado inválido'),
distancias AS (SELECT 1 AS ordem,'Até 5 km' AS categoria UNION ALL SELECT 2,'6 a 10 km' UNION ALL SELECT 3,'11 a 29 km' UNION ALL SELECT 4,'+30 km'),
totais AS (SELECT s.sexo,sum(c.n) AS total FROM sexos s JOIN classificados c ON s.sexo='geral' OR s.sexo=c.sexo GROUP BY s.sexo),
idade_por_sexo AS (SELECT s.sexo,f.ordem,f.categoria,coalesce(sum(c.n),0) AS total FROM sexos s CROSS JOIN idades f LEFT JOIN classificados c ON c.idade=f.categoria AND (s.sexo='geral' OR s.sexo=c.sexo) GROUP BY s.sexo,f.ordem,f.categoria),
geracao_por_sexo AS (SELECT s.sexo,f.ordem,f.categoria,coalesce(sum(c.n),0) AS total FROM sexos s CROSS JOIN geracoes f LEFT JOIN classificados c ON c.geracao=f.categoria AND (s.sexo='geral' OR s.sexo=c.sexo) GROUP BY s.sexo,f.ordem,f.categoria),
origem_por_sexo AS (SELECT s.sexo,f.ordem,f.categoria,coalesce(sum(c.n),0) AS total FROM sexos s CROSS JOIN origens f LEFT JOIN classificados c ON c.origem=f.categoria AND (s.sexo='geral' OR s.sexo=c.sexo) GROUP BY s.sexo,f.ordem,f.categoria),
cruzamento AS (SELECT g.ordem AS ordem_geracao,g.categoria AS geracao,d.ordem AS ordem_distancia,d.categoria AS distancia,coalesce(sum(c.n),0) AS total FROM geracoes g CROSS JOIN distancias d LEFT JOIN classificados c ON c.geracao=g.categoria AND c.distancia=d.categoria GROUP BY g.ordem,g.categoria,d.ordem,d.categoria),
medidas AS (
 SELECT 'idade' AS bloco,i.sexo,i.ordem,i.categoria,NULL::text AS distancia,i.total,t.total AS denominador FROM idade_por_sexo i JOIN totais t USING(sexo)
 UNION ALL SELECT 'geracao',g.sexo,g.ordem,g.categoria,NULL,g.total,t.total FROM geracao_por_sexo g JOIN totais t USING(sexo)
 UNION ALL SELECT 'origem',g.sexo,g.ordem,g.categoria,NULL,g.total,t.total FROM origem_por_sexo g JOIN totais t USING(sexo)
 UNION ALL SELECT 'geracao_na_distancia','geral',ordem_geracao,geracao,distancia,total,sum(total) OVER(PARTITION BY distancia) FROM cruzamento
 UNION ALL SELECT 'distancia_na_geracao','geral',ordem_distancia,geracao,distancia,total,sum(total) OVER(PARTITION BY geracao) FROM cruzamento
)
SELECT 2026 AS ano,*,total*100.0/nullif(denominador,0) AS percentual,current_timestamp AS coletado_em FROM medidas ORDER BY bloco,sexo,categoria,ordem;
