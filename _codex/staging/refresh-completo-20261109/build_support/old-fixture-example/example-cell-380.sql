-- Variação explícita, independente da fórmula histórica desconhecida do PDF.
-- Participação Alfa+Z14+ = soma Alfa e Z / todas as participações do gênero, incluindo idades ausentes e menores14.
-- Delta em pontos percentuais = participação do ano - participação do ano anterior.
-- 2025 anual compara com2023/2024 anuais;2026Jan–Set compara com2024/2025Jan–Set, mesmos filtros de conclusão.
WITH fontes AS(SELECT column1 AS id,column2 AS periodo FROM(VALUES(156,'anual'),(158,'anual'),(162,'q3'),(159,'anual'),(164,'q3'),(219,'q3'))t),
r AS(SELECT f.periodo,x.value AS v FROM fontes f JOIN estudo.notebook_runs n USING(id) CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows')x WHERE n.frozen AND n.status='ok' AND NOT n.truncated),
a AS(SELECT (v->>'ano')::int AS ano,periodo,v->>'sexo' AS sexo,sum((v->>'total')::bigint) FILTER(WHERE v->>'categoria' IN('Alfa','Geração Z')) AS jovens,max((v->>'denominador')::bigint) AS total FROM r WHERE v->>'bloco'='geracao' GROUP BY 1,2,3),
b AS(SELECT *,100.0*jovens/nullif(total,0) AS percentual FROM a)
SELECT b.*,c.ano AS ano_base,c.jovens AS jovens_base,c.total AS total_base,c.percentual AS percentual_base,b.percentual-c.percentual AS diferenca_pp FROM b JOIN b c ON b.periodo=c.periodo AND b.sexo=c.sexo AND c.ano<b.ano WHERE (b.ano=2025 AND b.periodo='anual') OR (b.ano=2026 AND b.periodo='q3') ORDER BY b.ano,b.sexo,c.ano
