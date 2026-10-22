"""Scoped incremental publication. Default preflight; --publish backs up and probes.

No SQL, secrets, credential/perms changes or Git operations. Only seven runtime
files owned by this task are eligible; original production hashes are mandatory.
"""
import base64
import hashlib
import json
import pathlib
import shlex
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
baseline = json.loads((ROOT / '_codex/deploy/geocoding-20261017.json').read_text())['manifest']
acceleration='--acceleration' in sys.argv
if acceleration:
    baseline.update(json.loads((ROOT/'_codex/deploy/geocoding-fontes-20261017.json').read_text())['manifest'])
    baseline['includes/backend/cron_jobs_service.cfm']={'after':'2cdbbdcb5304ab274dfd0f8ac08656685bfe2516e708a9f0deedfcbd97b37270'}
    baseline['cron-jobs/runner.cfm']={'after':'3fb19ec63c4aec38500dea20f58c5dab81c7a81a979651d58450eaac23464f1b'}
receipt_path=ROOT/('_codex/deploy/geocoding-aceleracao-20261018.json' if acceleration else '_codex/deploy/geocoding-fontes-20261017.json')
previous=json.loads(receipt_path.read_text()) if receipt_path.exists() else {}
baseline.update(previous.get('manifest',{}))
paths = ['services/geocoding/source_fetcher.py', 'services/geocoding/Sources.cfc',
         'services/geocoding/Policy.cfc', 'services/geocoding/Store.cfc', 'services/geocoding/Worker.cfc',
         'administracao/geolocalizacao/includes/backend.cfm', 'administracao/geolocalizacao/includes/view.cfm']
if acceleration:
    paths=['services/geocoding/Store.cfc','services/geocoding/Worker.cfc','services/geocoding/GeoapifyClient.cfc',
           'api/eventos/geolocalizar.cfm','includes/backend/cron_jobs_service.cfm','administracao/geolocalizacao/includes/view.cfm','cron-jobs/runner.cfm']
payload = {'publish':'--publish' in sys.argv, 'files':[
    {'path':path, 'before':baseline.get(path, {}).get('after'),
     'data':base64.b64encode((ROOT/path).read_bytes()).decode()} for path in paths]}

REMOTE = r'''
import base64,hashlib,json,os,pathlib,stat,subprocess,sys,tempfile
p=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run')
def sha(data):return hashlib.sha256(data).hexdigest()
def target(rel):
 path=root/rel
 if path.is_symlink() or root not in path.resolve().parents:raise RuntimeError('Unsafe publication target')
 return path
files=[];manifest={}
for item in p['files']:
 dest=target(item['path']);before=dest.read_bytes() if dest.exists() else None
 if (sha(before) if before is not None else None)!=item['before']:raise SystemExit('Production baseline conflict: '+item['path'])
 item['content']=base64.b64decode(item.pop('data'),validate=True);item['original']=before
 if item['before']==sha(item['content']):continue
 files.append(item);manifest[item['path']]={'before':item['before'],'after':sha(item['content'])}
if not p['publish']:
 print(json.dumps({'ok':True,'mode':'preflight','manifest':manifest}));sys.exit(0)
backup=pathlib.Path(tempfile.mkdtemp(prefix='business-geocoding-sources-',dir='/var/backups'));os.chmod(backup,0o700)
probes=[];published=[];metadata={}
def atomic(path,content,info):
 fd,tmp=tempfile.mkstemp(prefix='.geo-sources-',dir=path.parent)
 try:
  with os.fdopen(fd,'wb') as stream:
   stream.write(content);stream.flush();os.fsync(stream.fileno());os.fchmod(stream.fileno(),stat.S_IMODE(info.st_mode));os.fchown(stream.fileno(),info.st_uid,info.st_gid)
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
try:
 for item in files:
  rel=item['path'];dest=target(rel);current=dest.read_bytes() if dest.exists() else None
  if (sha(current) if current is not None else None)!=item['before']:raise RuntimeError('Concurrent production change: '+rel)
  info=dest.stat() if dest.exists() else target('services/geocoding/Policy.cfc').stat();metadata[rel]=info
  if current is not None:
   saved=backup/'before'/rel;saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(current);os.chmod(saved,0o600)
  atomic(dest,item['content'],info);published.append(item)
  if sha(dest.read_bytes())!=manifest[rel]['after']:raise RuntimeError('Uploaded hash mismatch')
 for path,method,expected in [('/api/eventos/geolocalizar.cfm','GET',405),('/api/eventos/geolocalizar.cfm','POST',401),('/services/geocoding/Sources.cfc','GET',403),('/services/geocoding/source_fetcher.py','GET',403),('/administracao/geolocalizacao/','GET',302)]:
  run=subprocess.run(['curl','--silent','--show-error','--max-time','25','--resolve','business.roadrunners.run:443:127.0.0.1','--request',method,'--write-out','\n%{http_code}','https://business.roadrunners.run'+path],capture_output=True,timeout=30)
  _,_,status=run.stdout.rpartition(b'\n');ok=run.returncode==0 and status==str(expected).encode();probes.append({'path':path,'method':method,'status':status.decode(),'ok':ok})
  if not ok:raise RuntimeError('Publication guard probe failed: '+path)
 checks=[{'path':rel,'ok':sha(target(rel).read_bytes())==item['after']} for rel,item in manifest.items()]
 if not all(check['ok'] for check in checks):raise RuntimeError('Final hash mismatch')
 result={'ok':True,'mode':'published','backup':str(backup),'manifest':manifest,'probes':probes,'checks':checks,'sql_applied':False,'credentials_changed':False}
except Exception as error:
 rollback=[]
 for item in reversed(published):
  rel=item['path'];dest=target(rel)
  if not dest.exists() or sha(dest.read_bytes())!=manifest[rel]['after']:
   rollback.append({'path':rel,'restored':False,'reason':'concurrent_change'});continue
  if item['original'] is not None:atomic(dest,item['original'],metadata[rel])
  else:
   saved=backup/'withdrawn'/rel;saved.parent.mkdir(parents=True,exist_ok=True);dest.rename(saved)
  rollback.append({'path':rel,'restored':True})
 result={'ok':False,'backup':str(backup),'reason':str(error),'rollback':rollback,'probes':probes}
(backup/'receipt.json').write_text(json.dumps(result,indent=2));os.chmod(backup/'receipt.json',0o600)
print(json.dumps(result));sys.exit(0 if result['ok'] else 1)
'''
run = subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod',
                      'python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=150)
try:
    result=json.loads(run.stdout)
except Exception:
    result={'ok':False,'error':run.stderr.decode(errors='replace')[-600:] or run.stdout.decode(errors='replace')[-600:] or 'Publication receipt unavailable'}
if result.get('mode') == 'published':
    delta=result['manifest'];result['delta']=delta
    result['manifest']={**previous.get('manifest',{}),**delta}
    result['previous_publications']=previous.get('previous_publications',[])+([{
        'backup':previous['backup'],'manifest':previous.get('delta',previous['manifest'])}] if previous else [])
    receipt_path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
if run.returncode or not result.get('ok'):sys.exit(1)
