from pathlib import Path
import base64, hashlib, importlib.util, json, re, shlex, subprocess
S=Path(__file__).resolve().parent;R=Path.cwd()
spec=importlib.util.spec_from_file_location('public',S/'check_public.py')
# The standalone public script has side effects; parse headings directly here.
from html.parser import HTMLParser
class H(HTMLParser):
 def __init__(self):super().__init__();self.n=0
 def handle_starttag(self,t,a):
  if t=='h1':self.n+=1
p={'sets':{}}
for route in ('corridaderua','trailrun'):
 name='circuitocatarinense/'+route+'/index.cfm';text=(S/'candidate'/name).read_text();old=(S/'baseline'/name).read_text()
 queries=lambda t:re.findall(r'<cfquery\b.*?</cfquery>',t,re.S|re.I)
 assert queries(text)==queries(old),name+' queries changed'
 h=H();h.feed(re.sub(r'<!---.*?--->','',text,flags=re.S));assert h.n==1
 p['sets'][route]='\n'.join(re.findall(r'<cfset VARIABLES\.(?:title|description) = .*?/>',text))
helpers=(R/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+r'''
import re
p=json.load(sys.stdin);body='APPLICATION.nomeSite="Road Runners";report={pages=[]};'
for route,code in p['sets'].items():
 assignments=';'.join(re.findall(r'<cfset (VARIABLES\.(?:title|description) = .*?)/>',code))+';'
 body+=assignments+'arrayAppend(report.pages,{route="'+route+'",title=VARIABLES.title,description=VARIABLES.description});'

print(json.dumps(bridge(Path('/var/www/business.roadrunners.run'),body)))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(p),capture_output=True,text=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout);r={k.lower():v for k,v in r.items()};pages=[{k.lower():v for k,v in x.items()} for x in r['pages']]
assert len(pages)==2 and len({x['title'] for x in pages})==2
for x in pages:
 assert '2026' in x['title'] and len(x['description'])>50 and '#APPLICATION' not in x['title']
receipt={'hashes':{n:hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest() for n in json.loads((S/'before.json').read_text())},'watch':json.loads((S/'watch.json').read_text()),'pages':pages,'queries_unchanged':True,'one_h1_each':True}
(S/'candidate-render-passed.json').write_text(json.dumps(receipt,indent=2,ensure_ascii=False))
print(json.dumps({'candidate_metadata_rendered':len(pages),'queries_unchanged':True,'one_h1_each':True},ensure_ascii=False))
