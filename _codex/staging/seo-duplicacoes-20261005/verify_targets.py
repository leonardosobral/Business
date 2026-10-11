from pathlib import Path
from html.parser import HTMLParser
import json,shlex,subprocess,sys,collections,datetime
P=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
events=[e for e in json.loads((P/'events.json').read_text())['events'] if e['id_evento'] in [37730,45554,45643,45646,45906]]
rows=[{'event':e,'lang':lang,'url':'https://roadrunners.run'+prefix+e['tag']+'/'} for e in events for lang,prefix in [('pt-BR','/evento/'),('en','/en/event/'),('es','/es/evento/')]]
remote='''import json,subprocess,sys,datetime
from concurrent.futures import ThreadPoolExecutor
def get(url):
 cp=subprocess.run(['curl','-sS','--max-time','20','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code} %{time_total}',url],capture_output=True,text=True,timeout=23);body,_,stats=cp.stdout.rpartition('\\n');return {'url':url,'body':body,'stats':stats,'returncode':cp.returncode}
with ThreadPoolExecutor(max_workers=2) as pool:pages=list(pool.map(get,json.load(sys.stdin)))
direct=get('https://roadrunners.run/includes/estrutura/event_title_date.cfm');direct.pop('body')
print(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pages':pages,'direct_include':direct}))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps([x['url'] for x in rows]),capture_output=True,text=True,timeout=180)
assert cp.returncode==0,cp.stderr[-1500:]
r=json.loads(cp.stdout)
class H(HTMLParser):
 def __init__(self):super().__init__();self.t=False;self.title='';self.h=False;self.h1='';self.canonical=[];self.alternates=[];self.meta={};self.j=False;self.jsonld=[];self.buffer=''
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='h1':self.h=True
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if t=='link' and a.get('hreflang'):self.alternates.append([a.get('hreflang'),a.get('href')])
  if t=='meta':
   key=a.get('name') or a.get('property')
   if key:self.meta.setdefault(key,[]).append(a.get('content'))
  if t=='script' and a.get('type')=='application/ld+json':self.j=True;self.buffer=''
 def handle_endtag(self,t):
  if t=='title':self.t=False
  if t=='h1':self.h=False
  if t=='script' and self.j:self.j=False;self.jsonld.append(json.loads(self.buffer))
 def handle_data(self,d):
  if self.t:self.title+=d
  if self.h:self.h1+=d
  if self.j:self.buffer+=d
for x in r['pages']:
 assert x['returncode']==0 and x['stats'].startswith('200 '),x['url']
 h=H();h.feed(x.pop('body'));x['meta']={k:getattr(h,k) for k in ['title','h1','canonical','alternates','meta','jsonld']}
assert r['direct_include']['stats'].startswith('404 ')
(P/('targets-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
if mode=='after':
 old=json.loads((P/'targets-before.json').read_text());groups=collections.defaultdict(list)
 for new,base,row in zip(r['pages'],old['pages'],rows):
  a,b=new['meta'],base['meta'];e=row['event']
  assert a['canonical']==b['canonical'] and a['alternates']==b['alternates'] and a['h1']==b['h1'] and a['jsonld']==b['jsonld'],new['url']
  assert {k:v for k,v in a['meta'].items() if k not in ['og:title','twitter:title']}=={k:v for k,v in b['meta'].items() if k not in ['og:title','twitter:title']},new['url']
  assert a['title']!=b['title'] and e['cidade'] in a['title'] and datetime.date.fromisoformat(e['data_inicial']).strftime('%d/%m/%Y') in a['title']
  assert a['meta']['og:title']==[a['title']] and a['meta']['twitter:title']==[a['title']]
  groups[row['lang']].append(a['title'])
 assert all(len(v)==5 and len(set(v))==5 for v in groups.values())
 # Require the complete original set to remain accessible and unique as well.
 after=json.loads((P/'after-pages.json').read_text());before=json.loads((P/'current-pages.json').read_text());titles=[]
 targets=set(row['url'] for row in rows)
 for a,b in zip(after['pages'],before['pages']):
  assert a['url']==b['url'] and a['stats'].split()[0]==b['stats'].split()[0]
  assert a['canonical']==b['canonical'] and a['descriptions']==b['descriptions'] and a['h1']==b['h1'] and a['robots']==b['robots']
  if a['url'] not in targets:assert a['title']==b['title'],a['url']
  if a['stats'].startswith('200 '):titles.append(a['title'])
 assert len(titles)==61 and len(set(titles))==61
 receipt={'passed':True,'at':r['at'],'original_urls':len(after['pages']),'duplicate_titles':0,'localized_targets':15,'headings_canonical_hreflang_description_schema_preserved':True,'direct_include_status':404}
 (P/'public-passed.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(receipt))
else:print(json.dumps({'before_targets':len(r['pages']),'direct_include':404}))
