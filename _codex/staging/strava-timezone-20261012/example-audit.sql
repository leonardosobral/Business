
WITH owner AS (SELECT strava_id FROM public.tb_usuarios WHERE id=100057),
acts AS MATERIALIZED (
 SELECT activity_id,athlete_id,activity_date,start_date,updated,processed,activity_source,id_athlete_donation,
  strava_raw->>'start_date' AS raw_utc,strava_raw->>'start_date_local' AS raw_local,strava_raw->>'timezone' AS raw_timezone,
  (type IN ('Run','VirtualRun','TrailRun') AND distance>=990) AS qualifying_run
 FROM public.tb_strava_activities
 WHERE (athlete_id IN(SELECT strava_id FROM owner) OR id_athlete_donation IN(SELECT strava_id FROM owner))
 AND start_date>=timestamp '2026-10-01' AND start_date<timestamp '2026-10-14'
), recent AS MATERIALIZED (
 SELECT a.activity_id,a.athlete_id,a.start_date,a.activity_date,a.updated,a.processed,
 left(a.strava_raw->>'start_date_local',10)::date AS expected_day,
 (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'UTC' AS raw_utc,
 (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'America/Sao_Paulo' AS raw_sp,
 a.strava_raw->>'timezone' AS raw_timezone
 FROM public.tb_strava_activities a
 WHERE a.start_date>=timestamp '2026-10-08' AND a.start_date<timestamp '2026-10-14'
 AND a.strava_raw->>'start_date_local' ~ '^2026-10-[0-3][0-9]T'
 AND a.strava_raw->>'start_date' ~ '^2026-10-[0-3][0-9]T'
)
SELECT jsonb_build_object(
 'measured_at',now(),
 'user_found',(SELECT count(*) FROM owner),
 'challenges',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT desafio FROM public.desafios WHERE id_usuario=100057)d),
 'example_activities',(SELECT jsonb_agg(to_jsonb(a) ORDER BY start_date) FROM acts a),
 'time_offsets',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT extract(epoch FROM (start_date-raw_utc))/3600 AS hours_vs_raw_utc,raw_timezone,count(*) AS activities,count(*) FILTER(WHERE start_date::date<>expected_day) AS wrong_start_day,count(*) FILTER(WHERE activity_date IS DISTINCT FROM expected_day) AS wrong_calendar_day,min(updated) AS first_update,max(updated) AS last_update FROM recent GROUP BY 1,2 ORDER BY activities DESC LIMIT 20)d),
 'legacy_day_mismatch_challenges',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT dc.desafio,count(DISTINCT r.activity_id) AS activities,count(DISTINCT usr.id) AS users FROM recent r JOIN public.tb_usuarios usr ON usr.strava_id=r.athlete_id JOIN public.desafios dc ON dc.id_usuario=usr.id WHERE r.start_date::date<>r.expected_day GROUP BY 1)d),
 'local_date_completeness',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT processed,(activity_date IS NOT NULL) AS has_calendar_day,(strava_raw->>'start_date_local' IS NOT NULL) AS has_original_local_day,count(*) AS activities FROM public.tb_strava_activities WHERE start_date>=timestamp '2026-10-08' AND start_date<timestamp '2026-10-14' GROUP BY 1,2,3)d)
)::text AS payload
