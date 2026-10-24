#!/usr/bin/env python3
"""Transfer the reviewed package privately, then explicitly invoke its guarded release CLI."""
import argparse
import json
import re
import shlex
import subprocess
from release_support import BASE, SSH, archive_files, load_package, publisher


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('prepare', 'publish', 'verify', 'rollback'))
    mode = parser.parse_args().mode
    release = BASE / 'release'
    script = BASE / 'release-tools/publish.py'
    script_sha = publisher.sha256(script)
    receipt = BASE / 'remote-release.json'
    payload = b''
    if mode == 'prepare':
        publisher.require(not receipt.exists(), 'Existing release receipt requires inspection; do not prepare again.')
        rows, manifest_sha, candidates = load_package(release)
        files = {'runtime.tsv': release / 'runtime.tsv', 'publish.py': script}
        files.update({'candidate/' + name: file for name, file in candidates.items()})
        payload = archive_files(files)
        publisher.require(publisher.sha256(release / 'runtime.tsv') == manifest_sha, 'Manifest changed during packaging')
        init = f'''
import io,secrets,tarfile
release=Path('/var/backups')/('rr-live-funnel.'+secrets.token_hex(6))
release.mkdir(mode=0o700)
allowed=set({list(files)!r})
archive=tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:')
members=archive.getmembers()
assert len(members)==len(allowed) and set(m.name for m in members)==allowed
for member in members:
    rel=Path(member.name)
    assert member.isfile() and not rel.is_absolute() and '..' not in rel.parts
    target=release/rel;target.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
    target.write_bytes(archive.extractfile(member).read());os.chmod(target,0o600)
assert hashlib.sha256((release/'runtime.tsv').read_bytes()).hexdigest()=={manifest_sha!r}
'''
    else:
        previous = json.loads(receipt.read_text())
        remote_dir = previous['directory']
        publisher.require(bool(re.fullmatch(r'/var/backups/rr-live-funnel\.[A-Za-z0-9]+', remote_dir)), 'Invalid remote receipt directory')
        publisher.require(previous['scriptSHA'] == script_sha, 'Reviewed publisher changed after preparation')
        init = f'release=Path({remote_dir!r})\n'
    remote = '''import hashlib,json,os,subprocess,sys
from pathlib import Path
''' + init + f'''
assert hashlib.sha256((release/'publish.py').read_bytes()).hexdigest()=={script_sha!r}
result=subprocess.run(['python3',str(release/'publish.py'),str(release),{mode!r}],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
state=json.loads((release/'state.json').read_text()) if (release/'state.json').exists() else {{}}
print(json.dumps({{'directory':str(release),'scriptSHA':{script_sha!r},'mode':{mode!r},'returncode':result.returncode,'output':result.stdout,'phase':state.get('phase'),'target_count':len(state.get('files',[])),'guard_count':len(state.get('guards',{{}})),'rollback_conflicts':state.get('rollbackConflicts',[])}}))
sys.exit(result.returncode)
'''
    result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], input=payload,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=200)
    (BASE / f'remote-{mode}-result.json').write_bytes(result.stdout)
    if mode == 'prepare' and result.stdout:
        report = json.loads(result.stdout)
        publisher.require(bool(re.fullmatch(r'/var/backups/rr-live-funnel\.[A-Za-z0-9]+', report['directory'])), 'Invalid prepare receipt')
        publisher.require(report['scriptSHA'] == script_sha and report['mode'] == mode, 'Prepare receipt mismatch')
        # Retain even a failed prepare receipt for operator inspection; never auto-retry.
        with receipt.open('xb') as handle:
            handle.write(result.stdout)
    print(result.stdout.decode())
    if result.stderr:
        print(result.stderr.decode())
    return result.returncode


if __name__ == '__main__':
    raise SystemExit(main())
