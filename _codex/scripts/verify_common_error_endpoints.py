from pathlib import Path
import json,subprocess,sys
remote=r'''import subprocess,json
checks=[]
for origin in [True,False]:
 for path,method,allowed in [('/api/analytics/collect.cfm','GET',[405]),('/api/analytics/collect.cfm','POST',[204,400]),('/carteira/check_transacao.cfm','GET',[200])]:
  cmd=['curl','-sS','--max-time','20','-w','\n%{http_code}','https://roadrunners.run'+path]
  if origin:cmd[1:1]=['--resolve','roadrunners.run:443:127.0.0.1']
  if method=='POST':cmd+=['-H','Content-Type: application/json','-H','Origin: https://roadrunners.run','--data','{}']
  p=subprocess.run(cmd,capture_output=True,text=True,check=True);body,status=p.stdout.rsplit('\n',1)
  item={'origin':origin,'path':path,'method':method,'status':int(status),'body':body.strip()[:200]};checks.append(item)
  assert int(status) in allowed,item
  if int(status)!=204:json.loads(body)
print(json.dumps({'passed':True,'checks':checks}))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -'],input=remote,capture_output=True,text=True,timeout=150)
print(p.stdout);print(p.stderr[-1600:]);(Path(__file__).resolve().parents[2]/'_codex/staging/common-errors-20261004/runtime-endpoints.json').write_text(p.stdout);sys.exit(p.returncode)
