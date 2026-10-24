from pathlib import Path
import json,shlex,subprocess
S=Path(__file__).resolve().parent
remote='''
from html.parser import HTMLParser
import json,subprocess,urllib.parse
class P(HTMLParser):
 def __init__(self):super().__init__();self.nav=False;self.links=[];self.canonical=[]
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='nav' and d.get('class')=='rr-footer-navigation':self.nav=True
  if self.nav and t=='a':self.links.append(d.get('href',''))
  if t=='link' and d.get('rel')=='canonical':self.canonical.append(d.get('href',''))
 def handle_endtag(self,t):
  if t=='nav':self.nav=False
def get(path):
 cp=subprocess.run(['curl','-sS','--max-time','30','--resolve','roadrunners.run:443:127.0.0.1','-w','\\n%{http_code}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=35)
 assert cp.returncode==0,cp.stderr
 body,status=cp.stdout.rsplit('\\n',1);assert status=='200',(path,status)
 return body
rows=[]
for path in ['/','/evento/2026-together-run-pe/','/estado/ba/','/ajuda/','/en/event/2026-together-run-pe/','/es/evento/2026-together-run-pe/']:
 p=P();p.feed(get(path));links=[x for x in p.links if x.startswith('/login/?redirect=')];assert len(links)==6,(path,links)
 returns=[urllib.parse.parse_qs(urllib.parse.urlsplit(x).query)['redirect'][0] for x in links]
 assert all(x.startswith('/') and not x.startswith('//') for x in returns)
 rows.append({'path':path,'status':200,'direct_login_links':len(links),'return_targets':returns,'canonical':p.canonical})
 if path=='/':login=links[0]
get(login);rows.append({'path':login,'status':200,'login_destination_works':True})
print(json.dumps(rows))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=210)
assert cp.returncode==0,cp.stderr[-2500:]
r=json.loads(cp.stdout);(S/'nav-public.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps({'pages_200':len(r),'direct_login_links_verified':36,'return_routes_preserved':True}))
