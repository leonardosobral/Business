"""Read sanitized job outcomes in a read-only database transaction."""
from pathlib import Path
import base64
import json
import os
import secrets
import shutil
import subprocess
import tempfile

root = Path('/var/www/business.roadrunners.run')
work = Path(tempfile.mkdtemp(prefix='strava-date-audit-', dir=root / '_codex'))
token = secrets.token_hex(32)
os.chmod(work, 0o755)
sql = "\nWITH recent AS MATERIALIZED (\n SELECT activity_id,athlete_id,activity_date,start_date,updated,processed,activity_source,\n        left(strava_raw->>'start_date_local',10) AS raw_local_day,\n        strava_raw->>'start_date' AS raw_utc,\n        strava_raw->>'timezone' AS raw_timezone\n FROM public.tb_strava_activities\n WHERE start_date >= timestamp '2026-10-08' AND start_date < timestamp '2026-10-14'\n), valid AS (\n SELECT *,CASE WHEN raw_local_day ~ '^2026-10-[0-3][0-9]$' THEN raw_local_day::date END AS expected_day\n FROM recent\n)\nSELECT jsonb_build_object(\n 'measured_at',now(),'timezone',current_setting('TimeZone'),\n 'columns',(SELECT jsonb_agg(jsonb_build_object('name',column_name,'type',data_type,'default',column_default) ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_strava_activities'),\n 'triggers',(SELECT jsonb_agg(jsonb_build_object('name',t.tgname,'enabled',t.tgenabled,'trigger',pg_get_triggerdef(t.oid),'function',pg_get_functiondef(t.tgfoid))) FROM pg_trigger t WHERE t.tgrelid='public.tb_strava_activities'::regclass AND NOT t.tgisinternal),\n 'counts',(SELECT jsonb_build_object('total',count(*),'processed',count(*) FILTER(WHERE processed),'with_local_day',count(expected_day),'wrong_activity_date',count(*) FILTER(WHERE expected_day IS NOT NULL AND activity_date IS DISTINCT FROM expected_day),'wrong_start_day',count(*) FILTER(WHERE expected_day IS NOT NULL AND start_date::date IS DISTINCT FROM expected_day),'earliest_update',min(updated),'latest_update',max(updated)) FROM valid),\n 'by_day',(SELECT jsonb_agg(to_jsonb(d) ORDER BY day) FROM (SELECT start_date::date AS day,count(*) AS total,count(*) FILTER(WHERE expected_day IS NOT NULL AND activity_date IS DISTINCT FROM expected_day) AS wrong_activity_date,count(DISTINCT athlete_id) FILTER(WHERE expected_day IS NOT NULL AND activity_date IS DISTINCT FROM expected_day) AS wrong_day_athletes,count(*) FILTER(WHERE expected_day IS NOT NULL AND start_date::date IS DISTINCT FROM expected_day) AS wrong_start_day FROM valid GROUP BY 1)d),\n 'mismatch_groups',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT activity_date AS stored_day,expected_day,raw_timezone,count(*) AS activities,count(DISTINCT athlete_id) AS athletes,min(updated) AS first_update,max(updated) AS last_update FROM valid WHERE expected_day IS NOT NULL AND activity_date IS DISTINCT FROM expected_day GROUP BY 1,2,3 ORDER BY 2,1 LIMIT 30)d),\n 'cron6',(SELECT jsonb_build_object('active',ativo,'last_run_at',last_run_at,'last_status',last_status,'next_run_at',next_run_at) FROM public.tb_cron_jobs WHERE id_cron_job=6)\n)::text AS payload\n"
encoded = base64.b64encode(sql.encode()).decode()
try:
    (work / '.htaccess').write_text('Require local\n')
    (work / 'Application.cfc').write_text('component { this.name="' + work.name + '"; this.datasource="runner_dba"; boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","' + token + '")!=0){cfheader(statuscode=404);abort;}return true;} }')
    (work / 'run.cfm').write_text('<cfsetting showdebugoutput="false" requesttimeout="30"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});q=queryExecute(toString(binaryDecode("' + encoded + '","base64")),{},{datasource="runner_dba",timeout=20});writeOutput(q.payload[1]);}</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message})#</cfoutput></cfcatch></cftry>')
    for file in work.iterdir():
        os.chmod(file, 0o644)
    result = subprocess.run(['curl', '-sS', '--max-time', '35', '--resolve', 'business.roadrunners.run:443:127.0.0.1', '-X', 'POST', '--data-urlencode', 'key=' + token, 'https://business.roadrunners.run/_codex/' + work.name + '/run.cfm'], capture_output=True, text=True, timeout=40)
    try:
        print(json.dumps(json.loads(result.stdout), indent=2))
    except ValueError:
        print(json.dumps({'curl_rc': result.returncode, 'json_response': False, 'stderr': result.stderr[:300]}))
finally:
    shutil.rmtree(work)
