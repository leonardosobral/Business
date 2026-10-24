"""Server half of the fixed four-file shell gap release. Receives JSON on stdin."""
from pathlib import Path
import base64
import datetime
import hashlib
import json
import os
import pwd
import shutil
import stat
import subprocess
import sys
import tempfile

ROOT = Path('/var/www/business.roadrunners.run')
NAMES = [
    'assets/css/business-shell.css',
    'assets/js/business-shell.js',
    'includes/estrutura/navbar.cfm',
    'includes/estrutura/header.cfm',
]


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def metadata(path):
    item = path.stat()
    return {'mode': stat.S_IMODE(item.st_mode), 'uid': item.st_uid, 'gid': item.st_gid}


def safe_path(name):
    relative = Path(name)
    require(not relative.is_absolute() and '..' not in relative.parts, 'Unsafe relative path')
    target = ROOT / relative
    require(target.resolve() == target, 'Runtime symlink or resolved path mismatch: ' + name)
    require(target.parent.is_dir(), 'Runtime parent missing: ' + name)
    require(not target.exists() or target.is_file(), 'Runtime target is not a file: ' + name)
    return target


def current(path):
    return digest(path.read_bytes()) if path.is_file() else None


def guard(expected):
    for name, row in expected.items():
        path = safe_path(name)
        require(current(path) == row.get('sha256'), 'Production baseline conflict: ' + name)
        if row.get('exists'):
            require(metadata(path) == {key: row[key] for key in ('mode', 'uid', 'gid')},
                    'Production metadata conflict: ' + name)


def write_private(path, data):
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    path.chmod(0o600)


