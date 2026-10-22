"""Publish only the new geocoding runtime and one origin-based menu insertion.

Default is a read-only preflight. --publish requires the exact captured baseline;
all replacements are backed up and conditionally rolled back on failed probes.
No SQL, credentials, cron activation or Git operations are performed here.
"""
import base64, hashlib, json, pathlib, shlex, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MENU = 'includes/estrutura/sidenav.cfm'
ANCHOR = '            <li class="sidenav-item business-sidenav-subgroup-label"><span>Gestão do evento</span></li>'
local_menu = (ROOT / MENU).read_text(encoding='utf-8-sig')
start = local_menu.index(ANCHOR) + len(ANCHOR)
end = local_menu.index('\n            <li class="sidenav-item">\n                <a class="sidenav-link <cfif VARIABLES.template EQ "/eventos/">', start)
insertion = local_menu[start:end]
if insertion.count('href="/administracao/geolocalizacao/"') != 1:
    raise SystemExit('Unexpected scoped menu insertion')
paths = [str(p.relative_to(ROOT)) for directory in ['services/geocoding', 'administracao/geolocalizacao']
         for p in (ROOT / directory).rglob('*') if p.is_file() and (p.suffix in ['.cfm', '.cfc', '.js'] or p.name == '.htaccess')]
paths.append('api/eventos/geolocalizar.cfm')
payload = {'publish': '--publish' in sys.argv, 'menu': MENU, 'anchor': ANCHOR, 'insertion': insertion,
           'menu_baseline': '4a7e039fc787199570e1f6322d133a21b5d9b389354ea697b59c2fbde04743ac',
           'files': {p: base64.b64encode((ROOT / p).read_bytes()).decode() for p in sorted(paths)}}
REMOTE = r'''
import base64,hashlib,json,os,pathlib,stat,subprocess,sys,tempfile
p=json.load(sys.stdin);root=pathlib.Path('/var/www/business.roadrunners.run')
def sha(data):return hashlib.sha256(data).hexdigest()
def target(rel):
 path=root/rel
 if path.is_symlink() or root not in path.resolve().parents:raise RuntimeError('Unsafe target')
 return path
menu=target(p['menu']);before=menu.read_bytes();info=menu.stat()
if sha(before)!=p['menu_baseline']:raise SystemExit('Menu baseline conflict; nothing published')
text=before.decode('utf-8-sig')
if text.count(p['anchor'])!=1 or '/administracao/geolocalizacao/' in text:raise SystemExit('Menu anchor conflict')
candidate=text.replace(p['anchor'],p['anchor']+p['insertion'],1).encode('utf-8')
if before.startswith(b'\xef\xbb\xbf'):candidate=b'\xef\xbb\xbf'+candidate
files={rel:base64.b64decode(content,validate=True) for rel,content in p['files'].items()}
for rel in files:
 if target(rel).exists():raise SystemExit('Existing new-module target; nothing published: '+rel)
files[p['menu']]=candidate
manifest={rel:{'before':sha(before) if rel==p['menu'] else None,'after':sha(content)} for rel,content in files.items()}
if not p['publish']:
 print(json.dumps({'ok':True,'mode':'preflight','runtime_count':len(files),'manifest':manifest}));sys.exit(0)
backup=pathlib.Path(tempfile.mkdtemp(prefix='business-geocoding-20261017-',dir='/var/backups'));os.chmod(backup,0o700)
(backup/'sidenav.before').write_bytes(before);os.chmod(backup/'sidenav.before',0o600)
(backup/'manifest.json').write_text(json.dumps(manifest,indent=2));os.chmod(backup/'manifest.json',0o600)
published=[];created_dirs=[];probes=[]
def atomic(path,data,mode=0o644,uid=info.st_uid,gid=info.st_gid):
 fd,tmp=tempfile.mkstemp(prefix='.geocoding-',dir=path.parent)
 try:
  with os.fdopen(fd,'wb') as stream:
   stream.write(data);stream.flush();os.fsync(stream.fileno());os.fchmod(stream.fileno(),mode);os.fchown(stream.fileno(),uid,gid)
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
try:
 for rel,data in files.items():
  dest=target(rel)
  if rel==p['menu']:
   if sha(dest.read_bytes())!=p['menu_baseline']:raise RuntimeError('Concurrent menu edit')
  elif dest.exists():raise RuntimeError('Concurrent new-module file')
  missing=[];parent=dest.parent
  while not parent.exists():missing.append(parent);parent=parent.parent
  for directory in reversed(missing):directory.mkdir(mode=0o755);created_dirs.append(str(directory))
  atomic(dest,data,stat.S_IMODE(info.st_mode) if rel==p['menu'] else 0o644)
  published.append(rel)
  if sha(dest.read_bytes())!=manifest[rel]['after']:raise RuntimeError('Post-write hash mismatch')
 for path,method,allowed,marker in [('/api/eventos/geolocalizar.cfm','GET',[405],'method_not_allowed'),('/api/eventos/geolocalizar.cfm','POST',[401,503],None),('/administracao/geolocalizacao/','GET',[302,303,401,403],None),('/services/geocoding/config.cfm','GET',[403],None)]:
  r=subprocess.run(['curl','--silent','--show-error','--max-time','25','--resolve','business.roadrunners.run:443:127.0.0.1','--request',method,'--write-out','\n%{http_code}','https://business.roadrunners.run'+path],capture_output=True,timeout=30)
  body,_,code=r.stdout.rpartition(b'\n');status=int(code) if code.isdigit() else 0
  ok=r.returncode==0 and status in allowed and (not marker or marker.encode() in body)
  probes.append({'path':path,'method':method,'status':status,'ok':ok})
  if not ok:raise RuntimeError('Runtime guard probe failed: '+path)
 for rel,expected in manifest.items():
  if sha(target(rel).read_bytes())!=expected['after']:raise RuntimeError('Final hash conflict')
 result={'ok':True,'mode':'published','backup':str(backup),'manifest':manifest,'probes':probes,'sql_applied':False,'cron_activated':False}
except Exception as exc:
 rollback=[]
 for rel in reversed(published):
  dest=target(rel)
  if not dest.exists() or sha(dest.read_bytes())!=manifest[rel]['after']:
   rollback.append({'path':rel,'restored':False,'reason':'concurrent_change'});continue
  if rel==p['menu']:atomic(dest,before,stat.S_IMODE(info.st_mode))
  else:
   recovered=backup/'withdrawn'/rel;recovered.parent.mkdir(parents=True,exist_ok=True);dest.rename(recovered)
  rollback.append({'path':rel,'restored':True})
 result={'ok':False,'backup':str(backup),'reason':str(exc),'rollback':rollback,'probes':probes}
(backup/'receipt.json').write_text(json.dumps(result,indent=2));os.chmod(backup/'receipt.json',0o600)
print(json.dumps(result));sys.exit(0 if result['ok'] else 1)
'''
proc = subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],
                      input=json.dumps(payload).encode(),capture_output=True,timeout=145)
try:
    result=json.loads(proc.stdout)
except Exception:
    result={'ok':False,'reason':proc.stderr.decode(errors='replace')[-600:] or 'Publication receipt unavailable'}
if result.get('mode')=='published':
    (ROOT/'_codex/deploy/geocoding-20261017.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
if proc.returncode or not result.get('ok'):sys.exit(1)
