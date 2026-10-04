"""Scoped deployment with baseline checks, backups and production hash verification."""
from pathlib import Path
import hashlib,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=ROOT/'_codex/staging/seo-routes-20261003'
MODE=sys.argv[1]
assert MODE in ['prepare','publish-rr','publish-business','verify','rollback','prepare-metadata','publish-metadata']
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
payload=json.load(sys.stdin);mode=payload['mode'];result={}
roots={'RoadRunners':Path('/var/www/roadrunners.com.br'),'Business':Path('/var/www/business.roadrunners.run')}
stages={'RoadRunners':Path('/var/backups/seo-routes-rr-20261003'),'Business':Path('/var/backups/seo-routes-business-20261003')}
if mode=='prepare':
 for project,p in payload['projects'].items():baseline(roots[project],p['files'],p['before'])
 for project,p in payload['projects'].items():
  result[project]=prepare(roots[project],stages[project],p['files'],p['before'])
  watch={}
  for name in (['evento/index.cfm','includes/backend/backend_evento.cfm','noticias/index.cfm','sitemaps/index.cfm'] if project=='RoadRunners' else ['portal/includes/seo_score_data.cfm','portal/conteudo/seo.cfm','includes/backend/require_admin.cfm']):
   f=roots[project]/name
   if f.exists():watch[name]=digest(f.read_bytes())
  (stages[project]/'watch.json').write_text(json.dumps(watch,indent=2))
 source=stages['Business']/'candidate';compiled=stages['Business']/'compiled';compiled.mkdir(mode=0o777);os.chmod(stages['Business'],0o755);os.chmod(compiled,0o777)
 args=['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)]
 p=subprocess.run(args,capture_output=True,text=True,timeout=120);output=p.stdout+p.stderr
 if p.returncode!=0 or 'Error compiling' in output or not any(compiled.rglob('*.cfm')):raise RuntimeError('Compilation failed: '+output)
 result['compile']={'returncode':p.returncode,'output':output}
 os.chmod(stages['Business'],0o700)
elif mode=='prepare-metadata':
 project='RoadRunners';mstage=Path('/var/backups/seo-routes-rr-metadata-20261003');p=payload['metadata']
 result['metadata']=prepare(roots[project],mstage,p['files'],p['before'])
 stage=stages['Business'];m=json.loads((stage/'manifest.json').read_text());baseline(roots['Business'],m['order'],m['before'])
 for name,want in m['candidate'].items():
  if digest((stage/'candidate'/name).read_bytes())!=want:raise RuntimeError('Prepared candidate changed')
 for name,content in payload['queue'].items():(stage/'candidate'/name).write_text(content)
 m['candidate']={name:digest((stage/'candidate'/name).read_bytes()) for name in m['order']};(stage/'manifest.json').write_text(json.dumps(m,indent=2))
 with tempfile.TemporaryDirectory(prefix='seo-routes-compile-',dir='/var/tmp') as directory:
  work=Path(directory);os.chmod(work,0o755);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
  for label,prepared in [('event',mstage),('queue',stage)]:
   source=work/label;shutil.copytree(prepared/'candidate',source)
   cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=120)
   output=cp.stdout+cp.stderr
   if cp.returncode!=0 or 'Error compiling' in output:raise RuntimeError('Compile failure: '+output)
   result[label+'_compile']={'returncode':cp.returncode,'output':output}
elif mode=='publish-metadata':
 result['metadata']=publish(roots['RoadRunners'],Path('/var/backups/seo-routes-rr-metadata-20261003'))
elif mode in ['publish-rr','publish-business']:
 project='RoadRunners' if mode=='publish-rr' else 'Business'
 result[project]=publish(roots[project],stages[project])
elif mode=='verify':
 for project in roots:
  result[project]=verify(roots[project],stages[project])
  watch=json.loads((stages[project]/'watch.json').read_text())
  own={'evento/index.cfm'} if project=='RoadRunners' else set()
  changed=[name for name,before in watch.items() if name not in own and digest((roots[project]/name).read_bytes())!=before]
  result[project]['unrelated_files_changed']=changed
 result['metadata']=verify(roots['RoadRunners'],Path('/var/backups/seo-routes-rr-metadata-20261003'))
else:
 mstage=Path('/var/backups/seo-routes-rr-metadata-20261003')
 if (mstage/'manifest.json').exists():result['metadata']=rollback(roots['RoadRunners'],mstage)
 for project in roots:result[project]=rollback(roots[project],stages[project])
print(json.dumps(result))
'''
payload={'mode':MODE}
if MODE=='prepare-metadata':
 name='evento/index.cfm'
 payload['metadata']={'files':{name:(STAGE/'candidate/RoadRunners'/name).read_text()},'before':{name:hashlib.sha256((STAGE/'baseline/RoadRunners'/name).read_bytes()).hexdigest()}}
 payload['queue']={'portal/includes/seo_queue_data.cfm':(STAGE/'candidate/Business/portal/includes/seo_queue_data.cfm').read_text()}
if MODE=='prepare':
 payload['projects']={}
 for project,names in [('RoadRunners',['.htaccess','evento/.htaccess']),('Business',['portal/includes/seo_queue_data.cfm'])]:
  files={name:(STAGE/'candidate'/project/name).read_text() for name in names}
  before={name:hashlib.sha256((STAGE/'baseline'/project/name).read_bytes()).hexdigest() for name in names}
  payload['projects'][project]={'files':files,'before':before}
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
if p.returncode:raise RuntimeError(p.stderr[-2200:])
r=json.loads(p.stdout);(STAGE/('release-'+MODE+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
