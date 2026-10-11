from pathlib import Path
from html.parser import HTMLParser
import base64,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');P=Path(__file__).resolve().parent
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT jsonb_build_object('events', jsonb_agg(to_jsonb(e)))::text AS payload FROM
 (SELECT id_evento,nome_evento,nome_simplificado,tag,tag_301,ativo,data_inicial,data_final,cidade,estado,tipo_corrida
  FROM tb_evento_corridas WHERE tag LIKE '%corrida-night-run-vitoria-airport%'
  OR tag='2026-costa-esmeralda-trail-2026' ORDER BY id_evento) e"""
paths=[]
for prefix in ['/evento/','/en/event/','/es/evento/']:
 for tag in ['2025-corrida-night-run-vitoria-airport','2026-corrida-night-run-vitoria-airport','2026-costa-esmeralda-trail-2026']:
  paths.append(prefix+tag+'/')
 paths.append(prefix+'2026-costa-esmeralda-trail-2026')
names={'rr':['.htaccess','includes/estrutura/event_title_date.cfm','services/EventRedirectService.cfc','includes/estrutura/event_redirect.cfm','includes/estrutura/head.cfm','evento/index.cfm','includes/backend/backend_evento.cfm','includes/estrutura/footer.cfm','privacidade/index.cfm'],'business':['portal/includes/seo_queue_data.cfm','portal/includes/seo_semrush_data.cfm','portal/conteudo/seo_semrush.cfm']}
remote=helpers+'''
from concurrent.futures import ThreadPoolExecutor
p=json.load(sys.stdin)
body='transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report=deserializeJSON(q.payload[1]);}'
report=bridge(ROOT,body);files={}
for group,names in p['names'].items():
 root=Path('/var/www/roadrunners.com.br') if group=='rr' else ROOT
 for name in names:files[group+':'+name]=base64.b64encode((root/name).read_bytes()).decode()
def fetch(path):
 cp=subprocess.run(['curl','-sS','--path-as-is','--max-time','25','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code} %{time_total} %{redirect_url}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=28)
 body,_,stats=cp.stdout.rpartition('\\n');return {'path':path,'body':body,'stats':stats,'returncode':cp.returncode}
with ThreadPoolExecutor(max_workers=2) as pool:pages=list(pool.map(fetch,p['paths']))
print(json.dumps({'report':report,'files':files,'pages':pages}))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql,'names':names,'paths':paths}),capture_output=True,text=True,timeout=150)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout)
r['local_drift']=[]
for key,b in r.pop('files').items():
 group,name=key.split(':',1);raw=base64.b64decode(b)
 local=(ROOT.parent/'RoadRunners' if group=='rr' else ROOT)/name
 if local.read_bytes()!=raw:
  if key in ['rr:.htaccess','rr:includes/estrutura/event_title_date.cfm','business:portal/includes/seo_queue_data.cfm','business:portal/conteudo/seo_semrush.cfm']:raise RuntimeError('Local/production drift: '+key)
  r['local_drift'].append(key)
 for sub in ['baseline','candidate']:
  dest=P/sub/group/name;dest.parent.mkdir(parents=True,exist_ok=True)
  if dest.exists() and dest.read_bytes()!=raw:raise RuntimeError('Baseline changed: '+str(dest))
  dest.write_bytes(raw)
for i,page in enumerate(r['pages']):
 raw=page.pop('body');(P/('before-'+str(i)+'.html')).write_text(raw)
 page['title']=__import__('re').search(r'<title>(.*?)</title>',raw,__import__('re').S).group(1) if '<title>' in raw else ''
(P/'inspection.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
print(json.dumps(r,ensure_ascii=False))
