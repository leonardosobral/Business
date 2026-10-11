from pathlib import Path
import json,shlex,subprocess
P=Path(__file__).resolve().parent
cases=[{'path':prefix+source+'/','expected':prefix+target+'/'} for source,target in [('2025-live-run-xp-brasilia-i-2025','2025-live-run-xp-brasilia-I-2025'),('2025-live-run-xp-brasilia-ii-2025','2025-live-run-xp-brasilia-II-2025'),('2026-endorfina-run-santo-andre-ii','2026-endorfina-run-santo-andre-II')] for prefix in ['/evento/','/en/event/','/es/evento/']]
remote='''import json,subprocess,sys
r=[]
for x in json.load(sys.stdin):
 cp=subprocess.run(['curl','-sS','-L','--max-redirs','3','--max-time','30','-A','RunnerHub-SEO-Verification/1.0','-o','/dev/null','-w','%{http_code} %{url_effective} %{num_redirects}','https://roadrunners.run'+x['path']],capture_output=True,text=True,timeout=35)
 r.append(dict(x,response=cp.stdout,returncode=cp.returncode))
print(json.dumps(r))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(cases),capture_output=True,text=True,timeout=180);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout)
for x in r:assert x['returncode']==0 and x['response']=='200 https://roadrunners.run'+x['expected']+' 1',x
(P/'follow-redirects-passed.json').write_text(json.dumps(r,indent=2));print(json.dumps({'redirects_followed':9,'destination_status':200,'hops_each':1}))
