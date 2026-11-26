-- Porte observado na captura, por evento (todas as distâncias juntas).
-- Não estima capacidade, inscrições vendidas ou captura completa.
WITH periodos AS (SELECT column1 AS ano,column2 AS inicio,column3 AS fim FROM (VALUES(2025,DATE '2025-01-01',DATE '2025-12-31'),(2026,DATE '2026-01-01',DATE '2026-09-26'))t),
eventos AS MATERIALIZED (
 SELECT p.ano,e.id_evento,e.nome_evento FROM periodos p JOIN public.tb_evento_corridas e ON e.data_final BETWEEN p.inicio AND p.fim
 WHERE e.ativo IS TRUE AND e.pais='BR' AND e.tipo_corrida='rua' AND (e.ranking IS NULL OR e.ranking<>'false')
), por_prova AS MATERIALIZED (
 SELECT e.ano,e.id_evento,count(*) AS participacoes FROM eventos e JOIN public.vw_resultados r ON r.id_evento=e.id_evento
 WHERE r.concluinte IS TRUE AND r.status_final=0 AND r.homologado IS TRUE GROUP BY e.ano,e.id_evento
), ordenadas AS (
 SELECT *,row_number() OVER(PARTITION BY ano ORDER BY participacoes,id_evento) AS posicao,
 row_number() OVER(PARTITION BY ano ORDER BY participacoes DESC,id_evento) AS maior,count(*) OVER(PARTITION BY ano) AS n FROM por_prova
), resumo AS (
 SELECT p.ano,p.inicio,p.fim,(SELECT count(*) FROM eventos e WHERE e.ano=p.ano) AS calendario,count(o.id_evento) AS provas,coalesce(sum(participacoes),0) AS participacoes,
 avg(participacoes)::text AS media,avg(participacoes) FILTER(WHERE posicao IN ((n+1)/2,(n+2)/2))::text AS mediana,
 count(*) FILTER(WHERE maior<=ceil(n*0.1)) AS maiores_provas,
 coalesce(sum(participacoes) FILTER(WHERE maior<=ceil(n*0.1)),0) AS maiores_participacoes,
 (sum(participacoes) FILTER(WHERE maior<=ceil(n*0.1))*100.0/nullif(sum(participacoes),0))::text AS concentracao
 FROM periodos p LEFT JOIN ordenadas o USING(ano) GROUP BY p.ano,p.inicio,p.fim
), limites AS (SELECT column1 AS ordem,column2 AS rotulo,column3 AS inferior,column4 AS superior FROM (VALUES
 (1,'1–99',1,99),(2,'100–499',100,499),(3,'500–999',500,999),(4,'1.000–4.999',1000,4999),(5,'5.000+',5000,NULL))t),
faixas AS (
 SELECT p.ano,l.ordem,l.rotulo,count(o.id_evento) AS provas,coalesce(sum(o.participacoes),0) AS participacoes,
 (count(o.id_evento)*100.0/nullif((SELECT provas FROM resumo r WHERE r.ano=p.ano),0))::text AS percentual_provas,
 (coalesce(sum(o.participacoes),0)*100.0/nullif((SELECT participacoes FROM resumo r WHERE r.ano=p.ano),0))::text AS percentual_participacoes
 FROM periodos p CROSS JOIN limites l LEFT JOIN por_prova o ON o.ano=p.ano AND o.participacoes>=l.inferior AND (l.superior IS NULL OR o.participacoes<=l.superior)
 GROUP BY p.ano,l.ordem,l.rotulo
)
SELECT jsonb_build_object('coletado_em',current_timestamp,
 'regra','Provas ativas BR/rua elegíveis ao ranking (nulo ou diferente de false), pela data final. Uma prova = id_evento; todas as modalidades somadas. Participações com status_final=0, homologado=true e concluinte=true; todas as idades, sem corte 14+, pois ranges estão em revisão. São linhas de conclusão registradas, não atletas únicos nem inscrições vendidas; captura parcial pode reduzir o porte observado. Somente provas com ao menos uma conclusão integram média, mediana e faixas. Top 10% usa ceil(0,1*n), ordem por volume decrescente e id_evento para desempate; os empatados no limite não são todos incluídos. Ano completo de 2025 e parcial até 26/09/2026 não representam crescimento comparável. Coleta própria não altera os comparativos anteriores.',
 'edicoes',(SELECT jsonb_object_agg(r.ano,jsonb_build_object('resumo',to_jsonb(r),'faixas',(SELECT jsonb_agg(to_jsonb(faixas)-'ano' ORDER BY ordem) FROM faixas WHERE ano=r.ano),'provas',(SELECT coalesce(jsonb_agg(jsonb_build_object('id_evento',id_evento,'participacoes',participacoes) ORDER BY id_evento),'[]'::jsonb) FROM por_prova WHERE ano=r.ano))) FROM resumo r)) AS payload;
