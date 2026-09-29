from pathlib import Path
import subprocess,shlex,json
root=Path('/Users/Shared/Projects/RunnerHub/Business')
source=(root/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
body='''transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});queryExecute("SET LOCAL statement_timeout='8s'",{},{datasource="runner_dba"});q=queryExecute("WITH sample AS (SELECT log_item,log_item_id,log_timestamp FROM tb_log WHERE site='RR' AND log_item IN ('erro','404') AND log_timestamp >= now()-interval '24 hours' ORDER BY id_log DESC LIMIT 5000) SELECT count(*) AS sampled,min(log_timestamp) AS first_seen,max(log_timestamp) AS last_seen,count(*) FILTER(WHERE log_item='erro') AS errors,count(*) FILTER(WHERE log_item='404') AS not_found,count(*) FILTER(WHERE log_item='404' AND trim(coalesce(log_item_id,'')) IN ('/404','/404/','/en/404/','/es/404/')) AS generic_404,count(*) FILTER(WHERE log_item='erro' AND log_item_id LIKE '%/404/index.cfm%') AS errors_mentioning_404 FROM sample",{},{datasource="runner_dba",timeout=10});report={};for(col in listToArray(q.columnList))report[lCase(col)]=q[col][1];}'''
source+='\nprint(json.dumps(bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')))\n'
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
p=subprocess.run(ssh+['python3 -c '+shlex.quote(source)],capture_output=True,text=True,timeout=40)
if p.returncode:print(p.stderr[-1000:]);raise SystemExit(p.returncode)
data=json.loads(p.stdout);(root/'_codex/staging/error-handler-audit/counts.json').write_text(json.dumps(data,indent=2));print(json.dumps(data))
