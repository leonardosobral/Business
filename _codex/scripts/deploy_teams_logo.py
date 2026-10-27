"""Scoped Teams logo release: CAS baseline, recoverable backup and HTTP verification."""
import base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];WORK=ROOT/'_codex/teams';sha=lambda b:hashlib.sha256(b).hexdigest()
mode=sys.argv[1];assert mode in ['preflight','publish']
publication=json.loads((WORK/'publication.json').read_text());items={}
for site in ['business','rr']:
 for rel in ['teams/includes/header.cfm','teams/assets/teams.css','teams/assets/rr_teams.svg']:
  source=(WORK/'roadrunners'/rel) if site=='rr' and rel.endswith('header.cfm') else ROOT/rel
  data=source.read_bytes();items[site+'/'+rel]={'before':publication['candidate_hashes'].get(site+'/'+rel),'after':sha(data),'data':base64.b64encode(data).decode()}
REMOTE=r'''
import base64,hashlib,json,os,pathlib,stat,subprocess,sys,tempfile
p=json.load(sys.stdin);roots={'business':pathlib.Path('/var/www/business.roadrunners.run'),'rr':pathlib.Path('/var/www/roadrunners.com.br')};sha=lambda b:hashlib.sha256(b).hexdigest()
allowed={s+'/'+r for s in roots for r in ['teams/includes/header.cfm','teams/assets/teams.css','teams/assets/rr_teams.svg']}
assert set(p['items'])==allowed
paths={k:roots[k.split('/')[0]]/k.split('/',1)[1] for k in allowed};previous={};metadata={}
for k,d in p['items'].items():
 path=paths[k];assert not path.is_symlink();old=path.read_bytes() if path.exists() else None
 assert (sha(old) if old is not None else None)==d['before'],'Production conflict: '+k
 data=base64.b64decode(d['data'],validate=True);assert sha(data)==d['after'];previous[k]=old
 metadata[k]=path.stat() if path.exists() else path.parent.stat()
if p['mode']=='preflight':print(json.dumps({'ok':True,'mode':'preflight','files':len(allowed)}));sys.exit(0)
backup=pathlib.Path(tempfile.mkdtemp(prefix='rr-teams-logo-',dir='/var/backups'));os.chmod(backup,0o700);written=[]
def atomic(k,data):
 path=paths[k];info=metadata[k];fd,tmp=tempfile.mkstemp(prefix='.teams-logo-',dir=path.parent)
 try:
  with os.fdopen(fd,'wb') as f:
   f.write(data);f.flush();os.fsync(f.fileno());os.fchmod(f.fileno(),stat.S_IMODE(info.st_mode) if previous[k] is not None else 0o644);os.fchown(f.fileno(),info.st_uid,info.st_gid)
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
probes=[]
try:
 (backup/'manifest.json').write_text(json.dumps({k:{'before':d['before'],'after':d['after']} for k,d in p['items'].items()},indent=2))
 for k in sorted(allowed):
  path=paths[k];now=path.read_bytes() if path.exists() else None;assert now==previous[k],'Concurrent change: '+k
  if now is not None:
   dest=backup/k;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(now);os.chmod(dest,0o600)
  atomic(k,base64.b64decode(p['items'][k]['data']));written.append(k)
 for k,d in p['items'].items():assert sha(paths[k].read_bytes())==d['after']
 for site,host in [('business','business.roadrunners.run'),('rr','roadrunners.run')]:
  for route in (['/teams/cadastro/','/teams/convites/'] if site=='business' else ['/teams/','/teams/entrar/']):
   run=subprocess.run(['curl','-fsS','--max-time','35','https://'+host+route],capture_output=True,timeout=40);assert run.returncode==0,'Page request failed: '+route
   body=run.stdout.decode('utf-8-sig');assert 'alt="Road Runners Teams"' in body and '/teams/assets/rr_teams.svg?v=1' in body and '/teams/assets/teams.css?v=3' in body,'Rendered logo missing: '+route
   probes.append({'url':'https://'+host+route,'logo':True})
  for asset in ['rr_teams.svg','teams.css']:
   run=subprocess.run(['curl','-fsS','--max-time','30','https://'+host+'/teams/assets/'+asset+'?v='+('1' if asset.endswith('svg') else '3')],capture_output=True,timeout=35);assert run.returncode==0 and sha(run.stdout)==p['items'][site+'/teams/assets/'+asset]['after'],'Asset mismatch: '+asset
   probes.append({'url':'https://'+host+'/teams/assets/'+asset,'sha256':sha(run.stdout)})
 result={'ok':True,'mode':'published','backup':str(backup),'files':len(allowed),'hashes':{k:d['after'] for k,d in p['items'].items()},'probes':probes}
except Exception as e:
 for k in reversed(written):
  if previous[k] is None:paths[k].unlink()
  else:atomic(k,previous[k])
 result={'ok':False,'backup':str(backup),'rolled_back':True,'error':str(e)}
(backup/'result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result));sys.exit(0 if result['ok'] else 1)
'''
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps({'mode':mode,'items':items}).encode(),capture_output=True,timeout=240)
if run.returncode and not run.stdout:raise SystemExit(run.stderr.decode())
result=json.loads(run.stdout);result['checked_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();(WORK/('logo-'+mode+'.json')).write_text(json.dumps(result,indent=2)+'\n')
if result.get('ok') and mode=='publish':
 shutil_publication=WORK/'publication-before-logo.json'
 if not shutil_publication.exists():shutil_publication.write_text(json.dumps(publication,indent=2)+'\n')
 publication['candidate_hashes'].update(result['hashes']);publication['runtime_files']=len(publication['candidate_hashes']);publication['logo_publication']=result
 (WORK/'publication.json').write_text(json.dumps(publication,indent=2)+'\n')
 for k,d in items.items():
  dest=WORK/'release'/k;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(base64.b64decode(d['data']))
print(json.dumps(result));raise SystemExit(0 if result.get('ok') else 1)
