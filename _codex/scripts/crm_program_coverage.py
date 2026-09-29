"""Guarded monthly Pagar.me coverage windows; no payment facts or contacts are written."""
from pathlib import Path
import json
import secrets
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / '.superpowers/sdd/2026-09-25-crm-todo-santo-dia-continuo'
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']
mode = sys.argv[1] if len(sys.argv) == 2 else ''
if mode not in ('check', 'seed', 'verify'):
    raise SystemExit('mode: check | seed | verify')
if mode == 'seed':
    previous = LEDGER / 'program-coverage-check.json'
    if not previous.exists() or json.loads(previous.read_text()).get('windows') != 0:
        raise SystemExit('empty production coverage check required before seeding')
nonce = secrets.token_hex(32)
name = '__crm_program_coverage_' + secrets.token_hex(12) + '.cfm'
source = '''<cfsetting showdebugoutput="false" requesttimeout="90"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function q(required string sql){return queryExecute(sql,{}, {datasource='runner_dba',timeout=60});}
try{
 if('MODE'=='seed')transaction{
  existing=q("SELECT count(*) AS n FROM crm_interno.program_coverage WHERE source='pagarme_historical'");
  if(existing.n!=0)throw(message='Existing historical coverage');
  q("WITH months AS (SELECT generate_series(DATE '2020-01-01',date_trunc('month',(now() AT TIME ZONE 'America/Sao_Paulo')::date-1)::date,interval '1 month')::date AS month_start), windows AS (SELECT month_start,least((month_start+interval '1 month - 1 day')::date,(now() AT TIME ZONE 'America/Sao_Paulo')::date-1) AS month_end FROM months) INSERT INTO crm_interno.program_coverage(source,window_start,window_end,status) SELECT 'pagarme_historical',month_start,month_end,'running' FROM windows");
 }
 transaction{q('SET TRANSACTION READ ONLY');state=q("SELECT count(*) AS windows,count(*) FILTER(WHERE status='running') AS running,count(*) FILTER(WHERE status='complete') AS complete,min(window_start) AS from_day,max(window_end) AS through_day,coalesce(sum(scanned),0) AS scanned,coalesce(sum(accepted),0) AS accepted,coalesce(sum(pending),0) AS pending FROM crm_interno.program_coverage WHERE source='pagarme_historical'");}
 report={mode='MODE',windows=state.windows,running=state.running,complete=state.complete,from_day=isDate(state.from_day)?dateFormat(state.from_day,'yyyy-mm-dd'):'',through_day=isDate(state.through_day)?dateFormat(state.through_day,'yyyy-mm-dd'):'',scanned=state.scanned,accepted=state.accepted,pending=state.pending};
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfheader(statuscode=500);cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message}));}
</cfscript>'''.replace('NONCE', nonce).replace('MODE', mode)
remote = f'''from pathlib import Path
import json,os,subprocess
p=Path('/var/www/business.roadrunners.run')/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--silent','--show-error','--max-time','90','--resolve','business.roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://business.roadrunners.run/'+{name!r}],capture_output=True,text=True,timeout=95)
 assert r.returncode==0,r.stderr
 print(json.dumps(json.loads(r.stdout)))
finally:p.unlink(missing_ok=True)
'''
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], capture_output=True,
                        text=True, timeout=105)
if result.returncode:
    raise SystemExit(result.stderr[-1000:])
data = {str(key).lower(): value for key, value in json.loads(result.stdout).items()}
if 'error' in data:
    raise SystemExit(str(data))
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / f'program-coverage-{mode}.json').write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps(data))
if mode == 'verify' and (data['windows'] < 1 or data['from_day'] != '2020-01-01'):
    raise SystemExit('historical coverage window verification failed')
