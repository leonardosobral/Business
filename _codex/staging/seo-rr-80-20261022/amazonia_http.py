from pathlib import Path
from urllib.parse import urljoin
import json,shlex,subprocess,sys
S=Path(__file__).resolve().parent
remote=r'''
from concurrent.futures import ThreadPoolExecutor
from html.parser import HTMLParser
import json,subprocess,sys,tempfile
from pathlib import Path
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.meta={};self.canonical=[];self.alternates=[];self.in_title=False;self.title='';self.in_json=False;self.buf='';self.schema=[]
 def handle_starttag(self,t,attrs):
  a=dict(attrs)
  if t=='title':self.in_title=True
  if t=='meta' and a.get('name','').lower() in ['description','robots']:self.meta[a['name'].lower()]=a.get('content','')
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if t=='link' and a.get('hreflang'):self.alternates.append([a.get('hreflang'),a.get('href')])
  if t=='script' and a.get('type')=='application/ld+json':self.in_json=True;self.buf=''
 def handle_data(self,d):
  if self.in_title:self.title+=d
  if self.in_json:self.buf+=d
 def handle_endtag(self,t):
  if t=='title':self.in_title=False
  if t=='script' and self.in_json:self.schema.append(json.loads(self.buf));self.in_json=False
def fetch(job):
 prefix,year,method,edge=job;path=prefix+str(year)+'-corrida-das-cores-da-amazonia/'
 with tempfile.TemporaryDirectory() as td:
  h=Path(td)/'headers';b=Path(td)/'body'
  args=['curl','-sS','--max-time','25','-D',str(h),'-o',str(b),'-w','%{http_code}']
  if method=='HEAD':args+=['-I']
  if not edge:args+=['--resolve','roadrunners.run:443:127.0.0.1']
  cp=subprocess.run(args+['https://roadrunners.run'+path],capture_output=True,text=True,timeout=30)
  if cp.returncode:raise RuntimeError('Request failed '+path+': '+cp.stderr[-200:])
  headers={}
  for line in h.read_text().splitlines():
   if ':' in line:
    k,v=line.split(':',1)
    if k.lower() in ['location','content-type','x-robots-tag']:headers[k.lower()]=v.strip()
  r=dict(path=path,method=method,edge=edge,status=int(cp.stdout),headers=headers)
  if method=='GET' and r['status']==200:
   p=Meta();p.feed(b.read_text());r['metadata']=dict(title=p.title,meta=p.meta,canonical=p.canonical,alternates=p.alternates,schema=p.schema)
  return r
mode=json.load(sys.stdin)['mode'];prefixes=['/evento/','/en/event/','/es/evento/']
jobs=[(p,y,'GET',False) for p in prefixes for y in [2026,2027]]
if mode=='after':jobs += [(p,2027,m,e) for p in prefixes for m,e in [('HEAD',False),('GET',True)]]
with ThreadPoolExecutor(max_workers=3) as pool:r=list(pool.map(fetch,jobs))
print(json.dumps(r,ensure_ascii=False))
'''
mode=sys.argv[1]
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode}),capture_output=True,text=True,timeout=130)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);(S/('amazonia-http-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
if mode=='before':assert all(x['status']==200 for x in r)
else:
 before=json.loads((S/'amazonia-http-before.json').read_text())
 for x in r:
  if '/2027-' in x['path']:
   assert x['status']==301,x
   assert urljoin('https://roadrunners.run'+x['path'],x['headers']['location']).rstrip('/')==('https://roadrunners.run'+x['path'].replace('/2027-','/2026-')).rstrip('/'),x
  else:
   assert x['status']==200,x
   old=next(v for v in before if v['path']==x['path'])
   assert x['metadata']==old['metadata'],'Original metadata changed '+x['path']
print(json.dumps({'mode':mode,'checked':len(r),'status_counts':{s:sum(x['status']==s for x in r) for s in set(x['status'] for x in r)},'original_metadata_preserved':mode=='after'}))
