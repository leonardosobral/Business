from pathlib import Path
import hashlib,json,shlex,subprocess,sys

ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');P=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ['prepare','publish','verify','rollback']
names=['portal/includes/seo_queue_data.cfm']
payload={'mode':mode}
if mode=='prepare':payload.update(files={n:(P/'candidate/business'/n).read_text() for n in names},before={n:hashlib.sha256((P/'baseline/business'/n).read_bytes()).hexdigest() for n in names},captured_watch=json.loads((P/'panel-baseline.json').read_text())['watch'])
if mode=='publish':
 r=json.loads((P/'candidate-render-passed.json').read_text());assert r['scenarios']==19
 payload['test_hashes']=r['hashes']
 assert r['hashes']=={n:hashlib.sha256((P/'candidate/business'/n).read_bytes()).hexdigest() for n in names}
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);root=ROOT;stage=Path('/var/backups/seo-event-performance-20261008-business');mode=p['mode']
watch=['portal/conteudo/seo.cfm','portal/conteudo/seo_ga4.cfm','portal/seo/ga4_service.cfm','portal/seo/ga4_api.cfm','portal/seo/assets/ga4.js','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_search_evidence.cfm','includes/backend/require_admin.cfm','portal/includes/seo_score_data.cfm']
if mode=='prepare':
 baseline(root,p['captured_watch'],p['captured_watch']);result=prepare(root,stage,p['files'],p['before']);(stage/'watch.json').write_text(json.dumps({n:digest((root/n).read_bytes()) for n in watch}))
 with tempfile.TemporaryDirectory(prefix='seo-audit-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);src=work/'source';shutil.copytree(stage/'candidate',src);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=160)
  output=cp.stdout+cp.stderr
  if cp.returncode or 'Error compiling' in output or len(list(out.rglob('*.cfm')))!=1:raise RuntimeError('Compilation failed: '+output)
  result={'prepared':len(p['files']),'compiled':len(p['files']),'watch':len(watch),'compiler_output':output}
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'compiled':len(p['files'])}))
elif mode=='publish':
 c=json.loads((stage/'compiled.json').read_text())
 if c['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile receipt mismatch')
 for n,sha in p['test_hashes'].items():
  if sha!=digest((stage/'candidate'/n).read_bytes()):raise RuntimeError('Test receipt mismatch: '+n)
 w=json.loads((stage/'watch.json').read_text());baseline(root,w,w)
 result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage);w=json.loads((stage/'watch.json').read_text());baseline(root,w,w);result['preserved_dependencies']=len(w)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=220)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
r=json.loads(cp.stdout);(P/('panel-'+mode+'.json')).write_text(json.dumps(r,indent=2));r.pop('compiler_output',None);print(json.dumps(r))
