"""Hash-guarded publication for the approved event-description translation scope.

prepare stages private sources; publish requires an independently checked Adobe
compile log and writes only the immutable manifest. The existing cron is paused
and restored separately through the application's datasource.
"""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import tarfile

task_root = Path(__file__).resolve().parents[2]
receipt_file = Path('/private/tmp/rr-translations-release.json')
staging_root = Path('/private/tmp/rr-description-locales-stage')
remote_stage = '/tmp/rr-event-translations-20260914'
ssh = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-i',
       '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run']

def run_remote(script):
    response = subprocess.run(ssh + ['python3', '-'], input=script, text=True,
                              capture_output=True, check=True)
    print(response.stdout.strip())
    return response.stdout

if len(sys.argv) != 2 or sys.argv[1] not in ('prepare', 'publish'):
    raise SystemExit('Usage: deploy_event_description_translations.py prepare|publish')

receipt = json.loads(receipt_file.read_text())
if sys.argv[1] == 'prepare':
    site = json.loads((staging_root / 'release.json').read_text())
    business = ['services/EventDescriptionRewriteService.cfc',
                'api/eventos/jobs/rewrite-descriptions.cfm', 'api/eventos/jobs/queue.cfm',
                'administracao/cron-jobs/home.cfm', 'administracao/cron-jobs/descricoes.cfm',
                'administracao/cron-jobs/includes/description_status.cfm']
    sources = {'business/' + name: task_root / name for name in business}
    sources.update({'site/' + item['path']: task_root.parent / 'RoadRunners' / item['path']
                    for item in site['files']})
    for item in site['files']:
        key = 'site/' + item['path']
        assert hashlib.sha256(sources[key].read_bytes()).hexdigest() == item['sha256'], key
        assert receipt['before'].get(key) == item['baselineSha256'], key
    manifest = {'roots': receipt['roots'], 'backup': receipt['backup'], 'stage': remote_stage,
                'before': {key: receipt['before'].get(key) for key in sources},
                'after': {key: hashlib.sha256(path.read_bytes()).hexdigest() for key, path in sources.items()}}
    manifest_path = Path('/private/tmp/rr-translations-manifest.json')
    manifest_path.write_text(json.dumps(manifest, indent=2))
    archive = Path('/private/tmp/rr-translations-runtime.tar.gz')
    with tarfile.open(archive, 'w:gz') as tar:
        for key, path in sources.items():
            tar.add(path, arcname=key)
        tar.add(task_root / 'api/eventos/jobs/schema.sql', arcname='schema.sql')
        tar.add(manifest_path, arcname='manifest.json')
    subprocess.run(['scp', '-i', '/Users/leonardosobral/.ssh/webs', str(archive),
                    'root@ssh.runnerhub.run:/tmp/rr-translations-runtime.tar.gz'], check=True)
    run_remote('''
from pathlib import Path
import tarfile,json,hashlib,os
stage=Path('/tmp/rr-event-translations-20260914')
stage.mkdir(exist_ok=True)
with tarfile.open('/tmp/rr-translations-runtime.tar.gz','r:gz') as tar:
 for member in tar.getmembers():
  assert not member.name.startswith('/') and '..' not in Path(member.name).parts
 tar.extractall(stage,filter='data')
m=json.loads((stage/'manifest.json').read_text())
for name,expected in m['after'].items():
 assert hashlib.sha256((stage/name).read_bytes()).hexdigest()==expected,name
 project,relative=name.split('/',1)
 current=Path(m['roots'][project])/relative
 assert (hashlib.sha256(current.read_bytes()).hexdigest() if current.exists() else None)==m['before'][name],name
 output=stage/'compiled'/name
 output.parent.mkdir(parents=True,exist_ok=True)
for p in [stage,*stage.rglob('*')]:
 os.chown(p,65534,65534)
 os.chmod(p,0o755 if p.is_dir() else 0o644)
print(json.dumps({'staged_files':len(m['after']),'stage':str(stage),'baseline_verified':True}))
''')
else:
    run_remote('''
from pathlib import Path
import json,hashlib,os,tempfile,shutil,datetime,re
stage=Path('/tmp/rr-event-translations-20260914')
m=json.loads((stage/'manifest.json').read_text())
backup=Path(m['backup'])
log=(stage/'compile.log').read_text()
assert re.search(r'^successful '+str(len(m['after']))+r'$',log,re.M),log[-3000:]
assert re.search(r'^total '+str(len(m['after']))+r'$',log,re.M),log[-3000:]
for name,expected in m['after'].items():
 assert hashlib.sha256((stage/name).read_bytes()).hexdigest()==expected,name
 project,relative=name.split('/',1)
 target=Path(m['roots'][project])/relative
 before=m['before'][name]
 assert (hashlib.sha256(target.read_bytes()).hexdigest() if target.exists() else None)==before,name
 if before is not None:
  saved=backup/name
  assert hashlib.sha256(saved.read_bytes()).hexdigest()==before,name
published=[]
try:
 for name,expected in m['after'].items():
  project,relative=name.split('/',1)
  target=Path(m['roots'][project])/relative
  assert target.parent.is_dir(),target.parent
  reference=target if target.exists() else Path(m['roots'][project])/('api/event-description-rewrite.cfm' if project=='business' else 'evento/index.cfm')
  stat=reference.stat()
  fd,tmp=tempfile.mkstemp(prefix='.event-translation-',dir=target.parent)
  with os.fdopen(fd,'wb') as stream: stream.write((stage/name).read_bytes())
  os.chmod(tmp,stat.st_mode & 0o777)
  os.chown(tmp,stat.st_uid,stat.st_gid)
  assert (hashlib.sha256(target.read_bytes()).hexdigest() if target.exists() else None)==m['before'][name],name
  if m['before'][name] is None:
   os.link(tmp,target); os.unlink(tmp)
  else: os.replace(tmp,target)
  published.append(name)
  assert hashlib.sha256(target.read_bytes()).hexdigest()==expected,name
except Exception:
 for name in reversed(published):
  project,relative=name.split('/',1); target=Path(m['roots'][project])/relative
  assert hashlib.sha256(target.read_bytes()).hexdigest()==m['after'][name],name
  if m['before'][name] is None: target.unlink()
  else: shutil.copy2(backup/name,target)
 raise
m['published_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
(backup/'published.json').write_text(json.dumps(m,indent=2))
print(json.dumps({'published_files':len(published),'backup':str(backup),'hashes_verified':True}))
''')
