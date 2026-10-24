from pathlib import Path
import json,shlex,subprocess
S=Path(__file__).resolve().parent
paths=['/en/','/en/event/2007-83-corrida-internacional-de-sao-silvestre/','/en/event/2026-2-corrida-cdl-movimenta-bom-jesus-do-oeste/','/es/evento/2007-83-corrida-internacional-de-sao-silvestre/','/es/evento/2026-corrida-farmacia-extra-popular/','/evento/2008-maratona-internacional-de-sao-paulo-2008/','/evento/2026-101-corrida-internacional-de-sao-silvestre/','/evento/2026-circuito-sesc-etapa-garanhuns/']
remote='''import json,subprocess,sys
paths=json.load(sys.stdin);results=[]
for run in range(2):
 for path in paths:
  cp=subprocess.run(['curl','-sS','--max-time','20','--resolve','roadrunners.run:443:127.0.0.1','-o','/dev/null','-w','%{http_code} %{time_starttransfer} %{time_total} %{size_download}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=25)
  assert cp.returncode==0,(path,cp.returncode);code,ttfb,total,size=cp.stdout.split();results.append({'path':path,'run':run+1,'status':int(code),'ttfb':float(ttfb),'total':float(total),'bytes':int(size)})
print(json.dumps(results))'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=200);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/'slow-origin.json').write_text(json.dumps(r,indent=2));assert all(x['status']==200 for x in r)
print(json.dumps({'requests':len(r),'status_200':len(r),'max_seconds':max(x['total'] for x in r),'min_seconds':min(x['total'] for x in r),'over_3_seconds':sum(x['total']>3 for x in r)}))
