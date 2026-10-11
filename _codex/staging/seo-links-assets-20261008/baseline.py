from config import *
import base64,hashlib,json,re,shlex,subprocess
script=(R/'_codex/scripts/minify_seo_assets.mjs').read_text();old_inputs=json.loads(re.search(r'const inputs=(\[.*?\]);',script).group(1).replace("'",'"'))
all_sources=old_inputs+SOURCES
remote='''from pathlib import Path
import base64,hashlib,json,sys
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');biz=Path('/var/www/business.roadrunners.run')
r={'files':{n:base64.b64encode((root/n).read_bytes()).decode() for n in p['files']},'watch':{n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in p['watch']},'business':{n:base64.b64encode((biz/n).read_bytes()).decode() for n in p['business']}}
for n in p['new']:
 if (root/n).exists():raise RuntimeError('New asset exists: '+n)
print(json.dumps(r))'''
bn=['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']
cp=subprocess.run(SSH+['python3 -c '+shlex.quote(remote)],input=json.dumps({'files':TEMPLATES+all_sources,'watch':WATCH,'new':GENERATED,'business':bn}),capture_output=True,text=True,timeout=60)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout)
for group,root,files in [('rr',R,r.pop('files')),('business',B,r.pop('business'))]:
 for n,b64 in files.items():
  raw=base64.b64decode(b64);assert (root/n).read_bytes()==raw,n+' local/production drift'
  for sub in ['baseline','candidate']:
   target=S/sub/group/n;target.parent.mkdir(parents=True,exist_ok=True)
   assert not target.exists() or target.read_bytes()==raw,'Existing baseline differs: '+n
   target.write_bytes(raw)
(S/'minify-baseline.mjs').write_text(script)
r.update(all_sources=all_sources,old_inputs=old_inputs,before={n:hashlib.sha256((S/'baseline/rr'/n).read_bytes()).hexdigest() for n in TEMPLATES})
(S/'baseline.json').write_text(json.dumps(r,indent=2));print(json.dumps({'runtime_templates_matched':len(TEMPLATES),'source_assets_matched':len(all_sources),'watch':len(WATCH),'business_files_matched':len(bn)}))
