-- P13: pódio revisado v1, derivado do congelamento 95, sem nova coleta.
-- 11 critérios: maiores contagens sub4/sub3/sub2h30; menores tempo mínimo/médio/mediano e médias top10/100/5%/10%/50%.
-- Não atribui medalhas aos percentuais; evita contar duas vezes a mesma faixa de tempo.
-- Uma medalha por posição em cada critério. RANK: empate compartilha a posição, pulando a seguinte.
-- Usa os valores publicados (tempos arredondados ao segundo); sem desempate por nome ou ID.
-- Elegibilidade de cada indicador já foi revisada nos congelamentos 41 e 67; mesmas dez provas.
-- Inference dos destaques do PDF, não confirmação do código histórico. No PDF, bronze top5% de Curitiba contradiz o menor tempo de Floripa.
WITH origem AS(SELECT result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs WHERE id=95 AND frozen AND status='ok' AND NOT truncated AND row_count=1),
criterios AS(SELECT column1 AS serie,column2 AS direcao FROM(VALUES('maratonas_sub4_contagem','desc'),('maratonas_sub3_contagem','desc'),('maratonas_sub2h30_contagem','desc'),('maratonas_tempo_menor','asc'),('maratonas_tempo_medio','asc'),('maratonas_tempo_mediano','asc'),('maratonas_top10','asc'),('maratonas_top100','asc'),('maratonas_top5pct','asc'),('maratonas_top10pct','asc'),('maratonas_top50pct','asc'))t),
medalhas AS(SELECT column1 AS medalha,column2 AS posicao FROM(VALUES('ouro',1),('prata',2),('bronze',3))t),
valores AS(
 SELECT 'atual' AS fonte,c.serie,c.direcao,x->>'categoria' AS prova,x->'atual'->>'valor' AS valor
 FROM origem CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes')x JOIN criterios c ON c.serie=x->>'serie' WHERE x->'atual' IS NOT NULL
 UNION ALL
 SELECT 'PDF',c.serie,c.direcao,v->>'rotulo',v->>'valor'
 FROM origem CROSS JOIN LATERAL jsonb_array_elements(payload->'series')s JOIN criterios c ON c.serie=s->>'id' CROSS JOIN LATERAL jsonb_array_elements(s->'valores')v
), pontuacao AS(
 SELECT *,CASE WHEN direcao='desc' THEN -valor::numeric ELSE extract(epoch FROM valor::time)::numeric END AS escore FROM valores
), completos AS(
 SELECT fonte,count(*)=110 AND count(DISTINCT prova)=10 AND count(DISTINCT serie)=11 AS completo FROM pontuacao GROUP BY fonte
), ranks AS(
 SELECT p.*,rank() OVER(PARTITION BY p.fonte,p.serie ORDER BY p.escore) AS posicao FROM pontuacao p JOIN completos c ON c.fonte=p.fonte AND c.completo
), totais AS(
 SELECT r.fonte,'medalhas' AS bloco,'maratonas_medalhas_'||m.medalha AS serie,r.prova AS categoria,count(*) FILTER(WHERE r.posicao=m.posicao) AS quantidade,
 NULL::text AS valor,NULL::bigint AS posicao FROM ranks r CROSS JOIN medalhas m GROUP BY r.fonte,r.prova,m.medalha,m.posicao
)
SELECT * FROM totais UNION ALL
SELECT fonte,'criterio',serie,prova,NULL,valor,posicao FROM ranks
ORDER BY fonte,bloco,serie,categoria;
