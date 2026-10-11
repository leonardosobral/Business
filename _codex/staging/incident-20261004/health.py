import subprocess,json,shlex
code='''import subprocess,json,concurrent.futures
cmds={"load":["uptime"],"memory":["free","-m"],"disk":["df","-h","/","/var","/tmp"],"services":["systemctl","list-units","--type=service","--state=running,failed","--no-pager","--plain"],"processes":["ps","-eo","pid,comm,%cpu,%mem,nlwp","--sort=-%cpu"]}
for name,cmd in cmds.items():
 p=subprocess.run(cmd,capture_output=True,text=True,timeout=8)
 text=p.stdout
 if name=="services":text="\\n".join(l for l in text.splitlines() if any(v in l.lower() for v in ['apache','httpd','coldfusion','postgres','nginx','failed']))
 if name=="processes":text="\\n".join(text.splitlines()[:12])
 print(json.dumps({"check":name,"output":text,"exit":p.returncode}),flush=True)
def fetch(path):
 p=subprocess.run(['curl','-sS','--max-time','10','--resolve','business.roadrunners.run:443:127.0.0.1','-o','/dev/null','-w','%{http_code} %{time_starttransfer} %{time_total}','https://business.roadrunners.run'+path],capture_output=True,text=True,timeout=13)
 return {'check':'origin','path':path,'result':p.stdout,'error':p.stderr,'exit':p.returncode}
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for r in pool.map(fetch,['/assets/css/business-ui.css','/portal/seo/']):print(json.dumps(r),flush=True)
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=8','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],text=True,capture_output=True,timeout=65)
print(p.stdout);print(p.stderr)
from pathlib import Path
Path(__file__).with_suffix('.jsonl').write_text(p.stdout)
