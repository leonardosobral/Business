-- Destaques P12 derivados exclusivamente dos resultados já congelados.
-- 2025: as dez provas da seleção histórica; 2026: dez maiores no corte 26/09.
-- Quantidades F/M exatas, não média dos percentuais por prova. Desconhecidos ficam no total.
WITH fontes AS (
 SELECT r.id AS execucao,r.cell_id AS celula,r.cell_version AS revisao,r.started_at AS coletado_em,
 CASE WHEN r.id=41 THEN 2025 ELSE 2026 END AS ano,
 CASE WHEN r.id=41 THEN r.result->'rows' ELSE r.result->'rows'->0->'payload'->'top10' END AS provas
 FROM estudo.notebook_runs r
 WHERE ((r.id=41 AND r.cell_id=259 AND r.cell_version=2) OR (r.id=111 AND r.cell_id=309 AND r.cell_version=1))
 AND r.frozen AND r.status='ok' AND NOT r.truncated
), eventos AS (
 SELECT f.*,x FROM fontes f CROSS JOIN LATERAL jsonb_array_elements(f.provas)x
), resumo AS (
 SELECT ano,max(execucao) AS execucao,max(celula) AS celula,max(revisao) AS revisao,max(coletado_em) AS coletado_em,
 count(*) AS provas,count(DISTINCT x->>'id_evento') AS provas_distintas,
 sum((x->>'concluintes')::bigint) AS concluintes,sum((x->>'feminino')::bigint) AS feminino,
 sum((x->>'masculino')::bigint) AS masculino,
 sum((x->>'concluintes')::bigint-(x->>'feminino')::bigint-(x->>'masculino')::bigint) AS outros,
 bool_and(x ? 'concluintes' AND x ? 'feminino' AND x ? 'masculino'
 AND (x->>'concluintes')::bigint>=0 AND (x->>'feminino')::bigint>=0 AND (x->>'masculino')::bigint>=0
 AND (x->>'concluintes')::bigint>=(x->>'feminino')::bigint+(x->>'masculino')::bigint) AS integra
 FROM eventos GROUP BY ano
)
SELECT jsonb_build_object('derivado_em',current_timestamp,'linhas',jsonb_agg(to_jsonb(r)||jsonb_build_object(
 'feminino_percentual',(feminino*100.0/nullif(concluintes,0))::text,
 'corte',CASE WHEN ano=2025 THEN '2025-12-31' ELSE '2026-09-26' END,
 'selecao',CASE WHEN ano=2025 THEN 'Dez provas da seleção histórica do quadro; não refaz o ranking nacional.' ELSE 'Dez maiores por concluintes elegíveis na coleta de 01/10, corte 26/09.' END) ORDER BY ano)) AS payload
FROM resumo r
HAVING count(*)=2 AND bool_and(provas=10 AND provas_distintas=10 AND integra AND concluintes>0);
