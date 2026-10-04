from pathlib import Path
import hashlib,json,re,shlex,subprocess,sys
stage=Path(__file__).resolve().parent
root=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
mode=sys.argv[1]
assert mode in ['prepare','amend','publish','verify','rollback']
names=['includes/backend/backend_estado_cidades.cfm','assets/js/runnerhub-estado-cidades.js','assets/css/runnerhub-estado-cidades.css','api/eventos.cfm','estado/index.cfm']
helpers=(Path('/Users/Shared/Projects/RunnerHub/Business/_codex/scripts/deploy_estudo.py')).read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
helpers=helpers.replace("(work/'run.cfm').write_text", "(work/'fixture.cfm').write_text(payload['fixture'])\n  (work/'run.cfm').write_text")
remote=helpers+'''
payload=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');stage=Path('/var/backups/rr-estado-cidades-20261003')
mode=payload['mode']
if mode in ['prepare','amend']:
 if mode=='prepare':
  result=prepare(root,stage,payload['files'],payload['before'])
  (stage/'watch.json').write_text(json.dumps(payload['watch'],indent=2))
 else:
  m=json.loads((stage/'manifest.json').read_text());baseline(root,m['order'],m['before'])
  if set(m['order'])!=set(payload['files']) or m['before']!=payload['before']:raise RuntimeError('Different release scope')
  for name,content in payload['files'].items():
   target=stage/'candidate'/name;target.write_text(content);m['candidate'][name]=digest(target.read_bytes())
  (stage/'manifest.json').write_text(json.dumps(m,indent=2));result=m
 with tempfile.TemporaryDirectory(prefix='rr-city-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=150)
  output=cp.stdout+cp.stderr;count=len(list(compiled.rglob('*.cfm')))
  if cp.returncode!=0 or 'Error compiling' in output or count!=3:raise RuntimeError('Compile failed: '+output)
  result['compile']={'templates':count,'returncode':cp.returncode}
 result['adobe']=bridge(Path('/var/www/business.roadrunners.run'),'savecontent variable="cityFixtureOutput" { include "fixture.cfm"; } report={output=trim(cityFixtureOutput)};')
 if 'RR_CITY_COUNTS_PASSED:8' not in result['adobe']['OUTPUT']:raise RuntimeError('Adobe assertion did not complete')
 (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'templates':3}))
elif mode=='publish':
 marker=json.loads((stage/'compiled.json').read_text())
 if marker['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Candidate not compiled')
 watch=json.loads((stage/'watch.json').read_text());baseline(root,watch,watch)
 result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage)
 watch=json.loads((stage/'watch.json').read_text());baseline(root,watch,watch)
 result['unrelated_files_unchanged']=len(watch)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode}
if mode in ['prepare','amend']:
 payload.update(files={n:(stage/'candidate'/n).read_text() for n in names},before=json.loads((stage/'before.json').read_text()),watch=json.loads((stage/'watch.json').read_text()),fixture=(stage/'counts-fixture.cfm').read_text())
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=200)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
result=json.loads(cp.stdout);(stage/('release-'+mode+'.json')).write_text(json.dumps(result,indent=2,ensure_ascii=False))
print(json.dumps({k:v for k,v in result.items() if k not in ['before','candidate','order']},ensure_ascii=False))
