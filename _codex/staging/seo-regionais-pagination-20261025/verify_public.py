from pathlib import Path
import subprocess,json,re,hashlib
from html import unescape
S=Path(__file__).resolve().parent
cases={'pr1':'/estado/pr/','pr2':'/estado/pr/?pagina=2','pr3':'/estado/pr/?pagina=3','curitiba':'/estado/pr/curitiba/','df':'/estado/df/','sc':'/estado/sc/','rs':'/estado/rs/','sp':'/estado/sp/','exact':'/estado/pr/?periodo_inicio=2026-11-01&periodo_fim=2026-11-30','missing':'/estado/pr/?pagina=99999','invalid':'/estado/pr/?pagina=-1','invalid-date':'/estado/pr/?periodo_inicio=2026-11-31&periodo_fim=2026-12-01','api':'/api/eventos.cfm?tag=PR&cidade=curitiba&distancia=5,5&periodo_inicio=2026-11-01&periodo_fim=2026-11-30','pace':'/calculadora-de-pace/'}
result={}
for name,path in cases.items():
 cp=subprocess.run(['curl','-sS','--max-time','45','-w','\n%{http_code}','https://roadrunners.run'+path],capture_output=True,text=True,check=True)
 body,status=cp.stdout.rsplit('\n',1);h=unescape(body);expected={'missing':404,'invalid':400,'invalid-date':400}.get(name,200)
 assert int(status)==expected,(name,status,h[:100]);item={'status':int(status)}
 if name.startswith('pr'):
  page=int(name[-1]);canonical=re.search(r'<link rel="canonical" href="([^"]+)',h)[1]
  assert canonical=='https://roadrunners.run'+path,(name,canonical)
  assert 'data-page="'+str(page)+'"' in h
  assert 'name="robots" content="noindex' not in h
  item['canonical']=canonical
 if name in ['pr1','pr2','pr3','curitiba','df','sc','rs','sp','exact','api']:assert 'data-regional-summary' in h,name
 if name=='exact':assert 'name="robots" content="noindex,follow"' in h
 result[name]=item
for name,version in [('assets/js/runnerhub-regional-period.min.js','20261025a'),('assets/js/runnerhub-event-filters.min.js','20261025pages2'),('assets/js/runnerhub-estado-cidades.min.js','20261025pages'),('assets/css/runnerhub-regionais.min.css','20261025b')]:
 cp=subprocess.run(['curl','-fsS','--max-time','45','https://roadrunners.run/'+name+'?v='+version],capture_output=True,check=True)
 assert cp.stdout==(S/'candidate'/name).read_bytes(),name
 result[name]={'sha256':hashlib.sha256(cp.stdout).hexdigest()}
(S/'public-verified.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'routes':len(cases),'assets':4,'passed':True}))
