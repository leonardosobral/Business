-- Somme exacte des neuf partitions mensuelles congelées. Types nuls séparés; indication delete exclue des activités publiées.
WITH r AS(SELECT x.value FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows')x WHERE n.id IN(175,179,180,181,182,183,184,185,186) AND n.frozen AND n.status='ok' AND NOT n.truncated),
a AS(SELECT value->>'type' AS type,sum((value->>'total')::bigint) AS total,sum((value->>'com_indicacion_delete')::bigint) AS deleted FROM r GROUP BY value->>'type'),
b AS(SELECT sum(total) AS registros_jan_set,sum(total) FILTER(WHERE type IS NULL) AS tipo_nulo,sum(total-deleted) FILTER(WHERE type IS NOT NULL) AS denominador FROM a)
SELECT a.type,a.total-a.deleted AS total,a.deleted AS com_indicacao_delete,b.*,100*(a.total-a.deleted)/nullif(b.denominador,0) AS percentual FROM a CROSS JOIN b WHERE type IS NOT NULL ORDER BY total DESC
