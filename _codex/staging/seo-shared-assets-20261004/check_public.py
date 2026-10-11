from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib,html,json,re,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['before','after']
paths=['/','/en/','/es/','/estado/sp/','/videos/canal/road-runners/','/circuitocatarinense/corridaderua/','/circuitocatarinense/trailrun/']
files=json.loads((S/'build.json').read_text())['files'];meta=lambda t:{'canonical':re.findall(r'<link[^>]*rel="canonical"[^>]*>',t),'alternates':re.findall(r'<link[^>]*hreflang[^>]*>',t),'jsonld':[json.loads(x) for x in re.findall(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',t,re.S|re.I)]}
def run(route):
 cp=subprocess.run(['curl','-sS','--max-time','25','-w','\n%{http_code}','https://roadrunners.run'+route],capture_output=True,text=True,timeout=30)
 t,code=cp.stdout.rsplit('\n',1);refs=html.unescape(t);assets=[f['target'] for f in files if '/'+f['target']+'?' in refs]
 return {'route':route,'status':code,'cf_error':'Error Occurred While Processing Request' in t,'meta':meta(t),'minified_assets':assets}
with ThreadPoolExecutor(max_workers=2) as p:pages=list(p.map(run,paths))
(S/('public-'+mode+'.json')).write_text(json.dumps(pages,indent=2,ensure_ascii=False));errors=[]
for page in pages:
 if page['status']!='200' or page['cf_error']:errors.append(page['route']+': HTTP/CF failure')
 if len(page['minified_assets'])!=5:errors.append(page['route']+': expected five minified assets, found'+str(len(page['minified_assets'])))
 if mode=='after':
  old=next(x for x in json.loads((S/'public-before.json').read_text()) if x['route']==page['route'])
  if old['meta']!=page['meta']:errors.append(page['route']+': metadata changed')
if mode=='after':
 for f in files:
  cp=subprocess.run(['curl','-sS','--max-time','20','-w','\n%{http_code}','https://roadrunners.run/'+f['target']+'?v=20261004seo'],capture_output=True,timeout=25)
  body,code=cp.stdout.rsplit(b'\n',1)
  if code!=b'200' or hashlib.sha256(body).hexdigest()!=f['output_sha256']:errors.append(f['target']+': asset response/hash mismatch')
print(json.dumps({'mode':mode,'pages':len(pages),'asset_hashes_checked':len(files) if mode=='after' else 0,'errors':errors},ensure_ascii=False))
if errors:raise SystemExit(1)
