from pathlib import Path
import json,subprocess,shlex,hashlib
from html.parser import HTMLParser
from html import unescape
import xml.etree.ElementTree as ET
S=Path(__file__).resolve().parent
paths=['/calculadora-de-pace/','/estado/pr/','/estado/pr/curitiba/','/estado/df/','/estado/df/brasilia/','/api/eventos.cfm?tag=PR&cidade=curitiba&distancia=5,5&page=0','/sitemaps/static.xml','/assets/js/runnerhub-pace.min.js?v=20261025b','/assets/css/runnerhub-pace.min.css?v=20261025a','/assets/css/runnerhub-regionais.min.css?v=20261025a']
remote='''import json,sys,subprocess
p=json.load(sys.stdin);out={}
for path in p:
 cp=subprocess.run(['curl','-sS','--max-time','50','-D','-','-w','\\n%{http_code}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=55)
 assert cp.returncode==0
 full,status=cp.stdout.rsplit('\\n',1);headers,body=full.split('\\n\\n',1);out[path]={'status':int(status),'headers':headers,'body':body}
print(json.dumps(out))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(paths),capture_output=True,text=True,timeout=590)
assert cp.returncode==0,cp.stderr[-2000:];r=json.loads(cp.stdout);summary={}
for name,v in r.items():
 assert v['status']==200,(name,v['status']);assert 'Error Occurred While Processing Request' not in v['body'],name
 summary[name]={'status':v['status'],'bytes':len(v['body'].encode())}
 if name.startswith('/assets/'):
  source=S/'candidate'/name[1:].split('?')[0];assert source.read_text()==v['body'],name
 if name.startswith('/estado/') or name.startswith('/api/'):
  assert 'data-regional-summary' in v['body'],name
  import re
  summary[name]['events']=int(re.search(r'data-regional-total="(\d+)"',v['body'])[1])
 if name.startswith('/calculadora'):
  assert 'data-pace-form' in v['body'] and 'noindex' not in v['headers'].lower()
  assert 'https://roadrunners.run/calculadora-de-pace/' in unescape(v['body'])
 if name.startswith('/sitemaps'):
  doc=ET.fromstring(v['body']);ns={'s':'http://www.sitemaps.org/schemas/sitemap/0.9'};matches=[u for u in doc.findall('s:url',ns) if u.findtext('s:loc',namespaces=ns)=='https://roadrunners.run/calculadora-de-pace/'];assert len(matches)==1;assert matches[0].findtext('s:lastmod',namespaces=ns)=='2026-10-25';summary[name]['calculatorInSitemap']=True
(S/'public-verified.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary,indent=2))
# Save just public event links for follow-up checks, without the full shared page.
class Links(HTMLParser):
 def __init__(self):super().__init__();self.urls=[]
 def handle_starttag(self,t,a):
  h=dict(a).get('href','')
  if t=='a' and '/evento/' in h and h not in self.urls:self.urls.append(h)
p=Links();p.feed(r['/estado/pr/curitiba/']['body']);(S/'public-event-links.json').write_text(json.dumps(p.urls[:3],indent=2)+'\n')
