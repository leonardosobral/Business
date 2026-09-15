"""Server-side restoration. Credentials arrive only over SSH stdin; never printed."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile

ROOT = Path('/var/www/conteudo.roadrunners.run')
TARGET = ROOT / 'config/content.local.cfm'
BASELINE = '9cdd1db30441944227de588ea8c8f167fd9889766eadb440bd57a61a78682256'
KEYS = ('sixCommGmailClientId', 'sixCommGmailClientSecret', 'sixCommGmailRedirectUri')


def main():
    original_client = sys.argv[1:] == ['original-login-client']
    if sys.argv[1:] and not original_client:
        raise RuntimeError('Unsupported restoration mode.')
    baseline = 'ba844ddb0bc5739ccae303540602164138a09a94a183b534e51f2310d75ad886' if original_client else BASELINE
    values = json.load(sys.stdin)
    if set(values) != set(KEYS) or not all(isinstance(v, str) for v in values.values()):
        raise RuntimeError('Unexpected configuration fields.')
    if not re.fullmatch(r'[0-9]+-[a-zA-Z0-9]+\.apps\.googleusercontent\.com', values[KEYS[0]]):
        raise RuntimeError('Invalid existing client identifier; value withheld.')
    if not re.fullmatch(r'[A-Za-z0-9_-]{20,200}', values[KEYS[1]]):
        raise RuntimeError('Invalid existing client secret; value withheld.')
    if values[KEYS[2]] != 'https://conteudo.roadrunners.run/admin/google_callback.cfm':
        raise RuntimeError('Unexpected production callback.')
    if TARGET.is_symlink():
        raise RuntimeError('Refusing symbolic link target.')
    original = TARGET.read_bytes()
    if hashlib.sha256(original).hexdigest() != baseline:
        raise RuntimeError('Production configuration changed; refusing overwrite.')
    for relative, expected in {
        'inc/sixcomm_gmail_api.cfc': '1eae0a3fb7a13137a66705707087e6cc1ce7586716c3184237f7c444f3a12c6f',
        'inc/content_local_config.cfc': 'f4a4ddafcff7307cbf906fd3b388a34fe7859ba3df928ce6ea46cc30a99b9a12',
    }.items():
        if hashlib.sha256((ROOT / relative).read_bytes()).hexdigest() != expected:
            raise RuntimeError('Runtime baseline changed; refusing restoration.')
    source = original.decode('utf-8')
    if not original_client and any(re.search(r'(?m)^\s*' + key + r'\s*=', source) for key in KEYS):
        raise RuntimeError('Dedicated configuration already exists.')
    ending = '\n};\n</cfscript>\n'
    if not source.endswith(ending):
        raise RuntimeError('Unexpected configuration structure.')
    if original_client:
        candidate_text = source
        for key in KEYS:
            pattern = r'(?m)^(    ' + key + r' = ")[^"\r\n]+("[,]?)$'
            candidate_text, count = re.subn(pattern, lambda m: m[1] + values[key] + m[2], candidate_text)
            if count != 1:
                raise RuntimeError('Unexpected existing OAuth field representation.')
        candidate = candidate_text.encode('utf-8')
    else:
        additions = ''.join(',\n    ' + key + ' = "' + values[key] + '"' for key in KEYS)
        candidate = (source[:-len(ending)] + additions + ending).encode('utf-8')
    backup = Path(tempfile.mkdtemp(prefix='content-sixcomm-oauth.', dir='/var/backups'))
    os.chmod(backup, 0o700)
    shutil.copy2(TARGET, backup / 'content.local.cfm.before')
    os.chmod(backup / 'content.local.cfm.before', 0o600)
    (backup / 'manifest.json').write_text(json.dumps({
        'target': str(TARGET), 'before_sha256': baseline,
        'after_sha256': hashlib.sha256(candidate).hexdigest(), 'changed_keys': KEYS,
    }))
    metadata = TARGET.stat()
    fd, temporary = tempfile.mkstemp(prefix='.sixcomm-restore-', dir=TARGET.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(candidate)
            stream.flush()
            os.fsync(stream.fileno())
        os.chown(temporary, metadata.st_uid, metadata.st_gid)
        os.chmod(temporary, metadata.st_mode & 0o777)
        if TARGET.read_bytes() != original:
            raise RuntimeError('Production configuration changed during staging.')
        os.replace(temporary, TARGET)
        if TARGET.read_bytes() != candidate:
            raise RuntimeError('Published configuration verification failed.')
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(json.dumps({'restored': True, 'changed_keys': KEYS, 'backup': str(backup),
                      'existing_secret_preserved': True, 'restart_required': False}))


if __name__ == '__main__':
    try:
        main()
    except Exception:
        print('Restoration stopped safely; configuration values withheld.', file=sys.stderr)
        sys.exit(1)
