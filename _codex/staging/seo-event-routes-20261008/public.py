from pathlib import Path
from html.parser import HTMLParser
import json,sys,time,urllib.request,urllib.parse
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
events=json.loads((S/'inspection.json').read_text())['events']['EVENTS']
all_events=json.loads((S/'expanded-catalog.json').read_text())['events']['EVENTS'] if (S/'expanded-catalog.json').exists() else events
titles=[e for e in events if e['id'] in [23725,25734,37918,45372]]
special=[e for e in events if e['id'] in [41252,43677,48153]]
routes=[('pt-BR','/evento/'),('en','/en/event/'),('es','/es/evento/')]
pages=[{'path':prefix+urllib.parse.quote(e['tag'],safe='')+'/','event':e,'lang':lang,'kind':kind} for kind,group in [('title',titles),('special',special)] for e in group for lang,prefix in routes]
pages += [{'path':p,'kind':'state'} for p in ['/estado/pr/','/estado/pr/palmeira/','/estado/pr/ponta-grossa/','/estado/pb/','/estado/pb/lastro/','/estado/sp/campinas/','/estado/sp/taboao-da-serra/']]
class Page(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.h1='';self.meta=[];self.links=[];self.in_title=False;self.in_h1=False;self.in_json=False;self.jsontext='';self.jsonld=[]
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='title':self.in_title=True
  if t=='h1':self.in_h1=True
  if t=='a':self.links.append(d.get('href',''))
  if t=='meta' and d.get('name') in ['description','robots']:self.meta.append(d)
  if t=='link' and (d.get('rel')=='canonical' or d.get('hreflang')):self.meta.append(d)
  if t=='script' and d.get('type')=='application/ld+json':self.in_json=True;self.jsontext=''
 def handle_endtag(self,t):
  if t=='title':self.in_title=False
  if t=='h1':self.in_h1=False
  if t=='script' and self.in_json:self.jsonld.append(json.loads(self.jsontext));self.in_json=False
 def handle_data(self,d):
  if self.in_title:self.title+=d
  if self.in_h1:self.h1+=d
  if self.in_json:self.jsontext+=d
rows=[];old=json.loads((S/'public-before.json').read_text()) if mode=='after' else None
for i,p in enumerate(pages):
 req=urllib.request.Request('https://roadrunners.run'+p['path'],headers={'User-Agent':'RunnerHub-SEO-Verification/1.0'})
 with urllib.request.urlopen(req,timeout=40) as response:
  html=response.read().decode();assert response.status==200;assert 'Error Occurred While Processing Request' not in html
 parser=Page();parser.feed(html)
 row={'path':p['path'],'kind':p['kind'],'lang':p.get('lang'),'status':200,'title':parser.title,'h1':parser.h1,'meta':parser.meta,'jsonld':parser.jsonld,'special_links':[l for l in parser.links if any(k in l for k in ['2026-1-corrida-de-aniversario','2026-rock-n-run','2026-%22','/2026-"']) or l.endswith('/2026-')]}
 if mode=='after':
  prev=old[i];assert row['path']==prev['path'];assert row['h1']==prev['h1'] and row['meta']==prev['meta'] and row['jsonld']==prev['jsonld'],p['path']+' metadata changed'
  if p['kind']=='title':assert p['event']['date'][0:4] in row['title'],p['path']+' year missing'
  else:assert row['title']==prev['title']
  if p['kind']=='state':
   for link in row['special_links']:
    assert not any(c in link for c in ['#','"','\n','\r',' ']),p['path']+' unsafe link'
    tag=urllib.parse.unquote(urllib.parse.urlparse(link).path).split('/evento/',1)[-1].rstrip('/')
    assert any(tag==e['tag'] for e in all_events),p['path']+' changed event identity'
 rows.append(row);time.sleep(1)
if mode=='after':
 for lang,_ in routes:
  selected=[r['title'].casefold() for r in rows if r['kind']=='title' and r['lang']==lang];assert len(set(selected))==4,lang+' duplicated titles'
(S/('public-'+mode+'.json')).write_text(json.dumps(rows,ensure_ascii=False,indent=2))
if mode=='after':(S/'public-passed.json').write_text(json.dumps({'passed':True,'public_pages':len(rows),'title_pages':12,'encoded_event_pages':9,'source_pages':7,'metadata_preserved':True},indent=2))
print(json.dumps({'mode':mode,'public_pages':len(rows),'passed':True}))
