"""Private loopback ColdFusion fixtures for the international event editor.

Schema mode is read-only. Other modes use synthetic events and rollback. No
provider calls, global application changes or real-event mutations.
"""
import ast,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
mode=sys.argv[1] if len(sys.argv)>1 else 'event_location'
tree=ast.parse((ROOT/'_codex/scripts/test_geocoding_native.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
anchor="content=content.replace('services.geocoding.','_codex.'+name+'.services.geocoding.')"
remote=remote.replace(anchor,anchor+"\n  content=content.replace('services.EventLocationPolicy','_codex.'+name+'.services.EventLocationPolicy')",1)
paths=['services/EventLocationPolicy.cfc','services/geocoding/Policy.cfc','services/geocoding/RegionNames.cfc',
       'eventos/includes/backend/event_mutations.cfm','eventos/includes/backend/event_delegation.cfm',
       'eventos/includes/event_location_fields.cfm','eventos/form_edicao.cfm',
       'eventos/includes/localizacoes_confirmadas.cfm','eventos/includes/enriquecimento_confirmado.cfm',
       'includes/parts/business_delegation_form.cfm','eventos/includes/event_location_error.cfm']
payload={'_mode':mode}
for name in paths:
 p=ROOT/name
 if p.exists():payload[name]=p.read_text()
for p in (ROOT/'_codex/tests/event-location').glob('*.cfm'):payload['tests/'+p.name]=p.read_text()
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=75)
try:result=json.loads(r.stdout)
except ValueError:result={'ok':False,'reason':'Native test transport failed','diagnostic':r.stderr.decode(errors='replace')[-600:]}
print(json.dumps(result,ensure_ascii=False))
raise SystemExit(0 if not r.returncode and result.get('ok') else 1)
