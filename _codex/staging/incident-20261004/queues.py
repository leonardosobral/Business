import subprocess,shlex
from pathlib import Path
code=r'''import subprocess,json,collections,concurrent.futures
p=subprocess.run(['ss','-Hant'],capture_output=True,text=True,timeout=10);counts=collections.Counter()
for l in p.stdout.splitlines():
 a=l.split()
 if len(a)>4:counts[(a[0],a[3].rsplit(':',1)[-1])]+=1
print(json.dumps({'socket_counts':[[*k,v] for k,v in counts.most_common(20)]}),flush=True)
def probe(t):
 label,url,host=t
 p=subprocess.run(['curl','-sS','--max-time','7','-H','Host: '+host,'-w','\nSTATUS %{http_code} %{time_total}',url],capture_output=True,text=True,timeout=10)
 text=p.stdout
 if label=='apache-status':text='\n'.join(l for l in text.splitlines() if l.startswith(('BusyWorkers:','IdleWorkers:','Scoreboard:','ConnsTotal:','ConnsAsync','STATUS','ServerUptimeSeconds:')))
 else:text=text.rsplit('STATUS ',1)[-1]
 return {'check':label,'result':text,'error':p.stderr}
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
 for r in ex.map(probe,[('apache-status','http://127.0.0.1/server-status?auto','localhost'),('coldfusion-direct','http://127.0.0.1:8500/robots.txt','localhost')]):print(json.dumps(r),flush=True)
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=8','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],capture_output=True,text=True,timeout=35)
print(p.stdout);print(p.stderr);Path(__file__).with_suffix('.jsonl').write_text(p.stdout)
