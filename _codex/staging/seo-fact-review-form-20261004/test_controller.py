from pathlib import Path
import json,shlex,subprocess,hashlib,sys,base64
root=Path('/Users/Shared/Projects/RunnerHub/Business');p=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['candidate','published']
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
helpers=helpers.replace('this.datasource="runner_dba";','this.datasource="runner_dba";this.sessionManagement=true;').replace('detail=cfcatch.detail}', 'detail=cfcatch.detail,context=cfcatch.tagContext}')
files={str(f.relative_to(p/'candidate')):f.read_text() for f in (p/'candidate').rglob('*') if f.is_file()}
remote=helpers+'''
p=json.load(sys.stdin);work=Path(tempfile.mkdtemp(prefix='fact_review_render_',dir=ROOT/'_codex'));os.chmod(work,0o755)
try:
 for name,content in p['files'].items():
  target=work/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(content if p['mode']=='candidate' else (ROOT/name).read_text())
 guard=work/'includes/backend/require_admin.cfm';guard.parent.mkdir(parents=True);shutil.copyfile(ROOT/'includes/backend/require_admin.cfm',guard)
 component='_codex.'+work.name+'.services.EventFactReviewService'
 view=work/'eventos/includes/backend/fontes_revisoes.cfm';view.write_text(view.read_text().replace('new services.EventFactReviewService()', 'createObject("component","'+component+'")'))
 setup=p['sql']
 if p['mode']=='published':
  setup="CREATE TEMP TABLE fact_review_test (LIKE public.tb_evento_fatos_revisao INCLUDING ALL);"
  svc=work/'services/EventFactReviewService.cfc';svc.write_text(svc.read_text().replace('public.tb_evento_fatos_revisao','pg_temp.fact_review_test'))
 results=[]
 for case in ['valid','csrf','mismatch','delegated','revoke']:
  body='transaction {'+raw_query(setup,'setup')+'service=createObject("component","'+component+'");VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}]);VARIABLES.businessEffectiveIsAdmin=true;URL.id_evento="37570";URL.sessao="dados";data=service.load(37570,true,false);'
  body+='FORM.action="conferir_fatos_evento";FORM.id_evento="37570";FORM.grupo="datas";FORM.source_url="https://example.org/source";FORM.version=data.versions.datas;FORM.request_id=createObject("java","java.util.UUID").randomUUID().toString();FORM.confirmed="1";FORM.fact_csrf=csrfGenerateToken("event-fact-review");'
  if case=='csrf':body+='FORM.fact_csrf="invalid";'
  if case=='mismatch':body+='FORM.id_evento="37526";'
  if case=='delegated':body+='REQUEST.businessAccessContext={accessMode="DELEGATED"};'
  if case=='revoke':
   body+='service.save(37570,FORM,true,false,true,true);FORM.action="retirar_conferencia_evento";FORM.id_revisao=service.load(37570,true,false).reviews.id_revisao;'
  body+='cfinclude(template="/_codex/'+work.name+'/eventos/includes/backend/fontes_revisoes.cfm");report={saved=VARIABLES.factReviewSaved,revoked=VARIABLES.factReviewRevoked,message=VARIABLES.factReviewError,tab=URL.sessao};transaction action="rollback";}'
  r=bridge(ROOT,body);r['CASE']=case;results.append(r)
 print(json.dumps({'RESULTS':results}))

finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'files':files,'sql':(root/'_codex/sql/2026-10-04_evento_fatos_revisao.sql').read_text()}),capture_output=True,text=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-6000:])
r=json.loads(cp.stdout);rows=r['RESULTS']
for row in rows:
 assert row['TAB']=='fontes'
 if row['CASE']=='valid':assert row['SAVED'] and not row['MESSAGE']
 elif row['CASE']=='revoke':assert row['REVOKED'] and not row['MESSAGE']
 else:assert row['MESSAGE'] and not row['SAVED'] and not row['REVOKED']
(p/f'controller-{mode}.json').write_text(json.dumps(rows,indent=2));print(json.dumps({'controller_cases':len(rows),'passed':True}))
