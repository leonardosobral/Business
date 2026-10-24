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
sql = "\nWITH owner AS (SELECT strava_id FROM public.tb_usuarios WHERE id=100057),\nacts AS MATERIALIZED (\n SELECT activity_id,athlete_id,activity_date,start_date,updated,processed,activity_source,id_athlete_donation,\n  strava_raw->>'start_date' AS raw_utc,strava_raw->>'start_date_local' AS raw_local,strava_raw->>'timezone' AS raw_timezone,\n  (type IN ('Run','VirtualRun','TrailRun') AND distance>=990) AS qualifying_run\n FROM public.tb_strava_activities\n WHERE (athlete_id IN(SELECT strava_id FROM owner) OR id_athlete_donation IN(SELECT strava_id FROM owner))\n AND start_date>=timestamp '2026-10-01' AND start_date<timestamp '2026-10-14'\n), recent AS MATERIALIZED (\n SELECT a.activity_id,a.athlete_id,a.start_date,a.activity_date,a.updated,a.processed,\n left(a.strava_raw->>'start_date_local',10)::date AS expected_day,\n (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'UTC' AS raw_utc,\n (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'America/Sao_Paulo' AS raw_sp,\n a.strava_raw->>'timezone' AS raw_timezone\n FROM public.tb_strava_activities a\n WHERE a.start_date>=timestamp '2026-10-08' AND a.start_date<timestamp '2026-10-14'\n AND a.strava_raw->>'start_date_local' ~ '^2026-10-[0-3][0-9]T'\n AND a.strava_raw->>'start_date' ~ '^2026-10-[0-3][0-9]T'\n)\nSELECT jsonb_build_object(\n 'measured_at',now(),\n 'user_found',(SELECT count(*) FROM owner),\n 'challenges',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT desafio FROM public.desafios WHERE id_usuario=100057)d),\n 'example_activities',(SELECT jsonb_agg(to_jsonb(a) ORDER BY start_date) FROM acts a),\n 'time_offsets',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT extract(epoch FROM (start_date-raw_utc))/3600 AS hours_vs_raw_utc,raw_timezone,count(*) AS activities,count(*) FILTER(WHERE start_date::date<>expected_day) AS wrong_start_day,count(*) FILTER(WHERE activity_date IS DISTINCT FROM expected_day) AS wrong_calendar_day,min(updated) AS first_update,max(updated) AS last_update FROM recent GROUP BY 1,2 ORDER BY activities DESC LIMIT 20)d),\n 'legacy_day_mismatch_challenges',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT dc.desafio,count(DISTINCT r.activity_id) AS activities,count(DISTINCT usr.id) AS users FROM recent r JOIN public.tb_usuarios usr ON usr.strava_id=r.athlete_id JOIN public.desafios dc ON dc.id_usuario=usr.id WHERE r.start_date::date<>r.expected_day GROUP BY 1)d),\n 'local_date_completeness',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT processed,(activity_date IS NOT NULL) AS has_calendar_day,(strava_raw->>'start_date_local' IS NOT NULL) AS has_original_local_day,count(*) AS activities FROM public.tb_strava_activities WHERE start_date>=timestamp '2026-10-08' AND start_date<timestamp '2026-10-14' GROUP BY 1,2,3)d)\n)::text AS payload\n"
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
