from pathlib import Path
import json,re,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[2];mode=sys.argv[1]
assert mode in ['baseline','candidate']
src=(S/'runtime'/mode/'includes/backend/backend_evento.cfm').read_text();q=re.search(r'<cfquery name="qEventoEdicoes"[^>]*>(.*?)</cfquery>',src,re.S)[1]
q=re.sub(r'<cfqueryparam[^>]*value="#VARIABLES.eventRecordAssetsBaseUrl#"[^>]*/>',"'https://roadrunners.run/assets/paginas/'",q)
q=re.sub(r'<cfqueryparam[^>]*value="#qEvento.id_agrega_evento#"[^>]*/>','49',q);assert '<cf' not in q
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')").replace('runner_dba','runnerhub')
remote=helpers+'''
p=json.load(sys.stdin)
body='transaction {'+raw_query("SET TRANSACTION READ ONLY; SET LOCAL statement_timeout='20s'",'limits')+raw_query('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) '+p['sql'],'qPlan')+'}plan=deserializeJSON(qPlan["QUERY PLAN"][1]);report={execution_ms=plan[1]["Execution Time"],rows=plan[1].Plan["Actual Rows"],nodes=[]};function walk(n){var x={};for(k in ["Node Type","Relation Name","Actual Loops","Actual Rows","Actual Total Time","Subplan Name","Shared Hit Blocks","Shared Read Blocks"]){if(structKeyExists(n,k))x[k]=n[k];}arrayAppend(report.nodes,x);if(structKeyExists(n,"Plans")){for(c in n.Plans)walk(c);}}walk(plan[1].Plan);'
print(json.dumps(bridge(ROOT,body)))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(dict(sql=q)),capture_output=True,text=True,timeout=80);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);r={k.lower():v for k,v in r.items()};(S/('plan-'+mode+'.json')).write_text(json.dumps(r,indent=2))
print(json.dumps(dict(execution_ms=r['execution_ms'],rows=r['rows'],costliest=sorted(r['nodes'],key=lambda n:n.get('Actual Loops',0)*n.get('Actual Total Time',0),reverse=True)[:18]),indent=2))
