from pathlib import Path
from html.parser import HTMLParser
import json,subprocess,sys,xml.etree.ElementTree as ET
P=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.canon=[];self.alts=[];self.robots=[];self.schemas=[];self.buf=None
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='link' and d.get('rel')=='canonical':self.canon.append(d.get('href'))
  if t=='link' and d.get('rel')=='alternate':self.alts.append(d)
  if t=='meta' and d.get('name')=='robots':self.robots.append(d.get('content'))
  if t=='script' and d.get('type')=='application/ld+json':self.buf=[]
 def handle_data(self,d):
  if self.buf is not None:self.buf.append(d)
 def handle_endtag(self,t):
  if t=='script' and self.buf is not None:self.schemas.append(json.loads(''.join(self.buf)));self.buf=None

def fetch(url):
 cp=subprocess.run(['curl','-sS','--max-time','40','-D','-','-w','\n%{http_code}\n%{time_total}',url],text=True,capture_output=True,timeout=45)
 if cp.returncode:raise RuntimeError(cp.stderr)
 headbody,status,elapsed=cp.stdout.rsplit('\n',2);head,body=headbody.split('\r\n\r\n' if '\r\n\r\n' in headbody else '\n\n',1)
 return int(status),float(elapsed),head,body
old='2026-4-corrida-do-turismo-abavse-2026';new='2027-4-corrida-do-turismo-abavse-2026';results=[]
for prefix in ['/evento/','/en/event/','/es/evento/']:
 for tag in [old,new]:
  url='https://roadrunners.run'+prefix+tag+'/'
  status,seconds,headers,body=fetch(url)
  if mode=='after' and tag==old:
   location=next((line.split(':',1)[1].strip() for line in headers.splitlines() if line.lower().startswith('location:')),'')
   assert status==301 and location in [prefix+new+'/','https://roadrunners.run'+prefix+new+'/'],(url,status,location)
   results.append({'url':url,'status':status,'location':location,'seconds':seconds});continue
  assert status==200 and 'Error Occurred While Processing Request' not in body,(url,status)
  m=Meta();m.feed(body);r={'url':url,'status':status,'seconds':seconds,'canonical':m.canon,'alternates':m.alts,'robots':m.robots,'schemas':m.schemas,'has_reschedule_notice':'2027' in body and ('adiad' in body.lower() or 'postpon' in body.lower() or 'aplaz' in body.lower())}
  if mode=='after':
   baseline=next(x for x in json.loads((P/'public-before.json').read_text()) if x['url']==url)
   for key in ['canonical','alternates','robots']:assert r[key]==baseline[key],(url,key)
   expected=baseline['schemas']
   found=0
   for schema in expected:
    if schema.get('@type')=='SportsEvent':schema['eventStatus']='https://schema.org/EventRescheduled';schema['previousStartDate']='2026-08-09';found+=1
   assert found==1 and r['schemas']==expected,(url,'schema delta')
  results.append(r)
(P/('public-'+mode+'.json')).write_text(json.dumps(results,indent=2,ensure_ascii=False))
print(json.dumps({'mode':mode,'verified_urls':len(results),'notices':[r.get('has_reschedule_notice') for r in results if new in r['url']]}))
if mode=='after':
 maps=[]
 for section in ['events-upcoming-1','events-history-1','events-history-2','events-history-3']:
  url='https://roadrunners.run/sitemaps/'+section+'.xml';status,seconds,headers,body=fetch(url)
  assert status==200,(url,status)
  tree=ET.fromstring(body);urls=[x.text for x in tree.findall('.//{http://www.sitemaps.org/schemas/sitemap/0.9}loc')]
  maps.append({'url':url,'status':status,'urls':len(urls),'old':sum('/'+old+'/' in u for u in urls),'new':sum('/'+new+'/' in u for u in urls),'seconds':seconds})
 (P/'public-sitemaps.json').write_text(json.dumps(maps,indent=2))
 assert sum(x['old'] for x in maps)==0 and sum(x['new'] for x in maps)==3,maps
 print(json.dumps({'sitemaps_verified':len(maps),'duplicate_absent':True,'target_locales':3}))
