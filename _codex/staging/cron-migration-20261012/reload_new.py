"""Back up relevant configuration, then use the existing Application reset endpoint."""
from pathlib import Path
import datetime
import hashlib
import json
import os
import re
import subprocess
import tempfile

os.umask(0o077)
root = Path('/var/www/business.roadrunners.run')
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
backup = Path(tempfile.mkdtemp(prefix='business-cron-reload-' + stamp + '-', dir='/var/backups'))
hashes = {}
for name in ['Application.cfc', 'bi/Application.cfc', 'config/business.local.cfm', 'cron-jobs/runner.cfm', 'includes/backend/cron_jobs_service.cfm']:
    data = (root / name).read_bytes()
    target = backup / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    hashes[name] = hashlib.sha256(data).hexdigest()
cron = subprocess.run(['crontab', '-l'], capture_output=True, check=True).stdout
(backup / 'root.crontab').write_bytes(cron)
active = [x for x in cron.decode().splitlines() if not x.lstrip().startswith('#') and 'business.roadrunners.run/cron-jobs/runner.cfm' in x]
if len(active) != 1:
    raise RuntimeError('Expected one active Business runner on new server.')
if 'ApplicationStop()' not in (root / 'Application.cfc').read_text():
    raise RuntimeError('Expected existing ApplicationStop handler.')


def request(path, local=True):
    args = ['curl', '-sS', '--max-time', '30', '-w', '\n%{http_code}']
    if local:
        args += ['--resolve', 'business.roadrunners.run:443:127.0.0.1']
    result = subprocess.run(args + ['https://business.roadrunners.run' + path], capture_output=True, text=True, timeout=35)
    body, _, status = result.stdout.rpartition('\n')
    report = {'curl_rc': result.returncode, 'http': status}
    try:
        report['json'] = json.loads(body)
    except ValueError:
        report['body_bytes'] = len(body.encode())
    return report


report = {'server': '172.233.2.76', 'backup': str(backup), 'before_sha256': hashes, 'before': request('/cron-jobs/runner.cfm')}
(backup / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n')
report['reset'] = request('/?resetApp')
report['after_local'] = request('/cron-jobs/runner.cfm')
report['after_public'] = request('/cron-jobs/runner.cfm', local=False)
report['runtime_files_unchanged'] = all(hashlib.sha256((root / name).read_bytes()).hexdigest() == sha for name, sha in hashes.items())
report['crontab_unchanged'] = subprocess.run(['crontab', '-l'], capture_output=True, check=True).stdout == cron
report['checked_at_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
(backup / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
if report['after_local']['http'] != '401' or report['after_public']['http'] != '401':
    raise RuntimeError('Expected authentication guard after reload; investigate before claiming recovery.')
