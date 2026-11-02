from pathlib import Path
import json,subprocess,shlex,sys
S=Path(__file__).resolve().parent
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def legacy_sql(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql=(S/(sys.argv[1]+'.sql')).read_text()
remote=helpers+'\np=json.load(sys.stdin);print(json.dumps(bridge(ROOT,raw_query(p["sql"])+"report=deserializeJSON(q.payload[1]);")))'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=80)
assert r.returncode==0,r.stderr[-2200:]
d=json.loads(r.stdout);(S/(sys.argv[1]+'.json')).write_text(json.dumps(d,ensure_ascii=False,indent=2));print(json.dumps(d,ensure_ascii=False)[:17000])
