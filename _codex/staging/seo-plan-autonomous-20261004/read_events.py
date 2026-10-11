from pathlib import Path
import json,shlex,subprocess
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
sql="""SELECT coalesce(jsonb_agg(jsonb_build_object('id_evento',id_evento,'nome_evento',nome_evento,'tag',tag,'data_inicial',data_inicial,'data_final',data_final,'cidade',cidade,'estado',estado,'ativo',ativo,'url_inscricao',url_inscricao,'url_hotsite',url_hotsite,'url_regulamento',url_regulamento,'descricao',descricao,'descricao_original',descricao_original,'status_evento',status_evento,'id_agrega_evento',id_agrega_evento) ORDER BY tag),'[]')::text AS payload
FROM tb_evento_corridas WHERE tag IN ('2026-4-corrida-do-turismo-abavse-2026','2027-4-corrida-do-turismo-abavse-2026','2026-maratona-de-aracaju-2026','2026-live-run-xp-porto-alegre-2026','2026-sp-city-marathon')"""
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')").replace('runner_dba','runnerhub')
remote=helpers+'''\np=json.load(sys.stdin);body='transaction {'+raw_query("SET TRANSACTION READ ONLY; SET LOCAL statement_timeout='20s'",'qLimits')+raw_query(p['sql'])+'}report={events=deserializeJSON(q.payload[1])};';print(json.dumps(bridge(Path('/var/www/business.roadrunners.run'),body)))'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=85)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);r={k.lower():v for k,v in r.items()};(STAGE/'selected-events.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
for e in r['events']:print(json.dumps({k:v for k,v in e.items() if 'descricao' not in k},ensure_ascii=False))
