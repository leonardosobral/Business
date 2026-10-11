from pathlib import Path
import json,shlex,subprocess
P=Path(__file__).resolve().parent;ROOT=P.parents[2]
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT jsonb_agg(jsonb_build_object('column',column_name,'nullable',is_nullable))::text AS payload FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas' AND column_name IN('nome_evento','data_inicial','cidade','estado')"""
remote=helpers+'''
p=json.load(sys.stdin);r=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report={schema=deserializeJSON(q.payload[1])};}');print(json.dumps(r))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=60)
assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(P/'schema.json').write_text(json.dumps(r,indent=2));print(json.dumps(r['SCHEMA'],ensure_ascii=False))
