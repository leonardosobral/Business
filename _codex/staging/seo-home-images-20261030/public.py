from pathlib import Path
import json,urllib.request
from html.parser import HTMLParser
S=Path(__file__).resolve().parent
class Page(HTMLParser):
 def __init__(self):super().__init__();self.images=[];self.links=[];self.controls=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='img' and 'home-spotlight-media' in a.get('class','').split():self.images.append(a)
  if tag=='link':self.links.append(a)
  if tag=='button' and any(k.startswith('data-spotlight-') for k in a):self.controls.append(a)
result=[]
for route in ['/','/en/','/es/']:
 with urllib.request.urlopen(urllib.request.Request('https://roadrunners.run'+route,headers={'User-Agent':'RunnerHub-SEO-Verification/1.0'}),timeout=40) as r:
  h=r.read().decode('utf-8');status=r.status
 p=Page();p.feed(h);assert status==200 and len(p.images)>1,(route,status,len(p.images))
 assert p.images[0].get('fetchpriority')=='high' and p.images[0].get('loading')=='eager',route
 assert all(a.get('fetchpriority')=='low' and a.get('loading')=='lazy' and a.get('decoding')=='async' for a in p.images[1:]),route
 assert len(p.controls)==2,route
 canonical=[a.get('href') for a in p.links if a.get('rel')=='canonical'];assert canonical==['https://roadrunners.run'+route],(route,canonical)
 assert all(a.get('alt') and a.get('src') and 'is-image-fallback' in a.get('onerror','') for a in p.images)
 result.append({'route':route,'status':status,'images':len(p.images),'highPriority':1,'lazy':len(p.images)-1,'canonical':canonical[0]})
(S/'public-verified.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
