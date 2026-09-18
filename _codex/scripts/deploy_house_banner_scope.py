"""Scoped HOUSE-banner release using the existing guarded publisher.

prepare stages/compiles privately; publish requires the reviewed SQL migration first.
No database connection, credentials, service restart or git operation is performed.
The task manifest explicitly names each runtime path, baseline and candidate SHA.
"""
from pathlib import Path
import argparse
import hashlib
import io
import json
import re
import shlex
import subprocess
import tarfile

ROOT = Path(__file__).resolve().parents[2]
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']
SHA = re.compile(r'[0-9a-f]{64}\Z')
ALLOWED = {
    'Business': {
        'portal/includes/banner_management_backend.cfm', 'portal/banners/home.cfm',
        'portal/includes/banner_form_helpers.cfm', 'portal/includes/banner_form.cfm',
        'assets/js/portal-banners.js',
    },
    'RoadRunners': {
        'services/AdsV1BannerDeliveryService.cfc', 'includes/ads_v1/banner_delivery.cfm',
        'includes/ads_v1/banner_context.cfm', 'includes/eventos_ads.cfm',
        'includes/ads_v1/native_event_slot.cfm',
        'includes/estrutura/home_sidebar_promos.cfm',
        'includes/estrutura/home_sidebar_mobile_banner.cfm',
        'includes/estrutura/home_sidebar_async_slot.cfm',
        'includes/estrutura/home_sidebar_mobile_banner_slot.cfm',
        'includes/estrutura/feed_lateral.cfm',
        'api/home_sidebar.cfm', 'api/home_mobile_banner.cfm',
    },
}


def digest(content):
    return hashlib.sha256(content).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['prepare', 'publish', 'verify', 'rollback'])
    parser.add_argument('manifest', type=Path)
    parser.add_argument('receipt', type=Path)
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text())
    rows = manifest['files']
    order = [(r['site'], r['path']) for r in rows]
    assert len(order) == len(set(order)) and rows, 'Empty or duplicate targets'
    for row in rows:
        assert row['path'] in ALLOWED.get(row['site'], set()), 'Out-of-scope target'
        assert SHA.fullmatch(row['after'])
        assert row['before'] == 'ABSENT' or SHA.fullmatch(row['before'])
    publisher = (ROOT / '_codex/staging/live-measurement/release-tools/publish.py').read_bytes()
    script_sha = digest(publisher)
    manifest_sha = digest(args.manifest.read_bytes())
    payload = b''
    if args.mode == 'prepare':
        assert not args.receipt.exists(), 'Do not overwrite a prepared release receipt'
        files = {'publisher.py': publisher}
        for row in rows:
            source = Path(row['candidate']).resolve()
            assert source.is_relative_to(ROOT.parent), 'Candidate outside project workspace'
            content = source.read_bytes()
            assert digest(content) == row['after'], 'Candidate drift'
            files['candidate/' + row['site'] + '/' + row['path']] = content
        files['runtime.tsv'] = ('\n'.join('\t'.join(str(r[k]) for k in
                                ('site', 'path', 'before', 'after')) for r in rows) + '\n').encode()
        buffer = io.BytesIO()
        with tarfile.open(fileobj=buffer, mode='w') as archive:
            for name, content in files.items():
                info = tarfile.TarInfo(name)
                info.size, info.mode = len(content), 0o600
                archive.addfile(info, io.BytesIO(content))
        payload = buffer.getvalue()
        init = f'''
release=Path('/var/backups')/('house-banner-scope.'+secrets.token_hex(6))
release.mkdir(mode=0o700)
allowed={set(files)!r}
with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:') as archive:
 members=archive.getmembers()
 assert len(members)==len(allowed) and set(m.name for m in members)==allowed
 for member in members:
  assert member.isfile() and '..' not in Path(member.name).parts and not member.name.startswith('/')
  target=release/member.name
  target.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
  target.write_bytes(archive.extractfile(member).read())
  os.chmod(target,0o600)
'''
    else:
        previous = json.loads(args.receipt.read_text())
        assert previous['publisherSHA'] == script_sha and previous['manifestSHA'] == manifest_sha
        assert re.fullmatch(r'/var/backups/house-banner-scope\.[0-9a-f]+', previous['directory'])
        init = f"release=Path({previous['directory']!r})\n"
    count = sum(Path(r['path']).suffix.lower() in ('.cfm', '.cfc') for r in rows)
    remote = '''from pathlib import Path
import hashlib,importlib.util,io,json,os,re,secrets,shutil,subprocess,sys,tarfile,tempfile
os.umask(0o077)
''' + init + f'''
assert os.geteuid()==0
assert hashlib.sha256((release/'publisher.py').read_bytes()).hexdigest()=={script_sha!r}
spec=importlib.util.spec_from_file_location('guarded_publisher',release/'publisher.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
module.ORDER={tuple(order)!r}
module.NEW_FILES=frozenset({tuple((r['site'],r['path']) for r in rows if r['before']=='ABSENT')!r})
module.GUARD_FILES={{site:tuple(p for p in paths if (site,p) not in module.ORDER) for site,paths in module.GUARD_FILES.items()}}
if {args.mode!r}=='publish':
 log=(release/'compile.log').read_text()
 assert re.search(r'successful\\s+{count}\\b',log) and re.search(r'total\\s+{count}\\b',log),'Native compile gate missing'
phase=module.Release(release).run({args.mode!r})
'''
    if args.mode == 'prepare':
        remote += f'''
stage=Path(tempfile.mkdtemp(prefix='house-banner-compile-',dir='/tmp'))
source=stage/'source';compiled=stage/'compiled';compiled.mkdir()
for candidate in (release/'candidate').rglob('*'):
 if candidate.is_file() and candidate.suffix.lower() in ('.cfm','.cfc'):
  target=source/candidate.relative_to(release/'candidate')
  target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(candidate,target)
for path in [stage,*stage.rglob('*')]:
 os.chown(path,65534,65534);os.chmod(path,0o755 if path.is_dir() else 0o644)
result=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=180)
log=result.stdout+result.stderr;(release/'compile.log').write_text(log)
shutil.move(str(stage),str(release/'compile-artifacts'))
assert result.returncode==0 and re.search(r'successful\\s+{count}\\b',log) and re.search(r'total\\s+{count}\\b',log),log[-6000:]
'''
    remote += f'''
state=json.loads((release/'state.json').read_text())
print(json.dumps({{'directory':str(release),'publisherSHA':{script_sha!r},'manifestSHA':{manifest_sha!r},'phase':phase,'mode':{args.mode!r},'files':state['files'],'guard_count':len(state['guards']),'compile_log':str(release/'compile.log')}}))
'''
    response = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], input=payload,
                              capture_output=True, timeout=240)
    if response.returncode:
        raise SystemExit(response.stderr.decode() + response.stdout.decode())
    result = json.loads(response.stdout)
    target = args.receipt if args.mode == 'prepare' else args.receipt.with_name(
        args.receipt.stem + '-' + args.mode + '.json')
    target.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({k: result[k] for k in ('directory', 'mode', 'phase', 'guard_count', 'compile_log')}))


if __name__ == '__main__':
    main()
