"""Publish only notification audience views, with immutable baseline and backup."""
from pathlib import Path
import json, shlex, subprocess, sys

ROOT = Path(__file__).resolve().parents[2]
STAGE = '/var/backups/business-notification-audience-20260928'
BEFORE = {
    'notificacoes/home.cfm': '57ec41a7e9a254abf727c03eed778c26204d84df98aa9a70dcd75af8a8f2d9b0',
    'notificacoes/includes/backend.cfm': '4f2b3e857039af0e9b1f3301884adf510941c7cfc91395128f62829d30c1f25b',
    'includes/estrutura/home_admin_dashboard.cfm': 'bc37462b7caddc63899329b7510dafce46b05ab7a5a141cc1b9789972f69a244'
}
FILES = ['notificacoes/includes/audience_filter.cfm', 'notificacoes/includes/backend.cfm',
         'notificacoes/home.cfm', 'includes/estrutura/home_admin_dashboard.cfm']
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=yes',
       '-i', '/Users/leonardosobral/.ssh/webs', 'root@ssh.runnerhub.run']
mode = sys.argv[1]
assert mode in ('prepare', 'compile', 'publish', 'verify', 'rollback')
source = (ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0]
source = source.replace('ROOT=Path(__file__).resolve().parents[2]', "ROOT=Path('/var/www/business.roadrunners.run')")
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
 if compiled['returncode']!=0 or compiled['compiled_files']!=4:
  raise RuntimeError('Compilation not confirmed')
 result=publish(root,stage)
else:
 result=remote(mode,{})
print(json.dumps(result))
'''
payload = {'mode': mode}
if mode == 'prepare':
    payload['files'] = {name: (ROOT/name).read_text() for name in FILES}
    payload['before'] = BEFORE
result = subprocess.run(SSH+['python3 -c '+shlex.quote(source)], input=json.dumps(payload),
                        capture_output=True, text=True, timeout=180)
if result.returncode:
    print(result.stderr[-4000:]); sys.exit(result.returncode)
report = json.loads(result.stdout)
print(json.dumps(report, indent=2))
if mode == 'compile' and (report['returncode'] != 0 or report['compiled_files'] != 4):
    sys.exit(1)
