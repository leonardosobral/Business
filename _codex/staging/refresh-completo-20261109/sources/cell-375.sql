-- Partitionnement mensuel, mêmes filtres que la source280. Pas de filtre delete implicite.
 WITH b AS MATERIALIZED(SELECT type,strava_raw->>'aspect_type' AS aspect FROM public.tb_strava_activities WHERE activity_date>=DATE '2026-08-01' AND activity_date<DATE '2026-09-01')
 SELECT type,count(*) AS total,count(*) FILTER(WHERE aspect='delete') AS com_indicacion_delete FROM b GROUP BY type