-- Exibe o calendário já congelado, sem nova coleta nem troca dos comparativos.
-- Origem: execução 56 (derivada da 33). Usa contagens mensais, nunca percentuais arredondados.
-- Eventos até 26/09, todas as modalidades/idades, status 0, homologado e concluinte.
WITH origem AS (
 SELECT result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs WHERE id=56 AND frozen AND status='ok' AND NOT truncated
), meses AS (
 SELECT column1 AS categoria,column2 AS mes FROM (VALUES ('Jan',1),('Fev',2),('Mar',3),('Abr',4),('Mai',5),('Jun',6),('Jul',7),('Ago',8),('Set',9)) t
), contagens AS (
 SELECT c->>'categoria' AS categoria,m.mes,(c->'atual'->>'contagem')::bigint AS total,
 (c->'atual'->>'denominador')::bigint AS denominador
 FROM origem CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes') c JOIN meses m ON m.categoria=c->>'categoria'
 WHERE c->>'serie'='meses'
), recortes AS (
 SELECT 'meses' AS serie,categoria,mes AS ordem,total,denominador,mes=9 AS parcial FROM contagens
 UNION ALL
 SELECT 'trimestres',ceil(mes/3.0)::integer::text,ceil(mes/3.0)::integer,sum(total),max(denominador),bool_or(mes=9)
 FROM contagens GROUP BY ceil(mes/3.0)
)
SELECT *,total*100.0/nullif(denominador,0) AS percentual,56 AS execucao_origem
FROM recortes WHERE (SELECT sum(total)=min(denominador) AND min(denominador)=max(denominador) AND count(*)=9 FROM contagens)
ORDER BY serie,ordem
