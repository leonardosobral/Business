from pathlib import Path
import subprocess,json,shlex,hashlib
S=Path(__file__).resolve().parent;B=S.parents[2];names=['portal/includes/seo_domains_data.cfm','portal/conteudo/seo_domains.cfm'];watch=['portal/conteudo/seo.cfm','portal/seo/assets/domains.js','portal/seo/assets/domains.css','includes/backend/require_admin.cfm']
code='from pathlib import Path;import json,hashlib;r=Path("/var/www/business.roadrunners.run");p='+repr(names+watch)+';print(json.dumps({n:{"hash":hashlib.sha256((r/n).read_bytes()).hexdigest(),"text":(r/n).read_text() if n in '+repr(names)+' else ""} for n in p}))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],capture_output=True,text=True,timeout=30);assert cp.returncode==0,cp.stderr;r=json.loads(cp.stdout)
for n in names:
 assert hashlib.sha256((B/n).read_bytes()).hexdigest()==r[n]['hash'],('Production differs',n)
 p=S/'baseline'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(r[n]['text'])
(S/'baseline.json').write_text(json.dumps({'names':names,'before':{n:r[n]['hash'] for n in names},'watch':{n:r[n]['hash'] for n in watch}},indent=2));print('Two scoped files match production; four dependencies recorded')
