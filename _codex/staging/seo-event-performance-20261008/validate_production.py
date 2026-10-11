from pathlib import Path
import hashlib,json,re,shlex,subprocess
S=Path(__file__).resolve().parent;B=S.parents[2];NAME='includes/backend/backend_evento.cfm'
cases=[('sao-silvestre','2026-101-corrida-internacional-de-sao-silvestre'),('jurere','2026-jurere-night-run-hard-rock-cafe-florianopolis-2026'),('maratona-florianopolis','lookup-florianopolis'),('maratona-rio','lookup-rio'),('empty-aggregate',None)]
def sql(group,tag):
    src=(S/group/'rr'/NAME).read_text();q=re.search(r'<cfquery name="qEventoEdicoes"[^>]*>(.*?)</cfquery>',src,re.S).group(1)
    q=re.sub(r'<cfqueryparam[^>]*value="#VARIABLES.eventRecordAssetsBaseUrl#"[^>]*/>',"'https://roadrunners.run/assets/paginas/'",q)
    aggregate="(SELECT id_agrega_evento FROM tb_evento_corridas WHERE tag='"+tag+"' LIMIT 1)" if tag else '-1'
    if tag=='lookup-florianopolis':aggregate="(SELECT id_agrega_evento FROM tb_evento_corridas WHERE id_agrega_evento>0 AND nome_evento ILIKE '%Maratona%Florian%' ORDER BY data_final DESC LIMIT 1)"
    if tag=='lookup-rio':aggregate="(SELECT id_agrega_evento FROM tb_evento_corridas WHERE id_agrega_evento>0 AND nome_evento ILIKE '%Maratona%Rio%' ORDER BY data_final DESC LIMIT 1)"
    q=re.sub(r'<cfqueryparam[^>]*value="#qEvento.id_agrega_evento#"[^>]*/>',aggregate,q);assert '<cf' not in q;return q
tests=[]
for name,tag in cases:
    q='WITH previous AS MATERIALIZED ('+sql('baseline',tag)+'), current AS MATERIALIZED ('+sql('candidate',tag)+') SELECT (SELECT count(*) FROM previous) AS previous_rows,(SELECT count(*) FROM current) AS current_rows,(SELECT count(*) FROM ((SELECT * FROM previous EXCEPT ALL SELECT * FROM current) UNION ALL (SELECT * FROM current EXCEPT ALL SELECT * FROM previous)) d) AS differences'
    tests.append(dict(name=name,sql=q))
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
code=helpers+'''
p=json.load(sys.stdin);body='report={checks=[]};transaction {'+raw_query("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY; SET LOCAL statement_timeout='20s'",'qLimits')
for item in p['tests']:
 body+=raw_query(item['sql'],'qCheck')+'arrayAppend(report.checks,{name="'+item['name']+'",previous_rows=qCheck.previous_rows[1],current_rows=qCheck.current_rows[1],differences=qCheck.differences[1]});'
body+='}';print(json.dumps(bridge(ROOT,body)))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(code)],input=json.dumps({'tests':tests}),capture_output=True,text=True,timeout=115)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout);failed=[x for x in r['CHECKS'] if x['DIFFERENCES']!=0 or x['PREVIOUS_ROWS']!=x['CURRENT_ROWS'] or (x['NAME']!='empty-aggregate' and x['CURRENT_ROWS']==0)]
r.update(failed=failed,source_hash=hashlib.sha256((S/'candidate/rr'/NAME).read_bytes()).hexdigest(),read_only=True,database_mutations=False)
(S/'production-equivalence.json').write_text(json.dumps(r,indent=2));print(json.dumps(r));assert not failed
