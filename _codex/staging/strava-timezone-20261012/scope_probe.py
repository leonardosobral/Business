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
sql = "\nWITH recent AS MATERIALIZED (\n SELECT a.activity_id,a.athlete_id,a.start_date,a.activity_date,a.updated,a.processed,a.activity_source,\n  left(a.strava_raw->>'start_date_local',10)::date AS expected_day,\n  (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'UTC' AS raw_utc,\n  (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'America/Sao_Paulo' AS proposed_start,\n  a.strava_raw->>'timezone' AS raw_timezone,\n  (a.type IN ('Run','VirtualRun','TrailRun') AND a.distance>=990) AS qualifying_run\n FROM public.tb_strava_activities a\n WHERE a.start_date>=timestamp '2026-10-01' AND a.start_date<timestamp '2026-10-14'\n AND a.strava_raw->>'start_date_local' ~ '^2026-10-[0-3][0-9]T'\n AND a.strava_raw->>'start_date' ~ '^2026-10-[0-3][0-9]T'\n), candidates AS MATERIALIZED (\n SELECT * FROM recent WHERE start_date=raw_utc AND start_date<>proposed_start\n  AND updated>=timestamp '2026-10-11' AND updated<timestamp '2026-10-12 14:28:06'\n  AND activity_source='strava' AND processed=true\n)\nSELECT jsonb_build_object(\n 'measured_at',now(),\n 'scope','start_date between 2026-10-01 inclusive and 2026-10-14 exclusive',\n 'summary',(SELECT jsonb_build_object('raw_activities',count(*),'wrong_activity_date',count(*) FILTER(WHERE activity_date IS DISTINCT FROM expected_day),'utc_stored',count(*) FILTER(WHERE start_date=raw_utc),'sp_stored',count(*) FILTER(WHERE start_date=proposed_start),'other_start_values',count(*) FILTER(WHERE start_date<>raw_utc AND start_date<>proposed_start)) FROM recent),\n 'repair_candidates',(SELECT jsonb_build_object('activities',count(*),'athletes',count(DISTINCT athlete_id),'changed_day',count(*) FILTER(WHERE start_date::date<>proposed_start::date),'changed_day_athletes',count(DISTINCT athlete_id) FILTER(WHERE start_date::date<>proposed_start::date),'qualifying_runs',count(*) FILTER(WHERE qualifying_run),'qualifying_runs_changed_day',count(*) FILTER(WHERE qualifying_run AND start_date::date<>proposed_start::date),'first_update',min(updated),'last_update',max(updated),'wrong_activity_date',count(*) FILTER(WHERE activity_date IS DISTINCT FROM expected_day),'proposed_day_differs_from_local',count(*) FILTER(WHERE proposed_start::date<>expected_day)) FROM candidates),\n 'candidates_by_day',(SELECT jsonb_agg(to_jsonb(d) ORDER BY stored_day) FROM (SELECT start_date::date AS stored_day,count(*) AS activities,count(*) FILTER(WHERE start_date::date<>proposed_start::date) AS changed_day FROM candidates GROUP BY 1)d),\n 'candidate_timezones',(SELECT jsonb_agg(to_jsonb(d) ORDER BY activities DESC) FROM (SELECT raw_timezone,count(*) AS activities,count(*) FILTER(WHERE start_date::date<>proposed_start::date) AS changed_day FROM candidates GROUP BY 1)d),\n 'example_corrections',(SELECT jsonb_agg(jsonb_build_object('activity_id',activity_id,'before',start_date,'after',proposed_start,'calendar_day',activity_date) ORDER BY start_date) FROM candidates WHERE athlete_id=(SELECT strava_id FROM public.tb_usuarios WHERE id=100057)),\n 'example_calendar',(SELECT jsonb_agg(to_jsonb(d) ORDER BY day) FROM (SELECT activity_date AS day,count(*) FILTER(WHERE qualifying_run) AS qualifying_activities FROM recent WHERE athlete_id=(SELECT strava_id FROM public.tb_usuarios WHERE id=100057) GROUP BY 1)d),\n 'example_page_matches',(SELECT id_usuario_cadastro=100057 FROM public.tb_paginas WHERE id_pagina=51115),\n 'candidates_challenges',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT dc.desafio,count(DISTINCT c.activity_id) AS activities,count(DISTINCT usr.id) AS users,count(DISTINCT c.activity_id) FILTER(WHERE c.start_date::date<>c.proposed_start::date) AS changed_day FROM candidates c JOIN public.tb_usuarios usr ON usr.strava_id=c.athlete_id JOIN public.desafios dc ON dc.id_usuario=usr.id GROUP BY 1)d)\n)::text AS payload\n"
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
