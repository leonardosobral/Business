"""Scoped production deployment. Run prepare, compile candidate, then publish."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import sys

ROOT=Path('/var/www/business.roadrunners.run')
STAGE=Path('/var/backups/business-helpdesk-workspace.PC9h1k')
BASELINES={
 'helpdesk/index.cfm':'29ca5ec4183c6b483e49895c0cc8d272dca2bd31048779524dbef422525abe0e',
 'helpdesk/home.cfm':'19dd08a6272d365bcce3915d4d8d17948aa2fb66e7ab24381ad0ecaa2a618c03',
 'helpdesk/includes/backend.cfm':'91043f040b596206df7e18a57b59e1c80d4584260dd7a6d9b216799e2b4b831b',
}
NEW=['helpdesk/includes/'+name for name in ['HelpdeskWorkspace.cfc','workspace-init.cfm','workspace-actions.cfm','workspace.cfm','workspace-sectors.cfm']]+['helpdesk/assets/workspace.css','helpdesk/assets/workspace.js']
FILES=list(BASELINES)+NEW
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def baseline():
 for name,digest in BASELINES.items():
  if (ROOT/name).is_symlink() or sha(ROOT/name)!=digest:raise RuntimeError('Production conflict: '+name)
 for name in NEW:
  if (ROOT/name).exists():raise RuntimeError('New target already exists: '+name)
def prepare():
 baseline()
 backup=STAGE/'baseline'
 backup.mkdir(mode=0o700,exist_ok=False)
 for name in BASELINES:
  target=backup/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/name,target)
 candidate={name:sha(STAGE/'candidate'/name) for name in FILES}
 (STAGE/'manifest.json').write_text(json.dumps({'before':BASELINES,'new':NEW,'candidate':candidate},indent=2))
 print('Baseline checked; recoverable backup prepared: '+str(backup))
def publish():
 baseline()
 manifest=json.loads((STAGE/'manifest.json').read_text())
 for name in FILES:
  if sha(STAGE/'candidate'/name)!=manifest['candidate'][name]:raise RuntimeError('Candidate changed: '+name)
 reference=(ROOT/'helpdesk/home.cfm').stat()
 # New dependencies first, shared backend next, entry point/template last.
 for name in NEW+['helpdesk/includes/backend.cfm','helpdesk/index.cfm','helpdesk/home.cfm']:
  target=ROOT/name;temporary=target.with_name(target.name+'.workspace-new')
  with temporary.open('xb') as stream:stream.write((STAGE/'candidate'/name).read_bytes())
  os.chown(temporary,reference.st_uid,reference.st_gid);os.chmod(temporary,reference.st_mode & 0o777)
  os.replace(temporary,target)
  if sha(target)!=manifest['candidate'][name]:raise RuntimeError('Published file mismatch: '+name)
 print(json.dumps({'published_files':FILES,'backup':str(STAGE/'baseline')}))
def rollback():
 manifest=json.loads((STAGE/'manifest.json').read_text())
 for name in FILES:
  target=ROOT/name
  if target.exists() and sha(target) not in [manifest['candidate'][name],BASELINES.get(name)]:raise RuntimeError('Concurrent change; manual recovery needed: '+name)
 for name in BASELINES:
  target=ROOT/name;metadata=target.stat();temporary=target.with_name(target.name+'.workspace-rollback')
  shutil.copy2(STAGE/'baseline'/name,temporary);os.chown(temporary,metadata.st_uid,metadata.st_gid);os.replace(temporary,target)
 # Retain new, unused dependencies for recoverability; old entry point never loads them.
 print('Original runtime restored; unused dependencies retained for recovery.')
def harden():
 manifest=json.loads((STAGE/'manifest.json').read_text())
 names=['helpdesk/includes/'+name for name in ['workspace-init.cfm','workspace-actions.cfm','workspace-sectors.cfm','workspace.cfm']]
 for name in FILES:
  if sha(ROOT/name)!=manifest['candidate'][name]:raise RuntimeError('Production conflict: '+name)
 for name in names:
  source=STAGE/'candidate'/name
  if 'NOT structKeyExists(VARIABLES,"helpdeskCanManage")' not in source.read_text():raise RuntimeError('Missing direct-access guard: '+name)
 backup=STAGE/'before-hardening';backup.mkdir(mode=0o700,exist_ok=False)
 for name in names:
  shutil.copy2(ROOT/name,backup/Path(name).name)
  manifest['candidate'][name]=sha(STAGE/'candidate'/name)
 (STAGE/'manifest.json').write_text(json.dumps(manifest,indent=2))
 for name in names:
  target=ROOT/name;metadata=target.stat();temporary=target.with_name(target.name+'.workspace-new')
  with temporary.open('xb') as stream:stream.write((STAGE/'candidate'/name).read_bytes())
  os.chown(temporary,metadata.st_uid,metadata.st_gid);os.chmod(temporary,metadata.st_mode & 0o777);os.replace(temporary,target)
  if sha(target)!=manifest['candidate'][name]:raise RuntimeError('Published file mismatch: '+name)
 print('Direct-access guards published; backup and manifest updated.')
if __name__=='__main__':
 {'prepare':prepare,'publish':publish,'harden':harden,'rollback':rollback}[sys.argv[1]]()
