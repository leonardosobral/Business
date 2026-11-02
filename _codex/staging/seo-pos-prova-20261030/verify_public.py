from pathlib import Path
from html import unescape
import json,urllib.request,urllib.error,re,hashlib,concurrent.futures
S=Path(__file__).resolve().parent
paths=[
'/evento/2026-maratona-internacional-de-floripa-2026/',
'/evento/2026-maratona-internacional-de-porto-alegre-206/',
'/evento/2025-circuito-da-estacoes-verao/',
'/evento/2025-circuito-das-estacoes-verao/',
'/evento/2026-live-run-xp-porto-seguro-2026/',
'/evento/2026-maratona-de-curitiba-santander-2026/',
'/en/event/2026-maratona-internacional-de-floripa-2026/',
'/es/evento/2026-maratona-internacional-de-floripa-2026/',
'/maratona/maratona-internacional-de-floripa/',
'/maratona/maratona-de-curitiba/',
'/maratona/maratona-monumental-de-brasilia/',
'/maratona/maratona-internacional-de-porto-alegre/',
'/circuito/estacoes/','/circuito/live-run-xp/']
def fetch(path):
 url='https://roadrunners.run'+path
 try:
  with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'RunnerHub-SEO-Validation/1.0'}),timeout=40) as r:return r.status,r.read(),r.headers
 except urllib.error.HTTPError as e:return e.code,e.read(),e.headers
def check(path):
 status,raw,headers=fetch(path);assert status==200,(path,status);h=unescape(raw.decode());assert 'Error Occurred While' not in h
 assert 'href="https://roadrunners.run'+path+'"' in h,(path,'canonical')
 assert len(re.findall(r'<h1[ >]',h))==1,(path,'h1')
 if path.startswith(('/maratona/','/circuito/')):
  assert 'data-permanent-post-race' in h and h.count('#pos-prova')==3,path
  assert 'CollectionPage' in h,path
 elif path=='/evento/2026-maratona-de-curitiba-santander-2026/':assert 'data-post-race' not in h,path
 else:
  assert h.count('id="pos-prova"')==1,path
  block=h.split('<section id="pos-prova"')[1].split('</section>')[0]
  if '2025-circuito' in path:
   assert 'data-mdb-foco-galleries' in block and 'openresults.run/evento/' not in block,path
  if 'porto-seguro' in path:assert 'Ainda não há resultados importados' in block and 'data-mdb-foco-galleries' not in block
  if '/en/' in path:assert 'After the race: results and photos' in block and '/en/event/2027-' in block
  if '/es/' in path:assert 'Después de la carrera: resultados y fotos' in block and '/es/evento/2027-' in block
 (S/('public-'+path.strip('/').replace('/','_')+'.html')).write_bytes(raw)
 return {'path':path,'status':status,'passed':True}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as p:report=list(p.map(check,paths))
for path in ['/evento/parts/post_race_data.cfm','/evento/parts/post_race.cfm']:
 status,body,headers=fetch(path);assert status==403,(path,status);report.append({'path':path,'status':status,'passed':True})
path='/assets/css/runnerhub-race-guides.css?v=20261030b';status,body,headers=fetch(path);assert status==200 and hashlib.sha256(body).hexdigest()==hashlib.sha256((S/'candidate/assets/css/runnerhub-race-guides.css').read_bytes()).hexdigest();report.append({'path':path,'status':status,'hashMatched':True})
(S/'public-verified.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'publicPages':len(paths),'protectedIncludes':2,'assets':1,'checks':len(report),'passed':True}))
