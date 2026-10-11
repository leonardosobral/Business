from pathlib import Path
import json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business');p=Path(__file__).resolve().parent
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('localities',jsonb_agg(jsonb_build_object('id',id_localidade,'city',nome_cidade,'state',estado)))::text payload FROM tbbi_dim_localidade l WHERE upper(estado)='RJ' AND get_tag(nome_cidade) IN ('pirai','barra-do-pirai')"
remote=helpers+'\np=json.load(sys.stdin)\nr=bridge(ROOT,raw_query(p["sql"])+"report=deserializeJSON(q.payload[1]);")\nprint(json.dumps(r))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=100)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);(p/'target-geography.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
