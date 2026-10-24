"""Scoped production repairs. Reuse existing secrets; never print their values."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import hmac
import json
import os
import re
import subprocess
import sys
import tempfile

BUSINESS = Path('/var/www/business.roadrunners.run')
NEWS = Path('/var/www/conteudo.roadrunners.run')
RR = Path('/var/www/roadrunners.com.br')
os.umask(0o077)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def secret(path, key):
    pattern = r'''(?i)["']?''' + re.escape(key) + r'''["']?\s*[:=]\s*["']([^"']*)["']'''
    found = re.findall(pattern, path.read_text())
    if len(found) != 1 or not found[0].strip():
        raise RuntimeError('Missing or ambiguous existing secret reference: ' + key)
    return found[0].strip()


def request(url, body=None, signing_secret=None, invalid_signature=False):
    config = ['url = ' + json.dumps(url)]
    if body is not None:
        config += ['data = ' + json.dumps(body), 'header = "Content-Type: application/json; charset=utf-8"']
    if signing_secret is not None:
        timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')
        signature = '0' * 64 if invalid_signature else hmac.new(signing_secret.encode(), (timestamp + '.' + body).encode(), hashlib.sha256).hexdigest()
        config += ['header = ' + json.dumps('X-RR-Handoff-Timestamp: ' + timestamp), 'header = ' + json.dumps('X-RR-Handoff-Signature: ' + signature)]
    result = subprocess.run(['curl', '-sS', '--max-time', '45', '--config', '-', '-w', '\n%{http_code}'], input='\n'.join(config), text=True, capture_output=True, timeout=50)
    raw, _, code = result.stdout.rpartition('\n')
    if result.returncode:
        raise RuntimeError('HTTP transport failed without exposing request credentials.')
    response = {'http': int(code)}
    try:
        payload = {k.lower(): v for k, v in json.loads(raw).items()}
        response['status'] = payload.get('status', payload.get('error', ''))
        response['success'] = payload.get('success')
    except (ValueError, AttributeError):
        response['json'] = False
    return response


def backup(prefix, paths):
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    directory = Path(tempfile.mkdtemp(prefix=prefix + '-' + stamp + '-', dir='/var/backups'))
    hashes = {}
    for path in paths:
        target = directory / path.relative_to('/var/www')
        target.parent.mkdir(parents=True, exist_ok=True)
        content = path.read_bytes()
        target.write_bytes(content)
        hashes[str(path)] = digest(content)
    (directory / 'manifest.json').write_text(json.dumps({'before': hashes}, indent=2) + '\n')
    return directory, hashes


def save(directory, report):
    (directory / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2), flush=True)


def news():
    shared = secret(BUSINESS / 'config/business.local.cfm', 'conteudo_internal')
    if shared != secret(NEWS / 'config/content.local.cfm', 'importerHandoffSecret'):
        raise RuntimeError('Existing News and Business secrets differ; no reload applied.')
    paths = [NEWS / name for name in ['Application.cfc', 'reset.cfm', 'inc/content_local_config.cfc', 'config/content.local.cfm']]
    directory, before = backup('news-importers-reload', paths)
    report = {'backup': str(directory), 'before_sha256': before, 'existing_secret_matches': True}
    endpoint = 'https://conteudo.roadrunners.run/api/admin/importers/contrarelogio.cfm'
    report['before_auth_guard'] = request(endpoint, '[]')
    report['reload'] = request('https://conteudo.roadrunners.run/reset.cfm')
    if report['reload']['http'] != 200:
        save(directory, report)
        raise RuntimeError('News reload failed.')
    report['checks'] = []
    for name in ['contrarelogio', 'corridanoar', 'cbat', 'jornalcorrida', 'sixcomm']:
        url = 'https://conteudo.roadrunners.run/api/admin/importers/' + name + '.cfm'
        checks = {'importer': name, 'unauthenticated': request(url, '[]'), 'invalid_signature': request(url, '[]', shared, True), 'authenticated_invalid_body': request(url, '[]', shared)}
        report['checks'].append(checks)
    report['runtime_files_unchanged'] = all(digest(path.read_bytes()) == before[str(path)] for path in paths)
    report['checked_at_utc'] = datetime.now(timezone.utc).isoformat()
    save(directory, report)
    if any(c['unauthenticated']['http'] != 401 or c['invalid_signature']['http'] != 401 or c['authenticated_invalid_body']['http'] != 400 for c in report['checks']):
        raise RuntimeError('News authentication validation failed; no import was executed by the probes.')


def crm():
    target = BUSINESS / 'config/business.local.cfm'
    shared = secret(target, 'road_runners_handoff')
    if shared != secret(RR / 'config/strava.local.cfm', 'handoffSecret'):
        raise RuntimeError('Existing Road Runners secret does not match the Business cron reference.')
    body = json.dumps({'scope': 'crm.worker', 'environment': 'prod', 'action': 'cron.migration.probe', 'input': {}, 'actor_id': 0, 'impersonating': False}, separators=(',', ':'))
    endpoint = 'https://roadrunners.run/api/crm-interno/worker.cfm'
    preflight = {'wrong_signature': request(endpoint, body, shared, True), 'existing_dispatch_secret': request(endpoint, body, secret(target, 'notificationDispatchSecret')), 'shared_cron_secret': request(endpoint, body, shared)}
    if preflight['wrong_signature']['http'] != 403 or preflight['shared_cron_secret'].get('status') != 'invalid_action':
        print(json.dumps({'preflight': preflight}))
        raise RuntimeError('Read-only CRM signature preflight failed; no configuration changed.')
    paths = [target, BUSINESS / 'Application.cfc', BUSINESS / 'services/CrmClient.cfc', RR / 'api/crm-interno/_common.cfm', RR / 'services/crm/CrmSecurity.cfc']
    directory, before = backup('business-crm-shared-config', paths)
    original = target.read_bytes()
    metadata = target.stat()
    pattern = r'''(["']notificationDispatchSecret["']\s*=\s*)(["'])([^"']*)(["'])'''
    candidate, count = re.subn(pattern, lambda m: m[1] + m[2] + shared + m[4], original.decode())
    if count != 1 or not re.fullmatch(r'[A-Za-z0-9_-]{32,512}', shared):
        raise RuntimeError('Unexpected local config format; no configuration changed.')
    report = {'backup': str(directory), 'before_sha256': before, 'preflight': preflight, 'changed_field': 'notificationDispatchSecret', 'existing_source_ref': 'cronSecrets.road_runners_handoff', 'credentials_generated': False}
    staged = directory / 'candidate.cfm'
    staged.write_text(candidate)
    if any(digest(path.read_bytes()) != before[str(path)] for path in paths):
        raise RuntimeError('Production baseline changed; no configuration changed.')
    fd, temp_name = tempfile.mkstemp(prefix='.business-crm-config-', dir=target.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(candidate.encode())
            stream.flush()
            os.fsync(stream.fileno())
        os.chown(temp_name, metadata.st_uid, metadata.st_gid)
        os.chmod(temp_name, metadata.st_mode & 0o777)
        os.replace(temp_name, target)
    finally:
        if Path(temp_name).exists():
            Path(temp_name).unlink()
    report['after_sha256'] = digest(target.read_bytes())
    report['other_fields_unchanged'] = re.sub(pattern, '', original.decode()) == re.sub(pattern, '', target.read_text())
    report['reload'] = request('https://business.roadrunners.run/?resetApp')
    report['runner_guard'] = request('https://business.roadrunners.run/cron-jobs/runner.cfm')
    report['checked_at_utc'] = datetime.now(timezone.utc).isoformat()
    save(directory, report)
    if report['reload']['http'] != 200 or report['runner_guard']['http'] != 401 or not report['other_fields_unchanged']:
        raise RuntimeError('CRM publication verification failed; inspect saved backup before recovery.')


if sys.argv[1:] == ['news']:
    news()
elif sys.argv[1:] == ['crm']:
    crm()
else:
    raise SystemExit('Use news or crm.')
