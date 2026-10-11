from pathlib import Path
import json,shlex,subprocess,hashlib,sys
root=Path('/Users/Shared/Projects/RunnerHub/Business');p=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ['candidate','published']
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql=(root/'_codex/sql/2026-10-04_evento_fatos_revisao.sql').read_text()
files={str(f.relative_to(p/'candidate')):f.read_text() for f in (p/'candidate').rglob('*') if f.is_file()}
helpers=helpers.replace('detail=cfcatch.detail}', 'detail=cfcatch.detail,context=cfcatch.tagContext}')
remote=helpers+'''
p=json.load(sys.stdin);work=Path(tempfile.mkdtemp(prefix='fact_review_test_',dir=ROOT/'_codex'));os.chmod(work,0o755)
try:
 (work/'services').mkdir();service=work/'services/EventFactReviewService.cfc'
 service.write_text(p['files']['services/EventFactReviewService.cfc'] if p['mode']=='candidate' else (ROOT/'services/EventFactReviewService.cfc').read_text())
 component='_codex.'+work.name+'.services.EventFactReviewService'
 results=[]
 for testSource in p['tests']:
  test=testSource.removeprefix('<cfscript>').removesuffix('</cfscript>\\n')
  setup=p['sql'] if p['mode']=='candidate' else "CREATE TEMP TABLE fact_review_test (LIKE public.tb_evento_fatos_revisao INCLUDING ALL);"
  if p['mode']=='published':
   service.write_text(service.read_text().replace('public.tb_evento_fatos_revisao','pg_temp.fact_review_test'))
   test=test.replace('public.tb_evento_fatos_revisao_id_revisao_seq','pg_temp.fact_review_test_id_revisao_seq').replace('public.tb_evento_fatos_revisao','pg_temp.fact_review_test')
  body='transaction {'+raw_query(setup,'setup')+'testComponent="'+component+'";'+test+'transaction action="rollback";}'
  r=bridge(ROOT,body);results.extend(r['CHECKS'])
 print(json.dumps({'CHECKS':results}))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'sql':sql,'files':files,'tests':[(p/'tests.cfm').read_text()]+[x.read_text() for x in sorted(p.glob('test-*.cfm'))]}),capture_output=True,text=True,timeout=115)
if cp.returncode:raise RuntimeError(cp.stderr[-5000:])
r=json.loads(cp.stdout);(p/f'tests-{mode}.json').write_text(json.dumps(r,indent=2));assert all(x['PASSED'] for x in r['CHECKS']);print(json.dumps({'checks':len(r['CHECKS']),'passed':True}))
if mode=='candidate':(p/'tested.json').write_text(json.dumps({'sql':hashlib.sha256(sql.encode()).hexdigest(),'files':{n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()}}))
