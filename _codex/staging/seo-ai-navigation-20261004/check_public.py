from pathlib import Path
from html.parser import HTMLParser
from concurrent.futures import ThreadPoolExecutor
import json,subprocess,re,hashlib,sys
P=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.canonical=[];self.title='';self.descriptions=[];self.t=False;self.h1=0
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='link' and d.get('rel')=='canonical':self.canonical.append(d.get('href'))
  if t=='meta' and d.get('name')=='description':self.descriptions.append(d.get('content'))
  if t=='h1':self.h1+=1
  if t=='title':self.t=True
 def handle_data(self,d):
  if self.t:self.title+=d
 def handle_endtag(self,t):
  if t=='title':self.t=False

def fetch(url):
 cp=subprocess.run(['curl','-sS','--max-time','35','-D','-','-w','\n%{http_code}',url],capture_output=True,text=True,timeout=40)
 if cp.returncode:raise RuntimeError(cp.stderr)
 hb,status=cp.stdout.rsplit('\n',1);headers,body=hb.split('\n\n',1);m=Meta();m.feed(body)
 return {'url':url,'status':int(status),'headers':headers,'body':body,'metadata':{'canonical':m.canonical,'title':m.title,'description':m.descriptions,'h1':m.h1}}
url='https://roadrunners.run/circuitocatarinense/';page=fetch(url);assert page['status']==200 and 'Error Occurred While Processing Request' not in page['body']
if mode=='after':
 before=json.loads((P/'public-before.json').read_text());assert page['metadata']==before['circuit']['metadata']
 for label in ['corridaderua','trailrun']:
  assert 'href="/circuitocatarinense/'+label+'/"' in page['body'] and 'href="'+label+'"' not in page['body']
 text=(P/'candidate/llms.txt').read_text();llms=fetch('https://roadrunners.run/llms.txt')
 assert llms['status']==200 and re.search(r'^content-type:\s*text/plain',llms['headers'],re.I|re.M),llms['headers'][:200]
 assert llms['body']==text
 urls=re.findall(r'\]\((https://[^)]+)\)',text);assert len(urls)==len(set(urls))
 with ThreadPoolExecutor(max_workers=3) as pool:links=list(pool.map(fetch,urls))
 assert all(p['status']==200 and 'Error Occurred While Processing Request' not in p['body'] for p in links),[(p['url'],p['status']) for p in links]
 result={'circuit':{k:v for k,v in page.items() if k not in ['headers','body']},'directory':{'status':200,'sha256':hashlib.sha256(text.encode()).hexdigest(),'links_verified':len(links),'urls':[{'url':p['url'],'status':p['status']} for p in links]}}
else:result={'circuit':{k:v for k,v in page.items() if k not in ['headers','body']}}
(P/('public-'+mode+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps({'mode':mode,'circuit_verified':True,'directory':result.get('directory',{}).get('links_verified')}))
