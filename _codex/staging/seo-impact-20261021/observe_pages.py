from pathlib import Path
import json,shlex,subprocess,sys
S=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ('before','after')
events=['2026-corrida-da-virada-2026-sp','2026-corrida-da-virada-2026-porto-franco','2026-corrida-da-virada-2026-sc','2026-together-run-pe','2026-together-run-pb']
targets=[{'host':'roadrunners.run','path':f'/{prefix}/{tag}/'} for prefix in ['evento','en/event','es/evento'] for tag in events]
targets += [{'host':'openresults.run','path':path} for path in ['/','/estado/RJ/','/estado/rj/','/estado/sp/?cidade=sao-paulo','/proximas-provas/','/evento/2026-mizuno-athenas-run-longer-2026/']]
remote='''
from html.parser import HTMLParser
import hashlib,json,sys,time,urllib.request,urllib.error
class P(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.intitle=False;self.jsonld=False;self.schema=[];self.description='';self.canonical=[];self.alternates=[];self.scripts=[];self.endpoints=[]
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='title':self.intitle=True
  if t=='script':
   self.jsonld=d.get('type')=='application/ld+json'
   if 'runner-apps-menu' in d.get('src',''):self.scripts.append(d['src'])
  if t=='link' and d.get('rel')=='canonical':self.canonical.append(d.get('href'))
  if t=='link' and d.get('rel')=='alternate' and 'hreflang' in d:self.alternates.append([d['hreflang'],d.get('href')])
  if t=='meta' and d.get('name')=='description':self.description=d.get('content','')
  if 'data-runner-apps-endpoint' in d:self.endpoints.append(d['data-runner-apps-endpoint'])
 def handle_endtag(self,t):
  if t=='title':self.intitle=False
  if t=='script':self.jsonld=False
 def handle_data(self,d):
  if self.intitle:self.title+=d
  if self.jsonld:self.schema.append(d)
rows=[]
for item in json.load(sys.stdin):
 start=time.monotonic();req=urllib.request.Request('http://127.0.0.1'+item['path'],headers={'Host':item['host'],'User-Agent':'RunnerHub-SEO/1.0'})
 try:
  with urllib.request.urlopen(req,timeout=50) as r:
   body=r.read(4000000).decode('utf-8');p=P();p.feed(body)
   rows.append({**item,'status':r.status,'seconds':round(time.monotonic()-start,3),'title':p.title,'canonical':p.canonical,'description':p.description,'hreflang':p.alternates,'schema_hash':hashlib.sha256(''.join(p.schema).encode()).hexdigest(),'scripts':p.scripts,'endpoints':p.endpoints})
 except urllib.error.HTTPError as e:rows.append({**item,'status':e.code})
print(json.dumps(rows))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(targets),capture_output=True,text=True,timeout=220)
assert cp.returncode==0,cp.stderr[-2200:]
rows=json.loads(cp.stdout);(S/f'pages-{mode}.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
assert all(x['status']==200 for x in rows),[x for x in rows if x['status']!=200]
if mode=='after':
 old=json.loads((S/'pages-before.json').read_text());expected=json.loads((S/'title-tests-green.json').read_text())['rows']
 for a,b in zip(old,rows):
  for field in ['host','path','status','canonical','description','hreflang','schema_hash']:assert a[field]==b[field],(a['path'],field)
  if b['host']=='openresults.run':assert b['scripts']==['https://roadrunners.run/assets/js/runner-apps-menu-lazy.min.js?v=20261008seo'],b
 for prefix in ['evento','en/event','es/evento']:
  values=[r['title'].lower() for r in rows if r['host']=='roadrunners.run' and r['path'].startswith('/'+prefix+'/')]
  assert len(values)==5 and len(set(values))==5,(prefix,values)
 print(json.dumps({'pages_200':len(rows),'metadata_preserved':len(rows),'distinct_event_titles':15,'shared_script_references':6}))
else:print(json.dumps({'baseline_pages_200':len(rows)}))
