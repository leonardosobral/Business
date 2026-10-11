import subprocess,shlex
from pathlib import Path
code=r'''import subprocess,json,re,collections
from html.parser import HTMLParser
class Table(HTMLParser):
 def __init__(self):super().__init__();self.rows=[];self.row=[];self.cell=None
 def handle_starttag(self,t,a):
  if t=='tr':self.row=[]
  if t=='td':self.cell=''
 def handle_data(self,d):
  if self.cell is not None:self.cell+=d
 def handle_endtag(self,t):
  if t=='td' and self.cell is not None:self.row.append(self.cell);self.cell=None
  if t=='tr' and self.row:self.rows.append(self.row)
p=subprocess.run(['curl','-sS','--max-time','8','http://127.0.0.1/server-status'],capture_output=True,text=True,timeout=11)
a=Table();a.feed(p.stdout);routes=collections.Counter();states=collections.Counter();ages=[]
known=['/busca/','/en/search/','/es/busqueda/','/evento/','/eventos/','/circuitocatarinense/','/desafiocna/','/portal/','/api/','/assets/','/cron/','/noticias/','/videos/','/estado/','/resultados/','/sitemaps/','/server-status']
for row in a.rows:
 if len(row)<10:continue
 request=row[-1];state=row[3];states[state]+=1
 m=re.search(r'(GET|POST|HEAD|OPTIONS)\s+(\S+)',request)
 if m:
  route=m.group(2).split('?')[0];group=next((k for k in known if route.startswith(k)), 'other')
  routes[group]+=1
 if len(row)>5:
  try:ages.append(float(row[5]))
  except ValueError:pass
print(json.dumps({'parsed_workers':sum(states.values()),'states':states,'route_groups_only':routes,'oldest_seconds_since_request_start':max(ages) if ages else None,'curl_exit':p.returncode}))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=8','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],capture_output=True,text=True,timeout=30)
print(p.stdout);print(p.stderr);Path(__file__).with_suffix('.jsonl').write_text(p.stdout)
