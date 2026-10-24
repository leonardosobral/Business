"""Local package validation shared by reviewed release wrappers. No side effects on import."""
import importlib.util
import io
from pathlib import Path
import tarfile

BASE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('live_funnel_publisher', BASE / 'release-tools/publish.py')
publisher = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(publisher)
SSH = ['ssh', '-i', '/Users/leonardosobral/.ssh/webs', '-o', 'BatchMode=yes', '-o', 'IdentitiesOnly=yes',
       '-o', 'StrictHostKeyChecking=yes', '-o', 'UpdateHostKeys=no', 'root@ssh.runnerhub.run']


def load_package(release):
    release = Path(release).resolve()
    rows, manifest_sha = publisher.Release(release).plan()
    files = {}
    for row in rows:
        name = f"{row['site']}/{row['path']}"
        source = release / 'candidate' / name
        publisher.require(publisher.sha256(source) == row['after'], f'Candidate differs from manifest: {name}')
        files[name] = source
    return rows, manifest_sha, files


def archive_files(files):
    archive = io.BytesIO()
    with tarfile.open(fileobj=archive, mode='w') as tar:
        for name, source in files.items():
            # SHA and tar read from the same immutable bytes; remote verifies them again.
            data = source.read_bytes()
            info = tarfile.TarInfo(name)
            info.size = len(data)
            info.mode = 0o600
            tar.addfile(info, io.BytesIO(data))
    return archive.getvalue()
