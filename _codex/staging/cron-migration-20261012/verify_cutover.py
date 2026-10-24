"""Verify cutover backups, cron state and completed runner requests."""
from pathlib import Path
from collections import deque
import datetime
import hashlib
import json
import subprocess

report = {'measured_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat()}
cron = subprocess.run(['crontab', '-l'], capture_output=True, check=True).stdout
report['active_runner_entries'] = sum('business.roadrunners.run/cron-jobs/runner.cfm' in line and not line.lstrip().startswith('#') for line in cron.decode().splitlines())
report['crontab_sha256'] = hashlib.sha256(cron).hexdigest()
report['backups'] = []
for pattern in ['business-cron-cutover-20261012T*', 'business-cron-reload-20261012T*']:
    for backup in Path('/var/backups').glob(pattern):
        manifest = json.loads((backup / 'manifest.json').read_text())
        item = {'path': str(backup), 'directory_mode': oct(backup.stat().st_mode & 0o777)}
        if 'before_sha256' in manifest and isinstance(manifest['before_sha256'], dict):
            item['backup_hashes_match'] = all(hashlib.sha256((backup / name).read_bytes()).hexdigest() == sha for name, sha in manifest['before_sha256'].items())
            item['new_cron_unchanged'] = (backup / 'root.crontab').read_bytes() == cron
        else:
            item['backup_hashes_match'] = hashlib.sha256((backup / 'root.crontab.before').read_bytes()).hexdigest() == manifest['before_sha256']
            item['old_cron_matches_disabled_candidate'] = (backup / 'root.crontab.after').read_bytes() == cron
        report['backups'].append(item)
log = Path('/var/log/apache2/access.log')
if log.exists():
    with log.open(errors='replace') as stream:
        tail = deque(stream, maxlen=10000)
    report['latest_runner_requests'] = [line.strip() for line in tail if 'GET /cron-jobs/runner.cfm?limit=5 HTTP' in line][-8:]
report['cron_service'] = subprocess.run(['systemctl', 'is-active', 'cron'], capture_output=True, text=True).stdout.strip()
print(json.dumps(report, indent=2))
