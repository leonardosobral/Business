-- Saída 2025: referência e demais indicadores preservados da execução 35.
-- Maratonas: execução 41, célula 259 revisão 2. Ver diagnóstico 40 e nota 258.
WITH anterior AS (
 SELECT result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs WHERE id=35 AND frozen AND status='ok' AND NOT truncated
), fonte AS (
 SELECT * FROM estudo.notebook_runs WHERE id=41 AND frozen AND status='ok' AND NOT truncated
), nomes AS (SELECT column1 AS id,column2 AS nome FROM (VALUES (24999,'Maratona do Rio'),(24998,'Maratona de Porto Alegre'),(26867,'SP City Marathon'),(22792,'Maratona de Floripa'),(22582,'Maratona de São Paulo'),(27104,'Maratona de Curitiba'),(28253,'Maratona Monumental de Brasília'),(22590,'New Balance 42k Porto Alegre'),(25481,'Maratona de Aracaju'),(24016,'Maratona de Salvador')) t),
metricas AS (SELECT column1 AS serie,column2 AS campo,column3 AS contagem FROM (VALUES ('maratonas_concluintes','concluintes','concluintes'),('maratonas_feminino','feminino_pct','feminino'),('maratonas_masculino','masculino_pct','masculino'),('maratonas_tempo_menor','tempo_menor',NULL),('maratonas_tempo_medio','tempo_medio',NULL),('maratonas_tempo_mediano','tempo_mediano',NULL),('maratonas_sub4_percentual','sub4_pct','sub4'),('maratonas_sub4_contagem','sub4','sub4'),('maratonas_sub3_percentual','sub3_pct','sub3'),('maratonas_sub3_contagem','sub3','sub3'),('maratonas_sub2h30_percentual','sub2h30_pct','sub2h30'),('maratonas_sub2h30_contagem','sub2h30','sub2h30')) t),
m AS (
 SELECT metricas.serie,nomes.nome AS categoria,
 jsonb_build_object('valor',r->metricas.campo,'fonte','Notebook · execução #41 · 30/09/2026','nota','Recálculo candidato de 30/09/2026: uma população para contagens e tempos; BR/rua/2025, 42–42,2 km, status 0, homologado, concluinte, tempo positivo, pcd=false e exclusões de modalidade do SQL legado. Não reproduz a base histórica do PDF.')
 || CASE WHEN metricas.contagem IS NOT NULL THEN jsonb_build_object('contagem',r->metricas.contagem) ELSE '{}'::jsonb END
 || CASE WHEN metricas.campo LIKE '%_pct' THEN jsonb_build_object('denominador',r->'concluintes') ELSE '{}'::jsonb END AS atual
 FROM fonte CROSS JOIN LATERAL jsonb_array_elements(result->'rows') r JOIN nomes ON nomes.id=(r->>'id_evento')::integer CROSS JOIN metricas
), comps AS (
 SELECT c.value || CASE WHEN m.serie IS NOT NULL THEN jsonb_build_object('atual',m.atual,'status','notebook_em_conciliacao') ELSE '{}'::jsonb END AS item,c.ordinality AS ordem
 FROM anterior CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes') WITH ORDINALITY c
 LEFT JOIN m ON m.serie=c.value->>'serie' AND m.categoria=c.value->>'categoria'
)
SELECT payload || jsonb_build_object(
 'meta',payload->'meta' || jsonb_build_object('notebook_fontes',(payload->'meta'->'notebook_fontes') || (SELECT jsonb_agg(jsonb_build_object('execucao',id,'celula',cell_id,'revisao',cell_version,'coletado_em',started_at)) FROM fonte)),
 'comparacoes',(SELECT jsonb_agg(item ORDER BY ordem) FROM comps),
 'conciliacao',(SELECT jsonb_object_agg(k,0) FROM jsonb_object_keys(payload->'conciliacao') k) || (SELECT jsonb_object_agg(status,total) FROM (SELECT item->>'status' AS status,count(*) AS total FROM comps GROUP BY 1) q),
 'series',(SELECT jsonb_agg(s.value || CASE WHEN s.value->>'id' IN(SELECT serie FROM metricas) THEN jsonb_build_object('ressalva','Publicado preserva o PDF. No recálculo: Recálculo candidato de 30/09/2026: uma população para contagens e tempos; BR/rua/2025, 42–42,2 km, status 0, homologado, concluinte, tempo positivo, pcd=false e exclusões de modalidade do SQL legado. Não reproduz a base histórica do PDF.') ELSE '{}'::jsonb END ORDER BY s.ordinality) FROM jsonb_array_elements(payload->'series') WITH ORDINALITY s)
) AS payload FROM anterior WHERE (SELECT count(*) FROM m)=120
