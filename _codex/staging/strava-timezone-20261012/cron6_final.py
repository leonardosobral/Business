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

b=Bridge()
try: print(json.dumps(b.query('SELECT jsonb_build_object(\'status\',status,\'started_at_utc\',started_at,\'finished_at_utc\',finished_at,\'updated\',substring(response_preview FROM \'(?i)"updated"\\s*:\\s*([0-9]+)\'),\'fetched\',substring(response_preview FROM \'(?i)"fetched"\\s*:\\s*([0-9]+)\'),\'processed\',substring(response_preview FROM \'(?i)"processed"\\s*:\\s*([0-9]+)\'),\'errors_empty\',response_preview ~ \'(?i)"errors"\\s*:\\s*\\[\\s*\\]\')::text AS payload FROM tb_cron_job_runs WHERE id_cron_job=6 AND started_at >= timestamp \'2026-10-12 14:59:31\' ORDER BY started_at DESC LIMIT 1'),indent=2))
finally:b.close()
