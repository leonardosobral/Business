"""Five-file CAS publication; no DDL, credentials, cron changes, Git or sends.

Preserves production Meta V2 while keeping the local V3 work unpublished.
Default is read-only preflight. --verify, then --publish --verified.
"""
import base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];RR=ROOT.parent/'RoadRunners'
FILES=[('rr','repositories/VickyBrasilGiganteRepository.cfc',None),
 ('rr','repositories/VickyProactiveRepository.cfc','0c4a6b1a0c96a6f7a2d370ede49139ce11d4e46f88c012af9bcae2fbf051a4bf'),
 ('rr','services/VickyProactiveService.cfc','efef57ff8223fca3abe0da489ab7d5e45ee6236fe0f6d7460fe2054eb8f43e81'),
 ('business','administracao/vicky/includes/backend.cfm','c2ee87dff2bd1edfd384336f3c16be6f120aa7ad7f452b306699eda8c1de10ec'),
 ('business','administracao/vicky/home.cfm','865f66977f272c8baa664f5963e418df8760fa76bf36015371902b2c1d7fcc20')]
sha=lambda data:hashlib.sha256(data).hexdigest()
receipt=ROOT/'_codex/deploy/vicky-cbg-20261024.json';proof_path=ROOT/'_codex/deploy/vicky-cbg-tests-20261024.json'
previous=json.loads(receipt.read_text()) if receipt.exists() else {}
items=[]
for site,rel,before in FILES:
 data=((RR if site=='rr' else ROOT)/rel).read_bytes()
 if site=='rr' and rel=='services/VickyProactiveService.cfc':
  if data.count(b'services.VickyMetaWhatsappServiceV3')!=1:raise SystemExit('Unexpected local Meta runtime baseline')
  data=data.replace(b'services.VickyMetaWhatsappServiceV3',b'services.VickyMetaWhatsappServiceV2')
 path=('roadrunners.com.br/' if site=='rr' else 'business.roadrunners.run/')+rel
 items.append({'path':path,'before':previous.get('candidate_hashes',{}).get(path,before),'data':base64.b64encode(data).decode(),'after':sha(data)})
candidate={p['path']:p['after'] for p in items}
if '--verify' in sys.argv:
 results=[]
 for mode in ['native','service','queue','form','render','meta']:
  run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_vicky_cbg_native.py'),mode,'--production-variant'],capture_output=True,text=True,timeout=80)
  try:result=json.loads(run.stdout)
  except ValueError:raise SystemExit('Invalid test output: '+mode)
  results.append({'mode':mode,**result})
  if run.returncode or not result.get('ok') or not result.get('stage_removed'):print(run.stdout[-3500:]);raise SystemExit('Failed suite '+mode)
 proof_path.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'tests':results},ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({'ok':True,'native_suites':len(results),'no_test_deliveries':True}));raise SystemExit(0)
