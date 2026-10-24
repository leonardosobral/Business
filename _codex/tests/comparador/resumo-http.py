"""Read-only assertions against the owned loopback CFML preview; never production login."""
import concurrent.futures,html,json,pathlib,re,urllib.parse,urllib.request,urllib.error,datetime
ROOT=pathlib.Path('/Users/Shared/Projects/RunnerHub/Comparador')
BASE='http://127.0.0.1:18510/codex-comparador-resumo-20261018/'
PAGE='administracao/comparador/resumo/index.cfm'
results=[]
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
opener=urllib.request.build_opener(NoRedirect())
def get(path):
 try:
  with opener.open(BASE+path,timeout=45)as r:return r.status,r.read().decode(),dict(r.headers)
 except urllib.error.HTTPError as e:return e.code,e.read().decode(),dict(e.headers)
def check(label,ok):
 results.append({'name':label,'pass':bool(ok)})
 if not ok:raise AssertionError(label)
def normalized(value):
 if isinstance(value,dict):return {k.lower():normalized(v) for k,v in value.items()}
 if isinstance(value,list):return [normalized(v) for v in value]
 return value
def data(**args):
 code,body,h=get('check.cfm?'+urllib.parse.urlencode(args));check('JSON query '+str(args),code==200);return normalized(json.loads(body))
for role,expected in [('anonymous',302),('common',403),('account',403),('delegated',403),('simulated',403),('admin',200)]:
 code,body,h=get(PAGE+'?role='+role);check('Authorization '+role,code==expected)
for name in ['backend.cfm','home.cfm']:
 code,_,_=get('administracao/comparador/resumo/'+name);check('Internal include protected '+name,code==403)
for tab in ['resumo','cobertura','prioridades']:
 code,body,headers=get(PAGE+'?role=admin&aba='+tab);check('CFML renders '+tab,code==200 and 'Resumo do Comparador'in body and 'coldfusion.runtime'not in body.lower());check('No-store '+tab,'no-store'in headers.get('Cache-Control',''));check('Read-only forms '+tab,'method="post"'not in body.lower())
 if tab=='resumo':check('Filters collapsed and keyboard-native', '<details class="filters mb-3"><summary' in body and '<details class="filters mb-3" open'not in body)
initial=data();q=json.load(open(ROOT/'codex/dados/peso-placa-pendencias.json'));stats=initial['stats']
for a,b in [('total','commercial_active'),('pendentes','pending_in_scope'),('completos','with_both'),('sem_peso','missing_weight'),('sem_placa','missing_plate')]:check('Real inventory matches '+a,stats[a]==q['counts'][b])
check('Variant versus reference weights separated',stats['peso_variante']==q['weight_coverage']['with_variant_weight']and stats['peso_referencia']==q['weight_coverage']['with_unattributed_reference'])
check('Photo gap is tracked',stats['sem_foto']==1)
with concurrent.futures.ThreadPoolExecutor(max_workers=4)as pool:pages=list(pool.map(lambda page:data(pagina=page),range(1,int(initial['pages'])+1)))
ids=[p['id_produto']for d in pages for p in d['queue']];check('Pagination has no duplicate products',len(ids)==len(set(ids))==208);check('Queue identities equal canonical backlog',set(ids)=={p['id_produto']for p in q['products']})
seen_non_brazil=False
for d in pages:
 for p in d['queue']:
  if not p['brasil']:seen_non_brazil=True
  check('Brazil priorities globally precede unmarked brands',not (p['brasil']and seen_non_brazil))
for scope in ['prototipos','arquivados']:
 d=data(escopo=scope);check('Technical metrics exclude '+scope,d['stats']['comerciais']==0 and d['stats']['pendentes']==0 and d['total']==0);check('N/A denominators '+scope,all(f['total']==0 for f in d['coverage']if f['base']!='todos'))
d=data(escopo='todos',tipo='todos');check('Whole catalogue is not duplicated by WA/variants',d['stats']['total']==d['overall']['total']==1509)
d=data(busca='zz-no-results-655899');check('Empty scope stays zero',d['stats']['total']==0 and d['total']==0 and all(f['total']==0 for f in d['coverage']))
rows=json.load(open(ROOT/'outputs/business-resumo-20261018/sql-production-readonly.json'))['rows'];brazil=[r for r in rows if r['tipo']=='tenis'and r['estado']!='arquivado'and not r['prototipo']and r['brasil']]
d=data(mercado='brasil');check('Brazil filter matches curation flags',d['stats']['total']==len(brazil))
d=data(marca='olympikus');check('Brand filter produces only matching queue rows',d['stats']['total']==31 and all(r['tag_marca']=='olympikus'for r in d['queue']))
d=data(falta='peso');check('Missing weight queue reconciles with card',d['total']==stats['sem_peso'])
d=data(falta='foto');check('Photo drilldown identifies the missing product',d['total']==1 and len(d['queue'])==1 and not d['queue'][0]['f_foto'])
for query in ['escopo=invalid','tipo=absent','marca=absent','pagina=0','pagina=-1','aba=invalid','falta=invalid','mercado=invalid']:
 code,body,_=get(PAGE+'?role=admin&'+query);check('Invalid filter returns safe422 '+query,code==422 and 'coldfusion.runtime'not in body.lower())
code,body,_=get(PAGE+'?role=admin&busca='+urllib.parse.quote('<script>alert(1)</script>'));check('Search escaped',code==200 and '<script>alert(1)</script>'not in body and '&lt;' in re.search(r'id="resumo-busca"[^>]*value="([^"]*)"',body).group(1))
report={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'passed':sum(r['pass']for r in results),'failed':sum(not r['pass']for r in results),'method':'Owned loopback preview, real read-only production catalogue; synthetic roles exist only inside private fixture','stats':stats,'overall':initial['overall'],'photo_gap_id':data(falta='foto')['queue'][0]['id_produto'],'results':results}
(ROOT/'outputs/business-resumo-20261018/http-tests.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items()if k!='results'},ensure_ascii=False))
