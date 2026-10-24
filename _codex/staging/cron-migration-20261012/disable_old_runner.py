"""Back up root crontab, disable only the Business runner, and verify readback."""
from pathlib import Path
import datetime
import hashlib
import json
import os
import subprocess
import tempfile

os.umask(0o077)


def crontab():
    result = subprocess.run(['crontab', '-l'], capture_output=True, check=True)
    return result.stdout


def digest(value):
    return hashlib.sha256(value).hexdigest()


before = crontab()
lines = before.decode().splitlines(keepends=True)
targets = [i for i, line in enumerate(lines) if line.strip() and not line.lstrip().startswith('#') and 'https://business.roadrunners.run/cron-jobs/runner.cfm' in line]
if len(targets) != 1:
    raise RuntimeError('Expected exactly one active Business runner entry; refusing to modify cron.')
target = lines[targets[0]]
if not target.startswith('* * * * * /usr/bin/curl ') or 'X-Business-Cron-Token:' not in target:
    raise RuntimeError('Unexpected runner command; refusing to modify cron.')
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
backup = Path(tempfile.mkdtemp(prefix='business-cron-cutover-' + stamp + '-', dir='/var/backups'))
(backup / 'root.crontab.before').write_bytes(before)
lines[targets[0]] = '# Business runner disabled after migration to 172.233.2.76; backup: ' + str(backup / 'root.crontab.before') + '\n'
candidate = ''.join(lines).encode()
(backup / 'root.crontab.after').write_bytes(candidate)
if crontab() != before:
    raise RuntimeError('Crontab changed after backup; review before applying.')
subprocess.run(['crontab', '-'], input=candidate, capture_output=True, check=True)
actual = crontab()
if actual != candidate:
    raise RuntimeError('Crontab readback mismatch; backup preserved for recovery.')
report = {
    'server': '172.233.26.63', 'changed_at_utc': stamp,
    'backup': str(backup), 'before_sha256': digest(before), 'after_sha256': digest(actual),
    'disabled_runner_entries': len(targets),
    'remaining_active_runner_entries': sum('business.roadrunners.run/cron-jobs/runner.cfm' in x and not x.lstrip().startswith('#') for x in actual.decode().splitlines()),
    'other_lines_preserved': [x for i, x in enumerate(before.decode().splitlines(keepends=True)) if i not in targets] == [x for i, x in enumerate(actual.decode().splitlines(keepends=True)) if i not in targets]
}
(backup / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
