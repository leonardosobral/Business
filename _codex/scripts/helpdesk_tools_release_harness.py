"""CAS release harness retained independently for Helpdesk tools."""
REMOTE = r'''
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
