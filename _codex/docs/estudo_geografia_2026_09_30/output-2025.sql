-- Publicação 2025: conserva a execução 45; atualiza somente capital/interior pelo congelamento #52.
-- Valores do PDF, totais, coortes e demais recortes permanecem intactos.
WITH anterior AS (
 SELECT result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs WHERE id=45 AND frozen AND status='ok' AND NOT truncated
), fonte AS (
 SELECT * FROM estudo.notebook_runs WHERE id=52 AND frozen AND status='ok' AND NOT truncated
), g AS (
 SELECT r->'dados' AS d FROM fonte CROSS JOIN LATERAL jsonb_array_elements(result->'rows') r
 WHERE r->>'bloco'='geografia' AND (r->'dados'->>'ano')::integer=2025
), regioes AS (SELECT column1 AS codigo,column2 AS nome FROM (VALUES ('Brasil','Brasil'),('N','Norte'),('NE','Nordeste'),('CO','Centro-Oeste'),('SE','Sudeste'),('S','Sul')) t
), m AS (
 SELECT 'capital_interior_'||regioes.nome AS serie,g.d->>'tipo' AS categoria,g.d,
 'Recálculo: 2025 anual; rua/BR, status 0 e homologado; sem filtro adicional de concluinte ou idade. Coleta de 30/09/2026. Base de '||replace(to_char((g.d->>'denominador')::bigint,'FM999,999,999'),',','.')||' participações; não classificadas: '||replace(to_char(coalesce((u.d->>'total')::bigint,0),'FM999,999,999'),',','.')||' ('||replace(round(coalesce((u.d->>'percentual')::numeric,0),2)::text,'.',',')||'%). Os casos sem classificação continuam no total; as barras não foram ajustadas para somar 100%.' AS nota
 FROM g JOIN regioes ON regioes.codigo=g.d->>'regiao'
 LEFT JOIN g u ON u.d->>'regiao'=g.d->>'regiao' AND u.d->>'tipo'='Não classificada'
 WHERE g.d->>'tipo' IN('Capital','Interior')
), notas AS (SELECT serie,max(nota) AS nota FROM m GROUP BY serie), comps AS (
 SELECT c.value || CASE WHEN m.serie IS NOT NULL THEN jsonb_build_object('atual',jsonb_build_object('valor',m.d->'percentual','contagem',m.d->'total','denominador',m.d->'denominador')||jsonb_build_object('fonte','Notebook · execução #52 · 30/09/2026','nota',m.nota),'status','notebook_em_conciliacao') ELSE '{}'::jsonb END AS item,c.ordinality AS ordem
 FROM anterior CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes') WITH ORDINALITY c
 LEFT JOIN m ON m.serie=c.value->>'serie' AND m.categoria=c.value->>'categoria'
)
SELECT payload || jsonb_build_object(
 'meta',payload->'meta'||jsonb_build_object('notebook_fontes',(payload->'meta'->'notebook_fontes')||(SELECT jsonb_agg(jsonb_build_object('execucao',id,'celula',cell_id,'revisao',cell_version,'coletado_em',started_at)) FROM fonte)),
 'comparacoes',(SELECT jsonb_agg(item ORDER BY ordem) FROM comps),
 'conciliacao',jsonb_build_object('compativel_no_valor',0,'divergente',0,'nao_recalculado',0,'compativel_no_arredondamento',0,'notebook_em_conciliacao',0)||(SELECT jsonb_object_agg(status,total) FROM (SELECT item->>'status' AS status,count(*) AS total FROM comps GROUP BY 1) q),
 'series',(SELECT jsonb_agg(s.value || CASE WHEN n.nota IS NOT NULL THEN jsonb_build_object('ressalva',n.nota) ELSE '{}'::jsonb END ORDER BY s.ordinality) FROM jsonb_array_elements(payload->'series') WITH ORDINALITY s LEFT JOIN notas n ON n.serie=s.value->>'id')
) AS payload FROM anterior WHERE (SELECT count(*) FROM m)=12
