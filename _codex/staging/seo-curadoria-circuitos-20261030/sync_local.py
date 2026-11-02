from pathlib import Path
import hashlib,json,shutil
S=Path(__file__).resolve().parent;R=S.parents[3]/'RoadRunners';b=json.loads((S/'baseline.json').read_text());v=json.loads((S/'candidate-verified.json').read_text())
for n in b['names']:
 p=R/n;have=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
 assert have==b['local'][n],('Local changed',n)
 assert hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest()==v['hashes'][n]
doc=R/'_codex/docs/2026-10-30_curadoria_provas_circuitos.md';assert not doc.exists()
for n in b['names']:
 p=R/n;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(S/'candidate'/n,p)
shutil.copyfile(S/'technical.md',doc)
result={'files':len(b['names']),'hashesVerified':all(hashlib.sha256((R/n).read_bytes()).hexdigest()==v['hashes'][n] for n in b['names']),'doc':str(doc)}
(S/'local-sync-verified.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
