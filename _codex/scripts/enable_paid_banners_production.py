"""One-time authorized flag rollout. Run through SSH on the production host.

Only adds the paid-banner placement. No SQL, campaign or other flag changes.
Backup and compiler evidence stay outside the webroot. Baseline drift aborts.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile

TARGET = Path('/var/www/roadrunners.com.br/config/ads.local.cfm')
BEFORE = 'dd3ff39886efec603025a331c596c644f803bddf0794ba3b9166fd8e2259b927'
ANCHOR = b'localAdsConfig = {\n'
ADDITION = b'    "bannerCpcPlacements" = ["rr-sidebar-banner-300x250"],\n'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    assert os.geteuid() == 0
    assert TARGET.resolve() == TARGET and TARGET.stat().st_nlink == 1
    original = TARGET.read_bytes()
    metadata = TARGET.stat()
    assert sha(original) == BEFORE, 'Production baseline changed; do not overwrite'
    assert original.count(ANCHOR) == 1 and b'bannerCpcPlacements' not in original
    candidate = original.replace(ANCHOR, ANCHOR + ADDITION, 1)
    assert candidate.replace(ADDITION, b'', 1) == original
    others = {str(p): sha(p.read_bytes()) for p in Path('/var/www').glob('*/config/ads.local.cfm') if p != TARGET}
    os.umask(0o077)
    backup = Path(tempfile.mkdtemp(prefix='paid-banner-enable.', dir='/var/backups'))
    shutil.copy2(TARGET, backup / 'ads.local.cfm.before')
    (backup / 'ads.local.cfm.candidate').write_bytes(candidate)
    stage = Path(tempfile.mkdtemp(prefix='paid-banner-flag-compile-', dir='/tmp'))
    source, compiled = stage / 'source', stage / 'compiled'
    source.mkdir(); compiled.mkdir()
    (source / 'ads.local.cfm').write_bytes(candidate)
    for p in [stage, *stage.rglob('*')]:
        os.chown(p, 65534, 65534)
        os.chmod(p, 0o755 if p.is_dir() else 0o644)
    result = subprocess.run([
        '/opt/ColdFusion/cfusion/bin/cfcompile.sh', '-deploy', '-cfruntimeuser', 'nobody',
        '-webroot', str(source), '-dir', str(source), '-deploydir', str(compiled)
    ], capture_output=True, text=True, timeout=180)
    log = result.stdout + result.stderr
    (backup / 'compile.log').write_text(log)
    shutil.move(str(stage), str(backup / 'compile-artifacts'))
    assert result.returncode == 0 and re.search(r'successful\s+1\b', log) and re.search(r'total\s+1\b', log), 'Compile failed; production not changed'
    assert TARGET.read_bytes() == original and TARGET.stat().st_mtime_ns == metadata.st_mtime_ns, 'Concurrent change'
    fd, temporary = tempfile.mkstemp(prefix='.ads-paid-enable-', dir=TARGET.parent)
    with os.fdopen(fd, 'wb') as f:
        f.write(candidate); f.flush(); os.fsync(f.fileno())
    os.chown(temporary, metadata.st_uid, metadata.st_gid)
    os.chmod(temporary, metadata.st_mode & 0o777)
    assert TARGET.read_bytes() == original, 'Concurrent change before publish'
    os.replace(temporary, TARGET)
    assert TARGET.read_bytes() == candidate
    assert all(sha(Path(p).read_bytes()) == value for p, value in others.items()), 'Other config changed'
    assert (TARGET.stat().st_uid, TARGET.stat().st_gid, TARGET.stat().st_mode & 0o777) == (metadata.st_uid, metadata.st_gid, metadata.st_mode & 0o777)
    receipt = {'target': str(TARGET), 'backup': str(backup), 'before': BEFORE, 'after': sha(candidate),
               'phase': 'enabled', 'compile': '1/1', 'placement': 'rr-sidebar-banner-300x250',
               'other_configs_preserved': others, 'existing_settings_preserved_byte_for_byte': True}
    (backup / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt))


if __name__ == '__main__':
    main()
