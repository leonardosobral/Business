"""Publish only shared minified assets and their includes with a checked baseline and backup."""
from pathlib import Path
import hashlib,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
MODE=sys.argv[1];assert MODE in ['prepare','publish','verify','rollback']
NAMES=['assets/css/cores.min.css', 'assets/css/rr-audience-privacy.min.css', 'assets/css/runnerhub-footer.min.css', 'assets/js/rr-audience-privacy.min.js', 'assets/js/runnerhub-entry-prompts.min.js', 'includes/analytics/privacy_controls.cfm', 'includes/estrutura/footer_assets.cfm', 'includes/estrutura/seo-web-tools-body-end.cfm', 'includes/estrutura/seo-web-tools-head.cfm']
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
remote=helpers+'''
payload=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');stage=Path('/var/backups/seo-shared-assets-20261004')
mode=payload['mode']
if mode=='prepare':
 result=prepare(root,stage,payload['files'],payload['before'])
 (stage/'watch.json').write_text(json.dumps(payload['watch'],indent=2))
 with tempfile.TemporaryDirectory(prefix='seo-stats-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=150)
  output=cp.stdout+cp.stderr
  if cp.returncode!=0 or 'Error compiling' in output or len(list(compiled.rglob('*.cfm')))!=4:raise RuntimeError('Compile failed: '+output)
  result['compile']={'templates':4,'output':output,'returncode':cp.returncode}
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'templates':4}))
elif mode=='publish':
 marker=json.loads((stage/'compiled.json').read_text())
 if marker['templates']!=4 or marker['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compilation not bound to this candidate')
 watch=json.loads((stage/'watch.json').read_text());baseline(root,watch,watch)
 if payload['render']['hashes']!=json.loads((stage/'manifest.json').read_text())['candidate'] or payload['render']['watch']!=watch:raise RuntimeError('Render receipt does not match prepared candidate/dependencies')
 result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage)
 watch=json.loads((stage/'watch.json').read_text())
 changed=[name for name,want in watch.items() if digest((root/name).read_bytes())!=want]
 if changed:raise RuntimeError('Unrelated runtime changed since baseline: '+str(changed))
 result['unrelated_files_unchanged']=len(watch)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':MODE}
if MODE=='publish':payload['render']=json.loads((STAGE/'candidate-render-passed.json').read_text())
if MODE=='prepare':
 payload['files']={n:(STAGE/'candidate'/n).read_text() for n in NAMES}
 payload['before']={n:hashlib.sha256((STAGE/'baseline'/n).read_bytes()).hexdigest() for n in NAMES if (STAGE/'baseline'/n).exists()}
 payload['watch']=json.loads((STAGE/'watch.json').read_text())
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=200)
if cp.returncode:raise RuntimeError(cp.stderr[-2400:])
result=json.loads(cp.stdout);(STAGE/('release-'+MODE+'.json')).write_text(json.dumps(result,indent=2,ensure_ascii=False))
print(json.dumps({k:v for k,v in result.items() if k not in ['before','candidate','order','compile']}|({'compiled_templates':4} if 'compile' in result else {}),ensure_ascii=False))
