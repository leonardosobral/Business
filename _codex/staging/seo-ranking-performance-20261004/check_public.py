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
mode=sys.argv[1];assert mode in ('before','after')
url='https://roadrunners.run/circuitocatarinense/corridaderua/'
urls=[url] if mode=='before' else [url,url,'https://roadrunners.run/circuitocatarinense/trailrun/','https://roadrunners.run/en/search/?distancia_inicio=5&distancia_fim=5&busca_mode=ai','https://roadrunners.run/']
results=[]
for u in urls:
 cp=subprocess.run(['curl','-sS','--max-time','45','-w','\n%{http_code}\n%{time_total}',u],capture_output=True,text=True,timeout=50)
 if cp.returncode:raise RuntimeError(cp.stderr)
 body,code,elapsed=cp.stdout.rsplit('\n',2);m=mod.Meta();m.feed(body);t=Tables();t.feed(body)
 r={'url':u,'status':int(code),'seconds':float(elapsed),'canonical':m.canonical,'title':m.title,'robots':m.robots,'cf_error':'Error Occurred While Processing Request' in body,'tables':t.tables}
 assert r['status']==200 and not r['cf_error'],r
 results.append(r)
(STAGE/('public-'+mode+'.json')).write_text(json.dumps(results,ensure_ascii=False,indent=2))
if mode=='after':
 before=json.loads((STAGE/'public-before.json').read_text())[0]
 for r in results[:2]:
  for k in ('canonical','title','robots','tables'):assert r[k]==before[k],(k,r[k],before[k])
  assert r['seconds']<2,r
print(json.dumps(results,ensure_ascii=False))
