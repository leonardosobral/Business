from pathlib import Path
import json,shlex,subprocess
STAGE=Path('/Users/Shared/Projects/RunnerHub/Business/_codex/staging/seo-routes-20261003')
remote=r'''
import json,urllib.request,urllib.error,urllib.parse,xml.etree.ElementTree as ET,time
from html.parser import HTMLParser
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
opener=urllib.request.build_opener(NoRedirect())
class Metadata(HTMLParser):
 def __init__(self):super().__init__();self.canonical=[];self.alternates=[];self.scripts=[];self.script=None
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='link':
   if 'canonical' in a.get('rel','').split():self.canonical.append(a.get('href',''))
   if 'alternate' in a.get('rel','').split() and 'hreflang' in a:self.alternates.append(a)
  if tag=='script' and a.get('type')=='application/ld+json':self.script=''
 def handle_data(self,data):
  if self.script is not None:self.script+=data
 def handle_endtag(self,tag):
  if tag=='script' and self.script is not None:self.scripts.append(self.script);self.script=None

def get(url):
 try:
  with opener.open(urllib.request.Request(url,headers={'User-Agent':'RunnerHub-SEO-verification/20261003'}),timeout=20) as r:return r.status,r.read(2*1024*1024).decode('utf8',errors='replace')
 except urllib.error.HTTPError as e:
  status=e.code;body=e.read(500).decode('utf8',errors='replace');e.close();return status,body

def same(left,right):
 a=urllib.parse.urlsplit(left);b=urllib.parse.urlsplit(right)
 return a.scheme==b.scheme and a.netloc==b.netloc and not a.query and not a.fragment and urllib.parse.unquote(a.path)==urllib.parse.unquote(b.path)

def objects(x):
 if isinstance(x,dict):
  yield x
  for value in x.values():yield from objects(value)
 elif isinstance(x,list):
  for value in x:yield from objects(value)

tags=[
 ('2026-operario\r\nnight\r\nrun','OPERÁRIO\r\nNIGHT\r\nRUN'),
 ('2026-rock-n-run\n----nashville-2026',"ROCK N' RUN\n                NASHVILLE 2026"),
 ('2026-atibaia-run-fest-trail-mode-#03-socorro-pico-do-gaviao','ATIBAIA RUN FEST - TRAIL MODE #03 - SOCORRO | PICO DO GAVIÃO'),
 ('2026-atibaia-run-fest-x-chopp-germania-corre-pela-breja-#01','ATIBAIA RUN FEST x CHOPP GERMÂNIA |Corre pela Breja #01')]
report={'checked_at_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'events':[],'guards':[],'news':{},'sitemaps':[]}
for tag,name in tags:
 for prefix in ['/evento/','/en/event/','/es/evento/']:
  url='https://roadrunners.run'+prefix+urllib.parse.quote(tag,safe='')+'/'
  status,body=get(url);meta=Metadata();meta.feed(body)
  schemas=[];parse_errors=0
  for raw in meta.scripts:
   try:schemas.extend(objects(json.loads(raw)))
   except ValueError:parse_errors+=1
  events=[x for x in schemas if x.get('@type')=='SportsEvent']
  event=events[0] if events else {}
  event_name=event.get('name',event.get('NAME',''))
  # Collapse layout whitespace without changing the event's meaningful name.
  identity=' '.join(event_name.split())==' '.join(name.split())
  canonical=len(meta.canonical)==1 and same(meta.canonical[0],url)
  alternates=len(meta.alternates)>=3 and all(any(same(a.get('href',''),'https://roadrunners.run'+p+urllib.parse.quote(tag,safe='')+'/') for a in meta.alternates) for p in ['/evento/','/en/event/','/es/evento/'])
  row={'url':url,'status':status,'event_name':event_name,'identity_ok':identity,'canonical':meta.canonical,'canonical_ok':canonical,'alternates_ok':alternates,'jsonld_parse_errors':parse_errors}
  report['events'].append(row)
report['events_ok']=all(r['status']==200 and r['identity_ok'] and r['canonical_ok'] and r['alternates_ok'] and r['jsonld_parse_errors']==0 for r in report['events'])
for path in ['/.env','/.git/config','/config.json','/mcp/']:
 status,_=get('https://roadrunners.run'+path);report['guards'].append({'path':path,'status':status})
report['guards_ok']=all(r['status']==403 for r in report['guards'])
slug='ranking-atualizado-com-maceio-live-inter-j-pessoa-taubate-floripa-goiania-movi-e-vitoria'
status,_=get('https://roadrunners.run/noticias/'+slug+'/');report['news']={'status':status,'slug':slug}
status,xml=get('https://roadrunners.run/sitemap.xml')
index=ET.fromstring(xml);children=[e.text for e in index.iter() if e.tag.endswith('loc')]
for url in children:
 if 'news' not in url:continue
 status,xml=get(url);root=ET.fromstring(xml)
 report['sitemaps'].append({'url':url,'status':status,'news_slug_present':any(slug in (e.text or '') for e in root.iter() if e.tag.endswith('loc'))})
report['news_ok']=status==200 and report['news']['status']==404 and len(report['sitemaps'])>=1 and all(r['status']==200 and not r['news_slug_present'] for r in report['sitemaps'])
print(json.dumps(report,ensure_ascii=False))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=240)
if p.returncode:raise RuntimeError(p.stderr[-2400:])
r=json.loads(p.stdout);(STAGE/'public-verification.json').write_text(json.dumps(r,indent=2,ensure_ascii=False))
print(json.dumps(r,ensure_ascii=False))
if not all(r[k] for k in ['events_ok','guards_ok','news_ok']):raise SystemExit(2)
