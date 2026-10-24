from pathlib import Path
import json,shlex,subprocess
S=Path(__file__).resolve().parent
paths=['/evento/2026-clandestina-ou-travessuras?/','/evento/2026-clandestina-ou-travessuras%3F/','/evento/2026-clandestina-ou-travessuras/','/en/event/2026-clandestina-ou-travessuras%3F/','/es/evento/2026-clandestina-ou-travessuras%3F/']
remote='''import json,subprocess,sys
from html.parser import HTMLParser
class Head(HTMLParser):
 def __init__(self):super().__init__();self.data={'canonical':[],'hreflang':[],'robots':[]};self.intitle=False
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='link' and a.get('rel')=='canonical':self.data['canonical'].append(a.get('href'))
  if t=='link' and a.get('hreflang'):self.data['hreflang'].append([a.get('hreflang'),a.get('href')])
  if t=='meta' and a.get('name')=='robots':self.data['robots'].append(a.get('content'))
  if t=='title':self.intitle=True
 def handle_endtag(self,t):
  if t=='title':self.intitle=False
 def handle_data(self,d):
  if self.intitle:self.data['title']=self.data.get('title','')+d
r=[]
for path in json.load(sys.stdin):
 cp=subprocess.run(['curl','-sS','--max-time','20','--resolve','roadrunners.run:443:127.0.0.1','-D','-','-w','\\n%{http_code}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=25);assert cp.returncode==0
 raw,status=cp.stdout.rsplit('\\n',1);headers,body=raw.split('\\n\\n',1);p=Head();p.feed(body);r.append({'path':path,'status':int(status),'location':[l for l in headers.splitlines() if l.lower().startswith('location:')],**p.data})
print(json.dumps(r))'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=150);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/'legacy-url.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,ensure_ascii=False,indent=2))
