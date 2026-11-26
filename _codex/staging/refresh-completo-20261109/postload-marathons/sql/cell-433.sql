-- Renovação candidata09/11; curadoria/capturas externas preservadas; entradas=[{"cell": 251, "revision": 42, "run": 351, "started_at": "2026-11-09 18:38:30.179861-03"}]
-- Principal2025 mantém congelamento205 histórico. Principal2026 é candidato novo, ainda sem afirmar publicação comercial.
WITH p AS (
 SELECT id,result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs
 WHERE id IN(205,351) AND frozen AND status='ok' AND NOT truncated AND row_count=1
)
SELECT CASE WHEN id=205 THEN 37 ELSE 42 END AS publicacao,
 (payload->'meta'->>'ano')::integer AS ano,
 jsonb_build_object('meta',payload->'meta'||jsonb_build_object('principal_source_run',id,'principal_state',CASE WHEN id=205 THEN 'historico2025' ELSE 'candidato2026' END),
 'series',(SELECT jsonb_agg(s) FROM jsonb_array_elements(payload->'series')s WHERE s->>'id' LIKE 'maratonas_%' OR s->>'id' LIKE 'performance_42k_%' OR s->>'id' LIKE 'cna_42k%'),
 'comparacoes',(SELECT jsonb_agg(c) FROM jsonb_array_elements(payload->'comparacoes')c WHERE c->>'serie' LIKE 'maratonas_%' OR c->>'serie' LIKE 'performance_42k_%' OR c->>'serie' LIKE 'cna_42k%')) AS payload FROM p ORDER BY ano
