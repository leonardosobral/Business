
WITH recent AS MATERIALIZED (
 SELECT activity_id,athlete_id,activity_date,start_date,updated,processed,activity_source,
        left(strava_raw->>'start_date_local',10) AS raw_local_day,
        strava_raw->>'start_date' AS raw_utc,
        strava_raw->>'timezone' AS raw_timezone
 FROM public.tb_strava_activities
 WHERE start_date >= timestamp '2026-10-08' AND start_date < timestamp '2026-10-14'
), valid AS (
 SELECT *,CASE WHEN raw_local_day ~ '^2026-10-[0-3][0-9]$' THEN raw_local_day::date END AS expected_day
 FROM recent
)
SELECT jsonb_build_object(
 'measured_at',now(),'timezone',current_setting('TimeZone'),
 'columns',(SELECT jsonb_agg(jsonb_build_object('name',column_name,'type',data_type,'default',column_default) ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_strava_activities'),
 'triggers',(SELECT jsonb_agg(jsonb_build_object('name',t.tgname,'enabled',t.tgenabled,'trigger',pg_get_triggerdef(t.oid),'function',pg_get_functiondef(t.tgfoid))) FROM pg_trigger t WHERE t.tgrelid='public.tb_strava_activities'::regclass AND NOT t.tgisinternal),
 'counts',(SELECT jsonb_build_object('total',count(*),'processed',count(*) FILTER(WHERE processed),'with_local_day',count(expected_day),'wrong_activity_date',count(*) FILTER(WHERE expected_day IS NOT NULL AND activity_date IS DISTINCT FROM expected_day),'wrong_start_day',count(*) FILTER(WHERE expected_day IS NOT NULL AND start_date::date IS DISTINCT FROM expected_day),'earliest_update',min(updated),'latest_update',max(updated)) FROM valid),
 'by_day',(SELECT jsonb_agg(to_jsonb(d) ORDER BY day) FROM (SELECT start_date::date AS day,count(*) AS total,count(*) FILTER(WHERE expected_day IS NOT NULL AND activity_date IS DISTINCT FROM expected_day) AS wrong_activity_date,count(DISTINCT athlete_id) FILTER(WHERE expected_day IS NOT NULL AND activity_date IS DISTINCT FROM expected_day) AS wrong_day_athletes,count(*) FILTER(WHERE expected_day IS NOT NULL AND start_date::date IS DISTINCT FROM expected_day) AS wrong_start_day FROM valid GROUP BY 1)d),
 'mismatch_groups',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT activity_date AS stored_day,expected_day,raw_timezone,count(*) AS activities,count(DISTINCT athlete_id) AS athletes,min(updated) AS first_update,max(updated) AS last_update FROM valid WHERE expected_day IS NOT NULL AND activity_date IS DISTINCT FROM expected_day GROUP BY 1,2,3 ORDER BY 2,1 LIMIT 30)d),
 'cron6',(SELECT jsonb_build_object('active',ativo,'last_run_at',last_run_at,'last_status',last_status,'next_run_at',next_run_at) FROM public.tb_cron_jobs WHERE id_cron_job=6)
)::text AS payload
