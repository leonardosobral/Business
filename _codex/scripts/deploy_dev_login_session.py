"""Publish only the tested DEV session/return fix, preserving Business dependencies."""
import ast,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
tests=json.loads((ROOT/'_codex/deploy/dev-login-tests-20261021.json').read_text())
age=datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(tests['checked_at'])
if not(tests.get('ok') and tests.get('checks',0)>=52 and tests.get('dev_header_sha256') and tests.get('dev_return_sha256')
 and tests.get('stage_removed') and len(tests.get('render_checks',[]))==4
 and all(case.get('ok') for case in tests['render_checks']) and 0<=age.total_seconds()<3600):
 raise SystemExit('Fresh successful session and header evidence is required')
for name,expected in tests['files'].items():
 if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=expected:raise SystemExit('Business dependency changed after tests')
patches=[json.loads((ROOT/name).read_text()) for name in ['_codex/patches/dev-login-session-identity.json','_codex/patches/dev-login-return-header.json','_codex/patches/dev-login-return-state.json']]
tree=ast.parse((ROOT/'_codex/scripts/deploy_dev_login.py').read_text())
remote=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign)
 and any(isinstance(target,ast.Name) and target.id=='REMOTE' for target in node.targets))
start=remote.index(" if set(payload['files'])!=allowed:")
end=remote.index(' for label,item in candidates.items():',start)
remote=remote[:start]+r'''
 for relative,expected in payload['dependencies'].items():
  if current(root/relative)!=expected:raise RuntimeError('Business dependency conflict: '+relative)
 whitelist={'/var/www/dev.roadrunners.run/Application.cfc','/var/www/dev.roadrunners.run/includes/estrutura/header.cfm','/var/www/dev.roadrunners.run/includes/backend/backend.cfm'}
 if set(p['path'] for p in payload['patches'])!=whitelist:raise RuntimeError('Unexpected session-fix scope')
 for patch in payload['patches']:
  dev=pathlib.Path(patch['path'])
  if current(dev)!=patch['baseline']:raise RuntimeError('DEV baseline conflict')
  source=dev.read_text()
  for step in patch.get('steps',[patch]):
   if source.count(step['before'])!=1:raise RuntimeError('DEV patch context changed')
   source=source.replace(step['before'],step['after'],1)
  if sha(source.encode())!=payload['expected'][str(dev)]:raise RuntimeError('DEV candidate differs from tested source')
  label='dev/'+str(dev.relative_to('/var/www/dev.roadrunners.run'))
  candidates[label]={'path':dev,'baseline':patch['baseline'],'content':source}
'''+remote[end:]
order_start=remote.index(" order=['business/services/")
order_end=remote.index('\n',order_start)
remote=remote[:order_start]+' order=list(candidates)'+remote[order_end:]
remote=remote.replace('business-dev-login-20261021-','business-dev-login-session-20261021-')
payload={'patches':patches,'dependencies':tests['files'],'expected':{
 patches[0]['path']:tests['dev_receiver_sha256'],patches[1]['path']:tests['dev_header_sha256'],patches[2]['path']:tests['dev_return_sha256']}}
proc=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=130)
try:result=json.loads(proc.stdout)
except Exception:result={'ok':False,'error':'Session publication transport failed; output suppressed'}
if result.get('ok'):
 result['tests']=tests
 (ROOT/'_codex/deploy/dev-login-session-20261021.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(result,ensure_ascii=False))
if proc.returncode or not result.get('ok'):sys.exit(1)
