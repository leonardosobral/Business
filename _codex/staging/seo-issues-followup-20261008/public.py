from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import quote
import json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
catalog=json.loads((S/'inspection.json').read_text())['catalog']['marathons']
cases=[{'path':'/maratona/'+quote(m['tag'],safe='')+'/','name':m['name'],'marathon':True} for m in catalog if m['tag']]
cases += [{'path':p,'marathon':False} for p in ['/','/org/sportsland/','/timer/branca-esportes-saude-e-lazer/','/circuito/live-run-xp/','/circuito/fca-corridaderua/','/evento/2026-corrida-night-run-vitoria-airport/','/sitemap.xml','/configuracoes/perfil/']]
remote='''from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,sys,tempfile,subprocess,time,threading
p=json.load(sys.stdin);lock=threading.Lock();next_request=[0.0]
def get(c):
 with lock:
  delay=next_request[0]-time.monotonic()
  if delay>0:time.sleep(delay)
  next_request[0]=time.monotonic()+1.0
 with tempfile.TemporaryDirectory(prefix='seo-marathon-public-') as d:
  header=Path(d)/'headers';body=Path(d)/'body'
  cp=subprocess.run(['curl','-sS','--path-as-is','--max-time','35','-A','RunnerHub-SEO-Verification/1.0','-D',str(header),'-o',str(body),'https://roadrunners.run'+c['path']],capture_output=True,text=True,timeout=40)
  lines=header.read_text().splitlines();status=next((int(x.split()[1]) for x in lines if x.startswith('HTTP/')),0)
  headers={line.split(':',1)[0].lower():line.split(':',1)[1].strip() for line in lines if ':' in line}
  return {**c,'status':status,'returncode':cp.returncode,'location':headers.get('location',''),'content_type':headers.get('content-type',''),'robots_header':headers.get('x-robots-tag',''),'body':body.read_text(errors='replace')}
with ThreadPoolExecutor(max_workers=2) as pool:r=list(pool.map(get,p['cases']))
print(json.dumps({'rows':r}))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'cases':cases}),capture_output=True,text=True,timeout=190)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout)
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.t=False;self.title='';self.on=False;self.h1=[];self.h1alt=[];self.meta={};self.canonical=[];self.alternates=[]
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='h1':self.on=True;self.h1.append('');self.h1alt.append([])
  if t=='img' and self.on:self.h1alt[-1].append(a.get('alt',''))
  if t=='meta' and a.get('name') in ['description','robots']:self.meta[a['name']]=a.get('content','')
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href',''))
  if t=='link' and a.get('rel')=='alternate':self.alternates.append([a.get('hreflang',''),a.get('href','')])
 def handle_endtag(self,t):
  if t=='title':self.t=False
  if t=='h1':self.on=False
 def handle_data(self,d):
  if self.t:self.title+=d
  if self.on:self.h1[-1]+=d
for row in r['rows']:
 body=row.pop('body');h=Meta();h.feed(body);row['metadata']={'title':h.title,'meta':h.meta,'canonical':h.canonical,'alternates':h.alternates};row['headings']=[' '.join(x.split()) for x in h.h1];row['heading_images']=h.h1alt;row['cf_error']='Error Occurred While Processing Request' in body
(S/('public-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
for row in r['rows']:
 assert not row['returncode'] and not row['cf_error'],row
 if row['marathon']:assert row['status']==200,row
if mode=='before':
 for row in r['rows']:
  if row['marathon']:assert len(row['headings'])==0,row
else:
 before=json.loads((S/'public-before.json').read_text());assert len(before['rows'])==len(r['rows']);checks=[]
 for old,new in zip(before['rows'],r['rows']):
  if new['marathon']:
   assert len(new['headings'])==1,new
   assert new['name'] in new['headings'][0] or any(new['name'] in alt for alt in new['heading_images'][0]),new
   assert {k:v for k,v in new.items() if k not in ['headings','heading_images']}=={k:v for k,v in old.items() if k not in ['headings','heading_images']},new['path']+' metadata changed'
  else:assert new==old,{'before':old,'after':new}
  checks.append({'path':new['path'],'passed':True,'h1_count':len(new['headings'])})
 (S/'public-passed.json').write_text(json.dumps({'passed':True,'checks':checks,'marathons':47,'controls':8},indent=2))
print(json.dumps({'mode':mode,'pages':len(r['rows']),'marathons':sum(x['marathon'] for x in r['rows']),'marathon_h1_counts':sorted(set(len(x['headings']) for x in r['rows'] if x['marathon'])),'control_statuses':[x['status'] for x in r['rows'] if not x['marathon']]}))