def atomic_replace(path, data, info):
    fd, temporary = tempfile.mkstemp(prefix='.business-shell-gap-', suffix=path.suffix, dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
            os.fchmod(stream.fileno(), info['mode'])
            os.fchown(stream.fileno(), info['uid'], info['gid'])
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def stage_path(value):
    path = Path(value)
    require(path.parent == Path('/var/backups') and path.name.startswith('business-shell-gap-20261024-'),
            'Unexpected stage path')
    require(path.resolve() == path and path.is_dir(), 'Invalid private stage')
    return path


def load_manifest(stage, payload):
    raw = (stage / 'manifest.json').read_bytes()
    require(digest(raw) == payload['manifest_sha256'], 'Private manifest changed')
    manifest = json.loads(raw)
    require(manifest['candidate'] == payload['hashes'], 'Candidate manifest mismatch')
    require(manifest['order'] == NAMES, 'Unexpected publication order/scope')
    for name, wanted in manifest['candidate'].items():
        require(digest((stage / 'candidate' / name).read_bytes()) == wanted, 'Candidate changed: ' + name)
    for name, row in manifest['baseline'].items():
        if row.get('exists'):
            require(digest((stage / 'baseline' / name).read_bytes()) == row['sha256'],
                    'Backup integrity mismatch: ' + name)
    return manifest


def verify(stage, manifest):
    guard(manifest['watch'])
    rows = {}
    for name, wanted in manifest['candidate'].items():
        path = safe_path(name)
        require(current(path) == wanted, 'Published checksum mismatch: ' + name)
        require(metadata(path) == manifest['metadata'][name], 'Published metadata mismatch: ' + name)
        rows[name] = {'sha256': wanted, **metadata(path)}
    return {'verified_files': rows, 'preserved_dependencies': len(manifest['watch'])}


def restore(stage, manifest, installed):
    # Check the whole rollback set before restoring anything. Never overwrite an
    # independently changed runtime file, even when a previous install failed.
    for name in installed:
        require(current(safe_path(name)) == manifest['candidate'][name],
                'Concurrent change prevents rollback: ' + name)
    restored = []
    for name in reversed(installed):
        target = safe_path(name)
        row = manifest['baseline'][name]
        if row.get('exists'):
            atomic_replace(target, (stage / 'baseline' / name).read_bytes(), row)
        else:
            withdrawn = stage / 'withdrawn' / name
            withdrawn.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
            require(not withdrawn.exists(), 'Withdrawn path already exists')
            os.replace(target, withdrawn)
        restored.append(name)
    guard(manifest['baseline'])
    return restored


def execute(payload):
    mode = payload['mode']
    require(set(payload['hashes']) == set(NAMES), 'Unexpected file scope')
    require(set(payload['baseline']) == set(NAMES), 'Incomplete production baseline')
    if mode == 'prepare':
        require(set(payload['files']) == set(NAMES), 'Unexpected candidate scope')
        guard(payload['baseline'])
        guard(payload['watch'])
        stage = Path(tempfile.mkdtemp(prefix='business-shell-gap-20261024-', dir='/var/backups'))
        stage.chmod(0o700)
        reference = metadata(ROOT / NAMES[-1])
        manifest = {'order': NAMES, 'baseline': payload['baseline'], 'watch': payload['watch'],
                    'candidate': payload['hashes'], 'metadata': {}}
        for name in NAMES:
            data = base64.b64decode(payload['files'][name], validate=True)
            require(digest(data) == payload['hashes'][name], 'Transport hash mismatch: ' + name)
            write_private(stage / 'candidate' / name, data)
            original = payload['baseline'][name]
            manifest['metadata'][name] = ({key: original[key] for key in ('mode', 'uid', 'gid')}
                                          if original.get('exists') else reference)
            if original.get('exists'):
                data = (ROOT / name).read_bytes()
                require(digest(data) == original['sha256'], 'Concurrent change during backup: ' + name)
                write_private(stage / 'baseline' / name, data)
        guard(payload['baseline'])
        raw = json.dumps(manifest, sort_keys=True, indent=2).encode()
        write_private(stage / 'manifest.json', raw)
        return {'stage': str(stage), 'manifest_sha256': digest(raw),
                'candidate_hashes': payload['hashes'], 'backup': str(stage / 'baseline'),
                'runtime_files_changed': False}

    stage = stage_path(payload['stage'])
    manifest = load_manifest(stage, payload)
    if mode == 'compile':
        guard(manifest['baseline'])
        guard(manifest['watch'])
        require(not (stage / 'compiled.json').exists(), 'Compile evidence already exists')
        with tempfile.TemporaryDirectory(prefix='business-shell-gap-compile-', dir='/var/tmp') as directory:
            work = Path(directory)
            work.chmod(0o755)
            source = work / 'source'
            shutil.copytree(stage / 'candidate', source)
            source.chmod(0o755)
            for item in source.rglob('*'):
                item.chmod(0o755 if item.is_dir() else 0o644)
            output = work / 'compiled'
            output.mkdir(mode=0o755)
            compiler = Path('/opt/coldfusion2025/cfusion/bin/cfcompile.sh')
            user = pwd.getpwuid((compiler.parent.parent / 'lib/seed.properties').stat().st_uid)
            os.chown(output, user.pw_uid, user.pw_gid)
            result = subprocess.run([str(compiler), '-deploy', '-cfruntimeuser', user.pw_name,
                '-webroot', str(source), '-dir', str(source), '-deploydir', str(output)],
                capture_output=True, text=True, timeout=180)
            log = result.stdout + result.stderr
            (stage / 'compile.log').write_text(log)
            (stage / 'compile.log').chmod(0o600)
            expected = sum(Path(name).suffix.lower() in ('.cfm', '.cfc') for name in NAMES)
            count = sum(item.is_file() and item.suffix.lower() in ('.cfm', '.cfc') for item in output.rglob('*'))
            require(result.returncode == 0 and 'Error compiling' not in log and count == expected,
                    'CFML compilation failed; inspect private compile.log')
        proof = {'manifest_sha256': payload['manifest_sha256'], 'compiled_templates': count,
                 'compiler': str(compiler), 'runtime_user': user.pw_name}
        write_private(stage / 'compiled.json', json.dumps(proof).encode())
        return {**proof, 'stage': str(stage), 'runtime_files_changed': False}
    if mode == 'publish':
        proof = json.loads((stage / 'compiled.json').read_text())
        require(proof['manifest_sha256'] == payload['manifest_sha256'], 'Compilation is stale')
        require(proof['compiled_templates'] == 2, 'Incomplete compilation proof')
        require(not (stage / 'published.json').exists(), 'Stage already published')
        guard(manifest['baseline'])
        guard(manifest['watch'])
        installed = []
        try:
            # Additive files and compatible CSS are installed before the entrypoint.
            for name in NAMES:
                guard({name: manifest['baseline'][name]})
                guard(manifest['watch'])
                atomic_replace(safe_path(name), (stage / 'candidate' / name).read_bytes(),
                               manifest['metadata'][name])
                installed.append(name)
            result = verify(stage, manifest)
        except Exception:
            restore(stage, manifest, installed)
            raise
        result.update(published_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                      backup=str(stage / 'baseline'), stage=str(stage))
        write_private(stage / 'published.json', json.dumps(result, indent=2).encode())
        return result
    if mode == 'verify':
        return {**verify(stage, manifest), 'stage': str(stage)}
    if mode == 'rollback':
        return {'restored': restore(stage, manifest, NAMES), 'stage': str(stage)}
    raise RuntimeError('Unknown operation')


if __name__ == '__main__':
    try:
        print(json.dumps(execute(json.load(sys.stdin)), indent=2))
    except Exception as failure:
        message = str(failure) if isinstance(failure, RuntimeError) else 'Release failed; inspect private stage'
        print(json.dumps({'ok': False, 'error': message}))
        sys.exit(1)
