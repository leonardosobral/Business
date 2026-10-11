from pathlib import Path
from html.parser import HTMLParser
import json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
prefixes=['atleta','en/athlete','es/atleta']
cases=[{'path':'/'+p+'/leonardo%20muniz/','method':m,'changed':True} for p in prefixes for m in ['GET','HEAD']]
cases += [{'path':'/'+p+'/runnerhub/','method':'GET'} for p in prefixes]
cases += [{'path':p,'method':'GET'} for p in ['/atleta/index.cfm?tag=leonardo%20muniz','/atleta/leonardo%20muniz/?filtro=resultados','/configuracoes/perfil/','/circuitocatarinense/trailrun/','/','/estado/sp/','/evento/2026-corrida-night-run-vitoria-airport/','/evento/2025-corrida-night-run-vitoria-airport/','/evento/2026-costa-esmeralda-trail-2026','/en/event/2026-costa-esmeralda-trail-2026','/es/evento/2026-costa-esmeralda-trail-2026','/sitemap.xml','/cdn-cgi/l/email-protection']]
cases[10]['changed']=True # Friendly space URL with an existing query; direct index remains a control.
remote='''from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,sys,tempfile,subprocess
p=json.load(sys.stdin)
def get(c):
 with tempfile.TemporaryDirectory(prefix='seo-athlete-public-') as d:
  header=Path(d)/'headers';body=Path(d)/'body';cmd=['curl','-sS','--path-as-is','--max-time','35','-A','RunnerHub-SEO-Verification/1.0','-D',str(header)]
  if c['method']=='HEAD':cmd+=['-I']
  cmd+=['-o',str(body),'https://roadrunners.run'+c['path']];cp=subprocess.run(cmd,capture_output=True,text=True,timeout=40)
  lines=header.read_text().splitlines();status=next((int(x.split()[1]) for x in lines if x.startswith('HTTP/')),0)
  headers={line.split(':',1)[0].lower():line.split(':',1)[1].strip() for line in lines if ':' in line}
  return {**c,'status':status,'returncode':cp.returncode,'location':headers.get('location',''),'content_type':headers.get('content-type',''),'robots_header':headers.get('x-robots-tag',''),'body':body.read_text(errors='replace')}
with ThreadPoolExecutor(max_workers=2) as pool:r=list(pool.map(get,p['cases']))
print(json.dumps({'rows':r}))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'cases':cases}),capture_output=True,text=True,timeout=230)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout)
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.t=False;self.title='';self.h=False;self.h1='';self.meta={};self.canonical=[];self.alternates=[]
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='h1':self.h=True
  if t=='meta' and a.get('name') in ['description','robots']:self.meta[a['name']]=a.get('content','')
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href',''))
  if t=='link' and a.get('rel')=='alternate':self.alternates.append([a.get('hreflang',''),a.get('href','')])
 def handle_endtag(self,t):
  if t=='title':self.t=False
  if t=='h1':self.h=False
 def handle_data(self,d):
  if self.t:self.title+=d
  if self.h:self.h1+=d
for row in r['rows']:
 body=row.pop('body');h=Meta();h.feed(body);row['metadata']={'title':h.title,'h1':h.h1,'meta':h.meta,'canonical':h.canonical,'alternates':h.alternates};row['cf_error']='Error Occurred While Processing Request' in body
(S/('public-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
if mode=='before':
 for row in r['rows']:
  assert not row['returncode'] and not row['cf_error'],row
  if row.get('changed'):assert row['status']==403,row
else:
 before=json.loads((S/'public-before.json').read_text());assert len(before['rows'])==len(r['rows']);checks=[]
 for old,new in zip(before['rows'],r['rows']):
  assert not new['returncode'] and not new['cf_error'],new
  if new.get('changed'):
   assert new['status']==302 and new['location'].removeprefix('https://roadrunners.run').startswith('/login/?redirect='),new
  else:assert new==old,{'before':old,'after':new}
  checks.append({'path':new['path'],'method':new['method'],'before':old['status'],'after':new['status'],'passed':True})
 (S/'public-passed.json').write_text(json.dumps({'passed':True,'checks':checks},indent=2))
print(json.dumps({'mode':mode,'pages':len(r['rows']),'responses':[{'path':x['path'],'method':x['method'],'status':x['status'],'location':x['location']} for x in r['rows']]},ensure_ascii=False))
