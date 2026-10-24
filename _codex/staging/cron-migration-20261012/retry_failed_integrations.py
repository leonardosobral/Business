"""Requeue only the nine repaired jobs if still failed and unchanged since backup."""
from pathlib import Path
from datetime import datetime, timezone
import base64
import json
import os
import secrets
import shutil
import subprocess
import tempfile

root = Path('/var/www/business.roadrunners.run')
os.umask(0o077)
backup = Path(tempfile.mkdtemp(prefix='cron-integration-retry-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-', dir='/var/backups'))


def query(sql):
    work = Path(tempfile.mkdtemp(prefix='cron-retry-op-', dir=root / '_codex'))
    os.chmod(work, 0o755)
    token = secrets.token_hex(32)
    encoded = base64.b64encode(sql.encode()).decode()
    try:
        (work / '.htaccess').write_text('Require local\n')
        (work / 'Application.cfc').write_text('component {this.name="' + work.name + '";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","' + token + '")!=0){cfheader(statuscode=404);abort;}return true;}}')
        (work / 'run.cfm').write_text('<cfsetting requesttimeout="30" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>transaction {queryExecute("SET LOCAL lock_timeout=\'2s\'",{},{datasource="runner_dba"});q=queryExecute(toString(binaryDecode("' + encoded + '","base64")),{},{datasource="runner_dba",timeout=20});writeOutput(q.payload[1]);}</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message})#</cfoutput></cfcatch></cftry>')
        for path in work.iterdir():
            os.chmod(path, 0o644)
        result = subprocess.run(['curl', '-sS', '--max-time', '35', '--resolve', 'business.roadrunners.run:443:127.0.0.1', '-X', 'POST', '--data-urlencode', 'key=' + token, 'https://business.roadrunners.run/_codex/' + work.name + '/run.cfm'], capture_output=True, text=True, timeout=40)
        payload = json.loads(result.stdout)
        if isinstance(payload, dict) and any(k.lower() == 'error' for k in payload):
            raise RuntimeError('Database operation failed; no raw diagnostic printed.')
        return payload
    finally:
        shutil.rmtree(work)


before = query("""SELECT coalesce(jsonb_agg(to_jsonb(j)),'[]')::text AS payload FROM (
 SELECT id_cron_job,nome,last_run_at,next_run_at,last_status,interval_minutes,ativo
 FROM tb_cron_jobs WHERE id_cron_job IN (3,4,5,13,14,20,21,22,23)
 AND ativo=true AND last_status IN ('http_error','error','failed','timeout')
 ORDER BY id_cron_job
) j""")
(backup / 'schedule-before.json').write_text(json.dumps(before, indent=2) + '\n')
data = base64.b64encode(json.dumps(before).encode()).decode()
result = query("""WITH expected AS (
 SELECT * FROM jsonb_to_recordset(convert_from(decode('""" + data + """','base64'),'UTF8')::jsonb)
 AS i(id_cron_job bigint,last_run_at timestamp,next_run_at timestamp,last_status text)
), changed AS (
 UPDATE tb_cron_jobs j SET next_run_at=now()
 FROM expected i WHERE j.id_cron_job=i.id_cron_job
 AND j.last_run_at=i.last_run_at AND j.next_run_at=i.next_run_at AND j.last_status=i.last_status
 AND j.ativo=true
 AND NOT EXISTS(SELECT 1 FROM tb_cron_job_runs r WHERE r.id_cron_job=j.id_cron_job AND r.status='running')
 RETURNING j.id_cron_job,j.next_run_at,j.interval_minutes
)
SELECT jsonb_build_object('requeued_at',now(),'jobs',coalesce(jsonb_agg(to_jsonb(changed)),'[]'))::text AS payload FROM changed""")
result['backup'] = str(backup)
result['only_next_run_at_changed'] = True
(backup / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
