from pathlib import Path
import json,subprocess,shlex
S=Path(__file__).resolve().parent
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def legacy_sql(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT jsonb_build_object('families',(SELECT jsonb_agg(x) FROM (SELECT a.tag,a.nome_evento_agregado,a.tipo_agregacao,count(*) AS editions,min(e.data_inicial) FILTER(WHERE e.data_inicial>=current_date) AS next_date FROM tb_agrega_eventos a JOIN tb_evento_corridas e ON e.id_agrega_evento=a.id_agrega_evento WHERE a.tipo_agregacao='maratona' GROUP BY a.tag,a.nome_evento_agregado,a.tipo_agregacao ORDER BY count(*) DESC LIMIT 50) x),'columns',(SELECT jsonb_agg(column_name) FROM information_schema.columns WHERE table_name='vw_evento_corridas' AND column_name IN ('tag','tag_cidade','id_evento','cidade','estado','distancias','data_inicial','data_final','pais','site','link_inscricao')))::text AS payload"""
remote=helpers+'\np=json.load(sys.stdin);print(json.dumps(bridge(Path("/var/www/business.roadrunners.run"),raw_query(p["sql"])+"report=deserializeJSON(q.payload[1]);")))'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=70)
assert r.returncode==0,r.stderr[-1200:]
d=json.loads(r.stdout);(S/'inventory.json').write_text(json.dumps(d,ensure_ascii=False,indent=2));print(json.dumps(d,ensure_ascii=False))
