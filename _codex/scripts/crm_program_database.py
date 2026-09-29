"""Guarded additive Todo Santo Dia commerce migrations via a one-use Business loopback probe."""
from pathlib import Path
import base64
import hashlib
import json
import secrets
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / '.superpowers/sdd/2026-09-25-crm-todo-santo-dia-continuo'
RR = ROOT.parent / 'RoadRunners'
NAMES = ('2026-09-25_crm_checkout_identity', '2026-09-25_crm_conversion_ledger', '2026-09-25_crm_tsd_program')
FILES = [RR / '_codex/sql/migrations' / f'{name}.sql' for name in NAMES]
HASHES = [hashlib.sha256(path.read_bytes()).hexdigest() for path in FILES]
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run']
mode = sys.argv[1] if len(sys.argv) == 2 else ''
if mode not in ('check', 'apply', 'verify'):
    raise SystemExit('mode: check | apply | verify')
if mode == 'apply':
    receipt = LEDGER / 'program-database-check.json'
    if not receipt.exists() or json.loads(receipt.read_text()).get('hashes') != HASHES:
        raise SystemExit('matching read-only check receipt required before apply')


def statements(sql):
    """Split trusted migration files on top-level semicolons, retaining DO $$ blocks."""
    result, part, index, quote = [], [], 0, ''
    while index < len(sql):
        c = sql[index]
        if quote == '$$' and sql.startswith('$$', index):
            part.append('$$'); index += 2; quote = ''; continue
        if quote == "'" and c == "'" and sql[index:index + 2] == "''":
            part.append("''"); index += 2; continue
        if quote and c == quote:
            quote = ''
        elif not quote and sql.startswith('$$', index):
            part.append('$$'); index += 2; quote = '$$'; continue
        elif not quote and c in ("'", '"'):
            quote = c
        elif not quote and c == ';':
            value = ''.join(part).strip()
            if value: result.append(value)
            part = []; index += 1; continue
        part.append(c); index += 1
    tail = ''.join(part).strip()
    if tail: result.append(tail)
    if quote: raise SystemExit('unclosed quote in migration')
    return result


migrations = [{'version': name, 'checksum': checksum, 'statements': statements(path.read_text())}
              for name, checksum, path in zip(NAMES, HASHES, FILES)]
nonce = secrets.token_hex(32)
name = '__crm_program_db_' + secrets.token_hex(12) + '.cfm'
encoded = base64.b64encode(json.dumps(migrations).encode()).decode()
source = '''<cfsetting showdebugoutput="false" requesttimeout="110"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function q(required string sql,struct params={}){return queryExecute(sql,params,{datasource='runner_dba',timeout=60});}
function inspect(required array migrations){
 var tables={checkout=q("SELECT to_regclass('crm_interno.checkout_order_identity') IS NOT NULL AS present").present,
  ledger=q("SELECT to_regclass('crm_interno.conversion_order_state') IS NOT NULL AS present").present,
  audit=q("SELECT to_regclass('crm_interno.pagarme_order_audit') IS NOT NULL AS present").present,
  coverage=q("SELECT to_regclass('crm_interno.program_coverage') IS NOT NULL AS present").present};
 var markers=[];
 for(var migration in migrations){var row=q('SELECT checksum FROM crm_interno.schema_migrations WHERE version=:version',{version={value=migration.version,cfsqltype='cf_sql_varchar'}});arrayAppend(markers,{version=migration.version,found=row.recordCount==1,matches=row.recordCount==1&&row.checksum==migration.checksum});}
 return {tables=tables,markers=markers};
}
try{
 migrations=deserializeJSON(toString(binaryDecode('PAYLOAD','base64')));mode='MODE';
 if(mode=='apply'){
  transaction {
   state=inspect(migrations);
   if(state.tables.checkout||state.tables.ledger||state.tables.audit||state.tables.coverage)throw(message='Existing or partial commerce schema');
   for(index=1;index<=arrayLen(migrations);index++){
    migration=migrations[index];
    if(state.markers[index].found)throw(message='Existing migration marker');
    for(sql in migration.statements)q(sql);
    q('INSERT INTO crm_interno.schema_migrations(version,checksum) VALUES(:version,:checksum)',{version={value=migration.version,cfsqltype='cf_sql_varchar'},checksum={value=migration.checksum,cfsqltype='cf_sql_varchar'}});
   }
  }
 }
 transaction {q('SET TRANSACTION READ ONLY');state=inspect(migrations);}
 report={mode=mode,tables=state.tables,markers=state.markers};
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfheader(statuscode=500);cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message}));}
</cfscript>'''.replace('NONCE', nonce).replace('PAYLOAD', encoded).replace('MODE', mode)
remote = f'''from pathlib import Path
import json,os,subprocess
p=Path('/var/www/business.roadrunners.run')/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--fail','--silent','--show-error','--max-time','110','--resolve','business.roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://business.roadrunners.run/'+{name!r}],capture_output=True,text=True,timeout=115)
 assert r.returncode==0,r.stderr
 print(json.dumps(json.loads(r.stdout)))
finally:p.unlink(missing_ok=True)
'''
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], capture_output=True, text=True, timeout=125)
if result.returncode:
    raise SystemExit(result.stderr[-1200:])
def lower_keys(value):
    if isinstance(value, dict):
        return {str(key).lower(): lower_keys(item) for key, item in value.items()}
    if isinstance(value, list):
        return [lower_keys(item) for item in value]
    return value


data = lower_keys(json.loads(result.stdout))
if 'error' in data:
    raise SystemExit(str(data))
data['hashes'] = HASHES
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / f'program-database-{mode}.json').write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps({'mode': mode, 'tables': data['tables'], 'markers': data['markers'], 'hashes': HASHES}))
if mode == 'verify' and (not all(data['tables'].values()) or not all(item['matches'] for item in data['markers'])):
    raise SystemExit('Commerce migration verification failed')
