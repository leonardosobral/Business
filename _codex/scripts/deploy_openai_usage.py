"""Reversible, hash-guarded release of usage telemetry. No keys, SQL or Git writes.

Default: read-only preflight. --verify: isolated, unpaid native tests.
--publish --verified: require fresh matching evidence, back up and publish scope.
"""
import base64, datetime, hashlib, json, pathlib, shlex, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
STAGE = ROOT / '_codex/staging/openai-usage'
BASELINE = json.loads((STAGE / 'baseline.json').read_text())
release_path = ROOT / '_codex/deploy/openai-usage-20261023.json'
previous_release = json.loads(release_path.read_text()) if release_path.exists() else {}
for key, item in previous_release.get('manifest', {}).items():
    app, name = key.split(':', 1); BASELINE[app][name] = item['after']
sha = lambda data: hashlib.sha256(data).hexdigest()
files = []
for app in ['business', 'news', 'rr']:
    names = ['Observer.cfc', 'Pricing.cfc', 'Catalog.cfc', '.htaccess']
    if app == 'business': names += ['Access.cfc', 'Store.cfc', 'Legacy.cfc']
    for name in names:
        files.append((app, 'services/openaiUsage/' + name, ROOT / 'services/openaiUsage' / name))
    for name in json.loads((STAGE / 'baseline.json').read_text())[app]:
        source = STAGE / app / name if app != 'business' or name == 'includes/estrutura/sidenav.cfm' else ROOT / name
        files.append((app, name, source))
for source in (ROOT / 'administracao/consumo-openai').rglob('*'):
    if source.is_file(): files.append(('business', str(source.relative_to(ROOT)), source))
