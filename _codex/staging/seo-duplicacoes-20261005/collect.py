from pathlib import Path
from html.parser import HTMLParser
import json,shlex,subprocess,sys,collections
P=Path(__file__).resolve().parent;mode=sys.argv[1] if len(sys.argv)>1 else 'before';assert mode in ['before','after']
source=json.loads((P.parent/'seo-indexacao-prioridades-20261005/issues.json').read_text())
urls=[r['source_url'] for x in source['reports'] if x['id']==6 for r in x['data']['data']]
remote='''import json,sys,subprocess,datetime
from concurrent.futures import ThreadPoolExecutor
def fetch(url):
 cp=subprocess.run(['curl','-sS','--max-time','20','-A','RunnerHub-SEO-Review/1.0','-w','\\n%{http_code} %{time_total} %{redirect_url}',url],capture_output=True,text=True,timeout=23)
 body,_,stats=cp.stdout.rpartition('\\n');return {'url':url,'body':body,'stats':stats,'returncode':cp.returncode}
urls=json.load(sys.stdin)
with ThreadPoolExecutor(max_workers=2) as pool:pages=list(pool.map(fetch,urls))
print(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pages':pages}))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(urls),capture_output=True,text=True,timeout=800)
assert cp.returncode==0,cp.stderr[-1500:]
r=json.loads(cp.stdout)
class H(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.t=False;self.canonical=[];self.descriptions=[];self.h1='';self.h=False;self.robots=[]
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='h1':self.h=True
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if t=='meta' and a.get('name')=='description':self.descriptions.append(a.get('content'))
  if t=='meta' and a.get('name')=='robots':self.robots.append(a.get('content'))
 def handle_endtag(self,t):
  if t=='title':self.t=False
  if t=='h1':self.h=False
 def handle_data(self,d):
  if self.t:self.title+=d
  if self.h:self.h1+=d
report=[]
for i,x in enumerate(r['pages']):
 h=H();h.feed(x['body']);(P/(mode+'-'+str(i)+'.html')).write_text(x.pop('body'))
 x.update({'title':h.title,'canonical':h.canonical,'descriptions':h.descriptions,'h1':h.h1,'robots':h.robots});report.append(x)
result={'at':r['at'],'pages':report,'source_snapshot':source['snapshot']}
(P/('current-pages.json' if mode=='before' else 'after-pages.json')).write_text(json.dumps(result,indent=2,ensure_ascii=False))
groups=collections.defaultdict(list)
for x in report:
 if x['stats'].startswith('200 '):groups[x['title']].append(x['url'])
print(json.dumps({'pages':len(report),'non200':[{'url':x['url'],'stats':x['stats']} for x in report if not x['stats'].startswith('200 ')],'remaining_duplicate_titles':[{ 'title':k,'urls':v} for k,v in groups.items() if len(v)>1]},ensure_ascii=False))
