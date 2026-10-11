from pathlib import Path
import json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business');p=Path(__file__).resolve().parent
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('role',(SELECT jsonb_build_object('name',rolname,'superuser',rolsuper) FROM pg_roles WHERE rolname=current_user),'can_set_runner',pg_has_role(current_user,'runner','SET'),'default_namespaces',(SELECT jsonb_agg(jsonb_build_object('namespace',nspname,'acl',nspacl)) FROM pg_namespace WHERE oid IN (6948641,7044987) OR nspname='public'))::text payload"
remote=helpers+'\np=json.load(sys.stdin)\nr=bridge(ROOT,raw_query(p["sql"])+"report=deserializeJSON(q.payload[1]);")\nprint(json.dumps(r))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=100)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);(p/'capabilities.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
