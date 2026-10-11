from pathlib import Path
import json,shlex,subprocess
P=Path(__file__).resolve().parent;ROOT=P.parents[2]
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""EXPLAIN (ANALYZE,FORMAT JSON) SELECT EXISTS(SELECT 1 FROM tb_evento_corridas WHERE ativo=true AND left(nome_evento,50)=left('CIRCUITO DE CORRIDAS - CORRER É MASSA APOSTOU LOTERIAS - ETAPA APUCARANA',50) AND nome_evento<>'CIRCUITO DE CORRIDAS - CORRER É MASSA APOSTOU LOTERIAS - ETAPA APUCARANA') AS truncated_name, EXISTS(SELECT 1 FROM tb_evento_corridas WHERE ativo=true AND left(nome_evento,50)=left('CIRCUITO DE CORRIDAS - CORRER É MASSA APOSTOU LOTERIAS - ETAPA APUCARANA',50) AND nome_evento<>'CIRCUITO DE CORRIDAS - CORRER É MASSA APOSTOU LOTERIAS - ETAPA APUCARANA' AND data_inicial='2026-10-17' AND coalesce(cidade,'')='Apucarana' AND coalesce(estado,'')='PR') AS ambiguous_context"""
remote=helpers+'''
p=json.load(sys.stdin);r=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report={plan=deserializeJSON(q["QUERY PLAN"][1])};}');print(json.dumps(r))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=60)
assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(P/'query-cost.json').write_text(json.dumps(r,indent=2));print(json.dumps(r['PLAN'][0],ensure_ascii=False))
