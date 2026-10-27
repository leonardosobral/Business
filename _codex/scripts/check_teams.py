"""Read-only production baselines and offline ColdFusion compilation for Teams."""
import base64,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
MODE=sys.argv[1]
SHARED=['business/index.cfm','business/includes/estrutura/sidenav.cfm','business/includes/backend/business_google_callback.cfm','business/services/accountDelegation/RequestBoundary.cfc','rr/atleta/index.cfm','rr/includes/estrutura/header.cfm']
def candidates():
 result={}
 for folder in ['teams','services/teams']:
  for p in (ROOT/folder).rglob('*'):
   if p.is_file():result['business/'+str(p.relative_to(ROOT))]=p.read_text()
 for rel in SHARED:
  if rel.startswith('business/'):result[rel]=(ROOT/rel.removeprefix('business/')).read_text()
 for p in (ROOT/'_codex/teams/roadrunners').rglob('*'):
  if p.is_file():result['rr/'+str(p.relative_to(ROOT/'_codex/teams/roadrunners'))]=p.read_text()
 for p in (ROOT/'services/teams').glob('*'):
  if p.is_file() and p.name not in ['Mailer.cfc','EmailTransport.cfc']:result['rr/services/teams/'+p.name]=p.read_text()
 for p in (ROOT/'teams/assets').glob('*'):
  if p.is_file():result['rr/teams/assets/'+p.name]=p.read_text()
 return result
REMOTE=r'''
import base64,hashlib,json,os,pathlib,subprocess,sys,tempfile
p=json.load(sys.stdin);root=pathlib.Path('/var/www');sites={'business':'business.roadrunners.run','rr':'roadrunners.com.br'}
if p['mode']=='baseline':
 files={}
 for rel in p['paths']:
  site,name=rel.split('/',1);target=root/sites[site]/name
  files[rel]={'hash':hashlib.sha256(target.read_bytes()).hexdigest() if target.exists() else None,'data':base64.b64encode(target.read_bytes()).decode() if target.exists() else None}
 print(json.dumps({'ok':True,'files':files}));sys.exit(0)
archive=pathlib.Path(tempfile.mkdtemp(prefix='rr-teams-compile-',dir='/var/backups'));os.chmod(archive,0o700)
with tempfile.TemporaryDirectory(prefix='rr-teams-compile-',dir='/var/tmp') as directory:
 stage=pathlib.Path(directory);os.chmod(stage,0o755);source=stage/'source';source.mkdir(mode=0o755);dest=stage/'compiled';dest.mkdir(mode=0o777);os.chmod(dest,0o777)
 for rel,body in p['files'].items():
  target=source/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(body,encoding='utf-8');os.chmod(target,0o644)
 run=subprocess.run(['/opt/coldfusion2025/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','coldfusion','-webroot',str(source),'-dir',str(source),'-deploydir',str(dest)],capture_output=True,text=True,timeout=170)
 raw=run.stdout+run.stderr;(archive/'compile.txt').write_text(raw);os.chmod(archive/'compile.txt',0o600)
 count=len([f for f in dest.rglob('*') if f.is_file()]);ok=run.returncode==0 and 'Error compiling' not in raw and 'Errors found' not in raw and 'CFMLCompileError' not in raw and count>0
 print(json.dumps({'ok':ok,'exit_code':run.returncode,'compiled_files':count,'output':raw[-7000:],'archive':str(archive)}))
'''
compile_files=candidates()
if MODE=='compile' and (ROOT/'_codex/teams/release-manifest.json').exists():
 manifest=json.loads((ROOT/'_codex/teams/release-manifest.json').read_text());compile_files={}
 for rel,entry in manifest.items():
  data=(ROOT/'_codex/teams/release'/rel).read_bytes()
  if hashlib.sha256(data).hexdigest()!=entry['after']:raise SystemExit('Release candidate changed: '+rel)
  compile_files[rel]=data.decode('utf-8')
payload={'mode':MODE,'paths':SHARED,'files':compile_files}
if MODE=='baseline':payload['paths']=list(payload['files'])
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=190)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-1500:]}
if result.get('ok') and MODE=='baseline':
 target=ROOT/'_codex/teams/baseline/production';target.mkdir(parents=True,exist_ok=True)
 for rel,info in result['files'].items():
  if info['data'] is not None:
   out=target/rel;out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(base64.b64decode(info.pop('data')))
  else:info.pop('data',None)
 (ROOT/'_codex/teams/production-baseline.json').write_text(json.dumps(result,indent=2)+'\n')
 result={'ok':True,'baseline_files':len(result['files'])}
elif MODE=='compile':(ROOT/'_codex/teams/compile.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