publish='--publish' in sys.argv
if publish:
 proof=json.loads(proof_path.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
 if '--verified' not in sys.argv or not 0<=age<3600 or proof['candidate_hashes']!=candidate:raise SystemExit('Matching fresh verification required')
preserved={}
old=json.loads((ROOT/'_codex/deploy/user-acquisition-20261023.json').read_text())
for rel,h in {**old['preserved_files'],**old['candidate_hashes']}.items():preserved['business.roadrunners.run/'+rel]=h
for item in items:preserved.pop(item['path'],None)
REMOTE=r'''
import base64,hashlib,json,os,pathlib,stat,subprocess,sys,tempfile
p=json.load(sys.stdin);root=pathlib.Path('/var/www');manifest={};files=[]
sha=lambda data:hashlib.sha256(data).hexdigest()
allowed={'roadrunners.com.br/repositories/VickyBrasilGiganteRepository.cfc','roadrunners.com.br/repositories/VickyProactiveRepository.cfc','roadrunners.com.br/services/VickyProactiveService.cfc','business.roadrunners.run/administracao/vicky/includes/backend.cfm','business.roadrunners.run/administracao/vicky/home.cfm'}
if {i['path'] for i in p['files']}!=allowed:raise SystemExit('Publication scope mismatch')
def target(rel):
 path=root/rel
 if path.is_symlink() or root not in path.resolve().parents:raise RuntimeError('Unsafe target')
 return path
preserved=p['preserved']
for rel in ['Application.cfc','config/settings.cfm','config/meta_whatsapp.local.cfm','includes/backend/vicky_meta_whatsapp_runtime_config.cfm','services/VickyMetaWhatsappServiceV2.cfc','api/integrations/vicky-proactive/worker.cfm','includes/estrutura/head.cfm','sso/comparador/_portal_nonce.cfm']:
 path=target('roadrunners.com.br/'+rel)
 if path.is_file():preserved['roadrunners.com.br/'+rel]=sha(path.read_bytes())
def check_preserved():
 for rel,expected in preserved.items():
  if sha(target(rel).read_bytes())!=expected:raise RuntimeError('Preserved file changed: '+rel)
check_preserved()
for item in p['files']:
 path=target(item['path']);current=path.read_bytes() if path.exists() else None
 if (sha(current) if current is not None else None)!=item['before']:raise SystemExit('Production baseline conflict: '+item['path'])
 data=base64.b64decode(item['data'],validate=True)
 if sha(data)!=item['after']:raise SystemExit('Invalid candidate')
 if current==data:continue
 item['content']=data;item['original']=current;files.append(item);manifest[item['path']]={'before':item['before'],'after':item['after']}
if not p['publish']:print(json.dumps({'ok':True,'mode':'preflight','manifest':manifest}));sys.exit(0)
backup=pathlib.Path(tempfile.mkdtemp(prefix='business-vicky-cbg-',dir='/var/backups'));os.chmod(backup,0o700)
published=[];metadata={};probes=[]
def atomic(path,data,info):
 fd,tmp=tempfile.mkstemp(prefix='.vicky-cbg-',dir=path.parent)
 try:
  with os.fdopen(fd,'wb') as stream:
   stream.write(data);stream.flush();os.fsync(stream.fileno());os.fchmod(stream.fileno(),stat.S_IMODE(info.st_mode));os.fchown(stream.fileno(),info.st_uid,info.st_gid)
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
try:
 for item in files:
  rel=item['path'];path=target(rel);current=path.read_bytes() if path.exists() else None
  if (sha(current) if current is not None else None)!=item['before']:raise RuntimeError('Concurrent modification: '+rel)
  info=path.stat() if path.exists() else target('roadrunners.com.br/repositories/VickyProactiveRepository.cfc').stat();metadata[rel]=info
  if current is not None:
   dest=backup/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(current);os.chmod(dest,0o600)
  atomic(path,item['content'],info);published.append(item)
 for host,path,method,expected in [('business.roadrunners.run','/administracao/vicky/?secao=interacoes','GET',302),('roadrunners.run','/api/integrations/vicky-proactive/worker.cfm','GET',405),('roadrunners.run','/api/integrations/vicky-proactive/worker.cfm','POST',401)]:
  run=subprocess.run(['curl','-sS','--max-time','25','--resolve',host+':443:127.0.0.1','--request',method,'--write-out','\n%{http_code}','https://'+host+path],capture_output=True,timeout=30)
  _,_,status=run.stdout.rpartition(b'\n');ok=not run.returncode and status==str(expected).encode();probes.append({'host':host,'path':path,'status':status.decode(),'ok':ok})
  if not ok:raise RuntimeError('Guard probe failed: '+path)
 check_preserved()
 if any(sha(target(i['path']).read_bytes())!=i['after'] for i in p['files']):raise RuntimeError('Final hash mismatch')
 result={'ok':True,'mode':'published','backup':str(backup),'manifest':manifest,'candidate_hashes':{i['path']:i['after'] for i in p['files']},'preserved_files':preserved,'probes':probes}
except Exception as error:
 rollback=[]
 for item in reversed(published):
  rel=item['path'];path=target(rel)
  if not path.exists() or sha(path.read_bytes())!=item['after']:rollback.append({'path':rel,'restored':False});continue
  if item['original'] is not None:atomic(path,item['original'],metadata[rel])
  else:
   dest=backup/'withdrawn'/rel;dest.parent.mkdir(parents=True,exist_ok=True);path.rename(dest)
  rollback.append({'path':rel,'restored':True})
 result={'ok':False,'backup':str(backup),'reason':str(error),'rollback':rollback,'probes':probes}
(backup/'receipt.json').write_text(json.dumps(result,indent=2));os.chmod(backup/'receipt.json',0o600)
print(json.dumps(result));sys.exit(0 if result['ok'] else 1)
'''
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps({'publish':publish,'files':items,'preserved':preserved}).encode(),capture_output=True,timeout=160)
try:result=json.loads(run.stdout)
except ValueError:print(json.dumps({'ok':False,'error':run.stderr.decode(errors='replace')[-1000:]}));raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
 result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'tests':proof['tests'],'meta_runtime_preserved':'VickyMetaWhatsappServiceV2','ddl':False,'git_mutations':False,'manual_test_deliveries':False})
 result['previous_publications']=previous.get('previous_publications',[])+([{'backup':previous['backup'],'candidate_hashes':previous['candidate_hashes']}] if previous else [])
 receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['preserved_files','tests']},ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
