from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[2];group,mode=sys.argv[1:];assert group in ['rr','business'] and mode in ['prepare','publish','verify','rollback']
names=['includes/estrutura/header_tema.cfm'] if group=='rr' else ['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm']
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br') if p['group']=='rr' else ROOT;stage=Path('/var/backups/seo-marathon-h1-20261008-'+p['group']+('-final' if p['group']=='business' else ''));mode=p['mode']
if mode=='prepare':
 if p['group']=='rr':watch=p['watch']
 else:watch={n:digest((root/n).read_bytes()) for n in ['portal/conteudo/seo.cfm','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_semrush_data.cfm','portal/includes/seo_search_evidence.cfm','includes/backend/require_admin.cfm','portal/conteudo/seo_ga4.cfm','portal/seo/ga4_service.cfm','portal/seo/ga4_api.cfm','portal/seo/assets/ga4.js']}
 baseline(root,watch,watch);result=prepare(root,stage,p['files'],p['before']);(stage/'watch.json').write_text(json.dumps(watch))
 with tempfile.TemporaryDirectory(prefix='seo-marathon-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);src=work/'source';shutil.copytree(stage/'candidate',src);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=165)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  if cp.returncode or 'Error compiling' in output or count!=len(p['files']):raise RuntimeError('Compile failed: '+output)
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes()),'templates':count}))
 result={'prepared_files':len(p['files']),'compiled_templates':count,'watched_dependencies':len(watch),'backup':str(stage/'baseline')}
elif mode=='publish':
 m=json.loads((stage/'manifest.json').read_text());c=json.loads((stage/'compiled.json').read_text());w=json.loads((stage/'watch.json').read_text())
 if c['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Compile receipt differs')
 for n,h in m['candidate'].items():
  if p['tested_hashes'][n]!=h:raise RuntimeError('Test receipt differs: '+n)
 baseline(root,w,w);result=publish(root,stage)
elif mode=='verify':
 result=verify(root,stage);w=json.loads((stage/'watch.json').read_text());baseline(root,w,w);result['preserved_dependencies']=len(w)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'group':group,'mode':mode}
if mode=='prepare':
 payload.update(files={n:(S/'candidate'/group/n).read_text() for n in names},before={n:hashlib.sha256((S/'baseline'/group/n).read_bytes()).hexdigest() for n in names})
 if group=='rr':payload['watch']=json.loads((S/'inspection.json').read_text())['watch']
if mode=='publish':
 if group=='rr':
  receipt=json.loads((S/'candidate-header-passed.json').read_text());assert len(receipt['rows'])==20 and all(x['passed'] for x in receipt['rows']);assert len(json.loads((S/'public-before.json').read_text())['rows'])==55
  expected=(S/'baseline/rr'/names[0]).read_text().replace('listFind("/org/,/timer/,/circuito/", VARIABLES.template)','listFind("/org/,/timer/,/circuito/,/maratona/", VARIABLES.template)')
  assert expected==(S/'candidate/rr'/names[0]).read_text();payload['tested_hashes']={names[0]:receipt['source_hash']}
 else:
  assert json.loads((S/'public-passed.json').read_text())['passed'];assert len(json.loads((S/'published-header-passed.json').read_text())['rows'])==20
  receipt=json.loads((S/'candidate-render-passed.json').read_text());assert receipt['scenarios']==19;payload['tested_hashes']=receipt['hashes']
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=210)
if cp.returncode:raise RuntimeError(cp.stderr[-4000:])
r=json.loads(cp.stdout);(S/(group+'-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
