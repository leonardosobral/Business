from pathlib import Path
from html.parser import HTMLParser
import concurrent.futures,urllib.request,json,re,sys
S=Path(__file__).resolve().parent
phase=sys.argv[1] if len(sys.argv)>1 else 'before'
assert phase in ['before','after']
pages={
 'rr-city':'https://roadrunners.run/estado/se/aracaju/',
 'rr-state':'https://roadrunners.run/estado/se/',
 'rr-race':'https://roadrunners.run/maratona/maratona-de-aracaju/',
 'rr-event':'https://roadrunners.run/evento/2026-maratona-de-aracaju-2026/',
 'or-event':'https://openresults.run/evento/2026-maratona-de-aracaju-2026/',
 'or-state':'https://openresults.run/estado/se/',
 'or-city':'https://openresults.run/estado/se/?cidade=aracaju'}
class Parser(HTMLParser):
 def __init__(self):super().__init__();self.meta={};self.links=[];self.text=[];self.skip=0
 def handle_starttag(self,t,a):
  a=dict(a)
  if t in ['script','style']:self.skip+=1
  if t=='meta':self.meta[a.get('name',a.get('property',''))]=a.get('content','')
  if t=='link' and a.get('rel')=='canonical':self.meta['canonical']=a.get('href')
  if t=='a' and a.get('href'):self.links.append(a['href'])
 def handle_endtag(self,t):
  if t in ['script','style']:self.skip=max(0,self.skip-1)
 def handle_data(self,d):
  if not self.skip and d.strip():self.text.append(d.strip())
def read(item):
 name,url=item
 with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'RunnerHub-SEO-Validation/1.0'}),timeout=55) as r:status=r.status;raw=r.read();head=dict(r.headers)
 (S/(phase+'-'+name+'.html')).write_bytes(raw);p=Parser();p.feed(raw.decode());text=' '.join(p.text)
 assert status==200 and 'Error Occurred While' not in raw.decode(),name
 if phase=='after':assert 'data-aracaju-2026' in raw.decode(),name
 return name,{'url':url,'status':status,'meta':p.meta,'links':[u for u in p.links if any(k in u.lower() for k in ['aracaju','runking','foco','resultado','74615'])],'excerpt':text[max(0,text.find('Maratona de Aracaju')):][:5000],'cache':{k:v for k,v in head.items() if k.lower() in ['cf-cache-status','x-robots-tag','content-type']}}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as ex:data=dict(ex.map(read,pages.items()))
(S/('public-'+phase+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:{'status':v['status'],'canonical':v['meta'].get('canonical'),'robots':v['meta'].get('robots'),'description':v['meta'].get('description'),'resultLinks':[u for u in v['links'] if 'runking' in u or 'openresults.run/evento/' in u]} for k,v in data.items()},ensure_ascii=False))
