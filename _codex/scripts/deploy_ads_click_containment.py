"""One-file, hash-guarded deployment approved for the 2026-09-11 CPC incident.

Run on the web host through SSH stdin. No endpoint execution or database access.
"""
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

target = Path('/var/www/roadrunners.com.br/api/ads/v1/cpc-click.cfm')
candidate = Path('/tmp/ads-click-compile.JsSAPD/cpc-click.cfm')
before = '846f76cc0c324d65fba8325d1a207895645ce228bf852ffce5390404f35bff82'
after = 'ff67e92dd0950e18970a38906b2c0c894fd1d5311e5bba0bd46f800283ffb2ab'
digest = lambda data: hashlib.sha256(data).hexdigest()
data = candidate.read_bytes()
assert digest(data) == after, 'Candidate changed; deployment aborted'
current = target.read_bytes()
assert digest(current) == before, 'Published file changed; deployment aborted'
attributes = target.stat()
backup_dir = Path(tempfile.mkdtemp(prefix='ads-click-containment-20260912.', dir='/var/backups'))
backup = backup_dir / 'cpc-click.cfm.before'
shutil.copy2(target, backup)
assert digest(backup.read_bytes()) == before, 'Backup verification failed'
fd, staged = tempfile.mkstemp(prefix='.cpc-click-containment-', dir=target.parent)
with os.fdopen(fd, 'wb') as stream:
    stream.write(data)
    stream.flush()
    os.fsync(stream.fileno())
os.chmod(staged, attributes.st_mode & 0o777)
os.chown(staged, attributes.st_uid, attributes.st_gid)
assert digest(target.read_bytes()) == before, 'Target changed before replacement; aborted'
os.replace(staged, target)
assert digest(target.read_bytes()) == after, 'Published hash mismatch'
print(json.dumps({'published_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'file': str(target), 'backup': str(backup), 'before': before, 'after': after,
    'mode': oct(attributes.st_mode & 0o777), 'owner': f'{attributes.st_uid}:{attributes.st_gid}'}))
