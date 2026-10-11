from pathlib import Path
import base64,hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent;B=S.parents[2];R=B.parent/'RoadRunners'
names={'rr':['includes/estrutura/header_tema.cfm'],'business':['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']}
watch=['Application.cfc','.htaccess','atleta/.htaccess','maratona/index.cfm','circuito/index.cfm','org/index.cfm','timer/index.cfm','evento/index.cfm','includes/estrutura/home_hero_busca.cfm','includes/estrutura/head.cfm','includes/estrutura/variaveis.cfm','includes/backend/backend_login.cfm']
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('marathons',coalesce(jsonb_agg(jsonb_build_object('tag',ag.tag,'name',ag.nome_evento_agregado,'type',ag.tipo_agregacao,'theme_id',ag.id_tema,'theme_logo',coalesce(tem.logo,'')) ORDER BY ag.tag),'[]'::jsonb))::text AS payload FROM tb_agrega_eventos ag LEFT JOIN tb_temas tem ON tem.id_tema=ag.id_tema WHERE ag.tipo_agregacao='maratona'"
remote=helpers+'''
p=json.load(sys.stdin);rr=Path('/var/www/roadrunners.com.br');business=ROOT
result={'files':{},'watch':{n:digest((rr/n).read_bytes()) for n in p['watch']}}
for group,root in [('rr',rr),('business',business)]:result['files'][group]={n:base64.b64encode((root/n).read_bytes()).decode() for n in p['names'][group]}
body='transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report=deserializeJSON(q.payload[1]);}'
result['catalog']=bridge(business,body);print(json.dumps(result))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'names':names,'watch':watch,'sql':sql}),capture_output=True,text=True,timeout=80)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout)
for group,files in r.pop('files').items():
 root=R if group=='rr' else B
 for n,b64 in files.items():
  raw=base64.b64decode(b64);assert (root/n).read_bytes()==raw,n+' local/production drift'
  for sub in ['baseline','candidate']:
   dest=S/sub/group/n;dest.parent.mkdir(parents=True,exist_ok=True)
   if dest.exists() and dest.read_bytes()!=raw:raise RuntimeError('Existing baseline differs: '+n)
   dest.write_bytes(raw)
(S/'inspection.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps({'baseline_files':4,'watched_dependencies':len(watch),'catalog':r['catalog']},ensure_ascii=False))
