"""Return only safe stopReason codes from recent run responses; never the raw response."""
from pathlib import Path
import json,shlex,subprocess
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql=r'''SELECT jsonb_build_object('measured_at',now(),'runs',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]') FROM (
SELECT started_at,finished_at,status,http_status,substring(response_preview FROM '(?i)"stopreason"\s*:\s*"([a-z_]{1,80})"') AS stop_reason
FROM public.tb_cron_job_runs WHERE id_cron_job=15 ORDER BY started_at DESC LIMIT 5) r))::text AS payload'''
remote=helpers+'''payload=json.load(sys.stdin);print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=120)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
result=json.loads(cp.stdout);(STAGE/'cron-diagnosis.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
