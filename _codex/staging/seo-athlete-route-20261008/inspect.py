from pathlib import Path
from html.parser import HTMLParser
import base64,hashlib,json,shlex,subprocess
R=Path('/Users/Shared/Projects/RunnerHub/RoadRunners');B=R.parent/'Business';S=Path(__file__).resolve().parent
names=['.htaccess','atleta/.htaccess']
watch=['Application.cfc','atleta/index.cfm','includes/backend/backend_perfil_publico.cfm','includes/estrutura/variaveis.cfm','includes/estrutura/head.cfm','circuitocatarinense/trailrun/index.cfm','evento/.htaccess','includes/estrutura/event_title_date.cfm']
paths=['/atleta/leonardo%20muniz/','/en/athlete/leonardo%20muniz/','/es/atleta/leonardo%20muniz/','/atleta/index.cfm?tag=leonardo%20muniz']
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('pages',coalesce(jsonb_agg(jsonb_build_object('id_pagina',id_pagina,'tag',tag,'tag_prefix',tag_prefix,'perfil_publico',perfil_publico)),'[]'::jsonb))::text AS payload FROM tb_paginas WHERE tag='leonardo muniz'"
remote=helpers+'''
from concurrent.futures import ThreadPoolExecutor
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br')
body='transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report=deserializeJSON(q.payload[1]);}'
result={'profile':bridge(ROOT,body),'files':{},'watch':{},'pages':[]}
for n in p['names']:result['files'][n]=base64.b64encode((root/n).read_bytes()).decode()
for n in p['watch']:result['watch'][n]=digest((root/n).read_bytes())
def get(path):
 cp=subprocess.run(['curl','-sS','--path-as-is','--max-time','25','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code} %{content_type} %{redirect_url}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=29)
 text,_,stats=cp.stdout.rpartition('\\n');return {'path':path,'stats':stats,'body':text,'returncode':cp.returncode}
with ThreadPoolExecutor(max_workers=2) as pool:result['pages']=list(pool.map(get,p['paths']))
lines=(Path('/var/log/apache2/error.log').read_text(errors='replace').splitlines()[-100:])
result['rewrite_error_messages']=[line[line.index('AH10411'):].split(', referer:')[0] for line in lines if 'AH10411:' in line][-8:]
print(json.dumps(result))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'names':names,'watch':watch,'paths':paths,'sql':sql}),capture_output=True,text=True,timeout=160)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout);before={}
for n,b in r.pop('files').items():
 raw=base64.b64decode(b)
 if (R/n).read_bytes()!=raw:raise RuntimeError('Local/production drift: '+n)
 for sub in ['baseline','candidate']:
  dest=S/sub/n;dest.parent.mkdir(parents=True,exist_ok=True)
  if dest.exists() and dest.read_bytes()!=raw:raise RuntimeError('Existing baseline changed: '+n)
  dest.write_bytes(raw)
 before[n]=hashlib.sha256(raw).hexdigest()
class Page(HTMLParser):
 def __init__(self):super().__init__();self.title='';self.t=False;self.canonical=[];self.robots=[]
 def handle_starttag(self,t,a):
  a=dict(a)
  if t=='title':self.t=True
  if t=='meta' and a.get('name')=='robots':self.robots.append(a.get('content'))
  if t=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
 def handle_endtag(self,t):
  if t=='title':self.t=False
 def handle_data(self,d):
  if self.t:self.title+=d
for page in r['pages']:
 body=page.pop('body');h=Page();h.feed(body);page['meta']={'title':h.title,'canonical':h.canonical,'robots':h.robots};page['apache_403']='403 Forbidden' in body;page['cf_error']='Error Occurred While Processing Request' in body
(S/'before.json').write_text(json.dumps(before,indent=2));(S/'watch.json').write_text(json.dumps(r.pop('watch'),indent=2));(S/'inspection.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
