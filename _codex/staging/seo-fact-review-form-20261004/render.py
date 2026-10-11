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
 view=work/'eventos/form_edicao_fontes.cfm';view.write_text(view.read_text().replace('new services.EventFactReviewService()', 'createObject("component","'+component+'")'))
 setup=p['sql']
 if p['mode']=='published':
  setup="CREATE TEMP TABLE fact_review_test (LIKE public.tb_evento_fatos_revisao INCLUDING ALL);"
  svc=work/'services/EventFactReviewService.cfc';svc.write_text(svc.read_text().replace('public.tb_evento_fatos_revisao','pg_temp.fact_review_test'))
 body='transaction {'+raw_query(setup,'setup')+'service=createObject("component","'+component+'");qEvento=queryNew("id_evento","integer",[{id_evento=37570}]);VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}]);VARIABLES.businessEffectiveIsAdmin=true;VARIABLES.factReviewError="";VARIABLES.factReviewSaved=false;VARIABLES.factReviewRevoked=false;URL.sessao="fontes";'
 body+='data=service.load(37570,true,false);for(group in ["datas","local","situacao"]){service.save(37570,{grupo=group,source_url="https://example.org/?a=1&b=2",version=data.versions[group],request_id=createObject("java","java.util.UUID").randomUUID().toString(),confirmed="1"},true,false,true,true);}q=service.load(37570,true,false).reviews;service.revoke(37570,q.id_revisao[1],true,false,true,true);'
 body+=raw_query("UPDATE public.tb_evento_corridas SET cidade=cidade||' <script>alert(1)</script>' WHERE id_evento=37570",'change')
 body+='savecontent variable="html" {cfinclude(template="/_codex/'+work.name+'/eventos/form_edicao_fontes.cfm");}report={html=toBase64(html,"utf-8")};transaction action="rollback";}'
 r=bridge(ROOT,body);print(json.dumps(r))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'files':files,'sql':(root/'_codex/sql/2026-10-04_evento_fatos_revisao.sql').read_text()}),capture_output=True,text=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-6000:])
r=json.loads(cp.stdout);html=base64.b64decode(r['HTML']).decode();assert 'Cadastro igual à conferência' in html and 'Cadastro alterado' in html and 'Retirada' in html
assert '<script>alert(1)</script>' not in html and '&lt;script&gt;' in html
assert html.count('name="version"')==3 and html.count('name="confirmed"')==3
assert 'não altera o evento' in html
(p/f'render-{mode}.html').write_text(html)
(p/f'render-{mode}.json').write_text(json.dumps({'states':['matches','changed','revoked'],'escaped':True,'forms':3,'hashes':{n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()}}))
print(json.dumps({'rendered':True,'states':3,'escaped':True,'forms':3}))
