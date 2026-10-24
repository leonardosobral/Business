"""Read-only server inventory. Suppress credentials and request query strings."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import socket
import subprocess
import xml.etree.ElementTree as ET


def command(args):
    result = subprocess.run(args, capture_output=True, text=True, timeout=20)
    return {'rc': result.returncode, 'output': redact(result.stdout + result.stderr)}


def redact(value):
    value = re.sub(r'(?i)(X-[\w-]*(?:token|key)\s*:\s*)[^\s"\']+', r'\1[REDACTED]', value)
    value = re.sub(r'(?i)(Authorization\s*:\s*)[^"\'\n]+', r'\1[REDACTED]', value)
    value = re.sub(r'(?i)(https?://[^\s"\'?]+)\?[^\s"\']*', r'\1?[QUERY REDACTED]', value)
    value = re.sub(r'(?i)((?:\w*TOKEN|\w*SECRET|\w*PASSWORD|\w*API_KEY)\s*=\s*)[^\n]+', r'\1[REDACTED]', value)
    return value


out = {'host': socket.gethostname(), 'clock': command(['date', '--iso-8601=seconds']), 'dns': {}}
for host in ['business.roadrunners.run', 'ssh.runnerhub.run']:
    try:
        out['dns'][host] = socket.gethostbyname_ex(host)[2]
    except OSError as error:
        out['dns'][host] = str(error)
paths = [Path('/etc/crontab')] + list(Path('/etc/cron.d').glob('*')) + list(Path('/var/spool/cron').rglob('*'))
out['crontabs'] = {str(p): redact(p.read_text(errors='replace')) for p in paths if p.is_file()}
out['timers'] = command(['systemctl', 'list-timers', '--all', '--no-pager'])
services = command(['systemctl', 'list-units', '--all', '--type=service', '--no-pager'])
out['services'] = '\n'.join(x for x in services['output'].splitlines() if re.search('coldfusion|apache|nginx|cron', x, re.I))
out['tools'] = {name: shutil.which(name) for name in ['psql', 'python3', 'curl']}
out['cf_config'] = {}
for base in Path('/opt').glob('*'):
    lib = base / 'cfusion/lib'
    if not lib.is_dir():
        continue
    for name in ['neo-cron.xml', 'neo-datasource.xml']:
        path = lib / name
        if not path.exists():
            continue
        data = path.read_bytes()
        doc = ET.fromstring(data)
        if name == 'neo-cron.xml':
            fields = []
            for node in doc.iter('var'):
                key = node.get('name', '')
                if any(s in key.lower() for s in ['password', 'username', 'proxy', 'cookie', 'header']):
                    continue
                if len(node) == 1 and node[0].tag in ['string', 'boolean', 'number', 'date']:
                    fields.append([key, redact(node[0].text or '')])
            out['cf_config'][str(path)] = {'sha256': hashlib.sha256(data).hexdigest(), 'fields': fields}
        else:
            out['cf_config'][str(path)] = {'runner_dba_present': b'runner_dba' in data}
out['web_roots'] = [str(p) for p in Path('/var/www').glob('*')]
root = Path('/var/www/business.roadrunners.run')
out['business_files'] = {}
for name in ['cron-jobs/runner.cfm', 'includes/backend/cron_jobs_service.cfm', 'Application.cfc', 'config/business.local.cfm']:
    path = root / name
    if path.is_file():
        data = path.read_bytes()
        out['business_files'][name] = {'size': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        if name.endswith('business.local.cfm'):
            out['business_files'][name]['cron_token_key_present'] = b'cronRunnerToken' in data
out['cron_journal'] = command(['journalctl', '-u', 'cron', '--since', '30 minutes ago', '-n', '20', '--no-pager'])
print(json.dumps(out, indent=2))
