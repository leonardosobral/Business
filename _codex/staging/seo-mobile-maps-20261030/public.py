from pathlib import Path
import hashlib,json,urllib.request
from html.parser import HTMLParser
S=Path(__file__).resolve().parent
class Page(HTMLParser):
 def __init__(self):super().__init__();self.scripts=[];self.links=[];self.headings=0
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='script':self.scripts.append(a)
  if tag=='link':self.links.append(a)
  if tag=='h1':self.headings+=1
out=[]
routes=['/evento/2026-maratona-de-aracaju-2026/','/en/event/2026-maratona-de-aracaju-2026/','/es/evento/2026-maratona-de-aracaju-2026/','/evento/2026-maratona-internacional-de-floripa-2026/','/evento/2026-live-run-xp-porto-seguro-2026/','/embed/percursos/?evento=2026-maratona-de-aracaju-2026&i18n_lang=pt-BR','/assets/js/event-maps-lazy.js','/assets/js/event-maps-lazy.min.js']
for route in routes:
 request=urllib.request.Request('https://roadrunners.run'+route,headers={'User-Agent':'RunnerHub-SEO-Verification/1.0'})
 with urllib.request.urlopen(request,timeout=40) as response:
  raw=response.read();status=response.status
 assert status==200,route
 if route.startswith('/assets/'):
  assert hashlib.sha256(raw).hexdigest()==hashlib.sha256((S/'candidate'/route.lstrip('/')).read_bytes()).hexdigest(),route
 else:
  h=raw.decode('utf-8');p=Page();p.feed(h)
  if route.startswith('/embed/'):
   assert not any('event-maps-lazy' in a.get('src','') for a in p.scripts)
   assert any('event-route-mapbox.min.js' in a.get('src','') for a in p.scripts)
  else:
   assert p.headings==1,route
   assert any(a.get('rel')=='canonical' and a.get('href')=='https://roadrunners.run'+route for a in p.links),route
   assert len([a for a in p.scripts if 'event-maps-lazy' in a.get('src','')])==1,route
   assert not any('api.mapbox.com/mapbox-gl-js/' in a.get('src','') for a in p.scripts),route
   if '2026-maratona-internacional-de-floripa' in route:assert 'data-post-race' in h
 out.append({'route':route,'status':status,'verified':True})
(S/'public-verified.json').write_text(json.dumps(out,indent=2));print(json.dumps({'publicChecks':len(out),'passed':True}))
