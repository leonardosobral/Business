from config import *
import json,hashlib,os
info=json.loads((S/'baseline.json').read_text())
for n in TEMPLATES:assert (R/n).read_bytes()==(S/'baseline/rr'/n).read_bytes(),'Local changed: '+n
for n,h in {n:info['watch'][n] for n in SOURCES}.items():assert hashlib.sha256((R/n).read_bytes()).hexdigest()==h,'Local dependency changed: '+n
for n in GENERATED:assert not (R/n).exists(),'Local path exists: '+n
generator=R/'_codex/scripts/minify_seo_assets.mjs'
assert generator.read_bytes()==(S/'minify-baseline.mjs').read_bytes(),'Generator changed'
assert json.loads((S/'public-passed.json').read_text())['passed']
for n in GENERATED+TEMPLATES:
 target=R/n;tmp=target.with_name(target.name+'.seo-assets-new')
 with tmp.open('xb') as out:out.write((S/'candidate/rr'/n).read_bytes())
 if target.exists():os.chmod(tmp,target.stat().st_mode & 0o777)
 os.replace(tmp,target)
generator.write_bytes((S/'minify_seo_assets.mjs').read_bytes())
print(json.dumps({'local_runtime_files':9,'generator_inputs':18,'sources_preserved':5}))
