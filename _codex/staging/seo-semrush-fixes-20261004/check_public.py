from pathlib import Path
from html.parser import HTMLParser
from concurrent.futures import ThreadPoolExecutor
import json,subprocess,sys,xml.etree.ElementTree as ET
stage=Path(__file__).resolve().parent
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.canonical=[];self.alternates={};self.description=[];self.title='';self.in_title=False;self.robots=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if tag=='link' and a.get('rel')=='alternate' and a.get('hreflang'):self.alternates[a['hreflang']]=a.get('href')
  if tag=='meta' and a.get('name')=='description':self.description.append(a.get('content'))
  if tag=='meta' and a.get('name')=='robots':self.robots.append(a.get('content'))
  if tag=='title':self.in_title=True
 def handle_endtag(self,tag):
  if tag=='title':self.in_title=False
 def handle_data(self,d):
  if self.in_title:self.title+=d

def fetch(u):
 p=subprocess.run(['curl','-sS','--max-time','45','-w','\n%{http_code}',u],capture_output=True,text=True,timeout=50)
 if p.returncode:return {'url':u,'error':p.stderr}
 body,code=p.stdout.rsplit('\n',1);m=Meta();m.feed(body)
 result={'url':u,'status':int(code),'canonical':m.canonical,'alternates':m.alternates,'title':m.title,'description':m.description,'robots':m.robots}
 if '/sitemaps/' in u:
  try:result['locs']=[x.text for x in ET.fromstring(body).iter() if x.tag.endswith('}loc')]
  except Exception as e:result['xml_error']=str(e)
 return result
if __name__=='__main__':
 issues=json.loads((stage/'issues.json').read_text())
 urls=sorted({x['source_url'] for k in ['6','15'] for x in issues[k]['data']['data']}|{x['target_url'] for x in issues['18']['data']['data']}|{'https://roadrunners.run/sitemaps/news-recent.xml','https://roadrunners.run/en/videos/?page=3','https://roadrunners.run/es/videos/?page=3','https://roadrunners.run/en/news/?page=3','https://roadrunners.run/es/noticias/?page=3'})
 with ThreadPoolExecutor(max_workers=3) as e:results=list(e.map(fetch,urls))
 (stage/(sys.argv[1]+'.json')).write_text(json.dumps(results,ensure_ascii=False,indent=2))
 for r in results:print(json.dumps(r,ensure_ascii=False))
