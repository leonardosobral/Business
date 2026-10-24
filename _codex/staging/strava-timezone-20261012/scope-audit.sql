
WITH recent AS MATERIALIZED (
 SELECT a.activity_id,a.athlete_id,a.start_date,a.activity_date,a.updated,a.processed,a.activity_source,
  left(a.strava_raw->>'start_date_local',10)::date AS expected_day,
  (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'UTC' AS raw_utc,
  (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'America/Sao_Paulo' AS proposed_start,
  a.strava_raw->>'timezone' AS raw_timezone,
  (a.type IN ('Run','VirtualRun','TrailRun') AND a.distance>=990) AS qualifying_run
 FROM public.tb_strava_activities a
 WHERE a.start_date>=timestamp '2026-10-01' AND a.start_date<timestamp '2026-10-14'
 AND a.strava_raw->>'start_date_local' ~ '^2026-10-[0-3][0-9]T'
 AND a.strava_raw->>'start_date' ~ '^2026-10-[0-3][0-9]T'
), candidates AS MATERIALIZED (
 SELECT * FROM recent WHERE start_date=raw_utc AND start_date<>proposed_start
  AND updated>=timestamp '2026-10-11' AND updated<timestamp '2026-10-12 14:28:06'
  AND activity_source='strava' AND processed=true
)
SELECT jsonb_build_object(
 'measured_at',now(),
 'scope','start_date between 2026-10-01 inclusive and 2026-10-14 exclusive',
 'summary',(SELECT jsonb_build_object('raw_activities',count(*),'wrong_activity_date',count(*) FILTER(WHERE activity_date IS DISTINCT FROM expected_day),'utc_stored',count(*) FILTER(WHERE start_date=raw_utc),'sp_stored',count(*) FILTER(WHERE start_date=proposed_start),'other_start_values',count(*) FILTER(WHERE start_date<>raw_utc AND start_date<>proposed_start)) FROM recent),
 'repair_candidates',(SELECT jsonb_build_object('activities',count(*),'athletes',count(DISTINCT athlete_id),'changed_day',count(*) FILTER(WHERE start_date::date<>proposed_start::date),'changed_day_athletes',count(DISTINCT athlete_id) FILTER(WHERE start_date::date<>proposed_start::date),'qualifying_runs',count(*) FILTER(WHERE qualifying_run),'qualifying_runs_changed_day',count(*) FILTER(WHERE qualifying_run AND start_date::date<>proposed_start::date),'first_update',min(updated),'last_update',max(updated),'wrong_activity_date',count(*) FILTER(WHERE activity_date IS DISTINCT FROM expected_day),'proposed_day_differs_from_local',count(*) FILTER(WHERE proposed_start::date<>expected_day)) FROM candidates),
 'candidates_by_day',(SELECT jsonb_agg(to_jsonb(d) ORDER BY stored_day) FROM (SELECT start_date::date AS stored_day,count(*) AS activities,count(*) FILTER(WHERE start_date::date<>proposed_start::date) AS changed_day FROM candidates GROUP BY 1)d),
 'candidate_timezones',(SELECT jsonb_agg(to_jsonb(d) ORDER BY activities DESC) FROM (SELECT raw_timezone,count(*) AS activities,count(*) FILTER(WHERE start_date::date<>proposed_start::date) AS changed_day FROM candidates GROUP BY 1)d),
 'example_corrections',(SELECT jsonb_agg(jsonb_build_object('activity_id',activity_id,'before',start_date,'after',proposed_start,'calendar_day',activity_date) ORDER BY start_date) FROM candidates WHERE athlete_id=(SELECT strava_id FROM public.tb_usuarios WHERE id=100057)),
 'example_calendar',(SELECT jsonb_agg(to_jsonb(d) ORDER BY day) FROM (SELECT activity_date AS day,count(*) FILTER(WHERE qualifying_run) AS qualifying_activities FROM recent WHERE athlete_id=(SELECT strava_id FROM public.tb_usuarios WHERE id=100057) GROUP BY 1)d),
 'example_page_matches',(SELECT id_usuario_cadastro=100057 FROM public.tb_paginas WHERE id_pagina=51115),
 'candidates_challenges',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT dc.desafio,count(DISTINCT c.activity_id) AS activities,count(DISTINCT usr.id) AS users,count(DISTINCT c.activity_id) FILTER(WHERE c.start_date::date<>c.proposed_start::date) AS changed_day FROM candidates c JOIN public.tb_usuarios usr ON usr.strava_id=c.athlete_id JOIN public.desafios dc ON dc.id_usuario=usr.id GROUP BY 1)d)
)::text AS payload
