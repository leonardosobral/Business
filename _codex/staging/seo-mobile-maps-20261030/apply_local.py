from pathlib import Path
import hashlib,json
S=Path(__file__).resolve().parent;R=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
b=json.loads((S/'baseline.json').read_text());extra=json.loads((S/'local-tools-before.json').read_text())
files={n:S/'candidate'/n for n in b['names']}
files.update({'_codex/scripts/minify_seo_assets.mjs':S/'local-tools/minify_seo_assets.mjs','_codex/tests/event_maps_lazy.test.cjs':S/'local-tools/event_maps_lazy.test.cjs','_codex/docs/2026-10-30_mapas_sob_demanda.md':S/'local-tools/2026-10-30_mapas_sob_demanda.md'})
expected={**b['local'],**extra}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
for n,source in files.items():
 assert sha(R/n) in [expected[n],sha(source)],'Local conflict: '+n
for n,source in files.items():
 target=R/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(source.read_bytes())
assert all(sha(R/n)==sha(source) for n,source in files.items())
(S/'local-synced.json').write_text(json.dumps({'files':list(files),'hashes':{n:sha(R/n) for n in files},'guarded':True},indent=2))
print(json.dumps({'synced':len(files),'runtime':len(b['names']),'guarded':True}))
