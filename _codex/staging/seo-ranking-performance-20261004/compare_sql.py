from pathlib import Path
import re,json,shlex,subprocess
s=Path(__file__).resolve().parent;root=Path.cwd()
def sql(mode):return re.search(r'<cfquery name="qRankingCatarina">(.*?)</cfquery>',(s/mode/'circuitocatarinense/corridaderua/index.cfm').read_text(),re.S).group(1).strip().rstrip(';')
a=sql('baseline');b=sql('candidate')
query='WITH old AS MATERIALIZED ('+a+'), new AS MATERIALIZED ('+b+'''), diff AS ((SELECT * FROM old EXCEPT ALL SELECT * FROM new) UNION ALL (SELECT * FROM new EXCEPT ALL SELECT * FROM old))
SELECT jsonb_build_object('old_rows',(SELECT count(*) FROM old),'new_rows',(SELECT count(*) FROM new),'different_rows',(SELECT count(*) FROM diff),'old_hash',(SELECT md5(string_agg(md5(to_jsonb(x)::text),'' ORDER BY md5(to_jsonb(x)::text))) FROM old x),'new_hash',(SELECT md5(string_agg(md5(to_jsonb(x)::text),'' ORDER BY md5(to_jsonb(x)::text))) FROM new x))::text payload'''
# Synthetic scoring cases catch duplicated results, multiple observations, wrong distances,
# absent users, null observations and unrelated events. No real athlete data involved.
cte=b[:b.index('SELECT *,')].strip();cte=cte.removeprefix('WITH ')
fixtures="""WITH desafios(id_usuario,desafio) AS (VALUES (1,'catarinensecorridaderua'),(2,'catarinensecorridaderua'),(1,'catarinensecorridaderua'),(99,'other')), tb_resultados(id_evento,num_peito,id_usuario,percurso) AS (VALUES
('35612',1,1,21),('35612',1,1,21),('35095',2,1,21),('37006',6,1,21),
('35612',9,2,5),('37004',3,2,21),('other',8,2,21),('37085',4,NULL::int,21)),
tb_resultados_obs(id_evento,num_peito,obs) AS (VALUES
('35612',1,'3'),('35612',1,'4'),('35095',2,'3'),('37006',6,NULL::text),
('35612',9,'100'),('37004',3,'5'),('other',8,'100'),('37085',4,'8')), """+cte+""", expected(id_usuario,pontos_1,pontos_2,pontos_3,pontos_4,pontos_5,pontos_6) AS (VALUES (1,14,3,0,0,0,0),(2,0,0,5,0,0,0)), actual AS (SELECT id_usuario,coalesce(pontos_1,0),coalesce(pontos_2,0),coalesce(pontos_3,0),coalesce(pontos_4,0),coalesce(pontos_5,0),coalesce(pontos_6,0) FROM pontuacoes WHERE id_usuario IS NOT NULL), diff AS ((SELECT * FROM actual EXCEPT ALL SELECT * FROM expected) UNION ALL (SELECT * FROM expected EXCEPT ALL SELECT * FROM actual)) SELECT count(*) AS differences FROM diff"""
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
helpers=helpers.replace('runner_dba','runnerhub')
remote=helpers+'''\np=json.load(sys.stdin)
body='transaction {'+raw_query("SET TRANSACTION READ ONLY; SET LOCAL statement_timeout='30s'",'qLimits')+raw_query(p['compare'],'qCmp')+raw_query(p['synthetic'],'qSynthetic')+'}report=deserializeJSON(qCmp.payload[1]);report.synthetic_differences=qSynthetic.differences[1];'
print(json.dumps(bridge(Path('/var/www/business.roadrunners.run'),body)))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'compare':query,'synthetic':fixtures}),capture_output=True,text=True,timeout=110)
if p.returncode:raise RuntimeError(p.stderr[-2500:])
r=json.loads(p.stdout);r={k.lower():v for k,v in r.items()};assert r['old_rows']==r['new_rows'] and r['different_rows']==0 and r['old_hash']==r['new_hash'] and r['synthetic_differences']==0,r
(s/'sql-equivalence.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
