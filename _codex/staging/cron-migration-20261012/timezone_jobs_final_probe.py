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
work = Path(tempfile.mkdtemp(prefix='cron-outcomes-audit-', dir=root / '_codex'))
token = secrets.token_hex(32)
os.chmod(work, 0o755)
sql = """
SELECT jsonb_build_object(
 'measured_at',now(),'timezone',current_setting('TimeZone'),
 'timestamp_columns',(SELECT jsonb_agg(jsonb_build_object('table',table_name,'column',column_name,'type',data_type)) FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('tb_cron_jobs','tb_cron_job_runs') AND column_name IN ('started_at','last_run_at','next_run_at')),'jobs',(SELECT jsonb_agg(to_jsonb(j) ORDER BY id_cron_job) FROM (
   SELECT id_cron_job,nome,ativo,interval_minutes,last_run_at,next_run_at,last_status,last_http_status,
          (ativo AND next_run_at<=(now() AT TIME ZONE 'UTC')) AS due,
          substring(last_error FROM '(?i)"(?:error|status|stopReason)"\\s*:\\s*"([a-z_]{1,80})"') AS error_code
   FROM public.tb_cron_jobs
 ) j),
 'runs_after_utc_fix',(SELECT coalesce(jsonb_agg(to_jsonb(r) ORDER BY id_cron_job),'[]') FROM (
   SELECT id_cron_job,status,trigger_type,count(*) AS runs,min(started_at) AS first_started,max(started_at) AS last_started,max(finished_at) AS last_finished
   FROM public.tb_cron_job_runs WHERE started_at >= timestamp '2026-10-12 14:35:05'
   GROUP BY id_cron_job,status,trigger_type
 ) r)
)::text AS payload
"""
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
