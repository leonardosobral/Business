"""Publish only the scoped production-derived candidates, with recoverable backups."""
from pathlib import Path
import hashlib,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
MODE=sys.argv[1]
assert MODE in ['prepare','compile-public','publish-public','prepare-business','revise-business','publish-business','verify','rollback']
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
payload=json.load(sys.stdin);mode=payload['mode'];result={}
roots={'RoadRunners':Path('/var/www/roadrunners.com.br'),'OpenResults':Path('/var/www/openresults.run'),'Business':Path('/var/www/business.roadrunners.run')}
stages={project:Path('/var/backups/seo-structure-'+project.lower()+'-20261003') for project in roots}
if mode in ['prepare','prepare-business','compile-public','revise-business']:
 for project,p in payload['projects'].items():baseline(roots[project],p['files'],p['before'])
 for project,p in payload['projects'].items():
  if mode in ['compile-public','revise-business']:
   m=json.loads((stages[project]/'manifest.json').read_text())
   for name,want in m['candidate'].items():
    if digest((stages[project]/'candidate'/name).read_bytes())!=want:raise RuntimeError('Candidate changed '+name)
   if mode=='revise-business':
    if m['before']!=p['before'] or set(m['order'])!=set(p['files']):raise RuntimeError('Revision scope mismatch')
    for name,content in p['files'].items():(stages[project]/'candidate'/name).write_text(content)
    m['candidate']={name:digest((stages[project]/'candidate'/name).read_bytes()) for name in m['order']}
    (stages[project]/'manifest.json').write_text(json.dumps(m,indent=2))
   result[project]={}
   continue
  result[project]=prepare(roots[project],stages[project],p['files'],p['before'])
  watch={}
  for name in ({'RoadRunners':['Application.cfc','.htaccess','evento/.htaccess','includes/backend/backend_evento.cfm','includes/estrutura/head.cfm','includes/card_evento_individual.cfm','services/EventRegistrationAvailability.cfc'], 'OpenResults':['Application.cfc','.htaccess','evento/index.cfm','includes/backend_evento.cfm','includes/head.cfm','includes/seo_event_schema.cfm'], 'Business':['portal/includes/seo_score_data.cfm','portal/conteudo/seo.cfm','portal/includes/seo_queue_backend.cfm','includes/backend/require_admin.cfm']}[project]):
   f=roots[project]/name
   if f.exists():watch[name]=digest(f.read_bytes())
  (stages[project]/'watch.json').write_text(json.dumps(watch,indent=2))
 with tempfile.TemporaryDirectory(prefix='seo-structure-compile-',dir='/var/tmp') as directory:
  work=Path(directory);os.chmod(work,0o755)
  for project in payload['projects']:
   source=work/project;shutil.copytree(stages[project]/'candidate',source)
   compiled=work/(project+'-compiled');compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
   cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=120)
   output=cp.stdout+cp.stderr;expected=len(list(source.rglob('*.cfm')))
   if cp.returncode!=0 or 'Error compiling' in output or len(list(compiled.rglob('*.cfm')))!=expected:raise RuntimeError('Compile failed '+project+': '+output)
   result[project]['compile']={'returncode':cp.returncode,'output':output,'templates':expected}
   (stages[project]/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stages[project]/'manifest.json').read_bytes()),'templates':expected}))
elif mode in ['publish-public','publish-business']:
 projects=['RoadRunners','OpenResults'] if mode=='publish-public' else ['Business']
 for project in projects:
  m=json.loads((stages[project]/'manifest.json').read_text());baseline(roots[project],m['order'],m['before'])
  compiled=json.loads((stages[project]/'compiled.json').read_text())
  if compiled['manifest_sha256']!=digest((stages[project]/'manifest.json').read_bytes()):raise RuntimeError('Compilation not confirmed for current candidate '+project)
 for project in projects:result[project]=publish(roots[project],stages[project])
elif mode=='verify':
 for project in roots:
  if not (stages[project]/'manifest.json').exists():continue
  followup=Path('/var/backups/seo-noindex-openresults-20261003')
  if project=='OpenResults' and (followup/'manifest.json').exists():
   prior=json.loads((stages[project]/'manifest.json').read_text());latest=json.loads((followup/'manifest.json').read_text())
   if latest['before']['robots.txt']!=prior['candidate']['robots.txt']:raise RuntimeError('Invalid authorized robots release chain')
   baseline(roots[project],['index.cfm'],{'index.cfm':prior['candidate']['index.cfm']})
   verify(roots[project],followup)
   result[project]={'verified_hashes':3,'authorized_followup':'athlete noindex'}
  else:result[project]=verify(roots[project],stages[project])
  watch=json.loads((stages[project]/'watch.json').read_text())
  if project=='OpenResults' and (followup/'manifest.json').exists():
   if latest['before']['includes/head.cfm']!=watch['includes/head.cfm']:raise RuntimeError('Invalid authorized head release chain')
   del watch['includes/head.cfm']
  changed=[name for name,want in watch.items() if digest((roots[project]/name).read_bytes())!=want]
  if changed:raise RuntimeError('Unrelated runtime changed '+project+': '+str(changed))
  result[project]['unrelated_files_unchanged']=len(watch)
else:
 for project in roots:
  if (stages[project]/'manifest.json').exists():result[project]=rollback(roots[project],stages[project])
print(json.dumps(result))
'''
payload={'mode':MODE}
if MODE in ['prepare','prepare-business','compile-public','revise-business']:
 payload['projects']={}
 projects={'RoadRunners':['includes/estrutura/home_hero_busca.cfm','evento/index.cfm'],'OpenResults':['index.cfm','robots.txt']} if MODE in ['prepare','compile-public'] else {'Business':['portal/includes/seo_queue_data.cfm']}
 for project,names in projects.items():
  files={name:(STAGE/'candidate'/project/name).read_text() for name in names}
  before={name:hashlib.sha256((STAGE/'baseline'/project/name).read_bytes()).hexdigest() for name in names}
  payload['projects'][project]={'files':files,'before':before}
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=320)
if p.returncode:raise RuntimeError(p.stderr[-2400:])
r=json.loads(p.stdout);(STAGE/('release-'+MODE+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
summary={project:{k:v for k,v in value.items() if k not in ['before','candidate','order','compile']}|({'compiled_templates':value['compile']['templates']} if 'compile' in value else {}) for project,value in r.items()}
print(json.dumps(summary,ensure_ascii=False))
