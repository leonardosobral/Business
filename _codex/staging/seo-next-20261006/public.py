from pathlib import Path
from html.parser import HTMLParser
import json,subprocess,shlex,sys,datetime
P=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
tag='2026-costa-esmeralda-trail-2026';prefixes=['/evento/','/en/event/','/es/evento/']
rows=[{'method':'GET','path':prefix+year+'-corrida-night-run-vitoria-airport/','kind':'night','date':'25/10/2025' if year=='2025' else '20/11/2026'} for prefix in prefixes for year in ['2025','2026']]
rows +=[{'method':'GET','path':prefix+tag+'/','kind':'target'} for prefix in prefixes]
rows +=[{'method':m,'path':prefix+tag,'kind':'alias'} for prefix in prefixes for m in ['GET','HEAD']]
rows +=[{'method':'GET','path':prefix+tag+'?utm_source=seo-verification','kind':'control'} for prefix in prefixes]
rows +=[{'method':'GET','path':path,'kind':'control'} for path in ['/','/en/','/es/','/evento/2026-circuito-de-corridas-correr-e-massa-apostou-loterias-etapa-apucarana/','/evento/2026-trackfield-run-series-2026-motiva-aeroportos-londrina/','/privacidade/']]
remote='''import json,subprocess,sys,datetime
from concurrent.futures import ThreadPoolExecutor
p=json.load(sys.stdin)
def get(r):
 cmd=['curl','-sS','--path-as-is','--max-time','20','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code} %{time_total} %{redirect_url}'];cmd+=['-I'] if r['method']=='HEAD' else [];cmd+=['https://roadrunners.run'+r['path']]
 cp=subprocess.run(cmd,capture_output=True,text=True,timeout=23);body,_,stats=cp.stdout.rpartition('\\n');return dict(r,body=body if r['method']=='GET' else '',stats=stats,returncode=cp.returncode)
with ThreadPoolExecutor(max_workers=2) as pool:pages=list(pool.map(get,p))
follow=[]
for r in p:
 if r['kind']=='alias' and r['method']=='GET' :
  cp=subprocess.run(['curl','-sS','-L','--max-redirs','3','--max-time','20','-o','/dev/null','-w','%{http_code} %{num_redirects} %{url_effective}','https://roadrunners.run'+r['path']],capture_output=True,text=True,timeout=23);follow.append({'path':r['path'],'stats':cp.stdout,'returncode':cp.returncode})
print(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pages':pages,'follow':follow}))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(rows),capture_output=True,text=True,timeout=250)
assert cp.returncode==0,cp.stderr[-1800:];r=json.loads(cp.stdout)
class H(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.h1='';self.canonical=[];self.description=[];self.alternates=[];self.robots=[];self.t=False;self.h=False;self.jsonld=[];self.j=False;self.rawjson=''
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='script' and a.get('type')=='application/ld+json':self.j=True;self.rawjson=''
  if t=='title':self.t=True
  if t=='h1':self.h=True
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if t=='link' and a.get('hreflang'):self.alternates.append([a.get('hreflang'),a.get('href')])
  if t=='meta' and a.get('name')=='description':self.description.append(a.get('content'))
  if t=='meta' and a.get('name')=='robots':self.robots.append(a.get('content'))
 def handle_endtag(self,t):
  if t=='script' and self.j:self.jsonld.append(json.loads(self.rawjson));self.j=False
  if t=='title':self.t=False
  if t=='h1':self.h=False
 def handle_data(self,d):
  if self.j:self.rawjson+=d
  if self.t:self.title+=d
  if self.h:self.h1+=d
for x in r['pages']:
 assert x['returncode']==0,x
 h=H();h.feed(x.pop('body'));x['meta']={k:getattr(h,k) for k in ['title','h1','canonical','description','alternates','robots','jsonld']}
(P/('aliases-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
if mode=='before':
 assert all(x['stats'].startswith('200 ') for x in r['pages']), [(x['path'],x['stats']) for x in r['pages'] if not x['stats'].startswith('200 ')]
 print(json.dumps({'before_requests':len(r['pages']),'night_pages':6,'aliases_200':6,'controls':9}))
else:
 old=json.loads((P/'aliases-before.json').read_text());count=0;changed=0
 for a,b in zip(r['pages'],old['pages']):
  assert a['path']==b['path'] and a['method']==b['method']
  if a['kind']=='alias':
   assert a['stats'].startswith('301 ') and a['stats'].split()[2]=='https://roadrunners.run'+a['path']+'/',a
   count+=1
  elif a['kind']=='night':
   assert a['stats'].startswith('200 ') and a['date'] in a['meta']['title'] and len(a['meta']['title'])<=70,a
   full_names={e['tag']:e['nome_evento'] for e in json.loads((P/'inspection.json').read_text())['report']['events']}
   assert full_names[a['path'].rstrip('/').split('/')[-1]] in a['meta']['title'],a['path']
   assert a['meta']['title']!=b['meta']['title']
   assert {k:v for k,v in a['meta'].items() if k!='title'}=={k:v for k,v in b['meta'].items() if k!='title'},a['path']
   changed+=1
  else:
   assert a['stats'].split()[0]==b['stats'].split()[0] and a['meta']==b['meta'],a['path']
 assert count==6 and changed==6
 night=[x for x in r['pages'] if x['kind']=='night']
 for i in range(0,6,2):assert night[i]['meta']['title'].casefold()!=night[i+1]['meta']['title'].casefold()
 assert len(r['follow'])==3
 for x in r['follow']:assert x['returncode']==0 and x['stats']=='200 1 https://roadrunners.run'+x['path']+'/',x
 for x in r['pages']:
  if x['kind']=='target':
   assert x['meta']['canonical']==['https://roadrunners.run'+x['path']]
   assert any(url=='https://roadrunners.run'+x['path'] for lang,url in x['meta']['alternates'])
 result={'passed':True,'at':r['at'],'alias_checks':count,'night_pages_distinct':changed,'unchanged_metadata_pages':12,'redirect_hops':1,'total_requests':len(r['pages'])+len(r['follow'])}
 (P/'public-passed.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
