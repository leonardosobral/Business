"""Run only on rr-prod. Restore the existing integration secret; never print it."""
import json
import os
from pathlib import Path
import re
import sys
import hashlib
import hmac
from datetime import datetime
from zoneinfo import ZoneInfo
import subprocess

ROOT = Path('/var/www/conteudo.roadrunners.run')
SOURCE = Path('/var/www/business.roadrunners.run/config/business.local.cfm')
TARGET = ROOT / 'config/content.local.cfm'
BACKUP = Path('/var/backups/content-importer-secret.Zo5F4h')
ENDPOINT = 'https://conteudo.roadrunners.run/api/admin/importers/corridanoar.cfm'


def existing_secret():
    matches = re.findall(r'''(?i)["']?conteudo_internal["']?\s*[:=]\s*["']([^"']*)["']''', SOURCE.read_text())
    if len(matches) != 1 or not re.fullmatch(r'[A-Za-z0-9_-]{32,512}', matches[0]):
        raise RuntimeError('Existing secret is absent, ambiguous, or has an unsupported representation; no value printed.')
    return matches[0]


def request(url, data=None, headers=None):
    # Same public HTTPS route; curl transport also used by the server's jobs.
    # Signature stays in stdin rather than command arguments or logs.
    config = ['url = ' + json.dumps(url)]
    for key, value in (headers or {}).items():
        config.append('header = ' + json.dumps(key + ': ' + value))
    if data is not None:
        config.append('data = ' + json.dumps(data.decode('utf-8')))
    result = subprocess.run(['curl', '-sS', '--max-time', '45', '--config', '-', '--write-out', '\n%{http_code}'],
                            input='\n'.join(config), text=True, capture_output=True, check=True)
    raw, code = result.stdout.rsplit('\n', 1)
    return int(code), raw


def restore():
    for relative, expected in {
        'Application.cfc': 'cf7c9fdbd67cac8cc0cdd064b1096e3fc2ee8c231e3b34a1409c2f1946fcd1bf',
        'inc/content_local_config.cfc': 'f4a4ddafcff7307cbf906fd3b388a34fe7859ba3df928ce6ea46cc30a99b9a12',
        'reset.cfm': '297c0eac1a6f6118dc225054a82eeb58b4d1be4012e88035ae8ee3110ad26209',
    }.items():
        if hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() != expected:
            raise RuntimeError('Runtime baseline changed; refusing restoration.')
    if TARGET.exists() or TARGET.is_symlink():
        raise RuntimeError('Configuration already exists; refusing overwrite.')
    secret = existing_secret()
    content = '<cfscript>\ncontentLocalConfig = {\n    importerHandoffSecret = "' + secret + '"\n};\n</cfscript>\n'
    # Root-only recovery area records prior absence and preserves the exact candidate.
    os.chmod(BACKUP, 0o700)
    (BACKUP / 'baseline.json').write_text(json.dumps({'target': str(TARGET), 'previously_absent': True, 'source_ref': 'conteudo_internal'}))
    candidate = BACKUP / 'content.local.cfm'
    fd = os.open(candidate, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as stream:
        stream.write(content)
        stream.flush()
        os.fsync(stream.fileno())
    metadata = SOURCE.stat()
    os.chown(candidate, metadata.st_uid, metadata.st_gid)
    os.chmod(candidate, 0o640)
    # Atomic creation with no overwrite, even if another operator creates the target.
    os.link(candidate, TARGET)
    if TARGET.read_text() != content:
        raise RuntimeError('Published configuration verification failed.')
    print(json.dumps({'restored': True, 'same_existing_secret': True, 'backup': str(BACKUP)}))
    code, _ = request('https://conteudo.roadrunners.run/reset.cfm')
    print(json.dumps({'application_reload_http': code}))
    if code != 200:
        raise RuntimeError('Application reload did not return HTTP 200.')


def validate():
    secret = existing_secret()
    # Invalid body intentionally stops after HMAC verification, before DB/import work.
    body = b'[]'
    # Match the Business runner's local dateTimeFormat(now(), ...) contract.
    timestamp = datetime.now(ZoneInfo('America/Sao_Paulo')).strftime('%Y-%m-%d %H:%M:%S')
    signature = hmac.new(secret.encode(), timestamp.encode() + b'.' + body, hashlib.sha256).hexdigest()
    checks = [
        ('unauthenticated', {}, 401, 'unauthorized'),
        ('wrong_signature', {'X-RR-Handoff-Timestamp': timestamp, 'X-RR-Handoff-Signature': '0' * 64}, 401, 'unauthorized'),
        ('authenticated_no_import', {'X-RR-Handoff-Timestamp': timestamp, 'X-RR-Handoff-Signature': signature}, 400, 'invalid_body'),
    ]
    for name, headers, expected_code, expected_status in checks:
        headers['Content-Type'] = 'application/json'
        code, raw = request(ENDPOINT, body, headers)
        payload = json.loads(raw)
        status = payload.get('status', payload.get('STATUS', ''))
        print(json.dumps({'check': name, 'http': code, 'status': status}))
        if code != expected_code or status != expected_status:
            raise RuntimeError('Authentication validation failed; no response body or credentials printed.')


if __name__ == '__main__':
    if sys.argv[1:] == ['restore']:
        restore()
        validate()
    elif sys.argv[1:] == ['validate']:
        validate()
    else:
        raise SystemExit('Use restore or validate.')
