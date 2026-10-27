"""Private localhost CF Teams tests; ephemeral schema and no deliveries."""
import ast,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
mode=sys.argv[1] if len(sys.argv)>1 else 'native'
tree=ast.parse((ROOT/'_codex/teams/native_harness.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
remote=remote.replace("raw[-5000:]","raw if mode=='render' else raw[-5000:]")
remote=remote.replace('user_acquisition_','teams_').replace('business-user-acquisition-test-','rr-teams-test-').replace('USER_ACQUISITION_','TEAMS_')
remote=remote.replace("body=body.replace('new services.UserAcquisitionMetrics','new _codex.'+name+'.services.UserAcquisitionMetrics')", "body=body.replace('new services.teams.Service','new _codex.'+name+'.services.teams.Service').replace('new services.teams.Mailer','new _codex.'+name+'.services.teams.Mailer').replace('new services.teams.EmailTransport','new _codex.'+name+'.services.teams.EmailTransport').replace('__TEAMS_COMPONENT__','_codex.'+name+'.services.teams.Service').replace('__PROTOCOL__','_codex.'+name+'.tests.Protocol').replace('__FAKE_ACCOUNTS__','_codex.'+name+'.tests.FakeAccounts').replace('__ACCOUNT_BOUNDARY__','_codex.'+name+'.services.accountDelegation.RequestBoundary').replace('__FAKE_SENDER__','_codex.'+name+'.tests.FakeSender')")
payload={'mode':mode}
payload['services/accountDelegation/RequestBoundary.cfc']=(ROOT/'services/accountDelegation/RequestBoundary.cfc').read_text()
payload['tests/Protocol.cfc']=(ROOT.parent/'RoadRunners/services/ComparadorIdentityProtocol.cfc').read_text()
for p in (ROOT/'services/teams').glob('*.cfc'):payload[str(p.relative_to(ROOT))]=p.read_text()
if mode=='existing_concurrency':
 key='services/teams/Service.cfc';body=payload[key]
 marker="q('SELECT id_team FROM {s}.team WHERE id_team=:team FOR UPDATE',{team=id});"
 assert body.count(marker)==1
 body=body.replace(marker,marker+"APPLICATION.existingDirectLocked=true;sleep(250);",1)
 marker="var invite=first(q('SELECT * FROM {s}.admin_invite WHERE token_hash=:hash FOR UPDATE',{hash=lCase(hash(token,'SHA-256'))}));"
 assert body.count(marker)==1
 body=body.replace(marker,marker+"sleep(300);",1)
 payload[key]=body

for p in (ROOT/'_codex/tests/teams').glob('*'):
 if p.is_file():payload['tests/'+p.name]=p.read_text()
p=ROOT/'_codex/sql/2026-10-26_rr_teams.sql'
if p.exists():payload['tests/install.sql']=p.read_text()
for p in (ROOT/'teams').rglob('*'):
 if p.is_file():payload[str(p.relative_to(ROOT))]=p.read_text()
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=65)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-1000:]}
if mode=='render' and result.get('ok'):
 import base64,tempfile
 marker='TEAMS_RENDER_PASSED '
 rendered=result['output'].split(marker,1)[1].strip()
 preview=pathlib.Path(tempfile.mkdtemp(prefix='rr-teams-preview-'))
 (preview/'index.html').write_bytes(base64.b64decode(rendered))
 assets=preview/'teams/assets';assets.mkdir(parents=True)
 for p in (ROOT/'teams/assets').glob('*'):
  if p.is_file():(assets/p.name).write_bytes(p.read_bytes())
 result['output']='TEAMS_RENDER_PASSED';result['preview_path']=str(preview)
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
