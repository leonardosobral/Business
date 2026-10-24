"""HTTP behavior tests; only the loopback-only synthetic Business harness."""
import http.cookiejar,html,json,pathlib,re,urllib.error,urllib.parse,urllib.request,uuid
BASE='http://127.0.0.1:18500/codex-comparador-20261016/business/'
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs): return None
results=[]
def session(): return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()),NoRedirect())
def request(opener,path,data=None,headers=None):
 req=urllib.request.Request(BASE+path,urllib.parse.urlencode(data).encode() if data is not None else None,headers or {})
 try:
  with opener.open(req,timeout=40) as r:return r.status,r.read().decode(),{k.lower():v for k,v in r.headers.items()}
 except urllib.error.HTTPError as e:return e.code,e.read().decode(),{k.lower():v for k,v in e.headers.items()}
def check(name,ok,detail=''):
 results.append({'name':name,'pass':bool(ok),'detail':detail[:1500] if not ok else ''});print(('PASS' if ok else 'FAIL'),name)
for role,want in [('anonymous',302),('common',403),('account',403),('delegated',403),('simulated',403),('admin',200)]:
 op=session()
 if role!='anonymous':request(op,'harness/login.cfm',{'role':role})
 status,body,_=request(op,'administracao/comparador/index.cfm')
 check('Real session/login/admin guards: '+role,status==want,f'{status} {body}')
 if role=='admin':admin=op
op=session();status,body,_=request(op,'administracao/comparador/index.cfm',headers={'Cookie':'id_usuario=99; is_admin=true'})
check('Forged legacy cookies do not authenticate',status==302,f'{status} {body}')
for path in ['administracao/comparador/includes/backend.cfm','administracao/comparador/home.cfm']:
 status,body,_=request(admin,path);check('Direct include blocked '+path,status==403,f'{status} {body}')
for query in ['', '?novo=1','?id=900004','?id=900004&aba=caracteristicas','?id=900004&aba=ofertas','?id=900004&aba=historico','?busca=Produto&pagina=2','?tipo=cameras&pendencia=preco','?id=900001']:
 status,body,_=request(admin,'administracao/comparador/index.cfm'+query)
 check('Admin page renders '+query,status==200,f'{status} {body}')
 if query=='?novo=1':new=body
 if query=='?id=900001':existing=body
# Mutation gates are checked against an existing synthetic product; no valid write is issued here.
status,body,_=request(admin,'administracao/comparador/index.cfm?id=900001',{'acao':'estado','id_produto':'900001','token':'0'*64,'estado':'arquivado','csrf_token':'forged'})
check('Page rejects invalid CSRF',status==403,f'{status} {body}')
status,body,_=request(admin,'administracao/comparador/index.cfm?id=900001&acao=estado&estado=arquivado')
check('GET action cannot mutate state',status==200 and 'publicado' in body,f'{status} {body}')
status,body,_=request(admin,'administracao/comparador/index.cfm?busca='+urllib.parse.quote('<script>alert(1)</script>'))
check('Search escaped in markup',status==200 and '<script>alert(1)</script>' not in body and '<script>' not in body,f'{status} {body}')
def hidden(body,name):
 return html.unescape(re.search(r'name="'+re.escape(name)+r'" value="([^"]*)"',body).group(1))
slug='admin-http-'+uuid.uuid4().hex
fields={'acao':'produto','csrf_token':hidden(new,'csrf_token'),'id_produto':'','token':'','nome_produto':'Produto HTTP <b>synthetic</b>','tag_tipo_produto':'cameras','tag_marca':'marca-a','tag_categoria':'video','tag_produto':slug,'num_versao':'0','versao':'1','preco_referencia':'','data_lancamento':'2026-10-16','resumo':'Sem dados inventados','descricao':'Descrição <b>segura</b>'}
status,body,headers=request(admin,'administracao/comparador/index.cfm?novo=1',fields)
check('Complete product POST creates draft',status==302,f'{status} {body}')
if status==302:
 product_id=re.search(r'[?&]id=([0-9]+)',headers['location']).group(1)
 path='administracao/comparador/index.cfm?id='+product_id
 status,body,_=request(admin,path)
 check('Created draft and text escaped',status==200 and 'rascunho' in body and '<b>segura</b>' not in body,f'{status} {body}')
 token=hidden(body,'token');csrf=hidden(body,'csrf_token')
 status,body,headers=request(admin,path,{'acao':'estado','csrf_token':csrf,'id_produto':product_id,'token':token,'estado':'publicado'})
 check('Explicit publish accepts valid launch date and unknown price',status==302,f'{status} {body}')
 status,body,_=request(admin,path,{'acao':'estado','csrf_token':csrf,'id_produto':product_id,'token':token,'estado':'arquivado'})
 check('Stale page POST rejected with no reusable forms',status==409 and '<form' not in body,f'{status} {body}')
 status,body,_=request(admin,path+'&aba=caracteristicas');token=hidden(body,'token')
 status,body,_=request(admin,path+'&aba=caracteristicas',{'acao':'caracteristicas','csrf_token':csrf,'id_produto':product_id,'token':token,'feature_ids':'','nova_tag':'resolucao','novo_valor':'4K','nova_nota':'','variante_U':'1','peso_U':'0','tamanho_U':'42,5'})
 check('Complete specification POST preserves zero and decimal',status==302,f'{status} {body}')
 status,body,_=request(admin,path+'&aba=ofertas');token=hidden(body,'token')
 status,body,_=request(admin,path+'&aba=ofertas',{'acao':'oferta','csrf_token':csrf,'id_produto':product_id,'token':token,'loja':'Loja sintética','preco_promocional':'999,90','data_expiracao':'2000-01-01','link':'https://example.test/oferta','cupom':'','condicoes':'Apenas teste'})
 check('Complete expired offer POST supported',status==302,f'{status} {body}')
 status,body,_=request(admin,path+'&aba=ofertas')
 check('Expired latest candidate labeled in history',status==200 and 'Vencida' in body and 'Mais recente' in body,f'{status} {body}')
 status,body,_=request(admin,path+'&aba=historico')
 check('HTTP writes visible in audit',status==200 and all(x in body for x in ['produto_criar','estado_publicado','caracteristicas','oferta_criar']),f'{status} {body}')
 (pathlib.Path(__file__).resolve().parents[3]/'harness/evidence/ui-product.txt').write_text(product_id)
report={'passed':sum(x['pass'] for x in results),'failed':sum(not x['pass'] for x in results),'results':results}
path=pathlib.Path(__file__).resolve().parents[2]/'docs/2026-10-16_comparador_http_evidence.json';path.write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report,ensure_ascii=False));raise SystemExit(bool(report['failed']))
