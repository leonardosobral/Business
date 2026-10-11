from pathlib import Path
import json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business');p=Path(__file__).resolve().parent
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('current',(SELECT jsonb_build_object('cidade',cidade,'estado',estado,'id_localidade',id_localidade,'cod_cidade',cod_cidade,'coordenadas',coordenadas,'endereco',endereco,'full_text',nome_evento_full_text) FROM tb_evento_corridas WHERE id_evento=45651),'functions',(SELECT jsonb_agg(pg_get_functiondef(oid)) FROM pg_proc WHERE proname IN ('preencher_id_localidade_evento','trg_atualiza_nome_evento_full_text','grava_evento_corridas_percursos')))::text payload"
remote=helpers+'\np=json.load(sys.stdin)\nr=bridge(ROOT,raw_query(p["sql"])+"report=deserializeJSON(q.payload[1]);")\nprint(json.dumps(r))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=100)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);(p/'current-geography-functions.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
