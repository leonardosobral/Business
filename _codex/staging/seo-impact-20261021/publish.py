from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent
files={str(p.relative_to(S/'candidate')):p.read_text() for p in (S/'candidate').rglob('*.cfm')}
checks=json.loads((S/'preflight-passed.json').read_text())
assert checks['compiled_templates']==3
assert checks['tested_hashes']=={n:hashlib.sha256(v.encode()).hexdigest() for n,v in files.items()}
for name in ['menu-tests-green.json','title-tests-green.json','title-controls-green.json']:
    assert not json.loads((S/name).read_text())['failed'],name
assert json.loads((S/'menu-tests-green.json').read_text())['menu_hash']==checks['tested_hashes']['rr/includes/estrutura/menu_apps.cfm']
assert json.loads((S/'title-tests-green.json').read_text())['source_hash']==checks['tested_hashes']['rr/includes/estrutura/event_title_date.cfm']
assert (S/'pages-before.json').exists()
watch={}
for site in ('rr','or'):
    for p in (S/'origin'/site).rglob('*'):
        if p.is_file():watch[site+'/'+str(p.relative_to(S/'origin'/site))]=hashlib.sha256(p.read_bytes()).hexdigest()
remote='''
from pathlib import Path
import datetime,hashlib,json,os,shutil,sys,tempfile
p=json.load(sys.stdin);roots={'rr':Path('/var/www/roadrunners.com.br'),'or':Path('/var/www/openresults.run')}
def target(n):
 site,rel=n.split('/',1)
 assert site in roots and not Path(rel).is_absolute() and '..' not in Path(rel).parts
 t=roots[site]/rel
 assert t.resolve()==t and all(not x.is_symlink() for x in [t,*t.parents] if x.exists())
 return t
def digest(t):return hashlib.sha256(t.read_bytes()).hexdigest()
def baseline():
 for n,h in p['watch'].items():assert digest(target(n))==h,'Production conflict: '+n
 assert not target('or/api/runner_apps_menu.cfm').exists(),'New proxy already exists'
baseline()
backup=Path('/var/backups/seo-impact-20261021-rr');backup.mkdir(mode=0o700,exist_ok=False)
for n in p['files']:
 if n.startswith('rr/'):
  b=backup/n[3:];b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target(n),b)
(backup/'manifest.json').write_text(json.dumps({'before':p['watch'],'after':p['hashes']},indent=2))
baseline()
published=[]
try:
 for n in ['or/api/runner_apps_menu.cfm','rr/includes/estrutura/menu_apps.cfm','rr/includes/estrutura/event_title_date.cfm']:
  t=target(n);ref=t.stat() if t.exists() else (roots['or']/'api/eventos.cfm').stat()
  fd,temporary=tempfile.mkstemp(prefix='.'+t.name+'.seo-',dir=t.parent)
  try:
   with os.fdopen(fd,'wb') as f:f.write(p['files'][n].encode())
   os.chmod(temporary,ref.st_mode & 0o777);os.chown(temporary,ref.st_uid,ref.st_gid)
   os.replace(temporary,t)
  finally:
   if Path(temporary).exists():Path(temporary).unlink()
  published.append(n);assert digest(t)==p['hashes'][n]
 for n,h in p['watch'].items():assert digest(target(n))==p['hashes'].get(n,h),'Dependency changed: '+n
except Exception:
 for n in reversed(published):
  t=target(n)
  if digest(t)!=p['hashes'][n]:raise RuntimeError('Concurrent change; manual recovery needed: '+n)
  if n.startswith('rr/'):
   ref=t.stat();fd,tmp=tempfile.mkstemp(prefix='.'+t.name+'.restore-',dir=t.parent)
   with os.fdopen(fd,'wb') as f:f.write((backup/n[3:]).read_bytes())
   os.chmod(tmp,ref.st_mode & 0o777);os.chown(tmp,ref.st_uid,ref.st_gid);os.replace(tmp,t)
  else:t.unlink()
 raise
result={'published':published,'verified_hashes':len(published),'preserved_dependencies':len(p['watch'])-2,'rr_recovery':str(backup),'or_recovery':'Remove only the new api/runner_apps_menu.cfm after restoring its shared consumer. No existing OpenResults file changed.','published_at':datetime.datetime.now(datetime.timezone.utc).isoformat()}
(backup/'published.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files,'watch':watch,'hashes':checks['tested_hashes']}),capture_output=True,text=True,timeout=60)
assert cp.returncode==0,cp.stderr[-3000:]
r=json.loads(cp.stdout);(S/'published.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
