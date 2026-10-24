from pathlib import Path
import json,shlex,subprocess
P=Path(__file__).parent;root=P.parents[2]
helper=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helper+r'''
import re
root=Path('/var/www/business.roadrunners.run');qd=root/'portal/audiencia/queries';base=(qd/'filter.sql').read_text();answer={};record={}
periods={'before':('2026-10-02','2026-10-09'),'after':('2026-10-09','2026-10-13'),'today':('2026-10-13','2026-10-14')}
for period,(start,end) in periods.items():
 lo="TIMESTAMPTZ '"+start+" 00:00:00-03'";hi="LEAST(now(),TIMESTAMPTZ '"+end+" 00:00:00-03')"
 f=re.sub(r"\(date_trunc\('day', now\(\) AT TIME ZONE 'America/Sao_Paulo'\)\s*- \(CAST\(:days AS integer\) - 1\) \* interval '1 day'\) AT TIME ZONE 'America/Sao_Paulo'",lo,base)
 assert ':days' not in f
 f=f.replace('e.occurred_at <= now()','e.occurred_at < '+hi)
 for name in ['live_journey','advertiser_acquisition']:
  s=(qd/(name+'.sql')).read_text().replace('/* AUDIENCE_FILTER */',f)
  if name=='advertiser_acquisition':
   s=re.sub(r"\(date_trunc\('day',now\(\) AT TIME ZONE 'America/Sao_Paulo'\)\s*- \(CAST\(:days AS integer\)-1\)\*interval '1 day'\) AT TIME ZONE 'America/Sao_Paulo'",lo,s)
   s=s.replace('e.received_at <= now()','e.received_at < '+hi)
  params={'environment':'prod','include_internal':False,'region_dimension':'market','uf':'','page_family':'','device_class':'','live_source':'google','live_campaign':'','live_city':'','live_event':''}
  for k,v in params.items():s=re.sub(r'(?<!:):'+k+r'\b',str(v).lower() if isinstance(v,bool) else "'"+v+"'",s)
  assert ':days' not in s
  missing=re.findall(r'(?<!:):([a-z_]+)\b',s);assert set(missing)<= {'live_registration'},missing
  key=period+'_'+name;record[key]=s
  body='transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runnerhub"});q=queryExecute(toString(binaryDecode("'+base64.b64encode(s.encode()).decode()+'","base64")),{},{datasource="runnerhub",timeout=30});}report={rows=[]};for(r in q)arrayAppend(report.rows,r);'
  answer[key]=bridge(root,body)
print(json.dumps({'results':answer,'queries':record}))
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=240)
if r.returncode:raise SystemExit(r.stderr[-3000:])
d=json.loads(r.stdout);(P/'warehouse.json').write_text(json.dumps(d,indent=2))
for k,v in d['results'].items():
 print(k)
 rows=v.get('rows',v.get('ROWS',[]))
 for row in rows:
  row={k.lower():v for k,v in row.items()}
  if 'journey' in k and row.get('row_type')=='campaign':print(json.dumps(row,ensure_ascii=False))
  elif 'advertiser' in k and row.get('source')=='google' and (row.get('clicked_deliveries',0)>0 or row.get('view_sessions',0)>10):print(json.dumps(row,ensure_ascii=False))
