from pathlib import Path
import hashlib,json,shlex,subprocess,sys,shutil
P=Path(__file__).resolve().parent;ROOT=P.parents[2];mode=sys.argv[1]
names=['includes/estrutura/event_redirect.cfm']
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-semrush-5000-redirect-20261005');mode=p['mode']
if mode=='baseline':
 r={n:{'source':(ROOT/n).read_text(),'sha256':digest((ROOT/n).read_bytes())} for n in p['names']}
elif mode=='prepare':
 r=prepare(ROOT,stage,p['files'],p['before'])
 with tempfile.TemporaryDirectory(prefix='seo-redirect-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);src=work/'source';shutil.copytree(stage/'candidate',src);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=160)
  if cp.returncode or 'Error compiling' in cp.stdout+cp.stderr:raise RuntimeError(cp.stdout+cp.stderr)
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes())}));r={'prepared':1,'compiled':1}
elif mode=='publish':
 receipt=p['tests'];m=json.loads((stage/'manifest.json').read_text())
 if receipt['passed']!=9:raise RuntimeError('Missing expected behavioral tests')
 for n in p['names']:
  if receipt['hashes'][n]!=digest((stage/'candidate'/n).read_bytes()):raise RuntimeError('Behavior receipt mismatch: '+n)
 if json.loads((stage/'compiled.json').read_text())['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile receipt mismatch')
 r=publish(ROOT,stage)
else:r=verify(ROOT,stage)
print(json.dumps(r))
'''
p={'mode':mode,'names':names}
if mode=='prepare':
 p['files']={n:(P/'redirect-candidate'/n).read_text() for n in names}
 p['before']={n:hashlib.sha256((P/'redirect-baseline'/n).read_bytes()).hexdigest() for n in names}
if mode=='publish':p['tests']=json.loads((P/'redirect-tests-passed.json').read_text())
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(p),capture_output=True,text=True,timeout=230)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout);(P/('redirect-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
if mode=='baseline':
 for n,x in r.items():
  d=P/'redirect-baseline'/n;d.parent.mkdir(parents=True,exist_ok=True);d.write_text(x['source']);assert hashlib.sha256(d.read_bytes()).hexdigest()==x['sha256']
 print(json.dumps({'baseline_files':len(r)}))
else:print(json.dumps(r))
