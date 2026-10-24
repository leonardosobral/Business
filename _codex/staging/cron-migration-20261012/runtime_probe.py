"""Read runtime and log evidence, without executing a cron job."""
from pathlib import Path
from collections import deque
import json
import re
import subprocess
import xml.etree.ElementTree as ET


def redact(value):
    value = re.sub(r'(?i)(X-[\w-]*(?:token|key)\s*:\s*)[^\s"\']+', r'\1[REDACTED]', value)
    value = re.sub(r'(?i)(https?://[^\s"\'?]+)\?[^\s"\']*', r'\1?[QUERY REDACTED]', value)
    return value


out = {}
root = Path('/var/www/business.roadrunners.run')
cron = subprocess.run(['crontab', '-l'], capture_output=True, text=True).stdout
match = re.search(r'X-Business-Cron-Token:\s*([^"\s]+)', cron)
config = (root / 'config/business.local.cfm').read_text()
local = re.search(r'["\']?cronRunnerToken["\']?\s*[=:]\s*["\']([^"\']+)', config)
out['cron_token_matches_file'] = bool(match and local and match[1] == local[1])
out['cron_urls'] = [redact(x) for x in re.findall(r'https?://[^"\s]+', cron)]
for local_origin in [False, True]:
    args = ['curl', '-sS', '--max-time', '20', '-w', '\n%{http_code}']
    if local_origin:
        args += ['--resolve', 'business.roadrunners.run:443:127.0.0.1']
    # Deliberately omit token: authentication failure cannot execute jobs.
    args += ['https://business.roadrunners.run/cron-jobs/runner.cfm']
    result = subprocess.run(args, capture_output=True, text=True, timeout=25)
    body, _, status = result.stdout.rpartition('\n')
    response = {'curl_rc': result.returncode, 'http': status, 'stderr': result.stderr[:500]}
    try:
        response['json'] = json.loads(body)
    except ValueError:
        response['title'] = re.findall(r'<title>(.*?)</title>', body, re.S)[:1]
        response['body_excerpt'] = re.sub('<[^>]+>', ' ', body)[:300]
    out['local' if local_origin else 'public'] = response
out['logs'] = {}
for directory in [Path('/var/log/apache2'), root / 'logs']:
    if not directory.exists():
        continue
    for path in directory.glob('*'):
        if path.is_file() and not path.name.endswith(('.gz', '.1')) and ('business' in path.name or path.name in ['access.log', 'error.log']):
            with path.open(errors='replace') as stream:
                tail = deque(stream, maxlen=3000)
            lines = [redact(x.strip()) for x in tail if '/cron-jobs/runner.cfm' in x]
            out['logs'][str(path)] = lines[-15:]
for base in Path('/opt').glob('*'):
    path = base / 'cfusion/logs/exception.log'
    if path.exists():
        with path.open(errors='replace') as stream:
            tail = deque(stream, maxlen=1000)
        out['logs'][str(path)] = [redact(x.strip())[:1500] for x in tail if 'cron_jobs' in x or 'cron-jobs' in x][-10:]
    path = base / 'cfusion/logs/scheduler.log'
    if path.exists():
        with path.open(errors='replace') as stream:
            tail = deque(stream, maxlen=6)
        out['logs'][str(path)] = [redact(x.strip())[:1200] for x in tail]
out['java_processes'] = subprocess.run(['pgrep', '-x', 'java'], capture_output=True, text=True).stdout.splitlines()
print(json.dumps(out, indent=2))
