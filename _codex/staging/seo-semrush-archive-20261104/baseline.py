from pathlib import Path
import base64, hashlib, json, shlex, subprocess

S = Path(__file__).resolve().parent
B = S.parents[2]
names = ['portal/conteudo/seo_semrush.cfm', 'portal/conteudo/seo_semrush_archive.cfm',
         'portal/includes/seo_semrush_archive_backend.cfm', 'portal/seo/arquivo.cfm']
watch = ['portal/conteudo/seo.cfm', 'portal/includes/seo_semrush_data.cfm',
         'includes/backend/require_admin.cfm', 'includes/backend/backend_login.cfm',
         'portal/seo/index.cfm']
remote = '''
from pathlib import Path
import base64, hashlib, json, sys
p=json.load(sys.stdin); root=Path('/var/www/business.roadrunners.run');out={}
for n in p['names']+p['watch']:
 f=root/n
 assert not f.is_symlink()
 if f.exists():out[n]={'sha':hashlib.sha256(f.read_bytes()).hexdigest(),'body':base64.b64encode(f.read_bytes()).decode()}
 else:out[n]=None
print(json.dumps(out))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'names':names,'watch':watch}),capture_output=True,text=True,timeout=35)
assert cp.returncode==0,cp.stderr
data=json.loads(cp.stdout); result={'before':{},'watch':{},'local':{}}
for n,v in data.items():
 f=B/n; result['local'][n]=hashlib.sha256(f.read_bytes()).hexdigest() if f.exists() else None
 if v:
  (S/'baseline'/n).parent.mkdir(parents=True,exist_ok=True)
  (S/'baseline'/n).write_bytes(base64.b64decode(v['body']))
  result['before' if n in names else 'watch'][n]=v['sha']
  if n in names:assert result['local'][n]==v['sha'], 'Local/produção divergentes: '+n
 elif n in names:assert not f.exists(), 'Arquivo local já existe: '+n
(S/'baseline.json').write_text(json.dumps(result,indent=2))
print(json.dumps({'runtime':len(names),'existing':len(result['before']),'dependencies':len(watch),'local_matches':True}))
