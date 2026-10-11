from config import *
import json,re,subprocess
info=json.loads((S/'baseline.json').read_text());script=(S/'minify-baseline.mjs').read_text()
replacement='const inputs='+json.dumps(info['all_sources'],separators=(',',':')).replace('"',"'")+';'
script,n=re.subn(r'const inputs=\[.*?\];',replacement,script,count=1);assert n==1
(S/'minify_seo_assets.mjs').write_text(script)
changed={}
for name in TEMPLATES:
 text=(S/'baseline/rr'/name).read_text();count=0
 for source,target in zip(SOURCES,GENERATED):
  text,n=re.subn(re.escape('/'+source)+r'\?[^"\s>]+','/'+target+'?v='+VERSION,text);count+=n
 assert count>0,name+' no changed reference'
 (S/'candidate/rr'/name).write_text(text);changed[name]=count
cp=subprocess.run(['node',str(S/'minify_seo_assets.mjs'),str(S/'candidate/rr'),str(S/'candidate/rr'),'/private/tmp/rr-seo-assets-20261008-tools/node_modules/esbuild'],capture_output=True,text=True,timeout=60)
if cp.returncode:raise RuntimeError(cp.stderr)
build=json.loads(cp.stdout);(S/'build.json').write_text(json.dumps(build,indent=2))
selected=[x for x in build['files'] if x['source'] in SOURCES];before=sum(x['before_bytes'] for x in selected);after=sum(x['after_bytes'] for x in selected)
print(json.dumps({'generated':len(selected),'references':changed,'before_bytes':before,'after_bytes':after,'reduction_percent':round(100*(1-after/before),1)}))
