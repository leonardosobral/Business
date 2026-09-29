"""Scoped menu release; reuse the existing backup/compile/atomic release helpers."""
from pathlib import Path
import json
import shlex
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
TARGET = 'includes/estrutura/sidenav.cfm'
BEFORE = '9ebf363c67f8f823f9d6735ba46396e255b313a97a0e47cc5a81ba19d97a9399'
STAGE = '/var/backups/business-menu-experiencia-20260928'
if len(sys.argv) > 2:
    assert sys.argv[2] == 'plataforma-ordem'
    BEFORE = '212660ccee163f407e9c3b1bb5fc4a1b963fd1fd12115256c4cad35c93e11f49'
    STAGE = '/var/backups/business-menu-plataforma-ordem-20260928'
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i',
       '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run']
mode = sys.argv[1]
assert mode in ('prepare', 'compile', 'publish', 'verify', 'rollback')
source = (ROOT / '_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0]
source = source.replace('ROOT=Path(__file__).resolve().parents[2]',
                        "ROOT=Path('/var/www/business.roadrunners.run')")
source = source.replace('/var/backups/business-error-triage-20260926', STAGE)
source += '''
payload=json.load(sys.stdin)
root=Path('/var/www/business.roadrunners.run')
stage=Path(''' + repr(STAGE) + ''')
mode=payload['mode']
if mode=='prepare':
 result=prepare(root,stage,payload['files'],payload['before'])
elif mode=='publish':
 compiled=json.loads((stage/'compile.json').read_text())
 if compiled['returncode']!=0 or compiled['compiled_files']!=1:
  raise RuntimeError('Compilation not confirmed')
 result=publish(root,stage)
else:
 result=remote(mode,{})
print(json.dumps(result))
'''
payload = {'mode': mode}
if mode == 'prepare':
    payload['files'] = {TARGET: (ROOT / TARGET).read_text()}
    payload['before'] = {TARGET: BEFORE}
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(source)],
                        input=json.dumps(payload), capture_output=True, text=True, timeout=180)
if result.returncode:
    print(result.stderr[-4000:])
    sys.exit(result.returncode)
report = json.loads(result.stdout)
print(json.dumps(report, indent=2))
if mode == 'compile' and (report['returncode'] != 0 or report['compiled_files'] != 1):
    sys.exit(1)
