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
backup=Path('/var/backups/strava-timezone-20261012-g18a8z2g')
manifest=json.loads((backup/'manifest.json').read_text())
raw=(backup/'activity-dates-before.json').read_bytes()
if hashlib.sha256(raw).hexdigest()!=manifest['backup_sha256']:raise RuntimeError('Backup checksum mismatch')
plan=json.loads(raw)['rows']
if len(plan)!=1689:raise RuntimeError('Unexpected approved backup count')
runtime=Path('/var/www/roadrunners.com.br/api/integrations/strava/batch-refresh.cfm')
published=json.loads((backup/'published.json').read_text())
if hashlib.sha256(runtime.read_bytes()).hexdigest()!=published['after']:raise RuntimeError('Runtime publication changed')
# Prepare guarded, column-only recovery before the first data mutation.
values=[]
for row in plan:
 values.append('('+str(row['activity_id'])+",timestamp '"+row['before']+"',timestamp '"+row['after']+"','"+row['other_fields_md5']+"')")
rollback="BEGIN;\nSET LOCAL lock_timeout='500ms';\nSET LOCAL statement_timeout='20s';\nUPDATE public.tb_strava_activities a SET start_date=p.old_start\nFROM (VALUES\n"+',\n'.join(values)+") AS p(activity_id,old_start,new_start,other_fields_md5)\nWHERE a.activity_id=p.activity_id AND a.start_date=p.new_start\nAND md5((to_jsonb(a)-'start_date')::text)=p.other_fields_md5;\nCOMMIT;\n"
(backup/'rollback-dates.sql').write_text(rollback)
plan_cte='WITH plan AS (SELECT * FROM jsonb_to_recordset(CAST(:plan AS jsonb)) AS p(activity_id bigint,"before" timestamp,"after" timestamp,activity_date date,other_fields_md5 text)) '
status_sql=plan_cte+'''SELECT jsonb_agg(jsonb_build_object('activity_id',p.activity_id,'status',CASE WHEN a.start_date=p."after" THEN 'correct' WHEN a.start_date=p."before" AND md5((to_jsonb(a)-'start_date')::text)=p.other_fields_md5 THEN 'pending' ELSE 'conflict' END))::text AS payload FROM plan p LEFT JOIN public.tb_strava_activities a USING(activity_id)'''
update_sql=plan_cte+''', repaired AS (
 UPDATE public.tb_strava_activities a SET start_date=p."after" FROM plan p
 WHERE a.activity_id=p.activity_id AND a.start_date=p."before"
 AND md5((to_jsonb(a)-'start_date')::text)=p.other_fields_md5
 AND a.activity_date IS NOT DISTINCT FROM p.activity_date
 RETURNING a.activity_id,a.start_date=p."after" AS date_correct,
 md5((to_jsonb(a)-'start_date')::text)=p.other_fields_md5 AS other_fields_preserved
) SELECT jsonb_build_object('count',count(*),'dates_correct',coalesce(bool_and(date_correct),false),'other_fields_preserved',coalesce(bool_and(other_fields_preserved),false))::text AS payload FROM repaired'''
report={'backup':str(backup),'started_at_utc':datetime.now(timezone.utc).isoformat(),'approved':len(plan),'updated':0,'already_correct':0,'batches':[]}
def save_report():
 raw=(json.dumps(report,indent=2)+'\n').encode()
 with open(backup/'repair-result.json','wb') as out:out.write(raw);out.flush();os.fsync(out.fileno())
bridge=Bridge()
try:
 for offset in range(0,len(plan),100):
  load=health();batch=plan[offset:offset+100]
  states=bridge.query(status_sql,params={'plan':{'value':json.dumps(batch),'cfsqltype':'cf_sql_longvarchar'}})
  if any(s['status']=='conflict' for s in states):raise RuntimeError('Concurrent data change in batch; stopped safely')
  pending={s['activity_id'] for s in states if s['status']=='pending'}
  remaining=[r for r in batch if r['activity_id'] in pending]
  report['already_correct']+=len(batch)-len(remaining)
  entry={'batch':offset//100+1,'planned':len(batch),'pending':len(remaining),'health':load}
  report['batches'].append(entry);save_report()
  if remaining:
   sql64=base64.b64encode(update_sql.encode()).decode()
   params64=base64.b64encode(json.dumps({'plan':{'value':json.dumps(remaining),'cfsqltype':'cf_sql_longvarchar'}}).encode()).decode()
   code='transaction {queryExecute("SET LOCAL lock_timeout=500",{},{datasource="runner_dba"});queryExecute("SET LOCAL statement_timeout=20000",{},{datasource="runner_dba"});l=queryExecute("SELECT pg_try_advisory_xact_lock(941001001) AS locked",{},{datasource="runner_dba"});if(!l.locked[1]){throw(message="strava_batch_busy");}q=queryExecute(toString(binaryDecode("'+sql64+'","base64")),deserializeJSON(toString(binaryDecode("'+params64+'","base64"))),{datasource="runner_dba",timeout=20});r=deserializeJSON(q.payload[1]);if(r.count NEQ '+str(len(remaining))+' OR !r.dates_correct OR !r.other_fields_preserved){throw(message="Guarded update count or invariant mismatch; transaction rolled back");}writeOutput(q.payload[1]);}'
   started=time.monotonic()
   for attempt in range(12):
    try:result=bridge.run(code);break
    except RuntimeError as exc:
     if 'strava_batch_busy' not in str(exc) or attempt==11:raise
     time.sleep(5);health()
   entry['result']=result;entry['elapsed_seconds']=round(time.monotonic()-started,3)
   report['updated']+=result['count']
  else:entry['elapsed_seconds']=0
  save_report();time.sleep(0.25)
 report['finished_at_utc']=datetime.now(timezone.utc).isoformat();report['final_health']=health();save_report()
 print(json.dumps(report,indent=2))
finally:bridge.close()
