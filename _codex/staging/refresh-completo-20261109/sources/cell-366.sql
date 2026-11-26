-- 2026: preço resumido, uma prova = um id_evento. Sem consultas de resultados.
-- Calendário anual BR/rua ativo, ranking nulo ou diferente de false, data_final.
-- Não certifica realização, categoria geral, preço efetivamente pago ou taxas.
WITH eventos AS MATERIALIZED (
 SELECT e.id_evento,e.nome_evento,e.data_final,e.valor_inscricao,e.precos
 FROM public.tb_evento_corridas e
 WHERE e.ativo IS TRUE AND e.pais='BR' AND e.tipo_corrida='rua'
 AND (e.ranking IS NULL OR e.ranking<>'false')
 AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01'
), opcoes AS (
 SELECT e.id_evento,min(CASE WHEN jsonb_typeof(t.value->'valor')='number' THEN (t.value->>'valor')::numeric END) FILTER (WHERE coalesce(t.value->>'moeda','BRL')='BRL' AND CASE WHEN jsonb_typeof(t.value->'valor')='number' THEN (t.value->>'valor')::numeric>0 ELSE false END) AS menor_json
 FROM eventos e CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(e.precos)='array' THEN e.precos ELSE '[]'::jsonb END)t
 GROUP BY e.id_evento
), pagas AS (
 SELECT id_evento,valor_inscricao,row_number() OVER (ORDER BY valor_inscricao,id_evento) AS posicao,count(*) OVER () AS n
 FROM eventos WHERE valor_inscricao>0.01
), resumo AS (
 SELECT count(*) AS calendario,count(valor_inscricao) AS informadas,count(*) FILTER(WHERE valor_inscricao IS NULL) AS ausentes,
 count(*) FILTER(WHERE valor_inscricao=0.01) AS simbolicas,count(*) FILTER(WHERE valor_inscricao=0) AS zeradas,count(*) FILTER(WHERE valor_inscricao<0) AS negativas,
 (SELECT count(*) FROM pagas) AS analisadas,
 (SELECT avg(valor_inscricao)::text FROM pagas) AS media,
 (SELECT avg(valor_inscricao)::text FROM pagas WHERE posicao IN ((n+1)/2,(n+2)/2)) AS mediana,
 (count(valor_inscricao)*100.0/nullif(count(*),0))::text AS cobertura,
 (count(*) FILTER(WHERE valor_inscricao IS NULL)*100.0/nullif(count(*),0))::text AS ausencia,
 count(*) FILTER(WHERE o.menor_json IS NOT NULL AND e.valor_inscricao IS NOT NULL AND o.menor_json<>e.valor_inscricao) AS divergencias_json
 FROM eventos e LEFT JOIN opcoes o USING(id_evento)
), limites AS (SELECT column1 AS ordem,column2 AS rotulo,column3 AS inferior,column4 AS superior FROM (VALUES
 (1,'Até R$ 50',0.01::numeric,50::numeric),
 (2,'Acima de R$ 50 até R$ 100',50,100),
 (3,'Acima de R$ 100 até R$ 150',100,150),
 (4,'Acima de R$ 150 até R$ 200',150,200),
 (5,'Acima de R$ 200',200,NULL))t
), faixas AS (
 SELECT l.ordem,l.rotulo,count(p.id_evento) AS contagem,(count(p.id_evento)*100.0/nullif((SELECT analisadas FROM resumo),0))::text AS percentual
 FROM limites l LEFT JOIN pagas p ON p.valor_inscricao>l.inferior AND (l.superior IS NULL OR p.valor_inscricao<=l.superior)
 GROUP BY l.ordem,l.rotulo
)
SELECT jsonb_build_object('ano',2026,'inicio','2026-01-01','fim','2026-09-30','coletado_em',current_timestamp,
 'regra','Calendário anual BR/rua ativo; ranking nulo ou diferente de false; data_final em 2026, somente até 30/09. Uma prova = id_evento. Campo valor_inscricao, descrito como menor valor positivo publicado; pode refletir lotes, kits, distâncias ou descontos restritos. Não equivale ao preço geral ou ao gasto efetivo; taxas adicionais não somadas. Média e mediana não ponderadas, valores acima de R$ 0,01; simbólicos, zeros, negativos e ausentes fora da amostra paga. Não identifica automaticamente PCD ou gratuidade. Cadastro não certifica realização; amostra não representa o mercado. Corte anual de preços não altera o corte de resultados até 30/09.',
 'resumo',(SELECT to_jsonb(resumo) FROM resumo),
 'faixas',(SELECT jsonb_agg(to_jsonb(faixas) ORDER BY ordem) FROM faixas),
 'auditoria',(SELECT coalesce(jsonb_agg(jsonb_build_object('id_evento',e.id_evento,'nome_evento',e.nome_evento,'data_final',e.data_final,'valor_inscricao',e.valor_inscricao::text,'menor_json',o.menor_json::text,'valor_simbolico',e.valor_inscricao=0.01,'valor_nao_positivo',e.valor_inscricao<=0,'opcoes_divergentes',o.menor_json IS NOT NULL AND e.valor_inscricao IS NOT NULL AND o.menor_json<>e.valor_inscricao) ORDER BY e.id_evento),'[]'::jsonb) FROM eventos e LEFT JOIN opcoes o USING(id_evento) WHERE e.valor_inscricao<=0.01 OR (o.menor_json IS NOT NULL AND e.valor_inscricao IS NOT NULL AND o.menor_json<>e.valor_inscricao))) AS payload;
