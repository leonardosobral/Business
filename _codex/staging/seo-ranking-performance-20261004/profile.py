from pathlib import Path
import re,json,shlex,subprocess,sys
s=Path(__file__).resolve().parent;root=Path.cwd();mode=sys.argv[1]
source=(s/mode/'circuitocatarinense/corridaderua/index.cfm').read_text();sql=re.search(r'<cfquery name="qRankingCatarina">(.*?)</cfquery>',source,re.S).group(1).strip()
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
helpers=helpers.replace('runner_dba','runnerhub')
code=helpers+'''
p=json.load(sys.stdin)
body='transaction {'+raw_query("SET TRANSACTION READ ONLY; SET LOCAL statement_timeout='20s'",'qLimits')+raw_query('EXPLAIN (ANALYZE, FORMAT JSON) '+p['sql'],'qPlan')+'}plan=deserializeJSON(qPlan["QUERY PLAN"][1]);report={execution_ms=plan[1]["Execution Time"],rows=plan[1].Plan["Actual Rows"],nodes=[]};function walk(n){var x={};for(k in ["Node Type","Relation Name","Actual Loops","Actual Rows","Actual Total Time","Subplan Name"]){if(structKeyExists(n,k))x[k]=n[k];}arrayAppend(report.nodes,x);if(structKeyExists(n,"Plans")){for(c in n.Plans)walk(c);}}walk(plan[1].Plan);'
print(json.dumps(bridge(Path('/var/www/business.roadrunners.run'),body)))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=105)
if p.returncode:raise RuntimeError(p.stderr[-2500:])
r=json.loads(p.stdout);(s/(mode+'-profile.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
