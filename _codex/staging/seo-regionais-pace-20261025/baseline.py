from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent
R=S.parents[3]/'RoadRunners'
names=['estado/index.cfm','api/eventos.cfm','includes/backend/backend_evento.cfm','evento/parts/breadcrumb.cfm','includes/estrutura/footer.cfm','sitemaps/index.cfm','includes/regional_summary.cfm','assets/css/runnerhub-regionais.css','assets/css/runnerhub-regionais.min.css','calculadora-de-pace/index.cfm','assets/js/runnerhub-pace.js','assets/js/runnerhub-pace.min.js','assets/css/runnerhub-pace.css','assets/css/runnerhub-pace.min.css']
watch=['Application.cfc','includes/backend/backend.cfm','includes/backend/backend_estado_cidades.cfm','includes/estrutura/head.cfm','includes/estrutura/header.cfm','includes/estrutura/home_hero_busca.cfm','includes/estrutura/seo-web-tools-body-end.cfm','assets/js/runnerhub-event-filters.min.js','assets/js/runnerhub-estado-cidades.min.js','.htaccess']
assert not (S/'baseline.json').exists()
code='''from pathlib import Path
import hashlib,json,sys
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');out={"files":{},"watch":{}}
for name in p['names']:
 f=root/name
 if f.exists():out['files'][name]={'sha':hashlib.sha256(f.read_bytes()).hexdigest(),'text':f.read_text()}
for name in p['watch']:out['watch'][name]=hashlib.sha256((root/name).read_bytes()).hexdigest()
print(json.dumps(out))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],input=json.dumps({'names':names,'watch':watch}),capture_output=True,text=True,timeout=45)
assert cp.returncode==0,cp.stderr[-1500:]
data=json.loads(cp.stdout);before={};local={};differences=[]
for n in names:
 p=R/n;local[n]=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
 if n in data['files']:
  f=S/'baseline'/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(data['files'][n]['text']);before[n]=data['files'][n]['sha']
  if local[n]!=before[n]:differences.append(n)
  c=S/'candidate'/n;c.parent.mkdir(parents=True,exist_ok=True);c.write_bytes(f.read_bytes())
 elif p.exists():differences.append(n)
(S/'baseline.json').write_text(json.dumps({'names':names,'before':before,'local':local,'watch':data['watch']},indent=2)+'\n')
print(json.dumps({'existing':len(before),'new':len(names)-len(before),'localProductionDifferences':differences}))
