from pathlib import Path
import json,shlex,subprocess,base64
p=Path(__file__).parent;root=p.parents[2]
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
s=(p/'candidate/Business/portal/audiencia/queries/advertiser_acquisition.sql').read_text().replace('/* AUDIENCE_FILTER */',(p/'baseline/filter.sql').read_text())
params={'days':7,'environment':'prod','include_internal':False,'region_dimension':'market','uf':'','page_family':'','device_class':''}
import re
for k,v in params.items():s=re.sub(r'(?<!:):'+k+r'\b',str(v).lower() if isinstance(v,(bool,int)) else "'"+v+"'",s)
body='transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runnerhub"});q=queryExecute(toString(binaryDecode("'+base64.b64encode(s.encode()).decode()+'","base64")),{},{datasource="runnerhub",timeout=15});}report={rows=[]};for(r in q)arrayAppend(report.rows,r);'
remote=helpers+'\nprint(json.dumps(bridge(ROOT,'+repr(body)+')))'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=120)
if r.returncode:raise SystemExit(r.stderr[-4000:])
data=json.loads(r.stdout);(p/'query-result.json').write_text(json.dumps(data,indent=2));print(json.dumps(data))
