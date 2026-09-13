"""Publish only this release's three previously absent runtime files on the web host."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import tempfile

root = Path('/var/www/business.roadrunners.run')
source = Path('/tmp/runnerhub-description-stage/runtime')
manifest = json.loads(Path('/tmp/runnerhub-description-runtime.json').read_text())
files = ['services/EventDescriptionRewriteService.cfc',
         'api/eventos/jobs/rewrite-descriptions.cfm', 'api/event-description-rewrite.cfm']
assert set(manifest) == set(files), 'Unexpected release scope'
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
for name in files:
    assert not (root / name).exists(), 'Production target already exists: ' + name
    assert digest(source / name) == manifest[name], 'Candidate changed: ' + name
backup = Path(tempfile.mkdtemp(prefix='business-event-description-20260913.', dir='/var/backups'))
receipt = {'created_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
           'root': str(root), 'backup': str(backup), 'before': {name: None for name in files},
           'after': manifest, 'published': []}
(backup / 'release.json').write_text(json.dumps(receipt, indent=2))
attributes = (root / 'api/youtube-import.cfm').stat()
for name in files:
    target = root / name
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.description-release-', dir=target.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write((source / name).read_bytes())
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, attributes.st_mode & 0o777)
        os.chown(temporary, attributes.st_uid, attributes.st_gid)
        # Atomic creation fails if another deployment created this path meanwhile.
        os.link(temporary, target)
        assert digest(target) == manifest[name], 'Published checksum mismatch'
    finally:
        os.unlink(temporary)
    receipt['published'].append(name)
    (backup / 'release.json').write_text(json.dumps(receipt, indent=2))
print(json.dumps(receipt))
