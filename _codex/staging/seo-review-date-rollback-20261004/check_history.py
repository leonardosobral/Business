from pathlib import Path
import json,shlex,subprocess
s=Path(__file__).resolve().parent;r=Path.cwd();helpers=(r/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('course_reversions',(SELECT count(DISTINCT id_entidade) FROM tb_evento_fatos_historico WHERE id_entidade IN (65367,65368,67993) AND entidade='percurso' AND registrado_em>clock_timestamp()-interval '15 minutes' AND alteracoes ? 'data_percurso'),'current_regulation',(SELECT count(*) FROM tb_evento_fatos_historico WHERE id_evento=39867 AND registrado_em>clock_timestamp()-interval '15 minutes' AND alteracoes ? 'url_regulamento'))::text payload"
remote=helpers+'\np=json.load(sys.stdin);print(json.dumps(bridge(ROOT,raw_query(p["sql"])+"report=deserializeJSON(q.payload[1]);")))'
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=110)
if p.returncode:raise RuntimeError(p.stderr[-1200:])
r=json.loads(p.stdout);(s/'history.json').write_text(json.dumps(r,indent=2));print(json.dumps(r));assert r['course_reversions']==3 and r['current_regulation']==1
