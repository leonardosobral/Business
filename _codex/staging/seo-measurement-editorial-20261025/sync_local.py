from pathlib import Path
import json,hashlib
S=Path(__file__).resolve().parent;B=S.parents[2];W=B.parent;b=json.loads((S/'baseline.json').read_text());v=json.loads((S/'candidate-verified.json').read_text());writes=[]
for group,d in b.items():
 root=W/group
 for name,want in d['local'].items():
  dest=root/name;got=hashlib.sha256(dest.read_bytes()).hexdigest() if dest.exists() else None
  assert got==want,('Local conflict',group,name)
  source=S/'candidate'/group/name;assert hashlib.sha256(source.read_bytes()).hexdigest()==v['hashes'][group][name];writes.append((source,dest))
for source,name in [(S/'technical.md','_codex/docs/2026-10-25_medicao_regionais_pace.md'),(S/'pace_measurement.test.cjs','_codex/tests/pace_measurement.test.cjs')]:
 dest=W/'RoadRunners'/name;assert not dest.exists(),('New local target exists',str(dest));writes.append((source,dest))
for source,dest in writes:
 dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(source.read_bytes());assert dest.read_bytes()==source.read_bytes()
(S/'local-sync-verified.json').write_text(json.dumps({'files':[str(d.relative_to(W)) for s,d in writes],'runtime_hashes':v['hashes'],'unrelated_files':'untouched'},indent=2));print(json.dumps({'synced':len(writes),'runtime':5,'new_test_and_doc':2}))
