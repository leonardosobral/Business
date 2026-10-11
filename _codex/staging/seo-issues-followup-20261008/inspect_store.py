from pathlib import Path
from html.parser import HTMLParser
import json,shlex,subprocess
S=Path(__file__).resolve().parent
paths=['/','/roadrunnersstore/inactive','/roadrunnersstore/products','/roadrunnersstore/products?page=2','/roadrunnersstore/store_sessions/new','/roadrunnersstore/terms/privacy_policy','/roadrunnersstore/terms/terms_of_use']
remote='''from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,sys,tempfile,subprocess,re
p=json.load(sys.stdin)
def get(path):
 with tempfile.TemporaryDirectory(prefix='seo-store-check-') as d:
  hd=Path(d)/'headers';bd=Path(d)/'body'
  cp=subprocess.run(['curl','-sS','-L','--max-redirs','5','--max-time','30','-D',str(hd),'-o',str(bd),'-w','%{http_code} %{url_effective}','https://store.roadrunners.run'+path],capture_output=True,text=True,timeout=35)
  return {'path':path,'stats':cp.stdout,'returncode':cp.returncode,'headers':hd.read_text(errors='replace'),'body':bd.read_text(errors='replace')}
with ThreadPoolExecutor(max_workers=2) as pool:rows=list(pool.map(get,p['paths']))
vhosts=[]
for f in Path('/etc/apache2/sites-enabled').glob('*'):
 text=f.read_text(errors='replace')
 if 'store.roadrunners' in text:vhosts.append({'file':f.name,'directives':[line.strip() for line in text.splitlines() if re.match(r'^\\s*(ServerName|ServerAlias|DocumentRoot|ProxyPass)\\s',line)]})
print(json.dumps({'rows':rows,'matching_origin_vhosts':vhosts}))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'paths':paths}),capture_output=True,text=True,timeout=150)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout)
class Page(HTMLParser):
 def __init__(self):super().__init__();self.t=False;self.title='';self.meta={};self.canonical=[];self.providers=set();self.robots=[]
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='meta' and a.get('name') in ['description','generator','robots']:self.meta[a['name']]=a.get('content','')
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href',''))
  for key in ['src','href']:
   for provider in ['umapenca.com','montink.com','shopify.com','nuvemshop.com','lojaintegrada.com','vnda.com','printify.com','printful.com']:
    if provider in a.get(key,''):self.providers.add(provider)
 def handle_endtag(self,t):
  if t=='title':self.t=False
 def handle_data(self,d):
  if self.t:self.title+=d
for row in r['rows']:
 body=row.pop('body');h=Page();h.feed(body);row['metadata']={'title':h.title,'meta':h.meta,'canonical':h.canonical,'providers':sorted(h.providers)};row['inactive_text']='inativ' in body.lower()
 headers=row.pop('headers');row['header_signals']=[line for line in headers.splitlines() if line.startswith('HTTP/') or line.lower().startswith(('content-type:','server:','location:','x-powered-by:','x-robots-tag:'))]
(S/'store-inspection.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
