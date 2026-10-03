-- Saída 2026: conserva a execução 33; apenas completa oito valores de distâncias a partir da execução 42.
-- Não há nova coleta: o corte e todos os demais números permanecem os mesmos.
WITH anterior AS (
 SELECT result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs WHERE id=33 AND frozen AND status='ok' AND NOT truncated
), alertas AS (
 SELECT string_agg((c->>'categoria')||': '||(c->'atual'->>'valor'),'; ' ORDER BY c->>'categoria') AS texto
 FROM anterior CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes') c
 WHERE c->>'serie'='maratonas_tempo_menor' AND (c->'atual'->>'valor')::time<TIME '02:00:00'
), fonte AS (
 SELECT r FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows') r
 WHERE n.id=42 AND n.frozen AND n.status='ok' AND NOT n.truncated
), comps AS (
 SELECT c.value || CASE WHEN r IS NOT NULL THEN jsonb_build_object('atual',jsonb_build_object('valor',r->'percentual','contagem',r->'total','denominador',r->'denominador'),'status','calculado') ELSE '{}'::jsonb END AS item,c.ordinality AS ordem
 FROM anterior CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes') WITH ORDINALITY c
 LEFT JOIN fonte ON r->>'serie'=c.value->>'serie' AND r->>'categoria'=c.value->>'categoria'
)
SELECT payload || jsonb_build_object(
 'meta',payload->'meta' || jsonb_build_object('origem','Snapshot 2026 v3 · execução #33; distâncias dentro de cada gênero derivadas na execução #42, sem nova coleta'),
 'comparacoes',(SELECT jsonb_agg(item ORDER BY ordem) FROM comps),
 'conciliacao',(SELECT jsonb_object_agg(status,total) FROM (SELECT item->>'status' AS status,count(*) AS total FROM comps GROUP BY 1) q),
 'series',(SELECT jsonb_agg(s.value || CASE WHEN s.value->>'id' IN('distancia_dentro_sexo_F','distancia_dentro_sexo_M') THEN jsonb_build_object('ressalva','Notebook, execução #42, derivada das contagens congeladas na execução #33. Rua, percurso positivo, BR, status 0, homologado e concluinte. Percentual das participações do próprio gênero; corte até 26/09/2026. Não depende do arredondamento dos outros gráficos.') WHEN s.value->>'id' LIKE 'maratonas_%' AND (SELECT texto FROM alertas) IS NOT NULL THEN jsonb_build_object('ressalva',coalesce(s.value->>'ressalva','')||' Auditoria do congelamento: mínimos abaixo de duas horas exigem revisão: '||(SELECT texto FROM alertas)||'. São tempos cadastrados, não desempenho validado. Contagens, médias e cortes também dependem da revisão desses registros; nenhum foi excluído automaticamente.') ELSE '{}'::jsonb END ORDER BY s.ordinality) FROM jsonb_array_elements(payload->'series') WITH ORDINALITY s)
) AS payload FROM anterior WHERE (SELECT count(*) FROM fonte)=8
