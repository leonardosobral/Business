from pathlib import Path
import json,base64,sys
from inspect import remote,FILES,ROOT,W
STAGE='/var/backups/business-launch-responsibles-20261104'
mode=sys.argv[1]
if mode=='prepare':
 before={n:i['sha']for n,i in json.loads((W/'baseline.json').read_text()).items()if i['sha']}
 files={n:(W/'runtime'/n).read_text()for n in [FILES[0],FILES[3],FILES[4],FILES[2],FILES[1]]}
 body=r'''
root=Path('/var/www/business.roadrunners.run');stage=Path(payload['stage'])
m=prepare(root,stage,payload['files'],payload['before'])
with tempfile.TemporaryDirectory(prefix='launch-checklist-compile-',dir='/var/tmp')as d:
 work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
 p=subprocess.run(['/opt/coldfusion2025/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','coldfusion','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=170)
 text=p.stdout+p.stderr
 if p.returncode or 'Error compiling'in text or not any(compiled.rglob('*.cfm')):raise RuntimeError('Compilation failed: '+text)
 (stage/'compile.txt').write_text(text)
print(json.dumps({'prepared':str(stage),'files':len(m['candidate']),'cfml_compiled':True}))
'''
 r=remote(body,{'stage':STAGE,'files':files,'before':before})
elif mode=='publish':
 r=remote("root=Path('/var/www/business.roadrunners.run');stage=Path(payload['stage']);assert(stage/'compile.txt').is_file();print(json.dumps(publish(root,stage)))",{'stage':STAGE})
elif mode=='verify':
 r=remote("print(json.dumps(verify(Path('/var/www/business.roadrunners.run'),Path(payload['stage']))))",{'stage':STAGE})
elif mode=='sync':
 import hashlib
 before=json.loads((W/'baseline.json').read_text())
 for n in FILES:
  p=ROOT/n;existing=hashlib.sha256(p.read_bytes()).hexdigest()if p.exists()else None;candidate=(W/'runtime'/n).read_bytes()
  assert existing in(before[n]['sha'],hashlib.sha256(candidate).hexdigest()),'Local drift '+n
 for n in FILES:(ROOT/n).write_bytes((W/'runtime'/n).read_bytes())
 r={'synced':len(FILES)}
else:raise SystemExit('Unknown mode')
(W/(mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False))
