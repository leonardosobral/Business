"""CF2025 regression checks: audit writes are rolled back; no campaign/balance mutations."""
from pathlib import Path
import base64,json,shlex,subprocess,sys
ROOT=Path(__file__).resolve().parents[3]
STAGE=Path(__file__).resolve().parent
mode=sys.argv[1] if len(sys.argv)>1 else 'candidate'
assert mode in ('candidate','published')
helper=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
functions=(ROOT/'ads/home.cfm').read_text().split('<cfscript>')[1].split('VARIABLES.adsV1WorkspaceView =')[0]
old=subprocess.check_output(['git','show','HEAD:services/accountDelegation/Store.cfc'],cwd=ROOT).decode()
files={'BaselineStore.cfc':old,'CandidateStore.cfc':(ROOT/'services/accountDelegation/Store.cfc').read_text(),'helpers.cfm':'<cfscript>'+functions+'</cfscript>'}
# Candidate/baseline CFCs are accessible only inside the guarded, ephemeral bridge.
extra="\n  fixture_files="+repr(files)+"\n  for name,content in fixture_files.items():\n   (work/name).write_text(content)\n"
helper=helper.replace("  (work/'run.cfm').write_text",extra+"  (work/'run.cfm').write_text")
body=r'''
include "helpers.cfm";
report={checks=[],engine=server.coldfusion.productversion};
function check(required boolean condition,required string label){if(!condition)throw(message="Regression: " & label);arrayAppend(report.checks,label);}
cases=[{s="ACTIVE",b=100,p=99.70,c=0.94,w=true},{s="ACTIVE",b=100,p=99.71,c=0.94,w=true},{s="ACTIVE",b=100,p=99.12,c=0.94,w=true},{s="ACTIVE",b=100,p=99.06,c=0.94,w=false},{s="ACTIVE",b=100,p=99.07,c=0.94,w=true},{s="ACTIVE",b=100,p=10,c=0.94,w=false},{s="PAUSED",b=100,p=100,c=0.94,w=true},{s="DRAFT",b=100,p=100,c=0.94,w=false},{s="ENDED",b=100,p=100,c=0.94,w=false},{s="ACTIVE",b=100,p=100,c=0,w=false},{s="ACTIVE",b="",p=0,c=0.94,w=false}];
for(i=1;i<=arrayLen(cases);i++){t=cases[i];check(adsV1CampaignBudgetExhausted(t.s,t.b,t.p,t.c)==t.w,"budget boundary " & i);}
opts={datasource="runnerhub",timeout=10};
resource={type="CAMPAIGN",id="ads-audit-regression-20261024"};
countSql="SELECT count(*) AS n FROM public.tb_conta_gestao_auditoria WHERE recurso_id='ads-audit-regression-20261024'";
check(queryExecute(countSql,{},opts).n[1]==0,"no existing regression audit entries");
transaction {
 queryExecute("SELECT 1",{},opts);
 ctx={actorId=142,accountId=1,managerAccountId=0,relationshipId=0};
 baseline=createObject("component","BaselineStore").init("runnerhub");
 transaction action="setsavepoint" savepoint="baseline";
 failed=false;
 try {baseline.audit(ctx,"ads.campaigns.manage",resource);} catch(any e){failed=findNoCase("not of type query",e.message)>0;}
 transaction action="rollback" savepoint="baseline";
 check(failed,"original audit reproduces CF query return-type error");
 candidate=STORE_COMPONENT;
 candidate.audit(ctx,"ads.campaigns.manage",resource);
 check(queryExecute(countSql,{},opts).n[1]==1,"corrected audit returns successfully within transaction");
 transaction action="setsavepoint" savepoint="audit_failure";
 failed=false;
 invalid=duplicate(ctx);invalid.accountId=-1;
 try {candidate.audit(invalid,"ads.campaigns.manage",resource);} catch(any e){failed=true;}
 transaction action="rollback" savepoint="audit_failure";
 check(failed,"invalid audit context still fails");
 check(queryExecute(countSql,{},opts).n[1]==1,"failed audit cannot leave a second entry");
 transaction action="rollback";
}
check(queryExecute(countSql,{},opts).n[1]==0,"entire audit regression rolled back; no persistent writes");
report.customer_records_changed=false;
'''
component='createObject("component","CandidateStore").init("runnerhub")'
if mode=='published':component='createObject("component","services.accountDelegation.Store").init("runnerhub")'
body=body.replace('STORE_COMPONENT',component)
# Production service mapping is only used after publication; it does not alter application config.
helper=helper.replace('this.datasource="runner_dba";', 'this.datasource="runner_dba";this.mappings["/services"]="/var/www/business.roadrunners.run/services";')
remote=helper+'\nprint(json.dumps(bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')))\n'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=115)
if r.returncode:raise SystemExit(r.stderr[-2500:])
report=json.loads(r.stdout);(STAGE/('test-'+mode+'.json')).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
