from pathlib import Path
import json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business');stage=Path(__file__).resolve().parent
helper=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
functions=(root/'ads/includes/backend.cfm').read_text().split('<cfscript>')[1].split('</cfscript>')[0]
helper=helper.replace("  (work/'run.cfm').write_text", "  (work/'Policy.cfc').write_text((root/'services/accountDelegation/Policy.cfc').read_text())\n  (work/'helpers.cfm').write_text("+repr('<cfscript>'+functions+'</cfscript>')+")\n  (work/'run.cfm').write_text")
body=r'''
include "helpers.cfm";
report={checks=[],customer_records_changed=false};
function check(required boolean ok,required string label){if(!ok)throw(message=label);arrayAppend(report.checks,label);}
p=createObject("component","Policy");
r=p.routePolicy('/ads/','POST',{view='campaigns'},{ads_v1_action='increase_campaign_budget'});
check(r.allowed && r.capability=='ads.campaigns.manage','budget POST requires campaign management');
r=p.routePolicy('/ads/','GET',{ads_v1_action='increase_campaign_budget'},{});check(!r.allowed,'budget mutation through GET denied');
r=p.routePolicy('/ads/','POST',{}, {ads_v1_action='increase_campaign_budget,save_campaign'});check(!r.allowed,'ambiguous action denied');
r=p.routePolicy('/ads/','GET',{view='campaigns',status='ongoing',manage='118e16c7-9f57-4e59-b138-a1fcd96bed4f'},{});check(r.allowed && r.capability=='ads.campaigns.view','manage deep link remains read only');
check(adsV1MoneyValue('200,45')==200.45 && adsV1MoneyValue('200.45')==200.45,'comma and dot decimal amounts parsed');
check(numberFormat(100.01,'0.00')=='100.01','browser min and hidden amount use decimal dot');
q=queryExecute("SELECT coalesce(has_function_privilege(current_user,to_regprocedure('ads.increase_campaign_budget(uuid,bigint,integer,numeric,numeric)'),'EXECUTE'),false) AS ready",{},{datasource='runnerhub',timeout=10});
report.migration_ready=q.ready[1];
'''
remote=helper+'\nprint(json.dumps(bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')))\n'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=115)
if r.returncode:raise SystemExit(r.stderr[-2500:])
report=json.loads(r.stdout);(stage/'cf-runtime-checks.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
