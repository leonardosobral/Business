"""Synchronize only this task's RoadRunners sources, preserving other work."""
import datetime,hashlib,importlib.util,json,pathlib,shutil,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];RR=ROOT.parent/'RoadRunners';WORK=ROOT/'_codex/teams';sha=lambda b:hashlib.sha256(b).hexdigest()
spec=importlib.util.spec_from_file_location('teams_patch',WORK/'patch_shared.py');patch=importlib.util.module_from_spec(spec);spec.loader.exec_module(patch)
items={}
for p in (WORK/'roadrunners/teams').rglob('*'):
 if p.is_file():items['teams/'+str(p.relative_to(WORK/'roadrunners/teams'))]=p.read_bytes()
for p in (ROOT/'services/teams').iterdir():
 if p.is_file() and p.name not in ['Mailer.cfc','EmailTransport.cfc']:items['services/teams/'+p.name]=p.read_bytes()
for p in (ROOT/'teams/assets').iterdir():
 if p.is_file():items['teams/assets/'+p.name]=p.read_bytes()
previous_path=WORK/'rr-local-sync.json';previous=json.loads(previous_path.read_text()) if previous_path.exists() else {}
backup=WORK/'baseline/rr-local'
for rel in ['atleta/index.cfm','includes/estrutura/header.cfm']:
 path=RR/rel;original=path.read_bytes()
 if previous.get(rel)==sha(original):items[rel]=original
 else:
  save=backup/rel;save.parent.mkdir(parents=True,exist_ok=True)
  if not save.exists():save.write_bytes(original)
  items[rel]=patch.patch('rr/'+rel,original.decode('utf-8-sig')).encode()
for rel,data in items.items():
 path=RR/rel
 if rel not in ['atleta/index.cfm','includes/estrutura/header.cfm'] and path.exists() and path.read_bytes()!=data and previous.get(rel)!=sha(path.read_bytes()):raise SystemExit('Unrelated local file conflict: '+rel)
if '--apply' in sys.argv:
 for rel,data in items.items():
  path=RR/rel;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
 previous_path.write_text(json.dumps({k:sha(v) for k,v in items.items()},indent=2)+'\n')
print(json.dumps({'ok':True,'applied':'--apply' in sys.argv,'files':len(items)}))
