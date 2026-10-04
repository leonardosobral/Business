from pathlib import Path
import json,shlex,subprocess
STAGE=Path(__file__).resolve().parent
remote=r'''
import json,time,urllib.request,urllib.parse,xml.etree.ElementTree as ET
from html.parser import HTMLParser
class Metadata(HTMLParser):
 def __init__(self):super().__init__();self.headings=[];self.current=None;self.canonical=[];self.schemas=[];self.script=None
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='h1':self.current=''
  if tag=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href',''))
  if tag=='script' and a.get('type')=='application/ld+json':self.script=''
 def handle_data(self,data):
  if self.current is not None:self.current+=data
  if self.script is not None:self.script+=data
 def handle_endtag(self,tag):
  if tag=='h1' and self.current is not None:self.headings.append(' '.join(self.current.split()));self.current=None
  if tag=='script' and self.script is not None:self.schemas.append(json.loads(self.script));self.script=None
def get(url):
 with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'RunnerHub-SEO-structure/20261003','Cache-Control':'no-cache'}),timeout=25) as r:
  return r.status,r.read(3*1024*1024).decode('utf8',errors='replace'),dict(r.headers)
def objects(value):
 if isinstance(value,dict):
  yield value
  for item in value.values():yield from objects(item)
 elif isinstance(value,list):
  for item in value:yield from objects(item)
news='gleison-da-silva-santos-e-tricampeao-do-circuito-caixa-em-maceio'
event='2026-maratona-salvador-2026'
report={'checked_at_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'headings':[],'facts':[],'robots':{},'sitemaps':[]}
for home,search,eventpath,newspath in [('/','/busca/','/evento/','/noticias/'),('/en/','/en/search/','/en/event/','/en/news/'),('/es/','/es/busqueda/','/es/evento/','/es/noticias/')]:
 for path,label in [(home,'home'),(search,'search'),(eventpath+event+'/','event'),(newspath+news+'/','news')]:
  url='https://roadrunners.run'+path;status,body,headers=get(url);meta=Metadata();meta.feed(body)
  row={'url':url,'kind':label,'status':status,'h1':meta.headings,'canonical':meta.canonical}
  row['ok']=status==200 and len(meta.headings)==1 and len(meta.canonical)==1
  if label=='search':row['ok']=row['ok'] and any(text in meta.headings[0] for text in ['Resultado da busca','Search results','Resultado de la búsqueda'])
  if label=='event':row['ok']=row['ok'] and meta.headings[0]=='Maratona de Salvador 2026'
  if label=='news':row['ok']=row['ok'] and 'Gleison' in meta.headings[0]
  report['headings'].append(row)
status,body,headers=get('https://openresults.run/');meta=Metadata();meta.feed(body)
report['headings'].append({'url':'https://openresults.run/','kind':'home','status':status,'h1':meta.headings,'canonical':meta.canonical,'ok':status==200 and len(meta.headings)==1 and 'resultados oficiais' in meta.headings[0]})
for tag,expected in [('2026-6-maratona-internacional-de-joao-pessoa-2026',None),('2027-maratona-internacional-de-floripa-fibra-2027','Grupo STC')]:
 for host in ['roadrunners.run','openresults.run']:
  url='https://'+host+'/evento/'+urllib.parse.quote(tag,safe='')+'/'
  status,body,headers=get(url);meta=Metadata();meta.feed(body)
  events=[value for raw in meta.schemas for value in objects(raw) if value.get('@type')=='SportsEvent'];event=events[0] if events else {}
  name=event.get('organizer',{}).get('name');expected_visible=expected is None or expected in body
  report['facts'].append({'url':url,'status':status,'organizer':name,'expected':expected,'ok':status==200 and len(events)==1 and name==expected and expected_visible})
status,body,headers=get('https://openresults.run/robots.txt');report['robots']={'status':status,'body':body,'content_type':headers.get('Content-Type'),'cf_cache_status':headers.get('CF-Cache-Status')}
for url in ['https://openresults.run/sitemap.cfm','https://roadrunners.run/sitemap.xml']:
 status,body,headers=get(url);root=ET.fromstring(body)
 report['sitemaps'].append({'url':url,'status':status,'xml_root':root.tag,'ok':status==200 and root.tag.endswith('sitemapindex')})
report['ok']=all(row['ok'] for row in report['headings']+report['facts']+report['sitemaps']) and report['robots']['status']==200
print(json.dumps(report,ensure_ascii=False))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=580)
if p.returncode:raise RuntimeError(p.stderr[-2200:])
r=json.loads(p.stdout);(STAGE/'public-verification.json').write_text(json.dumps(r,indent=2,ensure_ascii=False))
print(json.dumps({k:v for k,v in r.items() if k not in ['headings','facts','robots']}|{'headings_checked':len(r['headings']),'facts_checked':len(r['facts']),'failed':[row for row in r['headings']+r['facts']+r['sitemaps'] if not row['ok']]},ensure_ascii=False))
if not r['ok']:raise SystemExit(2)
