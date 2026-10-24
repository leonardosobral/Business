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
SELECT jsonb_agg(to_jsonb(j))::text AS payload FROM (
 SELECT started_at,status,http_status,
 substring(response_preview FROM '(?i)"failed"\\s*:\\s*([0-9]+)') AS failed_count,
 substring(response_preview FROM '(?i)"checked"\\s*:\\s*([0-9]+)') AS checked_count,
 substring(response_preview FROM '(?i)"status"\\s*:\\s*"([a-z_]{1,80})"') AS api_status
 FROM tb_cron_job_runs WHERE id_cron_job=23 AND started_at<timestamp '2026-10-12 12:29:57'
 ORDER BY started_at DESC LIMIT 6
) j
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
