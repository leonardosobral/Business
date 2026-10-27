from pathlib import Path
import base64,json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business')
helper=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT proname, prosrc, pg_get_userbyid(proowner) AS owner, prosecdef, proconfig FROM pg_proc WHERE oid IN ('ads.invalidate_campaign_review_on_edit()'::regprocedure,'ads.increase_campaign_budget(uuid,bigint,integer,numeric,numeric)'::regprocedure)"
body='transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{},{datasource="runner_dba",timeout=15});}report={rows=[]};for(r in q)arrayAppend(report.rows,r);' 
remote=helper+'\nr=bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')\n'
remote+='print(json.dumps(r))\n'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=80)
if r.returncode:raise SystemExit(r.stderr[-1500:])
result=json.loads(r.stdout)
import re
expected=re.findall(r'AS \$function\$(.*?)\$function\$',(root/'_codex/sql/2026-10-24_ads_increase_campaign_budget.sql').read_text(),re.S)
normalize=lambda text:'\n'.join(line.strip() for line in text.splitlines() if line.strip())
checks={}
for row in result['ROWS']:
 body=expected[0 if row['PRONAME'].startswith('invalidate') else 1]
 assert normalize(body)==normalize(row['PROSRC']),row['PRONAME']
 assert row['OWNER']=='ads_owner' and row['PROSECDEF'] and row['PROCONFIG']==['search_path=pg_catalog']
 checks[row['PRONAME']]='source and security attributes match; indentation ignored'
print(json.dumps(checks,indent=2))
