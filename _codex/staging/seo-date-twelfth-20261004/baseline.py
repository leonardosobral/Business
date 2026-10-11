from pathlib import Path
import json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business');p=Path(__file__).resolve().parent
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('events',(SELECT jsonb_agg(to_jsonb(x) ORDER BY id_evento) FROM (SELECT id_evento,nome_evento,tag,cidade,estado,categorias,url_hotsite,url_inscricao,data_inicial,data_final,url_regulamento,descricao,descricao_en,descricao_es,descricao_traducoes_meta,md5(to_jsonb(e)::text) row_hash FROM tb_evento_corridas e WHERE id_evento IN (43140,43541,45366,43854,43166,41908))x),'routes',(SELECT jsonb_agg(to_jsonb(p)||jsonb_build_object('row_hash',md5(to_jsonb(p)::text)) ORDER BY id_evento_percurso) FROM tb_evento_corridas_percursos p WHERE id_evento IN (43140,43541,45366,43854,43166,41908)))::text payload"
remote=helpers+'\np=json.load(sys.stdin)\nr=bridge(ROOT,raw_query(p["sql"])+"report=deserializeJSON(q.payload[1]);")\nprint(json.dumps(r))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=100)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);(p/'baseline-data.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps({'events':len(r['events']),'routes':len(r['routes'])}))
