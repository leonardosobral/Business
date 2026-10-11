"""Read-only baseline and public URL collection."""
from pathlib import Path
import json,subprocess,shlex,base64,hashlib
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');P=Path(__file__).resolve().parent
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT jsonb_build_object(
'circuits',(SELECT jsonb_agg(to_jsonb(r)) FROM (SELECT g.id_agrega_evento_legado,g.agregador_tag,g.agregador_nome,g.agregador_tipo,a.tag AS legacy_tag,(SELECT count(*) FROM tb_agregadores_eventos ge WHERE ge.agregador_tag=g.agregador_tag) AS events FROM tb_agregadores g LEFT JOIN tb_agrega_eventos a ON a.id_agrega_evento=g.id_agrega_evento_legado WHERE g.agregador_tag IN ('fca-corridaderua','circuito-catarinense-corrida-de-rua') OR a.tag IN ('fca-corridaderua','circuito-catarinense-corrida-de-rua'))r),
'events',(SELECT jsonb_agg(to_jsonb(r)) FROM (SELECT id_evento,nome_evento,tag,tag_301,ativo,cidade,estado,data_inicial,data_final,status_evento FROM tb_evento_corridas WHERE tag IN ('2026-1-edicao-corrida-farmelhor','2026-1-edicao-corrida-farmelhor-rn','2026-costa-esmeralda-trail-2026','2026-trail-in-motion-19-chacara-da-bolinha-2026') ORDER BY id_evento)r))::text AS payload"""
names={'rr':['circuito/index.cfm','desafiosupra/index.cfm','includes/estrutura/head.cfm','includes/estrutura/header.cfm','includes/estrutura/footer.cfm','includes/estrutura/header_tema.cfm','evento/index.cfm','includes/estrutura/event_redirect.cfm','services/EventRedirectService.cfc','Application.cfc','includes/backend/backend_evento.cfm'], 'business':['portal/includes/seo_queue_data.cfm','portal/includes/seo_semrush_data.cfm','portal/conteudo/seo_semrush.cfm']}
paths=['/','/estado/sp/','/circuito/fca-corridaderua/','/circuito/circuito-catarinense-corrida-de-rua/','/circuito/live-run-xp/','/desafiosupra/2024/','/desafiosupra/2025/','/evento/2026-1-edicao-corrida-farmelhor/','/evento/2026-1-edicao-corrida-farmelhor-rn/','/evento/2026-costa-esmeralda-trail-2026','/evento/2026-costa-esmeralda-trail-2026/','/evento/2026-trail-in-motion-19-chacara-da-bolinha-2026/','/sitemaps/events-history-3.xml']
remote=helpers+'''
p=json.load(sys.stdin);report=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report=deserializeJSON(q.payload[1]);}')
report['files']={}
for group,names in p['files'].items():
 root=Path('/var/www/roadrunners.com.br') if group=='rr' else ROOT
 for name in names:report['files'][group+':'+name]=base64.b64encode((root/name).read_bytes()).decode()
report['public']=[]
for path in p['paths']:
 cp=subprocess.run(['curl','-sS','--max-time','20','-A','RunnerHub-SEO-Verification/1.0','-w','\\n%{http_code} %{time_total} %{redirect_url}','https://roadrunners.run'+path],capture_output=True,text=True,timeout=23)
 body,_,stats=cp.stdout.rpartition('\\n');report['public'].append({'path':path,'stats':stats,'body':body,'returncode':cp.returncode})
report['apache']=subprocess.run(['curl','-sS','--max-time','5','http://127.0.0.1/server-status?auto'],capture_output=True,text=True).stdout
print(json.dumps(report,ensure_ascii=False))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql,'files':names,'paths':paths}),capture_output=True,text=True,timeout=330)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout)
for key,v in r.pop('files').items():
 group,name=key.split(':',1);b=base64.b64decode(v);f=P/'baseline'/group/name;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(b)
 local=(ROOT.parent/'RoadRunners' if group=='rr' else ROOT)/name
 if local.read_bytes()!=b:print('Preexisting local/production difference: '+key)
for i,item in enumerate(r['public']):
 (P/('public-before-'+str(i)+'.html')).write_text(item.pop('body'))
r['apache']=[x for x in r['apache'].splitlines() if x.startswith(('CurrentTime:','BusyWorkers:','IdleWorkers:','ServerUptime:','Load1:'))]
(P/'inspection.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False))
