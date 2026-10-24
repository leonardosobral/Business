"""One-time restoration of the omitted private route storage; refuse existing target."""
import hashlib
import io
import json
from pathlib import Path
import shlex
import subprocess
import tarfile

SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-i', '/Users/leonardosobral/.ssh/webs']
OLD = 'root@172.233.26.63'
NEW = 'root@ssh.runnerhub.run'
BACKUP = '/var/backups/percursos-storage-20261013'

def remote(host, command, data=None):
    return subprocess.run(SSH + [host, command], input=data, capture_output=True, check=True, timeout=55).stdout

source_script = '''
from pathlib import Path
import hashlib,json
p=Path('/var/lib/roadrunners/percursos')
assert p.is_dir() and not p.is_symlink()
result={}
for f in sorted(p.rglob('*')):
 assert not f.is_symlink(), str(f)
 if f.is_file(): result[str(f.relative_to(p))]=hashlib.sha256(f.read_bytes()).hexdigest()
print(json.dumps(result))
'''
manifest = json.loads(remote(OLD, 'python3 -c ' + shlex.quote(source_script)))
assert len(manifest) == 257, 'Source changed; inspect before restoring'
archive = remote(OLD, 'tar -czf - -C /var/lib/roadrunners percursos')
with tarfile.open(fileobj=io.BytesIO(archive), mode='r:gz') as tf:
    found = {}
    for item in tf.getmembers():
        assert (item.name == 'percursos' or item.name.startswith('percursos/')) and '..' not in Path(item.name).parts
        assert item.isdir() or item.isfile()
        if item.isfile():
            found[str(Path(item.name).relative_to('percursos'))] = hashlib.sha256(tf.extractfile(item).read()).hexdigest()
assert found == manifest, 'Source snapshot mismatch'
remote(NEW, 'test ! -e /var/lib/roadrunners/percursos && test ! -L /var/lib/roadrunners/percursos && umask 077 && mkdir ' + BACKUP + ' && cat > ' + BACKUP + '/percursos.tar.gz', archive)
remote(NEW, 'cat > ' + BACKUP + '/source-sha256.json', json.dumps(manifest, indent=2).encode())

restore = '''
from pathlib import Path
import hashlib,json,os,pwd,subprocess,tarfile,tempfile
backup=Path('/var/backups/percursos-storage-20261013')
target=Path('/var/lib/roadrunners/percursos')
assert not target.exists() and not target.is_symlink()
expected=json.loads((backup/'source-sha256.json').read_text())
parent=target.parent
parent.mkdir(mode=0o755,exist_ok=True)
assert not parent.is_symlink()
stage=Path(tempfile.mkdtemp(prefix='.percursos-restore-',dir=parent))
account=pwd.getpwnam('coldfusion')
with tarfile.open(backup/'percursos.tar.gz','r:gz') as tf:
 for m in tf.getmembers():
  assert (m.name == 'percursos' or m.name.startswith('percursos/')) and '..' not in Path(m.name).parts
  assert m.isdir() or m.isfile()
 tf.extractall(stage,filter='data')
root=stage/'percursos'
actual={str(f.relative_to(root)):hashlib.sha256(f.read_bytes()).hexdigest() for f in root.rglob('*') if f.is_file()}
assert actual==expected
for f in [root]+list(root.rglob('*')):
 os.chown(f,account.pw_uid,account.pw_gid)
 os.chmod(f,0o750 if f.is_dir() else 0o640)
assert not target.exists()
root.rename(target)
stage.rmdir()
check="from pathlib import Path; import tempfile,os; p=Path('/var/lib/roadrunners/percursos'); fs=[f for f in p.rglob('*') if f.is_file()]; assert len(fs)==257; [f.open('rb').read(1) for f in fs]; fd,n=tempfile.mkstemp(prefix='.storage-probe-',dir=p); os.write(fd,b'probe'); os.close(fd); assert Path(n).read_bytes()==b'probe'; Path(n).unlink(); print('read_all_and_write_ok')"
probe=subprocess.check_output(['runuser','-u','coldfusion','--','python3','-c',check],text=True).strip()
report={'files':len(actual),'all_hashes_match':True,'owner':'coldfusion:coldfusion','directories':'0750','files_mode':'0640','storage':str(target),'backup':str(backup),'probe':probe}
(backup/'restoration.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
'''
result = remote(NEW, 'python3 -c ' + shlex.quote(restore))
Path(__file__).with_name('restoration.json').write_bytes(result)
print(result.decode())
