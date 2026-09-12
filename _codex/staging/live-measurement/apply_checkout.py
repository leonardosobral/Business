#!/usr/bin/env python3
"""Apply the reviewed producer candidates, only if all local baselines still match."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

base = Path(__file__).resolve().parent
manifest = json.loads((base / 'roadrunners-manifest.json').read_text())
checkout = Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
candidate = base / 'RoadRunners'
assert manifest['checkout'] == str(checkout)
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
for row in manifest['files']:
    rel = Path(row['path'])
    assert not rel.is_absolute() and '..' not in rel.parts
    source, target = candidate / rel, checkout / rel
    assert source.is_file() and not source.is_symlink()
    assert digest(source) == row['candidateSHA'], f'Candidate changed: {rel}'
    assert not target.is_symlink()
    for parent in target.parents:
        if parent == checkout.parent:
            break
        assert not parent.is_symlink(), f'Symlink parent: {rel}'
    if row['baselineLocalSHA'] is None:
        assert not target.exists(), f'New-file collision: {rel}'
    else:
        assert target.is_file() and digest(target) == row['baselineLocalSHA'], f'Local drift: {rel}'
for row in manifest['files']:
    rel = Path(row['path'])
    source, target = candidate / rel, checkout / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    mode = target.stat().st_mode & 0o777 if target.exists() else 0o644
    fd, temporary = tempfile.mkstemp(prefix='.live-measurement-', dir=target.parent)
    os.close(fd)
    try:
        shutil.copyfile(source, temporary)
        os.chmod(temporary, mode)
        if row['baselineLocalSHA'] is None:
            assert not target.exists(), f'Concurrent new-file collision: {rel}'
        else:
            assert digest(target) == row['baselineLocalSHA'], f'Concurrent local drift: {rel}'
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    assert digest(target) == row['candidateSHA']
    print(f'Applied {rel}')
print(f'Verified {len(manifest["files"])} exact candidate hashes; no Git operations.')