candidate = {app + ':' + name: sha(source.read_bytes()) for app, name, source in files}
if len(candidate) != 29: raise SystemExit('Unexpected runtime scope')
proof_path = ROOT / '_codex/deploy/openai-usage-tests-20261023.json'
publish = '--publish' in sys.argv
if '--verify' in sys.argv or publish and '--verified' not in sys.argv:
    tests = []
    for suite in ['pricing', 'observer', 'store', 'legacy', 'wrappers', 'view', 'ledger']:
        run = subprocess.run([sys.executable, '-B', str(ROOT / '_codex/scripts/test_openai_usage_native.py'), suite], capture_output=True, text=True, timeout=90)
        try: result = json.loads(run.stdout)
        except ValueError: raise SystemExit('Invalid test result: ' + suite)
        result['suite'] = suite; tests.append(result)
        print(json.dumps(result, ensure_ascii=False), flush=True)
        if run.returncode or not result.get('ok') or not result.get('stage_archived'): raise SystemExit('Native verification failed')
    node = '/Users/geraldoprotta/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node'
    subprocess.run([node, '--check', str(ROOT / 'administracao/consumo-openai/assets/usage.js')], check=True)
    subprocess.run(['git', 'diff', '--check'], cwd=ROOT, check=True)
    if candidate != {a + ':' + n: sha(s.read_bytes()) for a, n, s in files}: raise SystemExit('Candidate changed during testing')
    proof_path.write_text(json.dumps({'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'candidate_hashes': candidate, 'tests': tests, 'js_ok': True}, ensure_ascii=False, indent=2) + '\n')
if publish:
    proof = json.loads(proof_path.read_text())
    age = (datetime.datetime.now(datetime.timezone.utc) - datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
    if not 0 <= age < 1800 or proof['candidate_hashes'] != candidate or len(proof['tests']) != 7 or not all(t.get('ok') and t.get('stage_archived') for t in proof['tests']) or not proof['js_ok']: raise SystemExit('Fresh matching tests required')
prior = json.loads((ROOT / '_codex/deploy/event-location-20261022.json').read_text())
preserved = {**prior['preserved_files'], **prior['candidate_hashes']}
preserved = {name: value for name, value in preserved.items() if 'business:' + name not in candidate}
payload = {'publish': publish, 'preserved': preserved, 'files': [{'app': a, 'path': n, 'before': BASELINE[a].get(n), 'data': base64.b64encode(s.read_bytes()).decode()} for a, n, s in files]}

REMOTE = r'''
import base64,hashlib,json,os,pathlib,pwd,stat,subprocess,sys,tempfile,time
p=json.load(sys.stdin)
roots={'business':pathlib.Path('/var/www/business.roadrunners.run'),'news':pathlib.Path('/var/www/conteudo.roadrunners.run'),'rr':pathlib.Path('/var/www/roadrunners.com.br')}
hosts={'business':'business.roadrunners.run','news':'conteudo.roadrunners.run','rr':'roadrunners.run'}
sha=lambda b:hashlib.sha256(b).hexdigest()
def target(app,rel):
 root=roots[app];path=root/rel
 if path.is_symlink() or root not in path.resolve().parents:raise RuntimeError('Unsafe target')
 return path
def guards():
 for rel,expected in p['preserved'].items():
  if sha(target('business',rel).read_bytes())!=expected:raise RuntimeError('Preserved front changed: '+rel)
guards();manifest={}
for item in p['files']:
 dest=target(item['app'],item['path']);current=dest.read_bytes() if dest.exists() else None
 if (sha(current) if current is not None else None)!=item['before']:raise SystemExit('Baseline conflict: '+item['app']+':'+item['path'])
 item['content']=base64.b64decode(item.pop('data'),validate=True);item['original']=current
 manifest[item['app']+':'+item['path']]={'before':item['before'],'after':sha(item['content'])}
directory=pathlib.Path('/var/lib/runnerhub/openai-usage');parent=directory.parent
if directory.is_symlink():raise SystemExit('Unsafe usage directory')
if not parent.is_dir() or parent.is_symlink():raise SystemExit('Private parent unavailable')
account=pwd.getpwnam('coldfusion')
since=0
if directory.exists():
 info=directory.stat()
 if not directory.is_dir() or info.st_uid!=account.pw_uid or stat.S_IMODE(info.st_mode)!=0o750:raise SystemExit('Private storage metadata changed')
 marker=json.loads((directory/'tracking.json').read_text());since=marker.get('since_ms',0)
 if not isinstance(since,int) or not 0<since<=int(time.time()*1000):raise SystemExit('Invalid existing cutover')
if not p['publish']:
 print(json.dumps({'ok':True,'mode':'preflight','manifest':manifest,'preserved_count':len(p['preserved']),'private_directory':'existing' if since else 'new'}));sys.exit(0)
backup=pathlib.Path(tempfile.mkdtemp(prefix='business-openai-usage-',dir='/var/backups'));os.chmod(backup,0o700)
published=[];metadata={};probes=[];private_created=False
def atomic(path,content,uid,gid,mode):
 path.parent.mkdir(mode=0o755,parents=True,exist_ok=True)
 fd,tmp=tempfile.mkstemp(prefix='.openai-usage-',dir=path.parent)
 try:
  with os.fdopen(fd,'wb') as stream:
   stream.write(content);stream.flush();os.fsync(stream.fileno());os.fchown(stream.fileno(),uid,gid);os.fchmod(stream.fileno(),mode)
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
try:
 for item in p['files']:
  app=item['app'];rel=item['path'];key=app+':'+rel;dest=target(app,rel);current=dest.read_bytes() if dest.exists() else None
  if (sha(current) if current is not None else None)!=item['before']:raise RuntimeError('Concurrent change: '+key)
  if current==item['content']:continue
  info=dest.stat() if current is not None else target(app,'Application.cfc').stat()
  metadata[key]=(info.st_uid,info.st_gid,stat.S_IMODE(info.st_mode))
  if current is not None:
   saved=backup/'before'/app/rel;saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(current);os.chmod(saved,0o600)
  atomic(dest,item['content'],*metadata[key]);published.append(item)
  if sha(dest.read_bytes())!=manifest[key]['after']:raise RuntimeError('Hash mismatch: '+key)
 if not since:
  directory.mkdir(mode=0o750);private_created=True;os.chown(directory,account.pw_uid,account.pw_gid)
  since=int(time.time()*1000)
  atomic(directory/'tracking.json',json.dumps({'since_ms':since,'version':1}).encode(),0,account.pw_gid,0o640)
 for app,path,expected,public in [
  ('business','/administracao/consumo-openai/',302,False),
  ('business','/administracao/consumo-openai/includes/backend.cfm',403,False),
  ('business','/administracao/consumo-openai/includes/view.cfm',403,False),
  ('business','/administracao/consumo-openai/assets/usage.css',200,False),
  ('business','/administracao/consumo-openai/assets/usage.js',200,False),
  ('business','/services/openaiUsage/Observer.cfc',403,True),
  ('news','/services/openaiUsage/Observer.cfc',403,True),
  ('rr','/services/openaiUsage/Observer.cfc',403,True)]:
  command=['curl','--silent','--show-error','--max-time','20','--output','/dev/null','--write-out','%{http_code}']
  if not public:command+=['--resolve',hosts[app]+':443:127.0.0.1']
  run=subprocess.run(command+['https://'+hosts[app]+path],capture_output=True,timeout=25)
  status=run.stdout.decode();ok=run.returncode==0 and status==str(expected);probes.append({'app':app,'path':path,'status':status,'ok':ok})
  if not ok:raise RuntimeError('Route verification failed: '+app+':'+path)
 guards()
 checks=[{'path':k,'ok':sha(target(k.split(':',1)[0],k.split(':',1)[1]).read_bytes())==v['after']} for k,v in manifest.items()]
 if not all(c['ok'] for c in checks):raise RuntimeError('Final hash mismatch')
 result={'ok':True,'mode':'published','backup':str(backup),'manifest':manifest,'probes':probes,'checks':checks,'tracked_since_ms':since,'preserved_count':len(p['preserved']),'credentials_changed':False,'sql_applied':False,'git_mutations':False}
except Exception as error:
 rollback=[]
 for item in reversed(published):
  key=item['app']+':'+item['path'];dest=target(item['app'],item['path'])
  if not dest.exists() or sha(dest.read_bytes())!=manifest[key]['after']:rollback.append({'path':key,'restored':False,'reason':'concurrent_change'});continue
  if item['original'] is not None:atomic(dest,item['original'],*metadata[key])
  else:
   saved=backup/'withdrawn'/item['app']/item['path'];saved.parent.mkdir(parents=True,exist_ok=True);dest.rename(saved)
  rollback.append({'path':key,'restored':True})
 if private_created:directory.rename(backup/'withdrawn-private-usage')
 result={'ok':False,'reason':str(error),'backup':str(backup),'rollback':rollback,'probes':probes}
(backup/'receipt.json').write_text(json.dumps(result,indent=2));os.chmod(backup/'receipt.json',0o600)
print(json.dumps(result));sys.exit(0 if result['ok'] else 1)
'''
run = subprocess.run(['ssh', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes', '-o', 'ConnectTimeout=12', 'rr-prod', 'python3 -c ' + shlex.quote(REMOTE)], input=json.dumps(payload).encode(), capture_output=True, timeout=240)
try: result = json.loads(run.stdout)
except ValueError: result = {'ok': False, 'diagnostic': run.stderr.decode(errors='replace')[-1000:]}
if result.get('ok') and result.get('mode') == 'published':
    result.update({'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'candidate_hashes': candidate, 'preserved_files': preserved})
    result['previous_publications'] = previous_release.get('previous_publications', []) + ([{'backup': previous_release['backup'], 'manifest': previous_release['manifest']}] if previous_release else [])
    release_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({**{key: result[key] for key in ['ok','mode','backup','reason','diagnostic','preserved_count','tracked_since_ms'] if key in result}, 'runtime_files': len(result.get('manifest', {})), 'changed_files': sum(item['before'] != item['after'] for item in result.get('manifest', {}).values()), 'probes_ok': all(probe['ok'] for probe in result.get('probes', []))}, ensure_ascii=False))
raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
