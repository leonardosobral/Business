from config import *
from html.parser import HTMLParser
import hashlib,json,shlex,subprocess,sys
mode=sys.argv[1];assert mode in ['before','after']
paths=['/','/en/','/es/','/estado/sp/','/estado/ba/','/estado/sc/','/estado/ba/salvador/','/estado/sc/florianopolis/','/busca/','/en/search/','/es/busqueda/','/ajuda/','/privacidade/','/atendimento/','/evento/2026-corrida-night-run-vitoria-airport/','/en/event/2026-corrida-night-run-vitoria-airport/','/es/evento/2026-corrida-night-run-vitoria-airport/','/maratona/maratona-internacional-de-sao-paulo/']
remote='''import json,subprocess,sys,datetime,hashlib
from concurrent.futures import ThreadPoolExecutor
p=json.load(sys.stdin)
def get(path):
 cp=subprocess.run(['curl','-sS','--path-as-is','--max-time','25','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code} %{content_type} %{redirect_url}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=29)
 body,_,stats=cp.stdout.rpartition('\\n');return {'path':path,'body':body,'stats':stats,'returncode':cp.returncode}
with ThreadPoolExecutor(max_workers=2) as pool:rows=list(pool.map(get,p['paths']))
print(json.dumps({'at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'rows':rows}))'''
payload={'paths':paths+['/'+n+'?v='+VERSION for n in GENERATED] if mode=='after' else paths}
cp=subprocess.run(SSH+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=260)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout)
class Page(HTMLParser):
 def __init__(self):super().__init__();self.meta=[];self.title='';self.h1='';self.jsonld=[];self.assets=[];self.in_title=False;self.in_h1=False;self.in_json=False;self.jsontext=''
 def handle_starttag(self,t,attrs):
  a=dict(attrs)
  if t=='title':self.in_title=True
  if t=='h1':self.in_h1=True
  if t=='meta' and a.get('name') in ['description','robots']:self.meta.append([a.get('name'),a.get('content')])
  if t=='link' and (a.get('rel')=='canonical' or a.get('hreflang')):self.meta.append([a.get('rel'),a.get('href'),a.get('hreflang')])
  if t=='script' and a.get('type')=='application/ld+json':self.in_json=True;self.jsontext=''
  if t in ['script','link']:
   key='src' if t=='script' else 'href';url=a.get(key,'')
   if any('/'+n+'?' in url for n in SOURCES+GENERATED):self.assets.append({'tag':t,'attrs':a,'url':url,'key':key})
 def handle_endtag(self,t):
  if t=='title':self.in_title=False
  if t=='h1':self.in_h1=False
  if t=='script' and self.in_json:self.jsonld.append(json.loads(self.jsontext));self.in_json=False
 def handle_data(self,d):
  if self.in_title:self.title+=d
  if self.in_h1:self.h1+=d
  if self.in_json:self.jsontext+=d
old=json.loads((S/'public-before.json').read_text()) if mode=='after' else None
for i,row in enumerate(r['rows']):
 assert row['returncode']==0 and (row['stats'].startswith('200 ') or (row['path']=='/atendimento/' and row['stats'].startswith('302 '))),(row['path'],row['stats'])
 body=row.pop('body')
 if i<len(paths):
  assert 'Error Occurred While Processing Request' not in body,row['path']
  page=Page();page.feed(body);row['meta']={'title':page.title,'h1':page.h1,'meta':page.meta,'jsonld':page.jsonld};row['assets']=page.assets
  if mode=='after':
   prev=old['rows'][i];assert prev['path']==row['path'] and prev['meta']==row['meta'] and prev['stats']==row['stats'],row['path']+' metadata/status changed'
   assert len(prev['assets'])==len(row['assets']),row['path']+' resource count changed'
   for a,b in zip(prev['assets'],row['assets']):
    source=next(n for n in SOURCES if '/'+n+'?' in a['url']);target=GENERATED[SOURCES.index(source)]
    expected=a['url'].split('/'+source+'?')[0]+'/'+target+'?v='+VERSION
    assert b['url']==expected,(row['path'],a['url'],b['url'])
    assert {k:v for k,v in a['attrs'].items() if k!=a['key']}=={k:v for k,v in b['attrs'].items() if k!=b['key']},row['path']+' script attributes changed'
 else:
  name=GENERATED[i-len(paths)];expected=(S/'candidate/rr'/name).read_bytes()
  row['sha256']=hashlib.sha256(body.encode()).hexdigest();assert row['sha256']==hashlib.sha256(expected).hexdigest(),name+' public hash mismatch'
  assert ('text/css' if name.endswith('.css') else 'javascript') in row['stats'],name+' MIME mismatch'
(S/('public-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
receipt={'at':r['at'],'passed':True,'public_pages':len(paths),'asset_hashes':len(GENERATED) if mode=='after' else 0,'page_asset_references':sum(len(x['assets']) for x in r['rows'][:len(paths)]),'metadata_preserved':mode=='after'}
if mode=='after':(S/'public-passed.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt))
