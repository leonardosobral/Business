from pathlib import Path
import base64, hashlib, json, shlex, subprocess

ROOT = Path('/Users/Shared/Projects/RunnerHub/Business')
STAGE = Path(__file__).resolve().parent
NAMES = ['portal/conteudo/seo_semrush.cfm', 'portal/includes/seo_semrush_data.cfm', 'portal/includes/seo_queue_data.cfm']
remote = '''from pathlib import Path
import base64,json,sys
root=Path('/var/www/business.roadrunners.run')
names=json.load(sys.stdin)
print(json.dumps({n:base64.b64encode((root/n).read_bytes()).decode() for n in names}))
'''
cp = subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)], input=json.dumps(NAMES), capture_output=True,text=True,timeout=40)
if cp.returncode: raise RuntimeError(cp.stderr[-2000:])
result = json.loads(cp.stdout)
hashes = {}
for name, value in result.items():
    body=base64.b64decode(value)
    if (ROOT/name).read_bytes() != body: raise RuntimeError('Production/local drift: '+name)
    path=STAGE/'baseline/business'/name
    path.parent.mkdir(parents=True,exist_ok=True)
    if path.exists() and path.read_bytes()!=body: raise RuntimeError('Baseline already exists and differs')
    path.write_bytes(body)
    candidate=STAGE/'candidate/business'/name
    candidate.parent.mkdir(parents=True,exist_ok=True)
    if not candidate.exists():candidate.write_bytes(body)
    hashes[name]=hashlib.sha256(body).hexdigest()
(STAGE/'baseline-hashes.json').write_text(json.dumps(hashes,indent=2))
print(json.dumps({'baseline_matches_local':len(hashes)}))
