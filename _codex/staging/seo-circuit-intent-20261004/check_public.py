from pathlib import Path
from html.parser import HTMLParser
import importlib.util, hashlib, json, subprocess, sys
STAGE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('meta',STAGE.parent/'seo-semrush-fixes-20261004/check_public.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
class Tables(HTMLParser):
 def __init__(self):super().__init__();self.tables=[];self.current=None;self.row=None;self.cell=None
 def handle_starttag(self,tag,attrs):
  if tag=='table':self.current=[]
  elif self.current is not None and tag=='tr':self.row=[]
  elif self.row is not None and tag in ('td','th'):self.cell=[]
 def handle_data(self,data):
  if self.cell is not None:self.cell.append(data)
 def handle_endtag(self,tag):
  if tag in ('td','th') and self.cell is not None:
   self.row.append(' '.join(' '.join(self.cell).split()));self.cell=None
  elif tag=='tr' and self.row is not None:
   self.current.append(self.row);self.row=None
  elif tag=='table' and self.current is not None:
   # Public rows held in memory only. Persist count + digest, never names.
   self.tables.append({'rows':len(self.current),'sha256':hashlib.sha256(json.dumps(self.current,ensure_ascii=False).encode()).hexdigest()});self.current=None

class Headings(HTMLParser):
 def __init__(self):super().__init__();self.h1=[];self.parts=None
 def handle_starttag(self,tag,attrs):
  if tag=='h1':self.parts=[]
 def handle_data(self,d):
  if self.parts is not None:self.parts.append(d)
 def handle_endtag(self,tag):
  if tag=='h1' and self.parts is not None:self.h1.append(' '.join(' '.join(self.parts).split()));self.parts=None
mode=sys.argv[1];assert mode in ('before','after')
results=[]
for route in ('corridaderua','trailrun'):
 u='https://roadrunners.run/circuitocatarinense/'+route+'/'
 cp=subprocess.run(['curl','-sS','--max-time','35','-w','\n%{http_code}\n%{time_total}',u],capture_output=True,text=True,timeout=40)
 if cp.returncode:raise RuntimeError(cp.stderr)
 body,code,elapsed=cp.stdout.rsplit('\n',2);m=mod.Meta();m.feed(body);h=Headings();h.feed(body);t=Tables();t.feed(body)
 r={'url':u,'route':route,'status':int(code),'seconds':float(elapsed),'canonical':m.canonical,'title':m.title,'description':m.description,'robots':m.robots,'h1':h.h1,'tables':t.tables,'cf_error':'Error Occurred While Processing Request' in body}
 results.append(r)
(STAGE/('public-'+mode+'.json')).write_text(json.dumps(results,ensure_ascii=False,indent=2))
errors=[]
for r in results:
 if r['status']!=200 or r['cf_error']:errors.append(r['route']+': HTTP/CF error')
 if len(r['h1'])!=1:errors.append(r['route']+': expected one H1, found '+str(len(r['h1'])))
 term='Corrida de Rua' if r['route']=='corridaderua' else 'Trail Run'
 if term not in r['title'] or '2026' not in r['title']:errors.append(r['route']+': title does not distinguish modality/year')
 if len(r['description'])!=1 or len(r['description'][0])<50:errors.append(r['route']+': generic description')
 if mode=='after':
  before=next(x for x in json.loads((STAGE/'public-before.json').read_text()) if x['route']==r['route'])
  for k in ('canonical','robots','tables'):
   if r[k]!=before[k]:errors.append(r['route']+': baseline '+k+' changed')
if len({r['title'] for r in results})!=2:errors.append('duplicate titles')
if len({tuple(r['description']) for r in results})!=2:errors.append('duplicate descriptions')
print(json.dumps({'mode':mode,'errors':errors,'pages':[{k:v for k,v in r.items() if k!='tables'} for r in results]},ensure_ascii=False))
if errors:raise SystemExit(1)
