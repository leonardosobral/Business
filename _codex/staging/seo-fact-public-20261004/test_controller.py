from pathlib import Path
import json,shlex,subprocess,sys
p=Path(__file__).resolve().parent;root=p.parents[2];mode=sys.argv[1]
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')").replace('this.datasource="runner_dba";','this.datasource="runner_dba";this.sessionManagement=true;').replace('detail=cfcatch.detail}', 'detail=cfcatch.detail,context=cfcatch.tagContext}')
remote=helpers+'''
p=json.load(sys.stdin);work=Path(tempfile.mkdtemp(prefix='fact_public_controller_',dir=ROOT/'_codex'));os.chmod(work,0o755)
try:
 for n,content in p['files'].items():
  target=work/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(content if p['mode']=='candidate' else (ROOT/n).read_text())
 guard=work/'includes/backend/require_admin.cfm';guard.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/'includes/backend/require_admin.cfm',guard)
 component='_codex.'+work.name+'.services.EventFactReviewService'
 for n in ['eventos/includes/backend/fontes_revisoes.cfm','eventos/form_edicao_fontes.cfm']:
  f=work/n;f.write_text(f.read_text().replace('new services.EventFactReviewService()', 'createObject("component","'+component+'")'))
 f=work/'services/EventFactReviewService.cfc';f.write_text(f.read_text().replace('public.tb_evento_corridas','pg_temp.event_fact_test').replace('public.tb_evento_fatos_revisao','pg_temp.review_fact_test'))
 setup="CREATE TEMP TABLE event_fact_test AS SELECT * FROM public.tb_evento_corridas WHERE id_evento=37570;ALTER TABLE event_fact_test ADD COLUMN IF NOT EXISTS conferencia_datas_publica jsonb;UPDATE event_fact_test SET conferencia_datas_publica=NULL;CREATE TEMP TABLE review_fact_test (LIKE public.tb_evento_fatos_revisao INCLUDING ALL);"
 results=[];views={}
 for case in ['publish','unpublish','missing-confirmation','csrf','event-mismatch','delegated','save','revoke']:
  body='transaction {'+raw_query(setup,'setup')+'s=createObject("component","'+component+'");VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}]);VARIABLES.businessEffectiveIsAdmin=true;URL.id_evento="37570";URL.sessao="fontes";qEvento=queryNew("id_evento","integer",[{id_evento=37570}]);d=s.load(37570,true,false);structAppend(FORM,{action="publicar_datas_conferidas",id_evento="37570",grupo="datas",source_url="https://official.example.org/source",version=d.versions.datas,request_id=createObject("java","java.util.UUID").randomUUID().toString(),confirmed="1",publish_confirmed="1",fact_csrf=csrfGenerateToken("event-fact-review")},true);s.save(37570,FORM,true,false,true,true);FORM.id_revisao=s.load(37570,true,false).reviews.id_revisao;'
  if case=='unpublish':body+='s.publishDates(37570,FORM.id_revisao,true,false,true,true);FORM.action="ocultar_datas_conferidas";'
  if case=='missing-confirmation':body+='structDelete(FORM,"publish_confirmed");'
  if case=='csrf':body+='FORM.fact_csrf="invalid";'
  if case=='event-mismatch':body+='FORM.id_evento="37526";'
  if case=='delegated':body+='REQUEST.businessAccessContext={accessMode="DELEGATED"};'
  if case=='save':body+='FORM.action="conferir_fatos_evento";'
  if case=='revoke':body+='s.publishDates(37570,FORM.id_revisao,true,false,true,true);FORM.action="retirar_conferencia_evento";'
  body+='cfinclude(template="/_codex/'+work.name+'/eventos/includes/backend/fontes_revisoes.cfm");report={saved=VARIABLES.factReviewSaved,revoked=VARIABLES.factReviewRevoked,message=VARIABLES.factReviewError,publication=VARIABLES.factReviewPublication,projection=s.load(37570,true,false).publicDateReview};'
  if case in ['publish','unpublish','save','revoke']:
   body+='savecontent variable="html" {cfinclude(template="/_codex/'+work.name+'/eventos/form_edicao_fontes.cfm");}report.html=html;'
  body+='transaction action="rollback";}'
  r=bridge(ROOT,body);r['CASE']=case
  if 'HTML' in r:views[case]=r.pop('HTML')
  results.append(r)
 print(json.dumps({'results':results,'views':views}))
finally:shutil.rmtree(work)
'''
files={str(f.relative_to(p/'candidate/business')):f.read_text() for f in (p/'candidate/business').rglob('*') if f.is_file()}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(dict(mode=mode,files=files)),capture_output=True,text=True,timeout=120)
if cp.returncode:raise RuntimeError(cp.stderr[-4000:])
r=json.loads(cp.stdout)
for row in r['results']:
 case=row['CASE']
 if case in ['csrf','event-mismatch','delegated','missing-confirmation']:assert row['MESSAGE'] and not row['PUBLICATION'] and not row['PROJECTION'],row
 else:
  assert not row['MESSAGE'],row
  if case=='publish':assert json.loads(row['PROJECTION'])['state']=='published' and row['PUBLICATION']
  if case in ['unpublish','revoke']:assert json.loads(row['PROJECTION'])['state']=='withdrawn'
  if case=='save':assert row['SAVED']
assert 'Retirar publicação do site' in r['views']['publish']
assert 'Publicar fonte das datas' not in r['views']['publish']
assert 'Publicar fonte das datas' in r['views']['unpublish']
assert 'Publicar fonte das datas' not in r['views']['revoke']
(p/('controller-'+mode+'.json')).write_text(json.dumps(r['results'],indent=2,ensure_ascii=False))
for name,html in r['views'].items():(p/('view-'+name+'.html')).write_text(html)
print(json.dumps({'controller_cases':len(r['results']),'rendered_states':len(r['views']),'passed':True}))
