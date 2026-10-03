-- Saída2026: acrescenta somente fontes individuais conferidas na auditoria125.
-- Preserva o JSON nativo, valores/contagens/denominadores, cortes e coortes de122.
WITH anterior AS(SELECT result->'rows'->0->'payload' AS p FROM estudo.notebook_runs WHERE id=122 AND frozen AND status='ok' AND NOT truncated AND row_count=1),
a AS(SELECT result->'rows'->0->'payload' AS p FROM estudo.notebook_runs WHERE id=125 AND cell_id=323 AND cell_version=3 AND frozen AND status='ok' AND NOT truncated AND row_count=1),
m AS(SELECT x FROM a CROSS JOIN LATERAL jsonb_array_elements(a.p->'indicadores')x),
c AS(SELECT t.value AS x,t.ordinality AS ord FROM anterior CROSS JOIN LATERAL jsonb_array_elements(p->'comparacoes')WITH ORDINALITY t),
alvos AS(SELECT c.x,c.ord,m.x AS fonte FROM c JOIN m ON c.x->>'serie'=m.x->>'serie' AND c.x->>'categoria'=m.x->>'categoria'),
novas AS(SELECT c.ord,c.x||CASE WHEN a.fonte IS NOT NULL THEN jsonb_build_object('atual',c.x->'atual'||jsonb_build_object('fonte',a.fonte->>'fonte')) ELSE '{}'::jsonb END AS x FROM c LEFT JOIN alvos a USING(ord))
SELECT anterior.p||jsonb_build_object('meta',anterior.p->'meta'||jsonb_build_object('contrato_versao',8,'totais_fontes',a.p->'totais'),'comparacoes',(SELECT jsonb_agg(x ORDER BY ord) FROM novas)) AS payload
FROM anterior CROSS JOIN a
WHERE(SELECT count(*) FROM m)=448 AND(SELECT count(*) FROM alvos)=448
AND NOT EXISTS(SELECT 1 FROM alvos WHERE x->'atual' IS DISTINCT FROM CAST(fonte->>'esperado_texto' AS jsonb) OR x->'atual' ? 'fonte')
AND NOT EXISTS(SELECT 1 FROM m GROUP BY x->>'serie',x->>'categoria' HAVING count(*)<>1);
