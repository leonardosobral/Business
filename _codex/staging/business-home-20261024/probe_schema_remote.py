"""Bounded read-only schema probe through the existing loopback-only CF pattern."""
from pathlib import Path
import json
import os
import secrets
import shutil
import subprocess
import tempfile

root = Path('/var/www/business.roadrunners.run')
work = Path(tempfile.mkdtemp(prefix='business-home-schema-', dir=root / '_codex'))
os.chmod(work, 0o755)
token = secrets.token_hex(32)
body = '''<cfsetting showdebugoutput="false" requesttimeout="25"/>
<cfcontent type="application/json" reset="true"/><cfscript>
report={};opts={datasource="runnerhub",timeout=10};
transaction {
 queryExecute("SET TRANSACTION READ ONLY",{},opts);
 queryExecute("SET LOCAL statement_timeout='8s'",{},opts);
 report.columns=queryExecute("SELECT table_schema,table_name,column_name,data_type,udt_name,is_nullable FROM information_schema.columns WHERE (table_schema='public' AND table_name IN ('tb_contas','tb_usuarios') AND column_name='data_criacao') OR (table_schema='public' AND table_name='tb_usuarios_gestao') OR (table_schema='ads' AND table_name='daily_metrics') OR (table_schema='audience' AND table_name='events' AND column_name IN ('occurred_at','event_name','visitor_id','environment','is_internal')) ORDER BY table_schema,table_name,ordinal_position",{},opts);
 report.primary_keys=queryExecute("SELECT c.table_schema,c.table_name,k.column_name FROM information_schema.table_constraints c JOIN information_schema.key_column_usage k ON k.constraint_schema=c.constraint_schema AND k.constraint_name=c.constraint_name AND k.table_name=c.table_name WHERE c.constraint_type='PRIMARY KEY' AND c.table_schema='public' AND c.table_name='tb_usuarios_gestao' ORDER BY k.ordinal_position",{},opts);
 report.timezone=queryExecute("SELECT current_setting('TimeZone') AS session_timezone,(SELECT reset_val FROM pg_settings WHERE name='TimeZone') AS reset_timezone,(SELECT source FROM pg_settings WHERE name='TimeZone') AS source",{},opts);
 report.timezone_settings=queryExecute("SELECT CASE WHEN s.setdatabase=0 THEN 'all databases' ELSE d.datname END AS database_scope,CASE WHEN s.setrole=0 THEN 'all roles' ELSE r.rolname END AS role_scope,setting FROM pg_db_role_setting s LEFT JOIN pg_database d ON d.oid=s.setdatabase LEFT JOIN pg_roles r ON r.oid=s.setrole CROSS JOIN LATERAL unnest(s.setconfig) AS setting WHERE lower(setting) LIKE 'timezone=%'",{},opts);
}
writeOutput(serializeJSON(report));</cfscript>'''
try:
    (work / '.htaccess').write_text('Require local\n')
    (work / 'Application.cfc').write_text(
        'component {this.name="' + work.name + '";this.datasource="runnerhub";'
        'boolean function onRequestStart(string target){'
        'if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||'
        'compare(form.key ?: "","' + token + '")!=0){cfheader(statuscode=404);abort;}'
        'return true;}}')
    (work / 'run.cfm').write_text(body)
    for path in work.iterdir():
        os.chmod(path, 0o644)
    result = subprocess.run([
        'curl', '-sS', '--max-time', '23', '--resolve',
        'business.roadrunners.run:443:127.0.0.1', '-X', 'POST',
        '--data-urlencode', 'key=' + token,
        'https://business.roadrunners.run/_codex/' + work.name + '/run.cfm',
    ], capture_output=True, text=True, timeout=26)
    if result.returncode:
        raise RuntimeError('Schema request failed; transport output withheld')
    try:
        report = json.loads(result.stdout)
    except ValueError:
        raise RuntimeError('Schema request returned non-JSON; response withheld')
    report.update(read_only=True, runtime_files_changed=False)
finally:
    shutil.rmtree(work)
print(json.dumps(report, indent=2))
