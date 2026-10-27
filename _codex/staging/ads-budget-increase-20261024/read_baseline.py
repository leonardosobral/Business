from pathlib import Path
import base64,json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business')
helper=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT p.proname,pg_get_functiondef(p.oid) AS definition,pg_get_userbyid(p.proowner) AS owner,p.proacl::text AS acl FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='ads' AND p.proname IN ('invalidate_campaign_review_on_edit','paid_banner_actor_allowed','guard_campaign_status_transition')"""
body='transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runnerhub"});q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{},{datasource="runnerhub",timeout=15});}report={functions=[]};for(r in q)arrayAppend(report.functions,{name=r.proname,definition=r.definition});'
remote=helper+'\nr=bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')\n'
remote+='print(json.dumps(r))\n'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=80)
if r.returncode:raise SystemExit(r.stderr[-1500:])
Path('_codex/staging/ads-budget-increase-20261024/functions-baseline.json').write_text(r.stdout);print('Function definitions captured')
