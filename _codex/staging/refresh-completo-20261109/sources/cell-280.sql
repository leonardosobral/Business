-- P15: atividades registradas de 2026. Fonte igual ao SELECT DataGrip 223: activity_date e tipo não nulo.
-- Não é contagem de usuários e não muda resultados de provas. Diagnósticos de exclusão permanecem explícitos.
WITH base AS (SELECT type,strava_raw->>'aspect_type' AS aspecto,activity_source FROM public.tb_strava_activities WHERE activity_date>=DATE '2026-01-01' AND activity_date<DATE '2026-09-27'),
a AS (SELECT type,count(*) AS total,count(*) FILTER(WHERE aspecto='delete') AS com_indicacao_delete FROM base WHERE type IS NOT NULL GROUP BY type),
b AS (SELECT count(*) AS registros_jan_set,count(*) FILTER(WHERE type IS NULL) AS tipo_nulo,count(*) FILTER(WHERE type IS NOT NULL) AS denominador FROM base)
SELECT a.*,b.*,a.total*100.0/nullif(b.denominador,0) AS percentual FROM a CROSS JOIN b ORDER BY a.total DESC,a.type
