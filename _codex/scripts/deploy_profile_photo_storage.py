"""CAS publication of profile-photo storage paths; never syncs entire environments."""
import ast,base64,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
WORK=pathlib.Path('/private/tmp/profile-photo-prod-20261114')
proof=json.loads((WORK/'tests-candidate.json').read_text())
assert proof['ok'] and proof['fixtures_removed'] and proof['stage_removed'] and len(proof['checks'])==4
sha=lambda b:hashlib.sha256(b).hexdigest()
files=[]
for host in ['roadrunners.com.br','dev.roadrunners.run']:
 for rel in ['api/upload_foto_atleta.cfm','includes/backend/backend_perfil_edicao.cfm']:
  path=host+'/'+rel;data=(WORK/'candidate'/path).read_bytes();assert sha(data)==proof['hashes'][path],path
  files.append({'path':path,'before':sha((WORK/'baseline'/path).read_bytes()),'after':sha(data),'data':base64.b64encode(data).decode()})
tree=ast.parse((ROOT/'_codex/scripts/helpdesk_tools_release_harness.py').read_text());remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
old=next(l for l in remote.splitlines() if l.startswith('allowed='));remote=remote.replace(old,'allowed='+repr({f['path'] for f in files}),1)
a=remote.index("preserved=p['preserved']");b=remote.index('def check_preserved():',a);remote=remote[:a]+"preserved={rel:sha(target(rel).read_bytes()) for rel in p['preserve_paths']}\n"+remote[b:]
remote=remote.replace("prefix='business-vicky-cbg-'","prefix='profile-photo-prod-storage-20261114-'").replace("prefix='.vicky-cbg-'","prefix='.profile-photo-storage-'")
probes=[]
for host in ['dev.roadrunners.run','roadrunners.run']:
 probes += [(host,'/api/upload_foto_atleta.cfm','GET',400),(host,'/api/upload_foto_atleta.cfm','POST',400),(host,'/atleta/','GET',302),(host,'/configuracoes/perfil/','GET',302)]
 for route in ['/teams/','/teams/meu-team/','/teams/entrar/','/teams/convidar/','/api/profile/teams.cfm']:
  for method in ['GET','POST']:probes.append((host,route,method,404))
old=next(l for l in remote.splitlines() if l.startswith(' for host,path,method,expected in '));remote=remote.replace(old,' for host,path,method,expected in '+repr(probes)+':',1)
preserved=[]
for host in ['dev.roadrunners.run','roadrunners.com.br']:
 preserved += [host+'/'+p for p in ['Application.cfc','config/strava.local.cfm','includes/backend/backend.cfm','includes/estrutura/header.cfm','includes/estrutura/variaveis.cfm','includes/modal/modal_profile_photo.cfm','atleta/index.cfm','atleta/parts/configuracoes.cfm','configuracoes/perfil/index.cfm','includes/backend/backend_profile_settings.cfm','api/profile/teams.cfm','teams/includes/start.cfm']]
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=10','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files,'publish':'--publish' in sys.argv,'preserve_paths':preserved}).encode(),capture_output=True,timeout=150)
if not p.stdout:raise SystemExit(p.stderr.decode(errors='replace')[-600:])
r=json.loads(p.stdout);(WORK/('published.json' if '--publish' in sys.argv else 'preflight.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
print(json.dumps({k:v for k,v in r.items() if k not in ['manifest','preserved_files','candidate_hashes']},ensure_ascii=False))
raise SystemExit(0 if not p.returncode and r.get('ok') else 1)
