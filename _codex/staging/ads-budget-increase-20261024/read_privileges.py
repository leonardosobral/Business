from pathlib import Path
import base64,json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business')
helper=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT current_user AS db_user, pg_has_role(current_user,'ads_owner','MEMBER') AS owns_ads, has_schema_privilege(current_user,'ads','CREATE') AS can_create, (SELECT md5(pg_get_functiondef(oid)) FROM pg_proc WHERE oid='ads.invalidate_campaign_review_on_edit()'::regprocedure) AS trigger_hash"""
body='transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{},{datasource="runner_dba",timeout=15});}report={rows=[]};for(r in q)arrayAppend(report.rows,r);' 
remote=helper+'\nr=bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')\n'
remote+='print(json.dumps(r))\n'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=80)
if r.returncode:raise SystemExit(r.stderr[-1500:])
print(r.stdout)
