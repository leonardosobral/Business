from pathlib import Path
import json,shlex,subprocess,sys
S=Path(__file__).resolve().parent
mode=sys.argv[1] if len(sys.argv)>1 else 'before';assert mode in ['before','after']
paths=['/en/event/2007-83-corrida-internacional-de-sao-silvestre/','/en/event/2008-84-corrida-internacional-de-sao-silvestre/','/es/evento/2019-95-corrida-internacional-de-sao-silvestre/','/evento/2026-101-corrida-internacional-de-sao-silvestre/']
remote='''from pathlib import Path
from html.parser import HTMLParser
import datetime,hashlib,json,subprocess,sys,tempfile,time
p=json.load(sys.stdin);rows=[]
class Page(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.on=False;self.meta=[];self.h1=0
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='title':self.on=True
  if t=='h1':self.h1+=1
  if t=='meta' and d.get('name') in ['description','robots']:self.meta.append(d)
  if t=='link' and (d.get('rel')=='canonical' or d.get('hreflang')):self.meta.append(d)
 def handle_endtag(self,t):
  if t=='title':self.on=False
 def handle_data(self,d):
  if self.on:self.title+=d
with tempfile.TemporaryDirectory(prefix='seo-latency-',dir='/var/tmp') as d:
 for route in p['paths']:
  for source in ['public','origin']:
   for sample in [1,2]:
    target=Path(d)/'page.html';cmd=['curl','-sS','--max-time','25','-A','RunnerHub-SEO-Latency/1.0','-o',str(target),'-w','%{json}']
    if source=='origin':cmd += ['--resolve','roadrunners.run:443:127.0.0.1']
    cp=subprocess.run(cmd+['https://roadrunners.run'+route],capture_output=True,text=True,timeout=30)
    if cp.returncode:raise RuntimeError('Measurement failed: '+route)
    info=json.loads(cp.stdout);raw=target.read_bytes();parser=Page();parser.feed(raw.decode())
    rows.append({'route':route,'source':source,'sample':sample,'http':info['http_code'],'ttfb_s':info['time_starttransfer'],'total_s':info['time_total'],'bytes':len(raw),'h1':parser.h1,'title':parser.title,'metadata_sha256':hashlib.sha256(json.dumps(parser.meta,sort_keys=True).encode()).hexdigest()})
    time.sleep(1)
print(json.dumps({'checkedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'rows':rows}))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'paths':paths}),capture_output=True,text=True,timeout=150)
if cp.returncode:raise RuntimeError(cp.stderr[-2200:])
r=json.loads(cp.stdout);assert len(r['rows'])==16 and all(x['http']==200 for x in r['rows'])
(S/('latency-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
if mode=='after':
 before=json.loads((S/'latency-before.json').read_text())
 for old,new in zip(before['rows'],r['rows']):
  assert (old['route'],old['source'],old['sample'])==(new['route'],new['source'],new['sample'])
  assert (old['metadata_sha256'],old['title'],old['h1'])==(new['metadata_sha256'],new['title'],new['h1'])
import statistics
report={'samples':len(r['rows']),'metadata_preserved':mode=='after','public_median_s':statistics.median(x['total_s'] for x in r['rows'] if x['source']=='public'),'origin_median_s':statistics.median(x['total_s'] for x in r['rows'] if x['source']=='origin'),'max_public_s':max(x['total_s'] for x in r['rows'] if x['source']=='public'),'max_origin_s':max(x['total_s'] for x in r['rows'] if x['source']=='origin')}
if mode=='after':
 report['previous_origin_median_s']=statistics.median(x['total_s'] for x in before['rows'] if x['source']=='origin')
 report['previous_public_median_s']=statistics.median(x['total_s'] for x in before['rows'] if x['source']=='public')
 (S/'public-passed.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,ensure_ascii=False))
