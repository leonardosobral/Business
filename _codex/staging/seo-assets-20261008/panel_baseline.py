from config import *
import base64,hashlib,json,shlex,subprocess
names=['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']
remote='''from pathlib import Path
import base64,json,sys
root=Path('/var/www/business.roadrunners.run');names=json.load(sys.stdin)
print(json.dumps({n:base64.b64encode((root/n).read_bytes()).decode() for n in names}))'''
cp=subprocess.run(SSH+['python3 -c '+shlex.quote(remote)],input=json.dumps(names),capture_output=True,text=True,timeout=40)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
result=json.loads(cp.stdout)
for n,b64 in result.items():
 raw=base64.b64decode(b64)
 if raw!=(B/n).read_bytes():raise RuntimeError('Local/production drift: '+n)
 for sub in ['baseline','candidate']:
  dest=S/sub/'business'/n;dest.parent.mkdir(parents=True,exist_ok=True)
  if dest.exists() and dest.read_bytes()!=raw:raise RuntimeError('Baseline changed: '+n)
  dest.write_bytes(raw)
print(json.dumps({'business_baselines_matched':len(result)}))
