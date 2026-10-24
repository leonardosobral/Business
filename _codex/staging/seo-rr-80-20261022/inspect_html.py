from pathlib import Path
import json,shlex,subprocess
S=Path(__file__).resolve().parent
remote='''
from html.parser import HTMLParser
import collections,json,sys,time,urllib.request
class SizeParser(HTMLParser):
 def __init__(self):super().__init__();self.stack=[];self.blocks=[];self.total=collections.Counter();self.text=[];self.links=[]
 def handle_starttag(self,t,a):
  d=dict(a);raw=self.get_starttag_text();size=len(raw.encode());self.total['markup']+=size
  for node in self.stack:node['bytes']+=size
  if t not in {'area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr'}:
   self.stack.append({'tag':t,'id':d.get('id',''),'class':d.get('class','')[:90],'src':d.get('src',''),'bytes':size,'text_bytes':0})
  if t=='a' and 'href' in d:self.links.append(d['href'])
 def handle_endtag(self,t):
  for n in self.stack:n['bytes']+=len(t)+3
  for i in range(len(self.stack)-1,-1,-1):
   if self.stack[i]['tag']==t:
    self.blocks.extend(self.stack[i:]);del self.stack[i:];break
 def handle_data(self,d):
  n=len(d.encode())
  for node in self.stack:node['bytes']+=n
  if not any(x['tag'] in ['script','style','svg','noscript'] for x in self.stack):
   text=len(' '.join(d.split()).encode())
   for node in self.stack:node['text_bytes']+=text
   self.total['text']+=text
rows=[]
for path in ['/','/evento/2026-together-run-pe/','/estado/ba/','/ajuda/']:
 start=time.monotonic()
 with urllib.request.urlopen(urllib.request.Request('http://127.0.0.1'+path,headers={'Host':'roadrunners.run','User-Agent':'RunnerHub-SEO/1.0'}),timeout=45) as r:body=r.read(5000000).decode('utf-8');status=r.status
 p=SizeParser();p.feed(body)
 groups={tag:sum(b['bytes'] for b in p.blocks if b['tag']==tag) for tag in ['script','style','svg']}
 groups.update({tag+'_count':sum(b['tag']==tag for b in p.blocks) for tag in ['script','style','svg']})
 rows.append({'path':path,'status':status,'html_bytes':len(body.encode()),'visible_text_bytes':p.total['text'],'groups':groups,'largest':[b for b in sorted(p.blocks,key=lambda x:x['bytes'],reverse=True) if b['tag'] not in ['html','body']][:14],'login_links':sum('/login/' in x for x in p.links),'private_links':{key:sum(key in x for x in p.links) for key in ['/atividades/','/agenda/','/atendimento/','/atleta/','/resultados/']},'seconds':round(time.monotonic()-start,3)})
print(json.dumps(rows))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=195)
assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/'html-before.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
