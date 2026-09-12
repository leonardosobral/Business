#!/usr/bin/env python3
"""Transfer only the reviewed two-file highlight package, then call its guarded CLI."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import shlex
import stat
import subprocess
import tarfile

BASE = Path(__file__).resolve().parent
ORDER = (
    ("RoadRunners", "circuito/live_highlight.cfm"),
    ("RoadRunners", "circuito/index.cfm"),
)
REVIEWED_PUBLISHER_SHA = "fea1cfb363cc2aa000789d1c7fbcbc90b75af9af9f7ae7141291997be801086a"
SSH = ["ssh", "-i", "/Users/leonardosobral/.ssh/webs", "-o", "BatchMode=yes", "-o", "IdentitiesOnly=yes",
       "-o", "StrictHostKeyChecking=yes", "-o", "UpdateHostKeys=no", "root@ssh.runnerhub.run"]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_regular(path):
    path = Path(path)
    for part in (path, *path.parents):
        require(not part.is_symlink(), f"Symlink refused: {part}")
    info = path.stat()
    require(stat.S_ISREG(info.st_mode) and info.st_nlink == 1, f"Expected regular file without hard links: {path}")
    content = path.read_bytes()
    after = path.stat()
    require((info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns) ==
            (after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns), f"File changed while reading: {path}")
    return content


def read_package(release):
    """Validate and freeze the exact two-file package before creating any archive."""
    release = Path(release)
    manifest = read_regular(release / "runtime.tsv")
    lines = manifest.decode("utf-8").splitlines()
    require(len(lines) == len(ORDER), "runtime.tsv requires exactly two rows, without a header")
    files = {"runtime.tsv": manifest}
    for index, (expected, line) in enumerate(zip(ORDER, lines)):
        parts = line.split("\t")
        require(len(parts) == 4, "runtime.tsv requires four TAB-separated fields")
        site, relative, before, after = parts
        require((site, relative) == expected, f"Unexpected site/path/order: {site}/{relative}")
        require(bool(re.fullmatch(r"[a-f0-9]{64}", after)), f"Invalid candidate SHA: {relative}")
        require(before == "ABSENT" if index == 0 else bool(re.fullmatch(r"[a-f0-9]{64}", before)),
                f"Invalid baseline/absence contract: {relative}")
        require(before != after, f"Unchanged candidate: {relative}")
        name = f"candidate/{site}/{relative}"
        content = read_regular(release / name)
        require(hashlib.sha256(content).hexdigest() == after, f"Candidate hash mismatch: {relative}")
        files[name] = content
    return files


def make_archive(files):
    """Archive already checked bytes as regular files; never follows source links."""
    archive = io.BytesIO()
    with tarfile.open(fileobj=archive, mode="w", format=tarfile.USTAR_FORMAT) as tar:
        for name, content in files.items():
            member = tarfile.TarInfo(name)
            member.size = len(content)
            member.mode = 0o600
            tar.addfile(member, io.BytesIO(content))
    return archive.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("prepare", "publish", "verify", "rollback"))
    mode = parser.parse_args().mode
    release = BASE / "release"
    script = BASE / "release-tools/publish.py"
    script_bytes = read_regular(script)
    script_sha = hashlib.sha256(script_bytes).hexdigest()
    require(script_sha == REVIEWED_PUBLISHER_SHA, "Publisher differs from the reviewed highlight release tool")
    receipt = BASE / "remote-release.json"
    payload = b""
    if mode == "prepare":
        require(not receipt.exists(), "Existing release receipt requires inspection before another preparation")
        files = read_package(release)
        files["publish.py"] = script_bytes
        expected_names = {"runtime.tsv", "publish.py", *(f"candidate/{site}/{path}" for site, path in ORDER)}
        require(set(files) == expected_names and len(files) == 4, "Unexpected transfer package scope")
        payload = make_archive(files)
        hashes = {name: hashlib.sha256(content).hexdigest() for name, content in files.items()}
        init = f'''
import io,secrets,tarfile
expected_hashes={hashes!r}
archive=tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:')
members=archive.getmembers()
if len(members)!=4 or set(m.name for m in members)!=set(expected_hashes):
    raise ValueError('Unexpected highlight archive members')
contents={{}}
for member in members:
    relative=Path(member.name)
    if not member.isfile() or relative.is_absolute() or '..' in relative.parts:
        raise ValueError('Unsafe highlight archive member')
    content=archive.extractfile(member).read()
    if hashlib.sha256(content).hexdigest()!=expected_hashes[member.name]:
        raise ValueError('Transferred member hash mismatch')
    contents[member.name]=content
release=Path('/var/backups')/('rr-live-highlight.'+secrets.token_hex(6))
release.mkdir(mode=0o700)
for name,content in contents.items():
    target=release/name
    target.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
    with target.open('xb') as handle: handle.write(content)
    os.chmod(target,0o600)
'''
    else:
        previous = json.loads(read_regular(receipt))
        remote_dir = previous["directory"]
        require(bool(re.fullmatch(r"/var/backups/rr-live-highlight\.[a-f0-9]+", remote_dir)), "Unexpected remote release directory")
        require(previous["scriptSHA"] == script_sha, "Reviewed publisher changed after preparation")
        init = f"release=Path({remote_dir!r})\n"
    remote = '''import hashlib,json,os,subprocess,sys
from pathlib import Path
''' + init + f'''
if hashlib.sha256((release/'publish.py').read_bytes()).hexdigest()!={script_sha!r}:
    raise ValueError('Remote publisher hash mismatch')
result=subprocess.run(['python3',str(release/'publish.py'),str(release),{mode!r}],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=90)
state=json.loads((release/'state.json').read_text()) if (release/'state.json').exists() else {{}}
print(json.dumps({{'directory':str(release),'scriptSHA':{script_sha!r},'mode':{mode!r},'returncode':result.returncode,'output':result.stdout,'phase':state.get('phase'),'target_count':len(state.get('files',[])),'guard_count':len(state.get('guards',{{}})),'rollback_conflicts':state.get('rollbackConflicts',[])}}))
sys.exit(result.returncode)
'''
    result = subprocess.run(SSH + ["python3 -c " + shlex.quote(remote)], input=payload,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=100)
    (BASE / f"remote-{mode}-result.json").write_bytes(result.stdout)
    if mode == "prepare" and result.stdout:
        receipt.write_bytes(result.stdout)
    print(result.stdout.decode())
    if result.stderr:
        print(result.stderr.decode())
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
