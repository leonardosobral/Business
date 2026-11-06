"""Two-file CAS publication of Wix extraction and bounded cron error samples."""
import ast,base64,datetime,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/cron13-jornalcorrida-20261105'
sha=lambda b:hashlib.sha256(b).hexdigest()
files=[('conteudo.roadrunners.run/admin/importer_contrarelogio.cfm',STAGE/'baseline/admin/importer_contrarelogio.cfm',ROOT.parent/'News/admin/importer_contrarelogio.cfm'),('business.roadrunners.run/includes/backend/cron_jobs_service.cfm',None,ROOT/'includes/backend/cron_jobs_service.cfm')]
items=[]
for rel,base,current in files:
 before=base.read_bytes() if base else (STAGE/'business-service-baseline.txt').read_bytes().split(b'\n',1)[1];after=current.read_bytes()
 items.append({'path':rel,'before':sha(before),'after':sha(after),'data':base64.b64encode(after).decode()})
candidate={i['path']:i['after'] for i in items};proof_path=ROOT/'_codex/deploy/jornalcorrida-extraction-tests-20261105.json';receipt=ROOT/'_codex/deploy/jornalcorrida-extraction-20261105.json'
if '--verify' in sys.argv:
 run=subprocess.run([sys.executable,'-B',str(ROOT/'_codex/scripts/test_jornalcorrida_extraction.py'),'candidate'],capture_output=True,text=True,timeout=75)
 test=json.loads(run.stdout)
 if run.returncode or not test.get('ok') or not test.get('stage_removed'):print(run.stdout);raise SystemExit(1)
 for repo,path in [(ROOT,'includes/backend/cron_jobs_service.cfm'),(ROOT.parent/'News','admin/importer_contrarelogio.cfm')]:
  check=subprocess.run(['git','diff','--check','--',path],cwd=repo,capture_output=True,text=True)
  if check.returncode:print(check.stdout);raise SystemExit(1)
 proof_path.write_text(json.dumps({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_hashes':candidate,'native_tests':test},indent=2)+'\n');print(json.dumps({'ok':True,'tests':test}));raise SystemExit(0)
publish='--publish' in sys.argv
if publish:
 proof=json.loads(proof_path.read_text());age=(datetime.datetime.now(datetime.timezone.utc)-datetime.datetime.fromisoformat(proof['checked_at'])).total_seconds()
 if '--verified' not in sys.argv or not 0<=age<3600 or proof['candidate_hashes']!=candidate:raise SystemExit('Fresh matching verification required')
tree=ast.parse((ROOT/'_codex/scripts/deploy_vicky_cbg.py').read_text());remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
old=next(line for line in remote.splitlines() if line.startswith('allowed='));remote=remote.replace(old,"allowed=set(p['allowed'])",1)
start=remote.index("preserved=p['preserved']");end=remote.index('def check_preserved():',start)
remote=remote[:start]+"preserved={rel:sha(target(rel).read_bytes()) for rel in p['preserve_paths']}\n"+remote[end:]
remote=remote.replace("prefix='business-vicky-cbg-'","prefix='business-jornalcorrida-'").replace("prefix='.vicky-cbg-'","prefix='.jornalcorrida-'")
old=next(line for line in remote.splitlines() if line.startswith(' for host,path,method,expected in '));remote=remote.replace(old," for host,path,method,expected in [('conteudo.roadrunners.run','/api/admin/importers/jornalcorrida.cfm','GET',405),('conteudo.roadrunners.run','/api/admin/importers/jornalcorrida.cfm','POST',401),('business.roadrunners.run','/administracao/cron-jobs/?aba=historico&historico_job_id=13','GET',302)]:",1)
preserve=['conteudo.roadrunners.run/'+n for n in ['Application.cfc','api/admin/importers/jornalcorrida.cfm','api/admin/importers/contrarelogio.cfm','admin/importer_jornalcorrida.cfm','config/content.local.cfm','inc/article_summary_service.cfc']]+['business.roadrunners.run/'+n for n in ['Application.cfc','config/business.local.cfm','cron-jobs/runner.cfm','services/geocoding/Store.cfc','includes/estrutura/sidenav.cfm']]
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps({'publish':publish,'files':items,'allowed':list(candidate),'preserve_paths':preserve}).encode(),capture_output=True,timeout=150)
try:result=json.loads(run.stdout)
except ValueError:print(run.stderr.decode()[-1200:]);raise SystemExit(1)
if result.get('ok') and result.get('mode')=='published':
 result.update({'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'tests':proof['native_tests'],'ddl':False,'credential_changes':False,'cron_schedule_changes':False,'git_mutations':False});receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['preserved_files','tests']},ensure_ascii=False));raise SystemExit(0 if result.get('ok') else 1)
