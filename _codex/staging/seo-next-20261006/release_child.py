from pathlib import Path
import hashlib,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');P=Path(__file__).resolve().parent
group,mode=sys.argv[1:];assert group in ['rr','business'] and mode in ['prepare','publish','verify','rollback']
names=['evento/.htaccess'] if group=='rr' else ['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm']
payload={'group':group,'mode':mode,'names':names}
if mode=='prepare':payload.update(files={n:(P/'candidate'/group/n).read_text() for n in names},before={n:hashlib.sha256((P/'baseline'/group/n).read_bytes()).hexdigest() for n in names})
if mode=='publish':
 if group=='rr':
  r=json.loads((P/'apache-tests.json').read_text());assert not r['failed'] and len(r['checks'])==27
  payload['test_hashes']={'evento/.htaccess':r['child_source_hash']}
 else:
  public=json.loads((P/'public-passed.json').read_text());assert public['passed'] and public['alias_checks']==6
  tested=json.loads((P/'candidate-render-passed.json').read_text())['hashes'];payload['test_hashes']={n:tested[n] for n in names}
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br') if p['group']=='rr' else ROOT;stage=Path('/var/backups/seo-next-20261006-rr-child') if p['group']=='rr' else Path('/var/backups/seo-next-20261006-business');mode=p['mode']
watch=['Application.cfc','evento/index.cfm','includes/backend/backend_evento.cfm','includes/estrutura/head.cfm','includes/estrutura/header.cfm','includes/estrutura/footer.cfm','includes/estrutura/header_tema.cfm','includes/estrutura/event_redirect.cfm','services/EventRedirectService.cfc','includes/estrutura/variaveis.cfm','includes/backend/backend_feed.cfm','desafiosupra/2024/index.cfm','desafiosupra/2025/index.cfm','circuito/index.cfm','timer/index.cfm','timer/.htaccess','includes/estrutura/event_title_date.cfm','.htaccess'] if p['group']=='rr' else ['portal/conteudo/seo.cfm','portal/conteudo/seo_ga4.cfm','portal/seo/ga4_service.cfm','portal/seo/ga4_api.cfm','portal/seo/assets/ga4.js','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_search_evidence.cfm','includes/backend/require_admin.cfm','portal/includes/seo_semrush_data.cfm']
if mode=='prepare':
 result=prepare(root,stage,p['files'],p['before']);(stage/'watch.json').write_text(json.dumps({n:digest((root/n).read_bytes()) for n in watch}))
 if p['group']=='rr':
  cp=subprocess.run(['apache2ctl','-t'],capture_output=True,text=True,timeout=20)
  if cp.returncode:raise RuntimeError('Apache config check failed')
 if p['group']=='rr':
  result={'prepared':1,'compiled':0,'watch':len(watch),'apache_config_valid':True}
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'compiled':0}))
 else:
  with tempfile.TemporaryDirectory(prefix='seo-indexacao-compile-',dir='/var/tmp') as d:
   work=Path(d);os.chmod(work,0o755);src=work/'source';src.mkdir();
   for n in p['files']:
    if n.endswith('.cfm'):
     target=src/n;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(stage/'candidate'/n,target)
   out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
   cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=160)
   output=cp.stdout+cp.stderr
   if cp.returncode or 'Error compiling' in output or not any(out.rglob('*.cfm')):raise RuntimeError('Compilation failed: '+output)
   result={'prepared':len(p['files']),'compiled':sum(n.endswith('.cfm') for n in p['files']),'watch':len(watch),'compiler_output':output}
   (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'compiled':sum(n.endswith('.cfm') for n in p['files'])}))
elif mode=='publish':
 c=json.loads((stage/'compiled.json').read_text());m=json.loads((stage/'manifest.json').read_text())
 if c['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile receipt mismatch')
 for n,sha in p['test_hashes'].items():
  if sha!=digest((stage/'candidate'/n).read_bytes()):raise RuntimeError('Test receipt mismatch: '+n)
 watch_hash=json.loads((stage/'watch.json').read_text());baseline(root,watch_hash,watch_hash)
 result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage);w=json.loads((stage/'watch.json').read_text());baseline(root,w,w);result['preserved_dependencies']=len(w)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=220)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
r=json.loads(cp.stdout);(P/(group+'-child-'+mode+'.json')).write_text(json.dumps(r,indent=2));r.pop('compiler_output',None);print(json.dumps(r))
