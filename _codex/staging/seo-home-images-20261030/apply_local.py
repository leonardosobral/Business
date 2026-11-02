from pathlib import Path
import hashlib,json
S=Path(__file__).resolve().parent;R=Path('/Users/Shared/Projects/RunnerHub/RoadRunners');b=json.loads((S/'baseline.json').read_text())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
assert sha(R/'index.cfm') in (b['local']['index.cfm'],sha(S/'candidate/index.cfm')),'Local home changed; preserve conflict'
doc=R/'_codex/docs/2026-10-30_home_imagens_prioridade.md';assert not doc.exists() or sha(doc)==sha(S/'local-doc.md'),'Local doc conflict'
(R/'index.cfm').write_bytes((S/'candidate/index.cfm').read_bytes());doc.write_bytes((S/'local-doc.md').read_bytes())
assert sha(R/'index.cfm')==sha(S/'candidate/index.cfm')
(S/'local-synced.json').write_text(json.dumps({'runtime':1,'doc':1,'guarded':True,'hash':sha(R/'index.cfm')},indent=2));print('Home and task documentation synchronized with hash guard.')
