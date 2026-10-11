"""Read JVM stack aggregates via the existing localhost-only CF fixture."""
from pathlib import Path
import json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business')
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
body='''threadInfos=createObject("java","java.lang.management.ManagementFactory").getThreadMXBean().dumpAllThreads(false,false); states={}; reqStates={}; tops={}; sqlMethods={}; reqTotal=0; sqlTotal=0;
for(threadObj in threadInfos){
 name=toString(threadObj.getThreadName());st=toString(threadObj.getThreadState());
 if(!structKeyExists(states,st)){states[st]=0;}states[st]++;
 isReq=reFindNoCase("^(ajp|http|catalina-exec)",name)>0;
 if(isReq){
  reqTotal++;if(!structKeyExists(reqStates,st)){reqStates[st]=0;}reqStates[st]++;
  frames=threadObj.getStackTrace();first=true;hasSql=false;
  for(frame in frames){
   method=toString(frame.getClassName()) & "." & toString(frame.getMethodName());
   if(first){if(!structKeyExists(tops,method)){tops[method]=0;}tops[method]++;first=false;}
   if(!hasSql && reFind("^(org[.]postgresql[.]|coldfusion[.]tagext[.]sql[.]|coldfusion[.]sql[.])",method)>0){hasSql=true;if(!structKeyExists(sqlMethods,method)){sqlMethods[method]=0;}sqlMethods[method]++;}
  }
  if(hasSql){sqlTotal++;}
 }
}
report={checked_at=dateTimeFormat(now(),"yyyy-mm-dd HH:nn:ss"),thread_states=states,request_thread_states=reqStates,request_threads=reqTotal,request_top_methods=tops,request_threads_with_sql_stack=sqlTotal,sql_stack_methods=sqlMethods};'''
remote=helpers+'\np=json.load(sys.stdin)\nr=bridge(ROOT,p["body"])\nprint(json.dumps(r))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=8','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'body':body}),capture_output=True,text=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);Path(__file__).with_suffix('.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
