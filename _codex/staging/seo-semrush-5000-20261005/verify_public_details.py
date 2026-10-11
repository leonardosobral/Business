from pathlib import Path
from urllib.parse import quote,urlsplit,unquote
from html.parser import HTMLParser
from datetime import datetime
import json,shlex,subprocess,html,re
P=Path(__file__).resolve().parent
class Page(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.canonical=[];self.alternates=[];self.in_title=False;self.title='';self.schema=[];self.in_schema=False
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='a':self.links.append(a.get('href',''))
  if tag=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if tag=='link' and a.get('rel')=='alternate':self.alternates.append((a.get('hreflang'),a.get('href')))
  if tag=='title':self.in_title=True
  if tag=='script' and a.get('type')=='application/ld+json':self.in_schema=True
 def handle_endtag(self,tag):
  if tag=='title':self.in_title=False
  if tag=='script':self.in_schema=False
 def handle_data(self,s):
  if self.in_title:self.title+=s
  if self.in_schema:self.schema.append(s)
rows=json.loads((P/'public-after.json').read_text());checks=[]
for x in rows:
 p=Page();p.feed(x['response'])
 if x['kind']=='parent':
  if x['path'].startswith('/timer/'):
   assert 'https://roadrunners.run'+x['path'] in p.links or x['path'] in p.links,(x['path'],'supplier self-link missing')
   assert not any('/assessoria/' in h for h in p.links),x['path']
  for h in p.links:
   if '/evento/' in h:assert not any(c in h for c in ['"','\n','\r']),h
  checks.append({'path':x['path'],'hrefs':len(p.links),'links_safe':True})
 if x['kind']=='case':
  loc=re.search(r'^location:\s*(.+)$',x['response'],re.I|re.M).group(1).strip();assert loc!=x['path'] and unquote(loc)!=unquote(x['path']),loc
 if x['kind']=='event':
  assert len(p.canonical)==1,(x['path'],p.canonical)
  assert unquote(urlsplit(p.canonical[0]).path)==unquote(x['path']),(x['path'],p.canonical)
  tag=next(e['tag'] for e in json.loads((P/'inspection.json').read_text())['events'] if e['id_evento']==x['id'])
  assert dict(p.alternates)=={lang:'https://roadrunners.run'+prefix+quote(tag,safe='')+'/' for lang,prefix in [('pt-BR','/evento/'),('en','/en/event/'),('es','/es/evento/'),('x-default','/evento/')]},p.alternates
# Check actual links to special tags in the city calendars.
links=[h for x in rows if x['kind']=='parent' for h in (lambda p:(p.feed(x['response']),p.links)[1])(Page())]
events=json.loads((P/'inspection.json').read_text())['events']
for ident in [41252,47423,48153,48167]:
 e=next(e for e in events if e['id_evento']==ident)
 target='/evento/'+e['tag']+'/'
 assert any(unquote(urlsplit(h).path)==target for h in links),(ident,'canonical link absent')
checks.append({'special_event_links':4,'hrefs_verified':True})
live=[e for e in events if e['id_evento'] in [37519,37521,37522,37524,37567,39734]]
cases=[{'path':prefix+('/event/' if prefix=='/en' else '/evento/')+quote(e['tag'],safe='')+'/','kind':'title','event':e,'lang':prefix or 'pt'} for e in live for prefix in ['', '/en','/es']]
cases += [{'path':'/includes/estrutura/event_title_date.cfm','kind':'direct'}]
for prefix in ['/en','/es']:
 for s in ['2025-live-run-xp-brasilia-i-2025','2025-live-run-xp-brasilia-ii-2025','2026-endorfina-run-santo-andre-ii']:
  cases.append({'path':prefix+('/event/' if prefix=='/en' else '/evento/')+s+'/','kind':'redirect','lang':prefix})
remote='''import json,subprocess,sys
r=[]
for x in json.load(sys.stdin):
 cp=subprocess.run(['curl','-sS','--max-time','30','-A','RunnerHub-SEO-Verification/1.0','-D','-','-w','\\n%{http_code}','https://roadrunners.run'+x['path']],capture_output=True,text=True,timeout=35)
 body,_,status=cp.stdout.rpartition('\\n');r.append(dict(x,status=status,response=body,returncode=cp.returncode))
print(json.dumps(r))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(cases),capture_output=True,text=True,timeout=300)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
extra=json.loads(cp.stdout);(P/'public-details-raw.json').write_text(json.dumps(extra,indent=2,ensure_ascii=False))
for x in extra:
 assert x['returncode']==0
 if x['kind']=='title':
  assert x['status']=='200' and 'Error Occurred While Processing Request' not in x['response'],x['path']
  p=Page();p.feed(x['response']);e=x['event'];date=datetime.strptime(e['data_inicial'],'%Y-%m-%d').strftime('%d/%m/%Y')
  assert date in p.title,(x['path'],p.title)
  assert len(p.title)<=70,(p.title,len(p.title))
  assert len(p.canonical)==1 and urlsplit(p.canonical[0]).path==x['path'],(x['path'],p.canonical)
  assert dict(p.alternates)=={lang:'https://roadrunners.run'+prefix+quote(e['tag'],safe='')+'/' for lang,prefix in [('pt-BR','/evento/'),('en','/en/event/'),('es','/es/evento/'),('x-default','/evento/')]},p.alternates
  assert e['data_inicial'] in ''.join(p.schema),(x['path'],'structured date absent')
  checks.append({'path':x['path'],'title':p.title,'length':len(p.title),'date':date,'canonical_verified':True})
 elif x['kind']=='redirect':
  assert x['status']=='301',x
  loc=re.search(r'^location:\s*(.+)$',x['response'],re.I|re.M).group(1).strip()
  assert urlsplit(loc).path.startswith(x['lang']+('/event/' if x['lang']=='/en' else '/evento/')) and loc!=x['path'],loc
  checks.append({'path':x['path'],'location':loc,'status':301})
 else:assert x['status']=='404',x
for lang in ['pt','/en','/es']:
 titles=[x['title'] for x in checks if 'title' in x and (('pt' if not x['path'].startswith(('/en/','/es/')) else '/'+x['path'].split('/')[1])==lang)]
 assert len(titles)==6 and len(set(titles))==6,(lang,titles)
receipt={'http_checks':len(rows)+len(extra),'special_links':4,'supplier_links':5,'unique_titles_per_language':6,'checks':checks}
(P/'public-details-passed.json').write_text(json.dumps(receipt,indent=2,ensure_ascii=False));print(json.dumps({k:v for k,v in receipt.items() if k!='checks'}))
