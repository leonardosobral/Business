from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[2];NAME='includes/backend/backend_evento.cfm'
mode=sys.argv[1];assert mode in ['prepare','publish','verify','rollback']
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
code=helpers+'''
p=json.load(sys.stdin);root=ROOT;stage=Path('/var/backups/seo-event-performance-20261008-rr');mode=p['mode']
if mode=='prepare':
 baseline(root,p['watch'],p['watch']);result=prepare(root,stage,p['files'],p['before'])
 watch=p['watch'];watch['evento/parts/edicoes_evento.cfm']=digest((root/'evento/parts/edicoes_evento.cfm').read_bytes());(stage/'watch.json').write_text(json.dumps(watch))
 with tempfile.TemporaryDirectory(prefix='seo-event-performance-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);src=work/'source';src.mkdir();out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  for n in p['files']:
   target=src/n;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(stage/'candidate'/n,target)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  if cp.returncode or 'Error compiling' in output or count!=1:raise RuntimeError('Compilation failed: '+output)
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'templates':count}))
 result={'prepared_files':1,'compiled_templates':count,'watched_dependencies':len(watch),'backup':str(stage/'baseline')}
elif mode=='publish':
 m=json.loads((stage/'manifest.json').read_text());c=json.loads((stage/'compiled.json').read_text());w=json.loads((stage/'watch.json').read_text())
 if c['templates']!=1 or c['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile receipt differs')
 if p['tested_hashes']!=m['candidate']:raise RuntimeError('Test receipt differs')
 baseline(root,w,w);result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage);w=json.loads((stage/'watch.json').read_text());baseline(root,w,w);result['preserved_dependencies']=len(w)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode}
if mode=='prepare':payload.update(files={NAME:(S/'candidate/rr'/NAME).read_text()},before={NAME:hashlib.sha256((S/'baseline/rr'/NAME).read_bytes()).hexdigest()},watch=json.loads((S/'profile-before.json').read_text())['watch'])
if mode=='publish':
    want=hashlib.sha256((S/'candidate/rr'/NAME).read_bytes()).hexdigest()
    for f,n in [('tests.json',34),('production-equivalence.json',5)]:
        r=json.loads((S/f).read_text());assert not r['failed'] and r['source_hash']==want and len(r['CHECKS'])==n
    profile=json.loads((S/'profile-candidate.json').read_text());assert profile['sha256']==want and all(x['ROWS']==19 and x['EXECUTION_MS']<1800 for x in profile['profiles'])
    assert (S/'latency-before.json').exists()
    payload['tested_hashes']={NAME:want}
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(code)],input=json.dumps(payload),capture_output=True,text=True,timeout=230)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
r=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
