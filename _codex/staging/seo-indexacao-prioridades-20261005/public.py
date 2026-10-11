from pathlib import Path
from html.parser import HTMLParser
import json,subprocess,shlex,xml.etree.ElementTree as E
P=Path(__file__).resolve().parent
paths=['/','/estado/sp/','/circuito/fca-corridaderua/','/circuito/circuito-catarinense-corrida-de-rua/','/circuito/live-run-xp/','/desafiosupra/2024/','/desafiosupra/2025/','/evento/2026-1-edicao-corrida-farmelhor/','/evento/2026-1-edicao-corrida-farmelhor-rn/','/evento/2026-costa-esmeralda-trail-2026','/evento/2026-costa-esmeralda-trail-2026/','/evento/2026-trail-in-motion-19-chacara-da-bolinha-2026/','/sitemaps/events-history-3.xml','/circuito/fca-corridaderua/?utm_source=seo-verification','/circuito/fca-corridaderua/?ano=2025']
paths += ['/circuito/fca-corridaderua/?distancia=1,42','/circuito/fca-corridaderua/?page=0']
remote='''from pathlib import Path
import json,subprocess,sys,datetime
report={'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pages':[]}
for i,path in enumerate(json.load(sys.stdin)):
 h=Path('/var/tmp/seo-index-public-headers-'+str(i));
 try:
  cp=subprocess.run(['curl','-sS','--max-time','20','-A','RunnerHub-SEO-Verification/1.0','-D',str(h),'-w','\\n%{http_code} %{time_total} %{redirect_url}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=23)
  body,_,stats=cp.stdout.rpartition('\\n');safe_headers='\\n'.join(x for x in h.read_text().splitlines() if not x.lower().startswith('set-cookie:'));report['pages'].append({'path':path,'stats':stats,'body':body,'headers':safe_headers,'returncode':cp.returncode})
 finally:h.unlink(missing_ok=True)
cp=subprocess.run(['curl','-sS','-L','--max-redirs','3','--max-time','20','-o','/dev/null','-w','%{http_code} %{num_redirects} %{url_effective}','https://roadrunners.run/circuito/fca-corridaderua/'],capture_output=True,text=True,timeout=23);report['chain']={'stats':cp.stdout,'returncode':cp.returncode}
cp=subprocess.run(['curl','-sS','--head','--max-time','20','-o','/dev/null','-w','%{http_code} %{redirect_url}','https://roadrunners.run/circuito/fca-corridaderua/'],capture_output=True,text=True,timeout=23);report['head']={'stats':cp.stdout,'returncode':cp.returncode}
report['apache']=[x for x in subprocess.run(['curl','-sS','--max-time','5','http://127.0.0.1/server-status?auto'],capture_output=True,text=True).stdout.splitlines() if x.startswith(('CurrentTime:','BusyWorkers:','IdleWorkers:','ServerUptime:','Load1:'))]
print(json.dumps(report))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=390)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout);(P/'public-after.json').write_text(json.dumps(r,indent=2))
class H(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.t=False;self.c=[];self.a=[];self.d=[];self.robots=[];self.h=False;self.h1=''
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='h1':self.h=True
  if t=='link' and a.get('rel')=='canonical':self.c.append(a.get('href'))
  if t=='link' and a.get('hreflang'):self.a.append([a.get('hreflang'),a.get('href')])
  if t=='meta' and a.get('name')=='description':self.d.append(a.get('content'))
  if t=='meta' and a.get('name')=='robots':self.robots.append(a.get('content'))
 def handle_endtag(self,t):
  if t=='title':self.t=False
  if t=='h1':self.h=False
 def handle_data(self,d):
  if self.t:self.title+=d
  if self.h:self.h1+=d
checks=[]
for i,x in enumerate(r['pages']):
 stats=x['stats'].split(' ',2);code=int(stats[0]);assert x['returncode']==0
 expected=301 if i==2 else 200;assert code==expected,(x['path'],code)
 if i==2:
  assert stats[2]=='https://roadrunners.run/circuito/circuito-catarinense-corrida-de-rua/'
 elif i==12:
  root=E.fromstring(x['body']);assert root.tag=='{http://www.sitemaps.org/schemas/sitemap/0.9}urlset' and len(list(root))>5000
 else:
  a=H();a.feed(x['body']);assert len(a.c)==1 and len(a.d)==1 and a.title
  if i>=13:assert a.c==['https://roadrunners.run/circuito/circuito-catarinense-corrida-de-rua/']
  else:
   b=H();b.feed((P/('public-before-'+str(i)+'.html')).read_text());assert a.c==b.c and a.a==b.a and a.robots==b.robots and a.h1==b.h1
   if i in [5,6]:
    year=x['path'].split('/')[-2];assert year in a.title and year in a.d[0]
   else:assert a.title==b.title and a.d==b.d
 checks.append({'path':x['path'],'status':code,'seconds':float(stats[1])})
assert r['chain']['returncode']==0 and r['chain']['stats']=='200 1 https://roadrunners.run/circuito/circuito-catarinense-corrida-de-rua/'
assert r['head']['returncode']==0 and r['head']['stats']=='301 https://roadrunners.run/circuito/circuito-catarinense-corrida-de-rua/'
receipt={'passed':True,'at':r['at'],'checks':checks,'one_hop_chain':True,'head_redirect':True,'apache':r['apache']}
(P/'public-passed.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(receipt))
