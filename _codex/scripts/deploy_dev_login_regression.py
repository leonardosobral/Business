"""Publish the tested login regression fix only to DEV, preserving current runtime."""
import ast,base64,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
WORK=pathlib.Path('/private/tmp/dev-login-fix-20261114')
proof=json.loads((WORK/'tests-candidate.json').read_text())
assert proof['ok'] and proof['checks']>=52 and proof['stage_removed']
assert len(proof['render_checks'])==4 and all(x['ok'] for x in proof['render_checks'])
fields={'Application.cfc':'dev_receiver_sha256','includes/backend/backend.cfm':'dev_return_sha256','includes/estrutura/header.cfm':'dev_header_sha256'}
sha=lambda b:hashlib.sha256(b).hexdigest()
files=[]
for rel,field in fields.items():
 data=(WORK/'candidate'/rel).read_bytes();assert sha(data)==proof[field],rel
 files.append({'path':'dev.roadrunners.run/'+rel,'before':sha((WORK/'baseline/dev.roadrunners.run'/rel).read_bytes()),'after':sha(data),'data':base64.b64encode(data).decode()})
tree=ast.parse((ROOT/'_codex/scripts/helpdesk_tools_release_harness.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
old=next(l for l in remote.splitlines() if l.startswith('allowed='));remote=remote.replace(old,'allowed='+repr({f['path'] for f in files}),1)
a=remote.index("preserved=p['preserved']");b=remote.index('def check_preserved():',a)
remote=remote[:a]+"preserved={rel:sha(target(rel).read_bytes()) for rel in p['preserve_paths']}\n"+remote[b:]
remote=remote.replace("prefix='business-vicky-cbg-'","prefix='business-dev-login-regression-20261114-'").replace("prefix='.vicky-cbg-'","prefix='.dev-login-regression-'")
probes=[('business.roadrunners.run','/administracao/usuarios/','GET',302),('dev.roadrunners.run','/?action=handoff_consume&token=invalid','GET',302),('roadrunners.run','/?action=handoff_consume&token=invalid','GET',302)]
for host in ['dev.roadrunners.run','roadrunners.run']:
 for route in ['/teams/','/teams/meu-team/','/teams/entrar/','/teams/convidar/','/api/profile/teams.cfm']:
  for method in ['GET','POST']:probes.append((host,route,method,404))
old=next(l for l in remote.splitlines() if l.startswith(' for host,path,method,expected in '));remote=remote.replace(old,' for host,path,method,expected in '+repr(probes)+':',1)
preserve=['business.roadrunners.run/'+p for p in ['Application.cfc','services/BusinessDevLogin.cfc','administracao/usuarios/includes/backend.cfm','administracao/usuarios/home.cfm']]
preserve+=['roadrunners.com.br/'+p for p in ['Application.cfc','includes/backend/backend.cfm','includes/estrutura/header.cfm','atleta/index.cfm','atleta/parts/configuracoes.cfm','configuracoes/perfil/index.cfm','includes/backend/backend_profile_settings.cfm','api/profile/teams.cfm','teams/includes/start.cfm']]
preserve+=['dev.roadrunners.run/'+p for p in ['config/strava.local.cfm','includes/models/Usuario.cfc','services/VerifiedEntitlement.cfc','atleta/index.cfm','atleta/parts/configuracoes.cfm','configuracoes/perfil/index.cfm','includes/backend/backend_profile_settings.cfm','api/profile/teams.cfm','teams/includes/start.cfm']]
payload={'files':files,'publish':'--publish' in sys.argv,'preserve_paths':preserve}
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=10','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=120)
if not p.stdout:raise SystemExit(p.stderr.decode(errors='replace')[-600:])
result=json.loads(p.stdout)
(WORK/('published.json' if payload['publish'] else 'preflight.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps({k:v for k,v in result.items() if k not in ['manifest','preserved_files','candidate_hashes']},ensure_ascii=False))
raise SystemExit(0 if not p.returncode and result.get('ok') else 1)
