from pathlib import Path
import base64,json,shlex,subprocess
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business')
STAGE=ROOT/'_codex/staging/seo-routes-20261003'
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]', "ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
from urllib.parse import quote
from html.parser import HTMLParser
files={}
for project,root,names in [('RoadRunners','/var/www/roadrunners.com.br',['.htaccess','evento/index.cfm','includes/backend/backend_evento.cfm','noticias/index.cfm','sitemaps/index.cfm','includes/i18n/routes.cfm']),('Business','/var/www/business.roadrunners.run',['portal/includes/seo_queue_data.cfm'])]:
 for name in names:
  f=Path(root)/name
  if f.is_file():files[project+'/'+name]=base64.b64encode(f.read_bytes()).decode()
queries={
 'events':"SELECT id_evento,nome_evento,tag,data_inicial,data_final,ativo FROM tb_evento_corridas WHERE lower(tag) LIKE '%operario%' OR lower(tag) LIKE '%rock-n-run%' OR lower(tag) LIKE '%atibaia-run-fest%' ORDER BY id_evento DESC LIMIT 35",
 'news_tables':"SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND (table_name ILIKE '%news%' OR table_name ILIKE '%noticia%' OR table_name ILIKE '%content%') ORDER BY table_name"
}
db={}
for name,sql in queries.items():
 try:db[name]=bridge(Path('/var/www/business.roadrunners.run'),raw_query(sql)+'report={rows=[]};for(row in q){arrayAppend(report.rows,row);}')
 except Exception as e:db[name]={'error':str(e)}
paths=['/es/evento/2026-operario%0D%0Anight%0D%0Arun/','/evento/2026-rock-n-run%0A----nashville-2026/','/evento/2026-atibaia-run-fest-trail-mode-%2303-socorro-pico-do-gaviao/','/evento/2026-atibaia-run-fest-x-chopp-germania-corre-pela-breja-%2301/','/noticias/ranking-atualizado-com-maceio-live-inter-j-pessoa-taubate-floripa-goiania-movi-e-vitoria/']
http=[]
for path in paths:
 for origin in (False,True):
  args=['curl','-sS','--path-as-is','--max-time','20','-A','RunnerHub-SEO-route-diagnostic/20261003','-D','-','-o','/dev/null']
  if origin:args+=['--resolve','roadrunners.run:443:127.0.0.1']
  p=subprocess.run(args+['https://roadrunners.run'+path],capture_output=True,text=True,timeout=22)
  http.append({'path':path,'origin':origin,'returncode':p.returncode,'headers':p.stdout,'error':p.stderr})
rewrite={}
for directory in ['/etc/apache2/sites-enabled','/etc/apache2/conf-enabled']:
 for f in Path(directory).glob('*'):
  if f.is_file():
   t=f.read_text(errors='replace')
   if 'roadrunners.com.br' in t:rewrite[str(f)]='\\n'.join(x for x in t.splitlines() if any(w in x for w in ['Rewrite','roadrunners','ErrorLog','CustomLog','DocumentRoot']))
logs={}
for f in Path('/var/log/apache2').glob('*error.log'):
 if 'roadrunners' in f.name:
  p=subprocess.run(['tail','-n','200',str(f)],capture_output=True,text=True)
  lines=[x for x in p.stdout.splitlines() if any(w in x.lower() for w in ['operario','atibaia','ah10410','ah10411','ah10508','nashville'])]
  if lines:logs[f.name]=lines[-12:]
print(json.dumps({'files':files,'db':db,'http':http,'rewrite':rewrite,'logs':logs}))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=260)
if p.returncode:raise RuntimeError(p.stderr[-2000:])
r=json.loads(p.stdout)
for name,b64 in r.pop('files').items():
 f=STAGE/'baseline'/name;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(base64.b64decode(b64))
(STAGE/'diagnostic.json').write_text(json.dumps(r,indent=2,ensure_ascii=False))
print(json.dumps(r,indent=2,ensure_ascii=False))
