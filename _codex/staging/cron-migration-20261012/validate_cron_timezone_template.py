from pathlib import Path
import base64, json, os, secrets, shutil, subprocess, tempfile

SERVICE_BASE64 = None
root = Path('/var/www/business.roadrunners.run')
work = Path(tempfile.mkdtemp(prefix='cron-timezone-audit-', dir=root / '_codex'))
token = secrets.token_hex(32)
os.chmod(work, 0o755)
try:
    (work / '.htaccess').write_text('Require local\n')
    (work / 'Application.cfc').write_text('component { this.name="' + work.name + '"; this.datasource="runner_dba"; boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","' + token + '")!=0){cfheader(statuscode=404);abort;}return true;} }')
    (work / 'service.cfm').write_bytes(base64.b64decode(SERVICE_BASE64))
    (work / 'run.cfm').write_text('''<cfsetting showdebugoutput="false" requesttimeout="30"/><cfcontent type="application/json" reset="true"/><cfinclude template="service.cfm"/><cftry><cfscript>
result = {};
transaction {
 queryExecute("SET TRANSACTION READ ONLY", {}, {datasource="runner_dba"});
 qOriginal=queryExecute("SELECT current_setting('TimeZone') AS tz", {}, {datasource="runner_dba"});
 result.original_database_timezone=qOriginal.tz[1];
 queryExecute("SET LOCAL TIME ZONE 'UTC'", {}, {datasource="runner_dba"});
 qUtc=queryExecute("SELECT coalesce(string_agg(id_cron_job::text, ',' ORDER BY id_cron_job),'') AS due FROM tb_cron_jobs WHERE ativo AND next_run_at <= (now() AT TIME ZONE 'UTC')", {}, {datasource="runner_dba"});
 queryExecute("SET LOCAL TIME ZONE 'America/Sao_Paulo'", {}, {datasource="runner_dba"});
 qLocal=queryExecute("SELECT coalesce(string_agg(id_cron_job::text, ',' ORDER BY id_cron_job),'') AS due FROM tb_cron_jobs WHERE ativo AND next_run_at <= (now() AT TIME ZONE 'UTC')", {}, {datasource="runner_dba"});
 result.due_job_ids=qLocal.due[1];
 result.due_jobs_timezone_invariant=qUtc.due[1]==qLocal.due[1];
 qTimes=queryExecute("SELECT extract(epoch FROM ((now() AT TIME ZONE 'UTC') - ((now() AT TIME ZONE 'UTC') - interval '90 seconds'))) AS duration_seconds, ((now() AT TIME ZONE 'UTC') + interval '5 minutes') - (now() AT TIME ZONE 'UTC') = interval '5 minutes' AS interval_preserved, ((now() AT TIME ZONE 'UTC') - interval '301 seconds') < (now() AT TIME ZONE 'UTC') - interval '300 seconds' AS stale_run_detected", {}, {datasource="runner_dba"});
 result.duration_seconds=qTimes.duration_seconds[1];
 result.interval_preserved=qTimes.interval_preserved[1];
 result.stale_run_detected=qTimes.stale_run_detected[1];
 storedUtc=parseDateTime("2026-10-12 01:30:00");
 localDate=cronJobsLocalTimestamp(storedUtc);
 result.display_crosses_day_correctly=dateTimeFormat(localDate,"yyyy-mm-dd HH:nn:ss")=="2026-10-11 22:30:00";
 roundtrip=dateConvert("local2utc",localDate);
 qBinding=queryExecute("SELECT to_char(CAST(:value AS timestamp), 'YYYY-MM-DD HH24:MI:SS') AS stored_value", {value={value=roundtrip,cfsqltype="cf_sql_timestamp"}}, {datasource="runner_dba"});
 result.edit_roundtrip_preserved=qBinding.stored_value[1]=="2026-10-12 01:30:00";
 result.all_passed=result.due_jobs_timezone_invariant AND result.duration_seconds==90 AND result.interval_preserved AND result.stale_run_detected AND result.display_crosses_day_correctly AND result.edit_roundtrip_preserved;
 writeOutput(serializeJSON(result));
}
</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message})#</cfoutput></cfcatch></cftry>''')
    for file in work.iterdir():
        os.chmod(file, 0o644)
    result = subprocess.run(['curl', '-sS', '--max-time', '35', '--resolve', 'business.roadrunners.run:443:127.0.0.1', '-X', 'POST', '--data-urlencode', 'key=' + token, 'https://business.roadrunners.run/_codex/' + work.name + '/run.cfm'], capture_output=True, text=True, timeout=40)
    try:
        print(json.dumps(json.loads(result.stdout), indent=2))
    except ValueError:
        print(json.dumps({'curl_rc': result.returncode, 'json_response': False}))
finally:
    shutil.rmtree(work)
