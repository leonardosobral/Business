from pathlib import Path
import subprocess,shlex,json,sys
source=r'''
import subprocess,json
checks=[]
for origin in [True,False]:
 for path,expected in [('/.env',403),('/.env.bak',403),('/nested/.env',403),('/%2eenv',403),('/.well-known/assetlinks.json',200),('/manifest.webmanifest',200),('/',200)]:
  cmd=['curl','-sS','--path-as-is','--max-time','25','-w','\n%{http_code}','https://roadrunners.run'+path]
  if origin:cmd[1:1]=['--resolve','roadrunners.run:443:127.0.0.1']
  p=subprocess.run(cmd,capture_output=True,text=True,check=True);body,status=p.stdout.rsplit('\n',1)
  assert int(status)==expected,(origin,path,status)
  if expected==403:assert body.strip()=='Access denied',(origin,path,'unexpected denial body')
  if path.endswith('assetlinks.json'):assert json.loads(body)==[]
  checks.append({'origin':origin,'path':path,'status':int(status),'access_denied':body.strip()=='Access denied'})
print(json.dumps({'passed':True,'checks':checks}))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],capture_output=True,text=True,timeout=100)
print(p.stdout);print(p.stderr[-1000:] if p.returncode else '')
if p.returncode:sys.exit(p.returncode)
(Path(__file__).resolve().parents[2]/'_codex/staging/rr-env-block/runtime.json').write_text(p.stdout)
