"""Versioned Todo Santo Dia CRM migration through a guarded Business loopback probe."""
from pathlib import Path
import base64
import hashlib
import json
import secrets
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / '.superpowers/sdd/2026-09-24-crm-interno-evolucao'
SOURCE = ROOT.parent / 'RoadRunners/_codex/sql/migrations/2026-09-25_crm_challenge_signup.sql'
VERSION = '2026-09-25_crm_challenge_signup'
SQL = SOURCE.read_text()
CHECKSUM = hashlib.sha256(SQL.encode()).hexdigest()
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']
mode = sys.argv[1] if len(sys.argv) == 2 else ''
if mode not in ('check', 'apply', 'verify'):
    raise SystemExit('mode: check | apply | verify')
if mode == 'apply':
    receipt = LEDGER / 'r6-database-check.json'
    if not receipt.exists():
        raise SystemExit('Read-only check receipt is required before apply')
    checked = json.loads(receipt.read_text())
    if checked.get('version') != VERSION or checked.get('checksum') != CHECKSUM:
        raise SystemExit('Migration changed after read-only check')
    if checked.get('partial') or checked.get('applied'):
        raise SystemExit('Migration already present or partially installed')

nonce = secrets.token_hex(32)
name = '__crm_r6_database_' + secrets.token_hex(12) + '.cfm'
statements = [part.strip() for part in SQL.split(';') if part.strip()]
encoded = base64.b64encode(json.dumps(statements).encode()).decode()
source = '''<cfsetting showdebugoutput="false" requesttimeout="90"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function q(required string sql,struct params={}){return queryExecute(sql,params,{datasource='runner_dba',timeout=60});}
function inspect(required string version){
 var state={ledger=q("SELECT to_regclass('crm_interno.schema_migrations') IS NOT NULL AS present").present,
  source=q("SELECT to_regclass('crm_interno.challenge_signup_source') IS NOT NULL AS present").present,
  events=q("SELECT to_regclass('crm_interno.challenge_signup_events') IS NOT NULL AS present").present,
  index=q("SELECT to_regclass('crm_interno.crm_challenge_signup_campaign') IS NOT NULL AS present").present};
 state.marker=state.ledger?q("SELECT checksum FROM crm_interno.schema_migrations WHERE version=:v",{v={value=version,cfsqltype='cf_sql_varchar'}}):queryNew('checksum');
 state.signup_events=state.events?q("SELECT count(*) AS n FROM crm_interno.challenge_signup_events").n:0;
 state.attributed_signups=state.events?q("SELECT count(*) AS n FROM crm_interno.challenge_signup_events WHERE method='last_recorded_click_7d'").n:0;
 return state;
}
try{
 version='VERSION';checksum='CHECKSUM';mode='MODE';
 if(mode!='apply'){
  transaction {q('SET TRANSACTION READ ONLY');state=inspect(version);if(state.source)state.started=q("SELECT started_at FROM crm_interno.challenge_signup_source WHERE challenge_code='todosantodia'").recordCount==1;}
 }else{
  transaction {
   state=inspect(version);
   if(state.marker.recordCount || state.source || state.events || state.index)throw(message='Existing or partial R6 schema');
   for(sql in deserializeJSON(toString(binaryDecode('PAYLOAD','base64'))))q(sql);
   q("INSERT INTO crm_interno.schema_migrations(version,checksum) VALUES(:v,:c)",{v={value=version,cfsqltype='cf_sql_varchar'},c={value=checksum,cfsqltype='cf_sql_varchar'}});
  }
  transaction {q('SET TRANSACTION READ ONLY');state=inspect(version);state.started=q("SELECT started_at FROM crm_interno.challenge_signup_source WHERE challenge_code='todosantodia'").recordCount==1;}
 }
 if(state.marker.recordCount && state.marker.checksum!=checksum)throw(message='Migration checksum conflict');
 report={version=version,checksum=checksum,mode=mode,applied=state.marker.recordCount==1 && state.marker.checksum==checksum,source=state.source,events=state.events,index=state.index,started=structKeyExists(state,'started')&&state.started,signup_events=state.signup_events,attributed_signups=state.attributed_signups,partial=(state.source||state.events||state.index) && !state.marker.recordCount};
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfheader(statuscode=500);cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message}));}
</cfscript>'''.replace('NONCE', nonce).replace('VERSION', VERSION).replace('CHECKSUM', CHECKSUM).replace('MODE', mode).replace('PAYLOAD', encoded)
remote = f'''from pathlib import Path
import json,os,subprocess
p=Path('/var/www/business.roadrunners.run')/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--fail','--silent','--show-error','--max-time','90','--resolve','business.roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://business.roadrunners.run/'+{name!r}],capture_output=True,text=True,timeout=95)
 assert r.returncode==0,r.stderr
 print(json.dumps(json.loads(r.stdout)))
finally:p.unlink(missing_ok=True)
'''
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)],
                        capture_output=True, text=True, timeout=110)
if result.returncode:
    raise SystemExit(result.stderr[-1500:])
data = {key.lower(): value for key, value in json.loads(result.stdout).items()}
if 'error' in data:
    raise SystemExit(data)
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / f'r6-database-{mode}.json').write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps(data))
if mode == 'verify' and not all(data.get(key) for key in ('applied', 'source', 'events', 'index', 'started')):
    raise SystemExit('R6 migration verification failed')
