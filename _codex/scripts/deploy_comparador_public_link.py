"""Publish only the reviewed public-link view patch, using the audited release library.

Default is read-only preflight. SQL, fixtures and authentication harness stay local.
Rollback this patch before rolling back the original five-file Business release.
"""
import argparse,base64,datetime,hashlib,importlib.util,json,pathlib,shlex,subprocess,sys,uuid
TARGET='administracao/comparador/home.cfm'
BEFORE='96775d9c70a61405294e3ac598a355f3cf162ff6deca37e3b41a78eafc4de0ff'
AFTER='c982cd4a39fff6d691c1ba918540e1ad623079ef99c4b57662b63ecf442c5fd8'
LIBRARY_SHA='aa551a07f6bb330cf6064bd8eb0c5e054bcff1e861c55c582080633eb0e5155b'
BACKUPS='/var/backups/business-comparador-admin-link-20261016'
ROOT=pathlib.Path(__file__).resolve().parents[2]
SOURCE=(pathlib.Path(__file__).parent/'deploy_comparador_admin.py').read_bytes()
if hashlib.sha256(SOURCE).hexdigest()!=LIBRARY_SHA:raise RuntimeError('Reviewed release library changed')
namespace={'__name__':'comparador_release_library'}
exec(compile(SOURCE,'deploy_comparador_admin.py','exec'),namespace)
namespace['PATHS']=(TARGET,)
def remote(payload):
 code="namespace={'__name__':'comparador_release_library'}\nexec("+repr(SOURCE.decode())+",namespace)\nnamespace['PATHS']="+repr((TARGET,))+"\nnamespace['BACKUPS']=namespace['pathlib'].Path("+repr(BACKUPS)+")\nnamespace['remote_main']()\n"
 result=subprocess.run(namespace['SSH']+['python3 -c '+shlex.quote(code)],input=json.dumps(payload),text=True,capture_output=True,timeout=180)
 if result.returncode:raise RuntimeError(result.stderr[-3000:] or 'Remote patch failed')
 return json.loads(result.stdout)
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('mode',nargs='?',default='preflight',choices=['preflight','publish','verify','rollback']);parser.add_argument('--release');args=parser.parse_args()
 if args.mode in ('verify','rollback'):
  if not args.release:parser.error('--release is required')
  report=remote({'mode':args.mode,'release':namespace['valid_release'](args.release)})
  if args.mode=='verify':report['smokes']=namespace['smokes']()
  print(json.dumps(report,indent=2));return
 data=(ROOT/TARGET).read_bytes()
 if hashlib.sha256(data).hexdigest()!=AFTER:raise RuntimeError('Reviewed view patch changed')
 payload={'mode':args.mode,'files':{TARGET:{'data':base64.b64encode(data).decode(),'before':BEFORE,'after':AFTER}}}
 if args.mode=='preflight':print(json.dumps(remote(payload),indent=2));return
 release=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+uuid.uuid4().hex[:8];payload['release']=release
 report_path=ROOT/'_codex/docs/2026-10-16_comparador_public_link_publicacao.json'
 report={'release':release,'backup':BACKUPS+'/'+release,'status':'starting','runtime_paths':[TARGET]}
 namespace['write_json'](report_path,report)
 try:
  report['remote']=remote(payload);report['hash_verification']=remote({'mode':'verify','release':release});report['smokes']=namespace['smokes']()
  if not all(case['passed'] for case in report['smokes']):raise RuntimeError('Anonymous smoke verification failed')
  report['status']='published_verified';report['verified_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
 except Exception as error:
  report['status']='failed';report['error']=str(error)
  try:report['rollback']=remote({'mode':'rollback','release':release});report['status']='rolled_back'
  except Exception as rollback_error:report['rollback_error']=str(rollback_error)
  namespace['write_json'](report_path,report);print(json.dumps(report,indent=2));raise SystemExit(1)
 namespace['write_json'](report_path,report);print(json.dumps(report,indent=2))
if __name__=='__main__':main()
