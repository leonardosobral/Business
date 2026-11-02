from pathlib import Path
import urllib.request,json,re,hashlib,concurrent.futures
from html import unescape
S=Path(__file__).resolve().parent
paths=['/estado/pr/','/estado/pr/curitiba/','/estado/df/','/estado/df/brasilia/','/estado/sc/','/estado/rs/','/estado/pr/?pagina=2','/estado/pr/curitiba/?cupom=true','/maratona/maratona-internacional-de-floripa/','/maratona/maratona-de-curitiba/','/maratona/maratona-monumental-de-brasilia/','/maratona/maratona-internacional-de-porto-alegre/']
def fetch(path):
 req=urllib.request.Request('https://roadrunners.run'+path,headers={'User-Agent':'RunnerHub-SEO-Validation/1.0'})
 try:
  with urllib.request.urlopen(req,timeout=30) as r:return path,r.status,r.read().decode(),r.geturl()
 except urllib.error.HTTPError as e:return path,e.code,e.read().decode(),e.url
report=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
 for i,(path,status,body,final) in enumerate(pool.map(fetch,paths)):
  assert status==200,(path,status,body[:200]);h=unescape(body)
  (S/('public-'+str(i)+'.html')).write_text(body)
  assert len(re.findall(r'<h1[ >]',body))==1,path
  canonical=re.search(r'<link rel="canonical" href="([^"]+)',h)[1]
  if path.startswith('/maratona/'):
   assert 'data-permanent-race' in body,path
   assert canonical=='https://roadrunners.run'+path
   assert 'name="robots" content="noindex' not in body
   ld=[json.loads(x) for x in re.findall(r'<script type="application/ld\+json">(.*?)</script>',body,re.S)]
   collection=next(x for x in ld if x.get('@type')=='CollectionPage')
   assert len(collection['mainEntity']['itemListElement'])>0
  else:
   assert 'data-regional-summary' in body
   assert ('data-regional-races' in body)==('pagina=2' not in path),path
   if 'cupom=true' in path:assert 'name="robots" content="noindex,follow"' in body
   else:assert canonical=='https://roadrunners.run'+path,(path,canonical)
  report.append({'path':path,'status':status,'canonical':canonical})
path='/assets/css/runnerhub-race-guides.css';_,status,body,_=fetch(path);assert status==200;assert hashlib.sha256(body.encode()).hexdigest()==hashlib.sha256((S/'candidate'/path.lstrip('/')).read_bytes()).hexdigest()
report.append({'path':path,'status':status,'hashMatches':True})
for path in ['/includes/regional_races.cfm','/includes/permanent_race_overview.cfm','/includes/backend/backend_permanent_race.cfm']:
 _,status,body,_=fetch(path);assert status==403,(path,status);report.append({'path':path,'status':status})
(S/'public-verified.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'pages':len(paths),'asset':1,'directIncludesDenied':3,'checks':'passed'}))
