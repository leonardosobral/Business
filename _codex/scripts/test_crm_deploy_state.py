"""Exercise interrupted publish and rollback with local temporary files only."""
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory

from crm_deploy_state import apply_transition


def digest(path):
    import hashlib
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


with TemporaryDirectory(prefix='crm-release-test-') as directory:
    base = Path(directory)
    site = base / 'site'
    release = base / 'release'
    site.mkdir()
    records = []
    for index in (1, 2):
        name = f'file-{index}.txt'
        target = site / name
        target.write_text(f'before-{index}')
        before = digest(target)
        backup = release / 'before' / 'Business' / name
        backup.parent.mkdir(parents=True, exist_ok=True)
        backup.write_bytes(target.read_bytes())
        candidate = release / 'candidate' / 'Business' / name
        candidate.parent.mkdir(parents=True, exist_ok=True)
        candidate.write_text(f'after-{index}')
        records.append({'site': 'Business', 'path': name, 'before': before,
                        'after': digest(candidate),
                        'metadata': {'uid': os.getuid(), 'gid': os.getgid(), 'mode': 0o644}})
    state = {'phase': 'prepared', 'files': records}
    statepath = release / 'state.json'
    statepath.write_text(json.dumps(state))
    replacements = 0

    def interrupt_second(source, target):
        global replacements
        replacements += 1
        if replacements == 2:
            raise OSError('simulated interruption')
        os.replace(source, target)

    try:
        apply_transition('publish', state, statepath, release, {'Business': site}, digest,
                         replace_fn=interrupt_second)
        raise AssertionError('publish should have been interrupted')
    except OSError as error:
        assert str(error) == 'simulated interruption'
    assert json.loads(statepath.read_text())['phase'] == 'publishing'
    assert digest(site / 'file-1.txt') == records[0]['after']
    assert digest(site / 'file-2.txt') == records[1]['before']
    apply_transition('publish', state, statepath, release, {'Business': site}, digest)
    assert json.loads(statepath.read_text())['phase'] == 'published'
    assert all(digest(site / row['path']) == row['after'] for row in records)

    replacements = 0
    try:
        apply_transition('rollback', state, statepath, release, {'Business': site}, digest,
                         replace_fn=interrupt_second)
        raise AssertionError('rollback should have been interrupted')
    except OSError as error:
        assert str(error) == 'simulated interruption'
    assert json.loads(statepath.read_text())['phase'] == 'rolling_back'
    apply_transition('rollback', state, statepath, release, {'Business': site}, digest)
    assert json.loads(statepath.read_text())['phase'] == 'rolled_back'
    assert all(digest(site / row['path']) == row['before'] for row in records)

print('CRM deploy state: PASS (interrupted publish and rollback resumed)')
