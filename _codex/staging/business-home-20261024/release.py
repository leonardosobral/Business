"""Scoped Business home release driver. No operation runs without an explicit mode.

prepare and compile write only private staging areas on the server. publish is a
separate command for the primary agent after functional and independent review.
"""
from pathlib import Path
import base64
import hashlib
import json
import shlex
import subprocess
import sys

STAGE = Path(__file__).resolve().parent
ROOT = STAGE.parents[2]
NAMES = [
    'includes/backend/business_home_metrics.cfm',
    'includes/estrutura/home_admin_decision_view.cfm',
    'assets/js/business-home-dashboard.js',
    'assets/css/admin-dashboard.css',
    'includes/estrutura/home_admin_dashboard.cfm',
]
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o',
       'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ('prepare', 'compile', 'publish', 'verify', 'rollback'):
        raise SystemExit('Usage: release.py prepare|compile|publish|verify|rollback')
    mode = sys.argv[1]
    baseline = json.loads((STAGE / 'production-baseline.json').read_text())
    files = {name: (ROOT / name).read_bytes() for name in NAMES}
    hashes = {name: hashlib.sha256(data).hexdigest() for name, data in files.items()}
    payload = {
        'mode': mode, 'hashes': hashes,
        'baseline': baseline['files'], 'watch': baseline['watch'],
    }
    if mode == 'prepare':
        payload['files'] = {name: base64.b64encode(data).decode() for name, data in files.items()}
    else:
        prepared = json.loads((STAGE / 'release-prepare.json').read_text())
        if hashes != prepared['candidate_hashes']:
            raise SystemExit('Local candidate changed after prepare; prepare a new private stage')
        payload['stage'] = prepared['stage']
        payload['manifest_sha256'] = prepared['manifest_sha256']
    command = 'python3 -c ' + shlex.quote((STAGE / 'release_remote.py').read_text())
    result = subprocess.run(SSH + [command], input=json.dumps(payload), capture_output=True,
                            text=True, timeout=220)
    if result.returncode:
        # Remote code produces controlled JSON; SSH failures have no secret output.
        print(result.stdout or result.stderr[-1500:])
        raise SystemExit(result.returncode)
    receipt = json.loads(result.stdout)
    (STAGE / ('release-' + mode + '.json')).write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt, indent=2))


if __name__ == '__main__':
    main()
