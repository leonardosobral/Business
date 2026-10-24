
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
 'captured_at',now(),
 'trigger_count',(SELECT count(*) FROM pg_trigger WHERE tgrelid='public.tb_strava_activities'::regclass AND NOT tgisinternal AND tgenabled<>'D'),
 'rows',(SELECT jsonb_agg(jsonb_build_object('activity_id',a.activity_id,'before',a.start_date,'after',c.proposed_start,'activity_date',a.activity_date,'other_fields_md5',md5((to_jsonb(a)-'start_date')::text)) ORDER BY a.activity_id) FROM candidates c JOIN public.tb_strava_activities a USING(activity_id))
)::text AS payload