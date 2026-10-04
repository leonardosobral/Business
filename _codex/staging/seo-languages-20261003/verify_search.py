from pathlib import Path
from html.parser import HTMLParser
from datetime import datetime,timezone
import json,urllib.request
STAGE=Path(__file__).resolve().parent
class Head(HTMLParser):
 def __init__(self):super().__init__();self.in_head=False;self.links=[];self.canonicals=[]
 def handle_starttag(self,tag,attrs):
  if tag=='head':self.in_head=True
  if tag!='link' or not self.in_head:return
  a=dict(attrs);rel=(a.get('rel') or '').lower().split()
  if 'canonical' in rel:self.canonicals.append(a.get('href'))
  if 'alternate' in rel and 'hreflang' in a:self.links.append({'lang':a['hreflang'],'url':a.get('href')})
 def handle_endtag(self,tag):
  if tag=='head':self.in_head=False
urls={'pt-BR':'https://roadrunners.run/busca/','en':'https://roadrunners.run/en/search/','es':'https://roadrunners.run/es/busqueda/'}
expected={**urls,'x-default':urls['pt-BR']};pages=[]
for lang,url in urls.items():
 req=urllib.request.Request(url,headers={'User-Agent':'RunnerHub-SEO-hreflang/20261003'})
 with urllib.request.urlopen(req,timeout=25) as response:
  parser=Head();parser.feed(response.read(3*1024*1024).decode('utf-8',errors='replace'))
  pages.append({'url':url,'lang':lang,'status':response.status,'final_url':response.geturl(),'canonical':parser.canonicals,'hreflang':parser.links,'ok':response.status==200 and response.geturl()==url and parser.canonicals==[url] and len(parser.links)==4 and {a['lang']:a['url'] for a in parser.links}==expected})
report={'checked_at_utc':datetime.now(timezone.utc).isoformat().replace('+00:00','Z'),'pages':pages,'ok':all(p['ok'] for p in pages)}
(STAGE/'search-public-verification.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
print(json.dumps({'pages':len(pages),'ok':report['ok']}));assert report['ok'],pages
