from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from html.parser import HTMLParser
import json,re,subprocess,sys,html
S=Path(__file__).resolve().parent;mode=sys.argv[1]
triage=json.loads((S.parent/'seo-plan-autonomous-20261004/semrush-accessibility-triage.json').read_text())
rows=[{'kind':'poster',**x} for x in triage['110']['data']['data']]
rows += [{'kind':'heading','source_url':u} for u in ['https://roadrunners.run/org/sportsland/','https://roadrunners.run/circuito/live-run-xp/','https://roadrunners.run/circuito/fca-corridaderua/','https://roadrunners.run/login/?redirect=/resultados/index.cfm']]
class Parser(HTMLParser):
 def __init__(self):super().__init__();self.images=[];self.h1=0;self.heading=[];self.in_h1=False
 def handle_starttag(self,t,a):
  if t=='img':self.images.append(dict(a))
  if t=='h1':self.h1+=1;self.in_h1=True
 def handle_endtag(self,t):
  if t=='h1':self.in_h1=False
 def handle_data(self,d):
  if self.in_h1:self.heading.append(d)
def check(pair):
 i,c=pair;cp=subprocess.run(['curl','-sS','--max-time','25','-w','\n%{http_code}',c['source_url']],capture_output=True,text=True);h,code=cp.stdout.rsplit('\n',1);x=Parser();x.feed(h)
 m={'title':re.findall(r'<title>(.*?)</title>',h,re.S),'meta':re.findall(r'<(?:meta[^>]*name="(?:description|robots)"[^>]*|link[^>]*(?:canonical|hreflang)[^>]*)>',h)}
 (S/f'public-{mode}-{i}.html').write_text(h)
 tests={'http200':code=='200','no_cf_error':'Error Occurred While Processing Request' not in h}
 if c['kind']=='poster':
  poster=[a for a in x.images if a.get('src')==c['target_url']];tests['poster_present']=len(poster)==1;tests['poster_alt']=len(poster)==1 and bool(poster[0].get('alt','').strip())
 else:tests['one_h1']=x.h1==1;tests['h1_has_name']=bool(''.join(x.heading).strip())
 if mode=='before':(S/f'metadata-before-{i}.json').write_text(json.dumps(m,ensure_ascii=False))
 else:tests['metadata_unchanged']=m==json.loads((S/f'metadata-before-{i}.json').read_text())
 return {'url':c['source_url'],'kind':c['kind'],'http':code,'h1':x.h1,'heading':''.join(x.heading).strip(),'checks':tests}
with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(check,enumerate(rows)))
(S/f'public-{mode}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));fails=[x for x in results if not all(x['checks'].values())];print(json.dumps({'urls':len(results),'fail_count':len(fails),'failed_urls':[x['url'] for x in fails]}));
if mode=='before':assert all(x['checks']['http200'] and x['checks']['no_cf_error'] for x in results)
else:assert not fails
