"""Recoverable file transitions for a scoped CRM release.

This source is embedded in the one-use remote publisher and tested locally.
"""
import json
import os
import shutil
import tempfile


def apply_transition(mode, state, statepath, release, roots, sha, replace_fn=os.replace):
    if mode == 'publish':
        assert state['phase'] in ('prepared', 'publishing'), 'RELEASE STATE CONFLICT'
        target_phase, final_phase = 'publishing', 'published'
        origin_dir, expected_key = 'candidate', 'after'
    elif mode == 'rollback':
        assert state['phase'] in ('prepared', 'publishing', 'published', 'rolling_back'), 'RELEASE STATE CONFLICT'
        target_phase, final_phase = 'rolling_back', 'rolled_back'
        origin_dir, expected_key = 'before', 'before'
    else:
        raise ValueError('Unsupported transition')

    ordered = sorted(state['files'], key=lambda row: row['site'] != 'RoadRunners')
    if mode == 'rollback':
        ordered.reverse()
    for row in ordered:
        target = roots[row['site']] / row['path']
        assert not target.is_symlink(), 'TARGET SYMLINK: ' + row['path']
        assert sha(target) in (row['before'], row['after']), 'TARGET CHANGED: ' + row['path']
        if row[expected_key] is not None:
            origin = release / origin_dir / row['site'] / row['path']
            assert sha(origin) == row[expected_key], 'BACKUP/CANDIDATE CHANGED: ' + row['path']

    def save_phase(phase):
        state['phase'] = phase
        with tempfile.NamedTemporaryFile(mode='w', dir=statepath.parent,
                                         prefix='state-', suffix='.json', delete=False) as file:
            staged = file.name
            json.dump(state, file, indent=2)
        os.replace(staged, statepath)

    save_phase(target_phase)
    for row in ordered:
        target = roots[row['site']] / row['path']
        desired = row[expected_key]
        if sha(target) == desired:
            continue
        if desired is None:
            target.unlink()
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        origin = release / origin_dir / row['site'] / row['path']
        fd, stage_name = tempfile.mkstemp(prefix=target.name + '.crm-stage-', dir=target.parent)
        os.close(fd)
        stage = type(target)(stage_name)
        try:
            shutil.copy2(origin, stage)
            metadata = row['metadata']
            os.chown(stage, metadata['uid'], metadata['gid'])
            os.chmod(stage, metadata['mode'])
            replace_fn(stage, target)
        finally:
            stage.unlink(missing_ok=True)
    save_phase(final_phase)
