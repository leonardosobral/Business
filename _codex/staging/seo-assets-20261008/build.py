from config import *
import json, re, subprocess
generator=(R/'_codex/scripts/minify_seo_assets.mjs').read_text()
old='const inputs='+json.dumps(OLD_SOURCES,separators=(',', ':')).replace('"', "'")+';'
assert old in generator
new='const inputs='+json.dumps(OLD_SOURCES+SOURCES,separators=(',', ':')).replace('"', "'")+';'
(S/'minify_seo_assets.mjs').write_text(generator.replace(old,new))
for name in TEMPLATES:
 text=(S/'baseline'/name).read_text();count=0
 for source,target in zip(SOURCES,GENERATED):
  pattern=re.escape('/'+source)+r'\?[^"\s>]+'
  text,n=re.subn(pattern,'/'+target+'?v=20261008seo',text);count+=n
 if not count:raise RuntimeError('No references changed: '+name)
 (S/'candidate'/name).write_text(text)
cp=subprocess.run(['node',str(S/'minify_seo_assets.mjs'),str(S/'candidate'),str(S/'candidate'),'/private/tmp/rr-seo-assets-20261008-tools/node_modules/esbuild'],capture_output=True,text=True,timeout=50)
if cp.returncode:raise RuntimeError(cp.stderr)
build=json.loads(cp.stdout)
(S/'build.json').write_text(json.dumps(build,ensure_ascii=False,indent=2))
selected=[x for x in build['files'] if x['source'] in SOURCES]
before=sum(x['before_bytes'] for x in selected);after=sum(x['after_bytes'] for x in selected)
print(json.dumps({'generated':len(selected),'template_references':len(TEMPLATES),'original_bytes':before,'minified_bytes':after,'reduction_percent':round(100*(1-after/before),1)}))
