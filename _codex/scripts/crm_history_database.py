"""Allowlisted additive CRM migrations through a one-use loopback CFML probe."""
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
SOURCE = ROOT.parent / 'RoadRunners/_codex/sql/migrations/2026-09-24_crm_audience_history.sql'
VERSION = '2026-09-24_crm_audience_history'
SQL = SOURCE.read_text()
CHECKSUM = hashlib.sha256(SQL.encode()).hexdigest()
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']
mode = sys.argv[1] if len(sys.argv) == 2 else ''
if mode not in ('check', 'apply', 'verify', 'smoke'):
    raise SystemExit('mode: check | apply | verify | smoke')
if mode == 'apply':
    receipt = LEDGER / 'history-database-check.json'
    if not receipt.exists():
        raise SystemExit('Read-only check receipt is required before apply')
    checked = json.loads(receipt.read_text())
    if checked.get('checksum') != CHECKSUM or checked.get('version') != VERSION:
        raise SystemExit('Migration changed after read-only check')

nonce = secrets.token_hex(32)
name = '__crm_evolution_' + secrets.token_hex(12) + '.cfm'
encoded = base64.b64encode(SQL.encode()).decode()
source = '''<cfsetting showdebugoutput="false" requesttimeout="110"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function q(required string sql,struct params={}){return queryExecute(sql,params,{datasource='runner_dba',timeout=90});}
try{
 version='VERSION';checksum='CHECKSUM';mode='MODE';
 hasLedger=q("SELECT to_regclass('crm_interno.schema_migrations') IS NOT NULL AS present").present;
 hasTable=q("SELECT to_regclass('crm_interno.audience_snapshots') IS NOT NULL AS present").present;
 hasMembers=q("SELECT to_regclass('crm_interno.audience_snapshot_members') IS NOT NULL AS present").present;
 marker=hasLedger?q("SELECT checksum FROM crm_interno.schema_migrations WHERE version=:version",{version={value=version,cfsqltype='cf_sql_varchar'}}):queryNew('checksum');
 if(marker.recordCount && marker.checksum!=checksum)throw(message='Migration checksum conflict');
 if(mode=='apply' && !marker.recordCount){
  if(!hasLedger||hasTable||hasMembers)throw(message='Partial or unrecorded history schema; manual review required');
  transaction{
   q(toString(binaryDecode('PAYLOAD','base64')));
   q("INSERT INTO crm_interno.schema_migrations(version,checksum) VALUES(:version,:checksum)",{version={value=version,cfsqltype='cf_sql_varchar'},checksum={value=checksum,cfsqltype='cf_sql_varchar'}});
  }
 }
 hasLedger=q("SELECT to_regclass('crm_interno.schema_migrations') IS NOT NULL AS present").present;
 hasTable=q("SELECT to_regclass('crm_interno.audience_snapshots') IS NOT NULL AS present").present;
 hasMembers=q("SELECT to_regclass('crm_interno.audience_snapshot_members') IS NOT NULL AS present").present;
 marker=hasLedger?q("SELECT checksum FROM crm_interno.schema_migrations WHERE version=:version",{version={value=version,cfsqltype='cf_sql_varchar'}}):queryNew('checksum');
 report={version=version,checksum=checksum,applied=marker.recordCount==1&&marker.checksum==checksum,snapshots=hasTable,members=hasMembers,mode=mode};
 if(report.applied){report.rows=q("SELECT count(*) n FROM crm_interno.audience_snapshots").n;report.history_index=q("SELECT to_regclass('crm_interno.crm_audience_snapshots_history') IS NOT NULL AS present").present;report.member_index=q("SELECT to_regclass('crm_interno.crm_audience_snapshot_members_user') IS NOT NULL AS present").present;}
 if(mode=='smoke'){
  report.audiences=q("SELECT count(*) n FROM crm_interno.audiences WHERE archived_at IS NULL").n;
  a=q("SELECT id,current_version FROM crm_interno.audiences WHERE archived_at IS NULL AND current_version>0 ORDER BY id LIMIT 1");
  if(a.recordCount){report.history=new services.crm.CrmAudienceHistoryService().init().history(a.id,30);report.history_checked=true;}
  report.calendar=new services.crm.CrmPlanningService().init().calendar('2026-09-24','2026-10-01','',1).total;
 }
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message}));}
</cfscript>'''.replace('NONCE', nonce).replace('VERSION', VERSION).replace('CHECKSUM', CHECKSUM).replace('MODE', mode).replace('PAYLOAD', encoded)
remote = f'''from pathlib import Path
import json,os,subprocess
p=Path('/var/www/roadrunners.com.br')/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--silent','--show-error','--max-time','110','--resolve','roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://roadrunners.run/'+{name!r}],capture_output=True,text=True,timeout=115)
 assert r.returncode==0,r.stderr
 print(json.dumps(json.loads(r.stdout)))
finally:p.unlink(missing_ok=True)
'''
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], capture_output=True,
                        text=True, timeout=125)
if result.returncode:
    print(result.stderr[-2500:], file=sys.stderr)
    raise SystemExit(result.returncode)
data = json.loads(result.stdout)
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / ('history-database-' + mode + '.json')).write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps(data))
if 'error' in data or (mode == 'verify' and not (data.get('applied') and data.get('snapshots') and data.get('members') and data.get('history_index') and data.get('member_index'))):
    raise SystemExit(1)
