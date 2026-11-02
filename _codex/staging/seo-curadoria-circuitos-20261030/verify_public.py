from pathlib import Path
import urllib.request,urllib.error,json,re,concurrent.futures
from html import unescape
S=Path(__file__).resolve().parent
paths=['/maratona/maratona-de-curitiba/','/maratona/maratona-monumental-de-brasilia/','/maratona/maratona-internacional-de-floripa/','/circuito/live-run-xp/','/circuito/estacoes/','/evento/2026-maratona-de-curitiba-santander-2026/','/evento/2026-maratona-monumental-de-brasilia-2026/','/evento/2026-santander-night-run-etapa-1-curitiba-2026/','/estado/pr/curitiba/','/estado/pr/pinhais/','/estado/df/brasilia/','/en/event/2026-maratona-monumental-de-brasilia-2026/','/es/evento/2026-maratona-monumental-de-brasilia-2026/']
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
opener=urllib.request.build_opener(NoRedirect)
def fetch(path):
 req=urllib.request.Request('https://roadrunners.run'+path,headers={'User-Agent':'RunnerHub-SEO-Validation/1.0'})
 try:
  with opener.open(req,timeout=40) as r:return path,r.status,r.read().decode(),dict(r.headers)
 except urllib.error.HTTPError as e:return path,e.code,e.read().decode(),dict(e.headers)
report=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
 for i,(path,status,body,headers) in enumerate(pool.map(fetch,paths)):
  (S/('public-'+str(i)+'.html')).write_text(body);assert status==200,(path,status)
  assert 'Error Occurred While' not in body
  h=unescape(body)
  if path.startswith(('/maratona/','/circuito/')):
   assert 'data-permanent-race' in h,path
   assert ('data-race-editorial' in h)==path.startswith('/maratona/'),path
   ld=[json.loads(x) for x in re.findall(r'<script type="application/ld\+json">(.*?)</script>',body,re.S)];c=next(x for x in ld if x.get('@type')=='CollectionPage');assert c['url']=='https://roadrunners.run'+path
   if '/circuito/' in path:assert 'Próxima etapa cadastrada' in h
   if 'maratona-de-curitiba/' in path:assert '2026-maratona-de-curitiba-santander-2026' in h
  if 'santander-night-run' in path:assert 'Pinhais' in h and 'Parque das Águas' in h
  if path.startswith('/evento/') and ('maratona-de-curitiba-' in path or 'monumental' in path):
   assert '42km' in h or '42 km' in h,path
   assert '22 de novembro de 2025' not in h,path
  report.append({'path':path,'status':status})
for prefix in ['/evento/','/en/event/','/es/evento/']:
 path=prefix+'2026-night-run-etapa-1-curitiba-2026/';_,status,body,headers=fetch(path);target=headers.get('Location',headers.get('location',''));assert status==301 and target.endswith(prefix+'2026-santander-night-run-etapa-1-curitiba-2026/'),(path,status,target);report.append({'path':path,'status':status,'location':target})
_,status,body,_=fetch('/includes/permanent_race_editorial.cfm');assert status==403;report.append({'path':'/includes/permanent_race_editorial.cfm','status':status})
(S/'public-verified.json').write_text(json.dumps(report,indent=2));print(json.dumps({'pages':len(paths),'localizedRedirects':3,'protectedInclude':1,'passed':True}))
