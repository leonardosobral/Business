from config import *
import json,hashlib,os
for n in TEMPLATES:
 assert (R/n).read_bytes()==(S/'baseline'/n).read_bytes(),'Local changed: '+n
for n in GENERATED:assert not (R/n).exists(),'Local new path exists: '+n
generator=R/'_codex/scripts/minify_seo_assets.mjs'
old='const inputs='+json.dumps(OLD_SOURCES,separators=(',', ':')).replace('"', "'")+';'
new='const inputs='+json.dumps(OLD_SOURCES+SOURCES,separators=(',', ':')).replace('"', "'")+';'
assert generator.read_text().replace(old,new)==(S/'minify_seo_assets.mjs').read_text(),'Generator changed'
for n in GENERATED+TEMPLATES:
 target=R/n;tmp=target.with_name(target.name+'.seo-assets-new')
 with tmp.open('xb') as stream:stream.write((S/'candidate'/n).read_bytes())
 if target.exists():os.chmod(tmp,target.stat().st_mode & 0o777)
 os.replace(tmp,target)
generator.write_text((S/'minify_seo_assets.mjs').read_text())
print(json.dumps({'local_runtime_files':len(GENERATED+TEMPLATES),'generator_updated':True}))
