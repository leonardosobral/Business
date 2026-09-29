"""Move the collector boundary to the verified handler deployment; preserve all logs/history."""
from pathlib import Path
import json,subprocess,shlex
root=Path(__file__).resolve().parents[2]
source=(root/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
source+='''
root=Path('/var/www/business.roadrunners.run');stage=Path('/var/backups/business-error-triage-recent-20260928')
assert (stage/'published.json').exists(),'Runtime publication required'
if (stage/'cutoff-applied.json').exists():raise RuntimeError('Cutoff already applied')
read_body="report={};q=queryExecute(\\"SELECT to_char(started_at,'YYYY-MM-DD HH24:MI:SS.US') AS started_at FROM tb_error_collector WHERE id=1\\",{},{datasource=\\"runner_dba\\"});report.started_at=q.started_at[1];"
before=bridge(root,read_body)
backup=stage/'collector-before.json'
with backup.open('x') as f:json.dump(before,f)
old=before.get('STARTED_AT',before.get('started_at'));assert old.startswith('2026-09-19 21:40:47'), 'Concurrent cutoff change'
body="transaction {queryExecute(\\"SET LOCAL lock_timeout='2s'\\",{},{datasource=\\"runner_dba\\"});q=queryExecute(\\"UPDATE tb_error_collector SET started_at=timestamp '2026-09-26 22:39:58',updated_at=now() WHERE id=1 AND started_at=CAST(:old AS timestamp) RETURNING to_char(started_at,'YYYY-MM-DD HH24:MI:SS') AS started_at\\",{old={value=\\""+old+"\\",cfsqltype=\\"cf_sql_varchar\\"}},{datasource=\\"runner_dba\\"});if(q.recordCount!=1)throw(message=\\"Collector changed concurrently\\");report={started_at=q.started_at[1],history_preserved=true};}"
result=bridge(root,body);(stage/'cutoff-applied.json').write_text(json.dumps(result));print(json.dumps(result))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],capture_output=True,text=True,timeout=110)
print(p.stdout);print(p.stderr[-1500:] if p.returncode else '')
if p.returncode==0:(root/'_codex/staging/error-triage-recent/cutoff-applied.json').write_text(p.stdout)
raise SystemExit(p.returncode)
