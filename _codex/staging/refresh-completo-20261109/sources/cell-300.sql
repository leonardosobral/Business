-- P11: estações por meses inteiros, decisão do responsável em 01/10/2026.
-- Verão dez/jan/fev, outono mar/abr/mai, inverno jun/jul/ago, primavera set/out/nov.
-- Agrupa parcelas do ano civil, não ciclos de estação que cruzam anos.
-- Deriva contagens mensais congeladas: não recoleta nem altera os comparativos.
-- 2026 até 26/09: verão só jan/fev; primavera só setembro parcial; dez/out/nov fora do corte.
WITH origens AS (
 SELECT n.id AS execucao_origem,(n.result->'rows'->0->'payload'->'meta'->>'ano')::integer AS ano,n.result->'rows'->0->'payload' AS payload
 FROM estudo.notebook_runs n WHERE n.id IN(95,96) AND n.frozen AND n.status='ok' AND NOT n.truncated AND n.row_count=1
), mapa AS(
 SELECT column1 AS mes,column2 AS estacao,column3 AS ordem FROM(VALUES
 ('Jan','Verão',1),('Fev','Verão',1),('Mar','Outono',2),('Abr','Outono',2),('Mai','Outono',2),
 ('Jun','Inverno',3),('Jul','Inverno',3),('Ago','Inverno',3),('Set','Primavera',4),('Out','Primavera',4),('Nov','Primavera',4),('Dez','Verão',1))t
), meses AS(
 SELECT o.ano,o.execucao_origem,m.mes,m.estacao,m.ordem,(c->'atual'->>'contagem')::bigint AS total,
 (c->'atual'->>'denominador')::bigint AS denominador
 FROM origens o CROSS JOIN LATERAL jsonb_array_elements(o.payload->'comparacoes')c JOIN mapa m ON m.mes=c->>'categoria' WHERE c->>'serie'='meses'
), integridade AS(
 SELECT ano,count(*) AS meses,sum(total)=min(denominador) AND min(denominador)=max(denominador) AS confere FROM meses GROUP BY ano
)
SELECT m.ano,m.estacao,m.ordem,max(m.execucao_origem) AS execucao_origem,sum(m.total) AS total,max(m.denominador) AS denominador,
 sum(m.total)*100.0/nullif(max(m.denominador),0) AS percentual,count(*) AS meses_incluidos,
 m.ano=2026 AND m.estacao IN('Verão','Primavera') AS incompleta_no_recorte
 FROM meses m JOIN integridade i ON i.ano=m.ano AND i.confere AND i.meses=CASE WHEN m.ano=2025 THEN 12 ELSE 9 END
 GROUP BY m.ano,m.estacao,m.ordem ORDER BY m.ano,m.ordem;
