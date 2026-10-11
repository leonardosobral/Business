from pathlib import Path
import json,shlex,subprocess
S=Path(__file__).resolve().parent
remote=r'''from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin,urlsplit
from urllib.robotparser import RobotFileParser
import json,subprocess,time,hashlib
base='https://roadrunners.run'; ua='RunnerHub-SEO-Verification/1.0'; next_at=0
class P(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.assets=[];self.h1=0;self.title='';self.t=False;self.canonical=[];self.description=[];self.robots=[]
 def handle_starttag(self,t,attrs):
  a=dict(attrs)
  if t=='title':self.t=True
  if t=='h1':self.h1+=1
  if t=='a' and a.get('href'):self.links.append(a['href'])
  if t=='script' and a.get('src'):self.assets.append({'tag':t,'url':a['src'],'attrs':a})
  if t=='link' and a.get('rel')=='stylesheet':self.assets.append({'tag':t,'url':a.get('href',''),'attrs':a})
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href',''))
  if t=='meta' and a.get('name') in ['description','robots']:getattr(self,a['name']).append(a.get('content',''))
 def handle_endtag(self,t):
  if t=='title':self.t=False
 def handle_data(self,d):
  if self.t:self.title+=d

def get(url):
 global next_at
 time.sleep(max(0,next_at-time.monotonic())); next_at=time.monotonic()+1
 cp=subprocess.run(['curl','-sS','--max-time','20','-A',ua,'-w','\n%{http_code} %{redirect_url}',url],capture_output=True,text=True,timeout=24)
 body,_,stats=cp.stdout.rpartition('\n');status=int(stats.split(' ',1)[0]) if stats else 0
 return cp.returncode,status,stats,body
rc,status,stats,body=get(base+'/robots.txt'); assert rc==0 and status==200,'robots fetch failed'
robot=RobotFileParser();robot.parse(body.splitlines())
seeds=['/','/estado/sp/','/estado/sc/','/estado/ba/','/busca/','/maratonas/','/ajuda/','/privacidade/','/evento/2026-corrida-night-run-vitoria-airport/','/evento/2026-costa-esmeralda-trail-2026/']
allowed_prefixes=['/evento/','/estado/','/cidade/','/maratona/','/org/','/timer/','/circuito/','/noticias/','/videos/','/en/event/','/es/evento/']
rows=[];discovered={}; seen=set()
queue=[base+x for x in seeds]
while queue and len(rows)<80:
 url=queue.pop(0)
 if url in seen:continue
 seen.add(url)
 if not robot.can_fetch(ua,url):continue
 rc,status,stats,body=get(url);page=P();page.feed(body)
 rows.append({'url':url,'status':status,'stats':stats,'returncode':rc,'h1_count':page.h1,'title':page.title,'canonical':page.canonical,'description':page.description,'robots':page.robots,'assets':page.assets,'cf_error':'Error Occurred While Processing Request' in body})
 if status!=200:continue
 for href in page.links:
  target=urljoin(url,href);u=urlsplit(target)
  if u.scheme!='https' or u.netloc!='roadrunners.run' or u.query or u.fragment or not any(u.path.startswith(prefix) for prefix in allowed_prefixes):continue
  if any(u.path.endswith(ext) for ext in ['.png','.jpg','.svg','.cfm','.pdf','.js','.css']):continue
  target=base+u.path
  discovered.setdefault(target,[])
  if url not in discovered[target]:discovered[target].append(url)
  if target not in seen and target not in queue:queue.append(target)
print(json.dumps({'rows':rows,'discovered_sources':{r['url']:discovered.get(r['url'],[]) for r in rows},'max_rps':1,'max_pages':80,'scope':'sample of public navigation; not Semrush or indexation'},ensure_ascii=False))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=600)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout);(S/'public-navigation.json').write_text(json.dumps(r,indent=2,ensure_ascii=False))
errors=[{k:row[k] for k in ['url','status','stats','h1_count','title','cf_error']} for row in r['rows'] if row['status'] not in [200,301,302] or row['cf_error'] or (row['status']==200 and row['h1_count']!=1)]
assets={}
for row in r['rows']:
 for asset in row['assets']:
  url=asset['url']
  if '/assets/' in url and '.min.' not in url:
   assets.setdefault(url,[]).append(row['url'])
print(json.dumps({'pages':len(r['rows']),'issues':errors,'non_minified_first_party_assets':[{ 'url':u,'pages':len(v)} for u,v in assets.items()]},ensure_ascii=False))
