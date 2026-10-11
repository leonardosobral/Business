from pathlib import Path
from html.parser import HTMLParser
import json,subprocess,shlex,sys,datetime
P=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
names=[x['tag_fornecedor'] for x in json.loads((P/'suppliers.json').read_text())['suppliers']]
rows=[{'method':'GET','path':'/timer/'+s+'/','kind':'target'} for s in names]
rows +=[{'method':m,'path':'/assessoria/'+s+('/' if slash else ''),'kind':'alias'} for s in names for m in ['GET','HEAD'] for slash in [True,False]]
rows +=[{'method':'GET','path':p,'kind':'control'} for p in ['/assessoria/not-registered/','/assessoria/','/assessoria/'+names[0]+'/?action=delete','/assessoria/'+names[0]+'/?utm_source=google','/assessoria/'+names[0]+'/?tag='+names[1]]]
remote='''import json,subprocess,sys,datetime
from concurrent.futures import ThreadPoolExecutor
p=json.load(sys.stdin)
def get(r):
 cmd=['curl','-sS','--path-as-is','--max-time','20','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code} %{time_total} %{redirect_url}'];cmd+=['-I'] if r['method']=='HEAD' else [];cmd+=['https://roadrunners.run'+r['path']]
 cp=subprocess.run(cmd,capture_output=True,text=True,timeout=23);body,_,stats=cp.stdout.rpartition('\\n');return dict(r,body=body if r['method']=='GET' else '',stats=stats,returncode=cp.returncode)
with ThreadPoolExecutor(max_workers=2) as pool:pages=list(pool.map(get,p))
follow=[]
for r in p:
 if r['kind']=='alias' and r['method']=='GET' and r['path'].endswith('/'):
  cp=subprocess.run(['curl','-sS','-L','--max-redirs','3','--max-time','20','-o','/dev/null','-w','%{http_code} %{num_redirects} %{url_effective}','https://roadrunners.run'+r['path']],capture_output=True,text=True,timeout=23);follow.append({'path':r['path'],'stats':cp.stdout,'returncode':cp.returncode})
print(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pages':pages,'follow':follow}))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(rows),capture_output=True,text=True,timeout=250)
assert cp.returncode==0,cp.stderr[-1800:];r=json.loads(cp.stdout)
class H(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.h1='';self.canonical=[];self.description=[];self.alternates=[];self.robots=[];self.t=False;self.h=False
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='h1':self.h=True
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if t=='link' and a.get('hreflang'):self.alternates.append([a.get('hreflang'),a.get('href')])
  if t=='meta' and a.get('name')=='description':self.description.append(a.get('content'))
  if t=='meta' and a.get('name')=='robots':self.robots.append(a.get('content'))
 def handle_endtag(self,t):
  if t=='title':self.t=False
  if t=='h1':self.h=False
 def handle_data(self,d):
  if self.t:self.title+=d
  if self.h:self.h1+=d
for x in r['pages']:
 assert x['returncode']==0,x
 h=H();h.feed(x.pop('body'));x['meta']={k:getattr(h,k) for k in ['title','h1','canonical','description','alternates','robots']}
(P/('aliases-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
if mode=='before':
 assert all(x['stats'].startswith('200 ') for x in r['pages'] if x['kind']=='target')
 assert all(x['stats'].startswith('404 ') for x in r['pages'] if x['kind']!='target')
 print(json.dumps({'before_requests':len(r['pages']),'valid_targets':5,'aliases_404':20,'controls_404':5}))
else:
 old=json.loads((P/'aliases-before.json').read_text());count=0
 for a,b in zip(r['pages'],old['pages']):
  assert a['path']==b['path'] and a['method']==b['method']
  if a['kind']=='alias':
   assert a['stats'].startswith('301 ') and a['stats'].split()[2]=='https://roadrunners.run'+a['path'].replace('/assessoria/','/timer/').rstrip('/')+'/',a
   count+=1
  else:
   assert a['stats'].split()[0]==b['stats'].split()[0] and a['meta']==b['meta'],a['path']
 assert count==20
 assert len(r['follow'])==5
 for x in r['follow']:assert x['returncode']==0 and x['stats']=='200 1 https://roadrunners.run'+x['path'].replace('/assessoria/','/timer/'),x
 original=json.loads((P/'before-pages.json').read_text());current=json.loads((P/'after-pages.json').read_text());n=0
 for a,b in zip(current['pages'],original['pages']):
  assert a['url']==b['url']
  if '/assessoria/' in a['url']:assert a['stats'].startswith('301 ');continue
  assert a['stats'].split()[0]==b['stats'].split()[0],a['url']
  for key in ['title','h1','description','canonical','alternates','robots']:assert a[key]==b[key],(a['url'],key)
  n+=1
 result={'passed':True,'at':r['at'],'alias_checks':count,'target_pages_preserved':5,'negative_cases_preserved':5,'audit_urls_rechecked':len(current['pages']),'other_urls_preserved':n,'redirect_hops':1}
 (P/'public-passed.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
