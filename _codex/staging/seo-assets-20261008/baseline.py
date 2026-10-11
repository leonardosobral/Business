from config import *
import base64, hashlib, json, shlex, subprocess
remote = '''from pathlib import Path
import base64,hashlib,json,sys
root=Path('/var/www/roadrunners.com.br');p=json.load(sys.stdin)
r={'files':{},'watch':{}}
for n in p['files']:
 b=(root/n).read_bytes();r['files'][n]=base64.b64encode(b).decode()
for n in p['watch']:r['watch'][n]=hashlib.sha256((root/n).read_bytes()).hexdigest()
for n in p['new']:
 if (root/n).exists():raise RuntimeError('New file already exists: '+n)
print(json.dumps(r))'''
cp=subprocess.run(SSH+['python3 -c '+shlex.quote(remote)],input=json.dumps({'files':TEMPLATES+SOURCES+OLD_SOURCES,'watch':WATCH,'new':GENERATED}),capture_output=True,text=True,timeout=50)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout);before={}
for n,b64 in r['files'].items():
 raw=base64.b64decode(b64)
 if (R/n).read_bytes()!=raw:raise RuntimeError('Local/production drift: '+n)
 for sub in ['baseline','candidate']:
  dest=S/sub/n;dest.parent.mkdir(parents=True,exist_ok=True)
  if dest.exists() and dest.read_bytes()!=raw:raise RuntimeError('Existing baseline differs: '+n)
  dest.write_bytes(raw)
 if n in TEMPLATES:before[n]=hashlib.sha256(raw).hexdigest()
(S/'before.json').write_text(json.dumps(before,indent=2))
(S/'watch.json').write_text(json.dumps(r['watch'],indent=2))
print(json.dumps({'templates_matched':len(TEMPLATES),'source_assets_matched':len(SOURCES+OLD_SOURCES),'dependencies_watched':len(WATCH),'generated_paths_absent':len(GENERATED)}))
