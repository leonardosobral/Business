from pathlib import Path
import json,shlex,subprocess
P=Path(__file__).resolve().parent;ROOT=P.parents[2]
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""EXPLAIN (ANALYZE,FORMAT JSON) WITH title_names AS (
                SELECT nome_evento, jsonb_agg(DISTINCT jsonb_build_object(
                       'name', nome_evento, 'city', coalesce(cidade, ''),
                       'state', coalesce(estado, ''), 'date', data_inicial::text
                )) AS variants
                FROM tb_evento_corridas
                WHERE ativo = true AND length(nome_evento) >= 50
                GROUP BY nome_evento
                -- Multiple dates already distinguish these names in the existing title rule.
                HAVING count(DISTINCT data_inicial) = 1
            )
            SELECT left(nome_evento, 50) AS name_prefix, jsonb_agg(variant)::text AS variants
            FROM title_names
            CROSS JOIN LATERAL jsonb_array_elements(title_names.variants) AS variant
            GROUP BY left(nome_evento, 50)
            HAVING count(DISTINCT nome_evento) > 1"""
remote=helpers+'''
p=json.load(sys.stdin);r=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report={plan=deserializeJSON(q["QUERY PLAN"][1])};}');print(json.dumps(r))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=60)
assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(P/'query-cost-final.json').write_text(json.dumps(r,indent=2));print(json.dumps(r['PLAN'][0],ensure_ascii=False))
