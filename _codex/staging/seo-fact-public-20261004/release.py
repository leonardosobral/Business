from pathlib import Path
import json,hashlib,subprocess,shlex,sys
p=Path(__file__).resolve().parent;root=p.parents[2];mode=sys.argv[1];project=sys.argv[2];config=json.loads((p/'config.json').read_text());names=config['names'][project]
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);root=Path(p['root']);stage=Path('/var/backups/seo-fact-public-20261004-'+p['project']);mode=p['mode']
if mode=='prepare':
 result=prepare(root,stage,p['files'],p['before']);(stage/'watch.json').write_text(json.dumps(p['watch']))
 with tempfile.TemporaryDirectory(prefix='fact-public-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=150)
  count=len(list(compiled.rglob('*.cfm')))+len(list(compiled.rglob('*.cfc')))
  if cp.returncode or 'Error compiling' in cp.stdout+cp.stderr or count!=len(p['files']):raise RuntimeError(cp.stdout+cp.stderr)
  (stage/'compile.json').write_text(json.dumps({'manifest':digest((stage/'manifest.json').read_bytes()),'count':count}));result={'prepared':True,'compiled':count,'backup':str(stage/'baseline')}
elif mode=='publish':
 if json.loads((stage/'compile.json').read_text())['manifest']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile mismatch')
 if json.loads((stage/'manifest.json').read_text())['candidate']!=p['hashes']:raise RuntimeError('Test candidate mismatch')
 watch=json.loads((stage/'watch.json').read_text());baseline(root,watch,watch);result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage);watch=json.loads((stage/'watch.json').read_text());baseline(root,watch,watch);result['dependencies_preserved']=len(watch)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
files={n:(p/'candidate'/project/n).read_text() for n in names}
payload=dict(mode=mode,project=project,root=config['roots'][project][1],files=files,before={n:hashlib.sha256((p/'baseline'/project/n).read_bytes()).hexdigest() for n in names},watch=config['watch'][project],hashes={n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()})
if mode=='publish':
 tested=json.loads((p/'tested-hashes.json').read_text())
 assert all(tested[project+'/'+n]==h for n,h in payload['hashes'].items())
 assert json.loads((p/'database-verify.json').read_text())['verified']
 assert all(x['PASSED'] for x in json.loads((p/'service-candidate.json').read_text())['checks'])
 assert all(x['PASSED'] for x in json.loads((p/'cfml-green.json').read_text())['CHECKS'])
 assert (p/'controller-candidate.json').exists()
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=170)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
r=json.loads(cp.stdout);(p/('release-'+project+'-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
