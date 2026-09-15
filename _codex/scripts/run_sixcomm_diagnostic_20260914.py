"""Run on production. Ephemeral HMAC-protected probe removed in finally."""
import hashlib
import hmac
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid

ROOT = Path('/var/www/conteudo.roadrunners.run')
BACKUP = Path('/var/backups/content-sixcomm-oauth.0d8rxvcj')
target = ROOT / ('sixcomm_diagnostic_' + uuid.uuid4().hex + '.cfm')
body = b'{"diagnostic":"sixcomm-oauth-20260914"}'
if sys.argv[1:] == ['candidate']:
    candidate_values = json.load(sys.stdin)
    assert set(candidate_values) == {'clientId', 'clientSecret'}
    assert all(isinstance(v, str) and 20 <= len(v) <= 300 for v in candidate_values.values())
    body = json.dumps({'diagnostic': 'sixcomm-oauth-20260914', 'candidate': candidate_values}).encode()
source = (ROOT / 'api/admin/importers/sixcomm.cfm').read_text()
auth = source.split('request.sixCommEmailImporterExecutionMode = "api";')[0]
assert 'expectedSignature' in auth and 'sendJson(401' in auth and auth.count('<cfscript>') == 1
guard = '\nif ((payloadData.diagnostic ?: "") NEQ "sixcomm-oauth-20260914") { sendJson(400, {status="invalid_body"}); abort; }\n'
guard += 'request.sixCommDiagnosticAuthorized = true;\n</cfscript>\n'
candidate = auth + guard + (BACKUP / 'diagnose.cfm').read_text()
secret = ''
for line in (ROOT / 'config/content.local.cfm').read_text().splitlines():
    if '=' in line:
        key, value = line.split('=', 1)
        if key.strip() == 'importerHandoffSecret':
            secret = value.strip().rstrip(',').strip().strip('"')
assert secret


def call(headers):
    config = ['url = ' + json.dumps('https://conteudo.roadrunners.run/' + target.name),
              'data = ' + json.dumps(body.decode()), 'header = "Content-Type: application/json"']
    config += ['header = ' + json.dumps(k + ': ' + v) for k, v in headers.items()]
    response = subprocess.run(['curl', '-sS', '--max-time', '45', '--config', '-', '--write-out', '\n%{http_code}'],
                              input='\n'.join(config), text=True, capture_output=True, check=True)
    raw, code = response.stdout.rsplit('\n', 1)
    return int(code), raw


try:
    fd = os.open(target, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o640)
    with os.fdopen(fd, 'w') as stream:
        stream.write(candidate)
    metadata = (ROOT / 'api/admin/importers/sixcomm.cfm').stat()
    os.chown(target, metadata.st_uid, metadata.st_gid)
    os.chmod(target, metadata.st_mode & 0o777)
    code, _ = call({})
    print(json.dumps({'unauthenticated_http': code}))
    assert code == 401
    timestamp = str(int(time.time()))
    code, _ = call({'X-RR-Handoff-Timestamp': timestamp, 'X-RR-Handoff-Signature': '0'*64})
    print(json.dumps({'invalid_signature_http': code}))
    assert code == 401
    signature = hmac.new(secret.encode(), timestamp.encode() + b'.' + body, hashlib.sha256).hexdigest()
    code, raw = call({'X-RR-Handoff-Timestamp': timestamp, 'X-RR-Handoff-Signature': signature})
    print(json.dumps({'authenticated_http': code}))
    if code == 200 and 'SIXCOMM_DIAG ' in raw:
        report = json.loads(raw.split('SIXCOMM_DIAG ',1)[1].strip())
        print(json.dumps(report))
    else:
        print('Diagnostic did not complete; raw response withheld.')
finally:
    if target.exists() and target.read_text() == candidate:
        target.unlink()
        print(json.dumps({'temporary_endpoint_removed': True}))
