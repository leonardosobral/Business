from pathlib import Path
import base64,json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business')
helper=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
import re
source=(root/'includes/estrutura/home_conta_dashboard.cfm').read_text()
queries={name:re.sub(r'<cfqueryparam[^>]*/>', '1',re.search(r'<cfquery name="'+name+r'"[^>]*>(.*?)</cfquery>',source,re.S).group(1)) for name in ['qBusinessHomeMarketingSummary','qBusinessHomeAdCampaigns']}
sql='SELECT jsonb_build_object(\'summary\',(SELECT to_jsonb(s) FROM ('+queries['qBusinessHomeMarketingSummary']+') s),\'campaigns\',(SELECT jsonb_agg(s) FROM ('+queries['qBusinessHomeAdCampaigns']+') s))::text AS payload'
body='transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{},{datasource="runner_dba",timeout=15});}report={rows=[]};for(r in q)arrayAppend(report.rows,r);' 
remote=helper+'\nr=bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')\n'
remote+='print(json.dumps(r))\n'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=80)
if r.returncode:raise SystemExit(r.stderr[-1500:])
(Path(__file__).parent/'home-query-result.json').write_text(r.stdout); print(r.stdout)
