from pathlib import Path
import json,subprocess,shlex,base64,hashlib
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');P=Path(__file__).resolve().parent
current=json.loads((P/'current-pages.json').read_text())
tags=sorted(set(x['url'].rstrip('/').rsplit('/',1)[-1] for x in current['pages'] if '/evento/' in x['url'] or '/event/' in x['url']))
quoted=','.join("'"+x.replace("'","''")+"'" for x in tags)
sql="SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb)::text AS payload FROM (SELECT id_evento,tag,tag_301,nome_evento,nome_simplificado,cidade,estado,data_inicial,data_final,ativo,tipo_corrida FROM tb_evento_corridas WHERE tag IN ("+quoted+") ORDER BY id_evento) r"
names={'rr':['includes/estrutura/event_title_date.cfm','includes/estrutura/head.cfm','evento/index.cfm','includes/backend/backend_evento.cfm'], 'business':['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']}
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);events=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report={events=deserializeJSON(q.payload[1])};}')['EVENTS']
files={}
for group,names in p['files'].items():
 root=Path('/var/www/roadrunners.com.br') if group=='rr' else ROOT
 for name in names:files[group+':'+name]=base64.b64encode((root/name).read_bytes()).decode()
print(json.dumps({'events':events,'files':files}))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql,'files':names}),capture_output=True,text=True,timeout=60)
assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout)
for k,v in r.pop('files').items():
 group,n=k.split(':',1);b=base64.b64decode(v);f=P/'baseline'/group/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(b)
 local=(ROOT.parent/'RoadRunners' if group=='rr' else ROOT)/n
 print(json.dumps({'file':k,'local_matches':local.read_bytes()==b,'sha':hashlib.sha256(b).hexdigest()}))
(P/'events.json').write_text(json.dumps(r,indent=2,ensure_ascii=False))
selected=[x for x in r['events'] if any(t in x['tag'] for t in ['correr-e-massa','motiva-aeroportos','rio-de-janeiro'])]
print(json.dumps({'events':len(r['events']),'selected':selected},ensure_ascii=False))
