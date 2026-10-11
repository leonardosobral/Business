"""Read only aggregate activity; no SQL text, client IPs or identifiers."""
from pathlib import Path
import json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business')
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT jsonb_build_object('checked_at',clock_timestamp(),'counts',(SELECT jsonb_agg(to_jsonb(x)) FROM (SELECT state,wait_event_type,wait_event,count(*) connections,round(max(extract(epoch from clock_timestamp()-query_start))) max_query_age_seconds FROM pg_catalog.pg_stat_activity WHERE backend_type='client backend' AND pid<>pg_backend_pid() GROUP BY state,wait_event_type,wait_event ORDER BY count(*) DESC)x),'active',(SELECT jsonb_agg(to_jsonb(x)) FROM (SELECT md5(query) query_hash,round(extract(epoch from clock_timestamp()-query_start)) age_seconds,wait_event_type,wait_event,ARRAY(SELECT name FROM unnest(ARRAY['tb_resultados','tb_evento_corridas','tb_evento_corridas_percursos','tb_evento_inscritos','tb_atividades']) name WHERE strpos(query,name)>0) known_tables FROM pg_catalog.pg_stat_activity WHERE state='active' AND pid<>pg_backend_pid() ORDER BY query_start LIMIT 20)x))::text payload"""
remote=helpers+'''
import re
p=json.load(sys.stdin)
r=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query("SET LOCAL statement_timeout='5s'")+raw_query(p['sql'])+'report=deserializeJSON(q.payload[1]);}')
settings=[]
for folder in [Path('/etc/apache2'),Path('/opt/ColdFusion/config/wsconfig')]:
 if not folder.exists():continue
 for f in folder.rglob('*'):
  if not f.is_file() or f.stat().st_size>1000000:continue
  try:content=f.read_text()
  except (OSError,UnicodeError):continue
  for line in content.splitlines():
   line=line.strip()
   if re.match(r'^(ServerLimit|MaxRequestWorkers|KeepAliveTimeout|Timeout|ProxyTimeout|ThreadsPerChild|StartServers|MinSpareThreads|MaxSpareThreads)\\s+\\d+',line):settings.append(line)
r['numeric_apache_settings']=sorted(set(settings))
print(json.dumps(r))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=8','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=100)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);Path(__file__).with_suffix('.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
