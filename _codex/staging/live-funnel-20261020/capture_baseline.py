import base64,hashlib,json,shlex,subprocess
from pathlib import Path
B=Path(__file__).resolve().parent
files={'RoadRunners':['evento/index.cfm','circuito/live_highlight.cfm','includes/card_evento_live.cfm','assets/js/rr-audience.js','services/AudienceMeasurementService.cfc','includes/analytics/bootstrap.cfm'],'Business':['portal/audiencia/queries/live_journey.sql','portal/audiencia/live_journey.cfm','portal/includes/audience_backend.cfm','portal/audiencia/home.cfm']}
roots={'RoadRunners':'/var/www/roadrunners.com.br','Business':'/var/www/business.roadrunners.run'}
code='''from pathlib import Path
import base64,hashlib,json
files=FILES;roots=ROOTS;result=[]
for site,paths in files.items():
 for rel in paths:
  p=Path(roots[site])/rel;b=p.read_bytes();s=p.stat()
  result.append(dict(site=site,path=rel,sha=hashlib.sha256(b).hexdigest(),mode=s.st_mode&0o777,uid=s.st_uid,gid=s.st_gid,content=base64.b64encode(b).decode()))
print(json.dumps(result))
'''.replace('FILES',repr(files)).replace('ROOTS',repr(roots))
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],capture_output=True,text=True,timeout=30)
if r.returncode:raise SystemExit(r.stderr)
rows=json.loads(r.stdout)
for row in rows:
 p=B/'production-baseline'/row['site']/row['path'];p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(base64.b64decode(row.pop('content')))
 local=Path('/Users/Shared/Projects/RunnerHub')/row['site']/row['path'];row['local_sha']=hashlib.sha256(local.read_bytes()).hexdigest();row['matches_local']=row['sha']==row['local_sha']
(B/'baseline.json').write_text(json.dumps(rows,indent=2));print(json.dumps(rows,indent=2))
