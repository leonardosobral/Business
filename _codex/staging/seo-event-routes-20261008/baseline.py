from pathlib import Path
import json,base64,hashlib,shlex,subprocess
S=Path(__file__).resolve().parent;B=S.parents[2];R=B.parent/'RoadRunners'
names=['includes/card_evento_individual.cfm','includes/estrutura/event_title_date.cfm'];watch=['Application.cfc','.htaccess','evento/index.cfm','includes/estrutura/head.cfm','includes/lista_de_eventos_simple.cfm','services/EventRedirectService.cfc','includes/backend/backend_login.cfm']
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT coalesce(jsonb_agg(jsonb_build_object('id',id_evento,'tag',tag,'name',nome_evento,'city',cidade,'state',estado,'date',data_inicial::text) ORDER BY id_evento),'[]'::jsonb)::text AS payload FROM tb_evento_corridas WHERE ativo=true AND (nome_evento ILIKE '%JURER% NIGHT RUN%' OR nome_evento ILIKE '%MARATONA INTERNACIONAL DE FLORIAN%OAKB%' OR nome_evento ILIKE '%NOSSA SENHORA APARECIDA%' AND estado='PR' OR nome_evento ILIKE '%Corrida de Anivers%Grupo Corrida%' OR nome_evento ILIKE '%ROCK N%NASHVILLE%' OR tag='2026-')"
remote=helpers+"""
p=json.load(sys.stdin);rr=Path('/var/www/roadrunners.com.br')
r={'files':{n:base64.b64encode((rr/n).read_bytes()).decode() for n in p['names']},'watch':{n:digest((rr/n).read_bytes()) for n in p['watch']}}
r['events']=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report={events=deserializeJSON(q.payload[1])};}')
print(json.dumps(r))
"""
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'names':names,'watch':watch,'sql':sql}),capture_output=True,text=True,timeout=100)
if cp.returncode:raise RuntimeError(cp.stderr[-2800:])
r=json.loads(cp.stdout);comparisons={}
for n,b64 in r.pop('files').items():
 data=base64.b64decode(b64);comparisons[n]=(R/n).read_bytes()==data
 for group in ['baseline','candidate']:
  target=S/group/'rr'/n;target.parent.mkdir(parents=True,exist_ok=True);assert not target.exists() or target.read_bytes()==data;target.write_bytes(data)
 target=S/'local-before'/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes((R/n).read_bytes())
r['local_matches']=comparisons
(S/'inspection.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps({'local_matches':comparisons,'events':r['events']},ensure_ascii=False))
