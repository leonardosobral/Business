from config import *
import hashlib,json,shlex,subprocess,sys
mode=sys.argv[1];assert mode in ['prepare','publish','verify','rollback']
names=TEMPLATES
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
remote=helpers+'''
p=json.load(sys.stdin);root=ROOT;stage=Path('/var/backups/seo-event-routes-20261008-rr');mode=p['mode']
if mode=='prepare':
 baseline(root,p['watch'],p['watch']);result=prepare(root,stage,p['files'],p['before'])
 (stage/'watch.json').write_text(json.dumps(p['watch']))
 with tempfile.TemporaryDirectory(prefix='seo-event-routes-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);src=work/'source';src.mkdir()
  for n in p['files']:
   if n.endswith('.cfm'):
    target=src/n;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(stage/'candidate'/n,target)
  out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  if cp.returncode or 'Error compiling' in output or count!=2:raise RuntimeError('Compilation failed: '+output)
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'templates':count}))
 result={'prepared_files':len(p['files']),'compiled_templates':count,'watched_dependencies':len(p['watch']),'backup':str(stage/'baseline')}
elif mode=='publish':
 m=json.loads((stage/'manifest.json').read_text());c=json.loads((stage/'compiled.json').read_text());w=json.loads((stage/'watch.json').read_text())
 if c['templates']!=2 or c['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile receipt differs')
 if p['tested_hashes']!=m['candidate']:raise RuntimeError('Test receipt differs')
 baseline(root,w,w);result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage);w=json.loads((stage/'watch.json').read_text());baseline(root,w,w);result['preserved_dependencies']=len(w)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode}
if mode=='prepare':payload.update(files={n:(S/'candidate/rr'/n).read_text() for n in names},before={n:hashlib.sha256((S/'baseline/rr'/n).read_bytes()).hexdigest() for n in names},watch=json.loads((S/'inspection.json').read_text())['watch'])
if mode=='publish':
 checks=json.loads((S/'tests-green.json').read_text());assert len(checks['CHECKS'])==91 and not checks['failed']
 cards=json.loads((S/'card-tests-green.json').read_text());assert len(cards['CHECKS'])==40 and not cards['failed']
 assert checks['source_hash']==hashlib.sha256((S/'candidate/rr'/names[1]).read_bytes()).hexdigest()
 assert cards['source_hash']==hashlib.sha256((S/'candidate/rr'/names[0]).read_bytes()).hexdigest()
 assert (S/'public-before.json').exists()
 payload['tested_hashes']={n:hashlib.sha256((S/'candidate/rr'/n).read_bytes()).hexdigest() for n in names}
cp=subprocess.run(SSH+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=240)
if cp.returncode:raise RuntimeError(cp.stderr[-4000:])
r=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
