from config import *
import hashlib,json,shlex,subprocess,sys
mode=sys.argv[1];assert mode in ['prepare','publish','verify','rollback']
names=['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm']
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);root=ROOT;stage=Path('/var/backups/seo-athlete-route-panel-20261008');mode=p['mode']
watch=['portal/conteudo/seo.cfm','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_semrush_data.cfm','portal/includes/seo_search_evidence.cfm','includes/backend/require_admin.cfm','portal/conteudo/seo_ga4.cfm','portal/seo/ga4_service.cfm','portal/seo/ga4_api.cfm','portal/seo/assets/ga4.js']
if mode=='prepare':
 result=prepare(root,stage,p['files'],p['before']);(stage/'watch.json').write_text(json.dumps({n:digest((root/n).read_bytes()) for n in watch}))
 with tempfile.TemporaryDirectory(prefix='seo-assets-panel-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);src=work/'source';shutil.copytree(stage/'candidate',src);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=160)
  count=len(list(out.rglob('*.cfm')));output=cp.stdout+cp.stderr
  if cp.returncode or 'Error compiling' in output or count!=2:raise RuntimeError('Compile failed: '+output)
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'templates':count}))
 result={'prepared_files':2,'compiled_templates':count,'watched_dependencies':len(watch),'backup':str(stage/'baseline')}
elif mode=='publish':
 m=json.loads((stage/'manifest.json').read_text());c=json.loads((stage/'compiled.json').read_text());w=json.loads((stage/'watch.json').read_text())
 if c['templates']!=2 or c['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile receipt differs')
 for n,sha in m['candidate'].items():
  if p['tested_hashes'][n]!=sha:raise RuntimeError('Render receipt differs: '+n)
 baseline(root,w,w);result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage);w=json.loads((stage/'watch.json').read_text());baseline(root,w,w);result['preserved_dependencies']=len(w)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode}
if mode=='prepare':payload.update(files={n:(S/'candidate/business'/n).read_text() for n in names},before={n:hashlib.sha256((S/'baseline/business'/n).read_bytes()).hexdigest() for n in names})
if mode=='publish':
 assert json.loads((S/'public-passed.json').read_text())['passed']
 receipt=json.loads((S/'candidate-render-passed.json').read_text());assert receipt['scenarios']==19
 payload['tested_hashes']=receipt['hashes']
cp=subprocess.run(SSH+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=210)
if cp.returncode:raise RuntimeError(cp.stderr[-4000:])
r=json.loads(cp.stdout);(S/('panel-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
