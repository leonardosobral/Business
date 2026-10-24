import pathlib,sys,uuid,html,re,json
source=pathlib.Path(__file__).with_name('test_http.py').read_text();exec(source.split('for role,want')[0])
def hidden(body,name):return html.unescape(re.search(r'name="'+re.escape(name)+r'" value="([^"]*)"',body).group(1))
for role,want in [('anonymous',302),('common',403),('account',403),('delegated',403),('simulated',403),('admin',200)]:
 op=session()
 if role!='anonymous':request(op,'harness/login.cfm',{'role':role})
 for folder in ['cadastros','ofertas']:
  status,body,_=request(op,'administracao/comparador/'+folder+'/index.cfm');check(folder+' authorization '+role,status==want,f'{status} {body}')
 if role=='admin':admin=op
for folder in ['cadastros','ofertas']:
 for file in ['backend.cfm','home.cfm']:
  status,body,_=request(admin,'administracao/comparador/'+folder+'/'+file);check('Direct '+folder+'/'+file,status==403,f'{status} {body}')
base='administracao/comparador/cadastros/index.cfm'
for entity in ['marcas','tipos','categorias','caracteristicas','vinculos','filtros','opcoes']:
 for q in ['', '&novo=1']:
  status,body,_=request(admin,base+'?cadastro='+entity+q);check(entity+q+' renders',status==200,f'{status} {body}')
status,body,_=request(admin,base+'?cadastro=marcas&novo=1');csrf=hidden(body,'csrf_token');key='http-'+uuid.uuid4().hex
fields={'acao':'salvar','csrf_token':csrf,'chave':'','token':'','tag_marca':key,'marca':'Marca HTTP <b>segura</b>'}
status,body,_=request(admin,base+'?cadastro=marcas&novo=1',dict(fields,csrf_token='invalid'));check('Catalog invalid CSRF',status==403,f'{status} {body}')
status,body,h=request(admin,base+'?cadastro=marcas&novo=1',fields);check('Create brand form',status==302,f'{status} {body}')
status,body,_=request(admin,base+'?cadastro=marcas&chave='+key);check('Brand escaped/history',status==200 and '&lt;b&gt;' in body and 'criar' in body,f'{status} {body}');token=hidden(body,'token')
fields.update(chave=key,token=token,marca='Marca editada');status,body,_=request(admin,base+'?cadastro=marcas&chave='+key,fields);check('Update brand form',status==302,f'{status} {body}')
status,body,_=request(admin,base+'?cadastro=marcas&chave='+key,fields);check('Stale brand form',status==409 and 'Reabrir cadastro' in body,f'{status} {body}')
status,body,_=request(admin,base+'?cadastro=marcas&chave='+key);token=hidden(body,'token')
status,body,_=request(admin,base+'?cadastro=marcas&chave='+key,{'acao':'excluir','csrf_token':csrf,'chave':key,'token':token,'confirmar':'sim'});check('Delete owned synthetic brand',status==302,f'{status} {body}')
for status_filter in ['recentes','anteriores','vencidas']:
 status,body,_=request(admin,'administracao/comparador/ofertas/index.cfm?situacao='+status_filter);check('Offer list '+status_filter,status==200,f'{status} {body}')
report={'passed':sum(x['pass'] for x in results),'failed':sum(not x['pass'] for x in results),'results':results};(pathlib.Path(__file__).resolve().parents[2]/'docs/2026-10-17_comparador_http_evidence.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps(report,ensure_ascii=False));sys.exit(bool(report['failed']))
