from pathlib import Path
from html.parser import HTMLParser
import json,subprocess,shlex,base64,sys
P=Path(__file__).resolve().parent;ROOT=P.parents[2];mode=sys.argv[1] if len(sys.argv)>1 else 'before';assert mode in ['before','after']
issues=json.loads((ROOT/'_codex/staging/seo-indexacao-prioridades-20261005/issues.json').read_text())
urls=list(dict.fromkeys(x['source_url'] for r in issues['reports'] if r['id']!=6 for x in r['data']['data']))
urls=[x.replace(' ','%20') for x in urls]
urls+=['https://roadrunners.run/privacidade/','https://roadrunners.run/en/privacy/','https://roadrunners.run/es/privacidad/','https://roadrunners.run/evento/2026-1-edicao-corrida-farmelhor-rn/','https://roadrunners.run/en/event/2026-1-edicao-corrida-farmelhor/','https://roadrunners.run/en/event/2026-1-edicao-corrida-farmelhor-rn/','https://roadrunners.run/en/event/2026-costa-esmeralda-trail-2026/','https://roadrunners.run/es/evento/2026-costa-esmeralda-trail-2026/']
urls=list(dict.fromkeys(urls))
names={'rr':['evento/index.cfm','includes/estrutura/head.cfm','includes/estrutura/event_title_date.cfm','includes/backend/backend_evento.cfm','includes/backend/backend_require_login.cfm','privacidade/index.cfm','includes/estrutura/footer.cfm','includes/estrutura/side_footer.cfm','atleta/index.cfm','services/EventRedirectService.cfc'], 'business':['portal/includes/seo_queue_data.cfm','portal/includes/seo_semrush_data.cfm','portal/conteudo/seo_semrush.cfm']}
remote='''import json,subprocess,sys,base64,datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
p=json.load(sys.stdin)
def get(url):
 cp=subprocess.run(['curl','-sS','--path-as-is','--max-time','20','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code} %{time_total} %{redirect_url}',url],capture_output=True,text=True,timeout=23);body,_,stats=cp.stdout.rpartition('\\n');return {'url':url,'body':body,'stats':stats,'returncode':cp.returncode}
with ThreadPoolExecutor(max_workers=2) as pool:pages=list(pool.map(get,p['urls']))
files={}
for group,names in p['files'].items():
 root=Path('/var/www/roadrunners.com.br') if group=='rr' else Path('/var/www/business.roadrunners.run')
 for n in names:
  if (root/n).is_file():files[group+':'+n]=base64.b64encode((root/n).read_bytes()).decode()
print(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pages':pages,'files':files}))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'urls':urls,'files':names if mode=='before' else {}}),capture_output=True,text=True,timeout=250)
assert cp.returncode==0,cp.stderr[-2000:];r=json.loads(cp.stdout)
for key,b in r.pop('files').items():
 group,n=key.split(':',1);dest=P/'baseline'/group/n;dest.parent.mkdir(parents=True,exist_ok=True);assert not dest.exists();dest.write_bytes(base64.b64decode(b))
class H(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.h1='';self.description=[];self.canonical=[];self.alternates=[];self.robots=[];self.links=[];self.t=False;self.h=False;self.text=[]
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='h1':self.h=True
  if t=='meta' and a.get('name')=='description':self.description.append(a.get('content'))
  if t=='meta' and a.get('name')=='robots':self.robots.append(a.get('content'))
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if t=='link' and a.get('hreflang'):self.alternates.append([a.get('hreflang'),a.get('href')])
  if t=='a' and a.get('href'):self.links.append(a['href'])
 def handle_endtag(self,t):
  if t=='title':self.t=False
  if t=='h1':self.h=False
 def handle_data(self,d):
  if self.t:self.title+=d
  if self.h:self.h1+=d
for i,x in enumerate(r['pages']):
 body=x.pop('body');h=H();h.feed(body);(P/(mode+'-'+str(i)+'.html')).write_text(body)
 x.update({k:getattr(h,k) for k in ['title','h1','description','canonical','alternates','robots','links']})
(P/(mode+'-pages.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
print(json.dumps({'at':r['at'],'pages':len(r['pages']),'results':[{k:v for k,v in x.items() if k not in ['links','alternates']} for x in r['pages']]},ensure_ascii=False))
