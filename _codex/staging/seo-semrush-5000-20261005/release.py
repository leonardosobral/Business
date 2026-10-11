from pathlib import Path
import hashlib,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');P=Path(__file__).resolve().parent
group,mode=sys.argv[1:];assert group in ['rr','business'] and mode in ['prepare','publish','verify','rollback']
names=['includes/estrutura/event_title_date.cfm','services/EventRedirectService.cfc','includes/card_evento_individual.cfm','includes/estrutura/header_tema.cfm','includes/estrutura/head.cfm'] if group=='rr' else ['portal/includes/seo_semrush_data.cfm','portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm']
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br') if p['group']=='rr' else ROOT;stage=Path('/var/backups/seo-semrush-5000-20261005-'+p['group']);mode=p['mode']
watch=['Application.cfc','evento/index.cfm','timer/index.cfm','includes/estrutura/footer.cfm','includes/estrutura/header.cfm'] if p['group']=='rr' else ['portal/conteudo/seo.cfm','portal/conteudo/seo_ga4.cfm','portal/seo/ga4_service.cfm','portal/seo/ga4_api.cfm','portal/seo/assets/ga4.js','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_search_evidence.cfm','includes/backend/require_admin.cfm']
if mode=='prepare':
 result=prepare(root,stage,p['files'],p['before']);(stage/'watch.json').write_text(json.dumps({n:digest((root/n).read_bytes()) for n in watch}))
 with tempfile.TemporaryDirectory(prefix='seo-5000-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);src=work/'source';shutil.copytree(stage/'candidate',src);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=160)
  output=cp.stdout+cp.stderr
  if cp.returncode or 'Error compiling' in output:raise RuntimeError(output)
  result={'prepared':len(p['files']),'compiled':len(p['files']),'compiler_output':output,'watch':len(watch)}
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'templates':len(p['files'])}))
elif mode=='publish':
 c=json.loads((stage/'compiled.json').read_text());m=json.loads((stage/'manifest.json').read_text())
 if p['group']=='business':
  receipt=p['render_receipt']
  if receipt.get('scenarios')!=19 or receipt.get('mode')!='candidate':raise RuntimeError('Missing panel validation')
  for n,sha in receipt['hashes'].items():
   if sha!=digest((stage/'candidate'/n).read_bytes()):raise RuntimeError('Panel receipt mismatch: '+n)
 if c['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile receipt mismatch')
 watch=json.loads((stage/'watch.json').read_text());baseline(root,watch,watch)
 result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage);watch=json.loads((stage/'watch.json').read_text());baseline(root,watch,watch);result['preserved_dependencies']=len(watch)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'group':group,'mode':mode}
if mode=='publish' and group=='business':payload['render_receipt']=json.loads((P/'candidate-render-passed.json').read_text())
if mode=='prepare':
 payload['files']={n:(P/'candidate'/group/n).read_text() for n in names}
 payload['before']={n:hashlib.sha256((P/'baseline'/group/n).read_bytes()).hexdigest() for n in names if (P/'baseline'/group/n).exists()}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=220)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
r=json.loads(cp.stdout);(P/(group+'-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False));r.pop('compiler_output',None);print(json.dumps(r,ensure_ascii=False))
