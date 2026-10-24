from pathlib import Path
import json,shlex,subprocess
S=Path(__file__).resolve().parent
paths=['/evento/2026-corrida-das-cores-da-amazonia/','/evento/2027-corrida-das-cores-da-amazonia/']
remote='''from html.parser import HTMLParser
import json,subprocess,sys
class Public(HTMLParser):
 def __init__(self):super().__init__();self.json=False;self.buf='';self.scripts=[];self.registration=[]
 def handle_starttag(self,t,attrs):
  a=dict(attrs)
  if t=='script' and a.get('type')=='application/ld+json':self.json=True;self.buf=''
  if t=='a' and any(x in a.get('href','') for x in ['ticketsports.com.br','ticketagora.com.br','minhasinscricoes.com.br']):self.registration.append(a['href'])
 def handle_data(self,d):
  if self.json:self.buf+=d
 def handle_endtag(self,t):
  if t=='script' and self.json:
   self.scripts.append(json.loads(self.buf));self.json=False

def events(x):
 if isinstance(x,list):
  for v in x:yield from events(v)
 if isinstance(x,dict):
  if 'startDate' in x and 'name' in x:yield x
  for v in x.values():
   if isinstance(v,(dict,list)):yield from events(v)
r=[]
for path in json.load(sys.stdin):
 cp=subprocess.run(['curl','-sS','--max-time','20','--resolve','roadrunners.run:443:127.0.0.1','-w','\\n%{http_code}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=25);assert cp.returncode==0
 html,status=cp.stdout.rsplit('\\n',1);p=Public();p.feed(html);out=[]
 for e in events(p.scripts):
  address=e.get('location',{}).get('address',{});offers=e.get('offers',[]);offers=offers if isinstance(offers,list) else [offers]
  out.append({'name':e['name'],'startDate':e['startDate'],'endDate':e.get('endDate'),'eventStatus':e.get('eventStatus'),'previousStartDate':e.get('previousStartDate'),'city':address.get('addressLocality'),'state':address.get('addressRegion'),'url':e.get('url'),'offer_urls':[o.get('url') for o in offers],'organizer':e.get('organizer',{}).get('name')})
 r.append({'path':path,'status':int(status),'events':out,'registration_links':sorted(set(p.registration))})
print(json.dumps(r))'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=70);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/'amazonia-public.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False,indent=2))
