from pathlib import Path
from datetime import datetime, timezone
import base64,hashlib,json,os,secrets,shutil,subprocess,tempfile,time

class Bridge:
 def __init__(self):
  self.work=Path(tempfile.mkdtemp(prefix='strava-date-ops-',dir='/var/www/business.roadrunners.run/_codex'))
  self.key=secrets.token_hex(32);os.chmod(self.work,0o755)
  (self.work/'.htaccess').write_text('Require local\n')
  (self.work/'Application.cfc').write_text('component { this.name="'+self.work.name+'";this.datasource="runner_dba";this.serialization.preservecaseforstructkey=true;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+self.key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
  for f in self.work.iterdir():os.chmod(f,0o644)
 def run(self,code):
  p=self.work/'run.cfm';p.write_text('<cfsetting showdebugoutput="false" requesttimeout="45"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>'+code+'</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>');os.chmod(p,0o644)
  r=subprocess.run(['curl','-sS','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+self.key,'https://business.roadrunners.run/_codex/'+self.work.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
  if r.returncode:raise RuntimeError('Probe transport failure '+str(r.returncode))
  try:out=json.loads(r.stdout)
  except ValueError:raise RuntimeError('Probe returned non-JSON response')
  if isinstance(out,dict) and 'error' in out:raise RuntimeError(json.dumps(out)[:1500])
  return out
 def query(self,sql,readonly=True,params=None):
  sql64=base64.b64encode(sql.encode()).decode();params64=base64.b64encode(json.dumps(params or {}).encode()).decode()
  pre='queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});' if readonly else ''
  return self.run('transaction {'+pre+'queryExecute("SET LOCAL statement_timeout=20000",{},{datasource="runner_dba"});queryExecute("SET LOCAL lock_timeout=500",{},{datasource="runner_dba"});q=queryExecute(toString(binaryDecode("'+sql64+'","base64")),deserializeJSON(toString(binaryDecode("'+params64+'","base64"))),{datasource="runner_dba",timeout=20});writeOutput(q.payload[1]);}')
 def close(self):shutil.rmtree(self.work)

def health():
 r=subprocess.run(['curl','-sS','--max-time','4','http://127.0.0.1/server-status?auto'],capture_output=True,text=True,timeout=5)
 values={k.strip():v.strip() for k,_,v in (line.partition(':') for line in r.stdout.splitlines()) if k in ('BusyWorkers','IdleWorkers','ConnsTotal')}
 mem={l.split(':')[0]:int(l.split()[1]) for l in Path('/proc/meminfo').read_text().splitlines() if l.startswith(('MemAvailable:','SwapFree:','SwapTotal:'))}
 values.update(mem);values['load1']=os.getloadavg()[0];values['cpus']=os.cpu_count()
 if r.returncode or int(values.get('BusyWorkers',999))>50 or int(values.get('IdleWorkers',0))<15 or mem['MemAvailable']<2097152 or values['load1']>values['cpus']*1.5:raise RuntimeError('Load guard stopped work: '+json.dumps(values))
 return values

os.umask(0o077)
root=Path('/var/www/roadrunners.com.br')
relative='api/integrations/strava/batch-refresh.cfm'
baseline='2c182ac30ebadd3236b5ad2031a42e5b2e200ccb114dee99e3574b154e294cbf'
if hashlib.sha256((root/relative).read_bytes()).hexdigest()!=baseline:raise RuntimeError('Production baseline conflict')
load=health()
bridge=Bridge()
try:
 data={'rows':[],'trigger_count':0}
 after_id=0
 while True:
  page=bridge.query("\nWITH recent AS MATERIALIZED (\n SELECT a.activity_id,a.athlete_id,a.start_date,a.activity_date,a.updated,a.processed,a.activity_source,\n  left(a.strava_raw->>'start_date_local',10)::date AS expected_day,\n  (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'UTC' AS raw_utc,\n  (a.strava_raw->>'start_date')::timestamptz AT TIME ZONE 'America/Sao_Paulo' AS proposed_start,\n  a.strava_raw->>'timezone' AS raw_timezone,\n  (a.type IN ('Run','VirtualRun','TrailRun') AND a.distance>=990) AS qualifying_run\n FROM public.tb_strava_activities a\n WHERE a.start_date>=timestamp '2026-10-01' AND a.start_date<timestamp '2026-10-14'\n AND a.strava_raw->>'start_date_local' ~ '^2026-10-[0-3][0-9]T'\n AND a.strava_raw->>'start_date' ~ '^2026-10-[0-3][0-9]T'\n), candidates AS MATERIALIZED (\n SELECT * FROM recent WHERE start_date=raw_utc AND start_date<>proposed_start\n  AND updated>=timestamp '2026-10-11' AND updated<timestamp '2026-10-12 14:28:06'\n  AND activity_source='strava' AND processed=true\n)\nSELECT jsonb_build_object(\n 'captured_at',now(),\n 'trigger_count',(SELECT count(*) FROM pg_trigger WHERE tgrelid='public.tb_strava_activities'::regclass AND NOT tgisinternal AND tgenabled<>'D'),\n 'rows',(SELECT jsonb_agg(jsonb_build_object('activity_id',a.activity_id,'before',a.start_date,'after',c.proposed_start,'activity_date',a.activity_date,'other_fields_md5',md5((to_jsonb(a)-'start_date')::text)) ORDER BY a.activity_id) FROM (SELECT * FROM candidates WHERE activity_id > :after_id ORDER BY activity_id LIMIT 100) c JOIN public.tb_strava_activities a USING(activity_id))\n)::text AS payload",params={'after_id':{'value':str(after_id),'cfsqltype':'cf_sql_bigint'}})
  data['captured_at']=page['captured_at'];data['trigger_count']=page['trigger_count']
  current=page['rows'] or []
  data['rows'].extend(current)
  if len(current)<100:break
  after_id=current[-1]['activity_id']
  time.sleep(0.1)
finally: bridge.close()
rows=data['rows'] or []
if data['trigger_count']!=0:raise RuntimeError('Unexpected active database triggers')
if not 0<len(rows)<=1689:raise RuntimeError('Candidate count exceeds approved scope or is empty: '+str(len(rows)))
if len({r['activity_id'] for r in rows})!=len(rows):raise RuntimeError('Duplicate IDs')
backup=Path(tempfile.mkdtemp(prefix='strava-timezone-20261012-',dir='/var/backups'))
raw=(json.dumps(data,indent=2)+'\n').encode()
with open(backup/'activity-dates-before.json','wb') as out:out.write(raw);out.flush();os.fsync(out.fileno())
(backup/'batch-refresh.cfm.before').write_bytes((root/relative).read_bytes())
report={'backup':str(backup),'captured_at':data['captured_at'],'activities':len(rows),'changed_day':sum(r['before'][:10]!=r['after'][:10] for r in rows),'backup_sha256':hashlib.sha256(raw).hexdigest(),'runtime_before_sha256':baseline,'health':load,'only_mutated_column_planned':'start_date'}
(backup/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
