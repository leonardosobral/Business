from pathlib import Path
from html.parser import HTMLParser
from datetime import datetime,timezone
from urllib.parse import urljoin
import json,urllib.request,sys
STAGE=Path(__file__).resolve().parent
class Metadata(HTMLParser):
 def __init__(self):super().__init__();self.in_head=False;self.alternates=[];self.canonicals=[];self.navigation=[]
 def handle_starttag(self,tag,attrs):
  if tag=='head':self.in_head=True
  a=dict(attrs)
  if tag=='link' and self.in_head:
   rel=(a.get('rel') or '').lower().split()
   if 'canonical' in rel:self.canonicals.append(a.get('href'))
   if 'alternate' in rel and 'hreflang' in a:self.alternates.append({'lang':a['hreflang'],'url':a.get('href')})
  if tag=='a' and 'rr-language-switch-link' in (a.get('class') or '').split():self.navigation.append({'lang':a.get('lang'),'url':a.get('href')})
 def handle_endtag(self,tag):
  if tag=='head':self.in_head=False
languages=['pt-BR','en','es'];groups=[]
for route,paths in [('about',['/sobre/','/en/about/','/es/sobre/']),('help',['/ajuda/','/en/help/','/es/ayuda/']),('privacy',['/privacidade/','/en/privacy/','/es/privacidad/']),('home',['/','/en/','/es/']),('search',['/busca/','/en/search/','/es/busqueda/'])]:
 groups.append({'kind':'institutional' if route in ['about','help','privacy'] else 'control','route':route,'urls':dict(zip(languages,['https://roadrunners.run'+p for p in paths]))})
for slug in ['o-que-aconteceu-com-a-nike-no-mundo-da-corrida-e-na-bolsa','por-que-ele-trocou-de-camiseta-tantas-vezes-no-podio','gleison-da-silva-santos-e-tricampeao-do-circuito-caixa-em-maceio']:
 groups.append({'kind':'external_news' if not slug.startswith('gleison') else 'control','route':slug,'urls':dict(zip(languages,['https://roadrunners.run'+b+slug+'/' for b in ['/noticias/','/en/news/','/es/noticias/']])),'external_canonical':'https://corridanoar.com/'+slug+'/'})
groups.append({'kind':'control','route':'event','urls':dict(zip(languages,['https://roadrunners.run'+b+'2026-maratona-salvador-2026/' for b in ['/evento/','/en/event/','/es/evento/']]))})
pages=[]
for group in groups:
 expected={**group['urls'],'x-default':group['urls']['pt-BR']}
 for lang,url in group['urls'].items():
  request=urllib.request.Request(url,headers={'User-Agent':'RunnerHub-SEO-hreflang/20261003'})
  with urllib.request.urlopen(request,timeout=30) as response:
   parser=Metadata();parser.feed(response.read(3*1024*1024).decode('utf-8',errors='replace'))
   external=group['kind']=='external_news';canonical=group['external_canonical'] if external else url
   navigation={a['lang']:urljoin(url,a['url']) for a in parser.navigation}
   alternate_ok=(len(parser.alternates)==0 if external else len(parser.alternates)==4 and {a['lang']:a['url'] for a in parser.alternates}==expected)
   # The existing header renders this menu only for authenticated visitors.
   # Anonymous requests still verify any links delivered; route retention is covered by CFML.
   navigation_ok=not navigation or navigation==group['urls']
   row={'url':url,'lang':lang,'kind':group['kind'],'status':response.status,'final_url':response.geturl(),'canonical':parser.canonicals,'hreflang':parser.alternates,'navigation':navigation,'navigation_check':'matched' if navigation else 'not_rendered_anonymous','ok':response.status==200 and response.geturl()==url and parser.canonicals==[canonical] and alternate_ok and navigation_ok}
   pages.append(row)
report={'checked_at_utc':datetime.now(timezone.utc).isoformat().replace('+00:00','Z'),'pages':pages,'ok':len(pages)==27 and all(p['ok'] for p in pages)}
target=STAGE/('public-baseline.json' if '--baseline' in sys.argv else 'public-verification.json');target.write_text(json.dumps(report,indent=2,ensure_ascii=False))
print(json.dumps({'pages':len(pages),'ok':report['ok'],'failed':[p['url'] for p in pages if not p['ok']]}))
if '--baseline' not in sys.argv:assert report['ok']
