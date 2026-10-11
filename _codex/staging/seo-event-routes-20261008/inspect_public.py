import concurrent.futures,json,time,urllib.request
from html.parser import HTMLParser
from pathlib import Path
S=Path(__file__).resolve().parent
paths=['/evento/2025-jurere-night-run-hard-rock-cafe-florianopolis-2025/','/evento/2026-jurere-night-run-hard-rock-cafe-florianopolis-2026/','/evento/2025-meia-maratona-internacional-de-florianopolis-oakberry-2025/','/evento/2027-meia-maratona-internacional-de-florianopolis-oakberry-2027/','/estado/pr/','/estado/pb/lastro/','/estado/sp/campinas/']
class Page(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.in_title=False;self.links=[];self.a=None
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='title':self.in_title=True
  if t=='a':self.a={'href':d.get('href'),'text':''}
 def handle_endtag(self,t):
  if t=='title':self.in_title=False
  if t=='a' and self.a:self.links.append(self.a);self.a=None
 def handle_data(self,d):
  if self.in_title:self.title+=d
  if self.a:self.a['text']+=d
rows=[]
for path in paths:
 req=urllib.request.Request('https://roadrunners.run'+path,headers={'User-Agent':'RunnerHub-SEO-Verification/1.0'})
 with urllib.request.urlopen(req,timeout=35) as response:
  parser=Page();parser.feed(response.read().decode());rows.append({'path':path,'status':response.status,'title':parser.title,'suspect_links':[l for l in parser.links if l['href'] and (l['href'].endswith('/2026-') or 'aniversario-do-grupo-corrida' in l['href'] or 'rock-n-run' in l['href'])]})
 time.sleep(1)
(S/'public-inspection.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2));print(json.dumps(rows,ensure_ascii=False))
