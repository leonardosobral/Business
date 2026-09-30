"""One-time, backed-up removal of pre-2026-09-26 problems; never changes tb_log."""
from pathlib import Path
import json, shlex, subprocess, sys
ROOT=Path(__file__).resolve().parents[2]
MODE=sys.argv[1]
assert MODE in ('prepare','validate','apply','verify')
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
source+=r'''
root=Path('/var/www/business.roadrunners.run')
stage=Path('/var/backups/business-error-triage-cleanup-20260929')
mode=MODE
# Include complete rows and a stable checksum; abort if anything changes after backup.
snapshot="""WITH old AS (SELECT * FROM tb_error_problem WHERE last_seen < timestamp '2026-09-26 00:00:00'), snapshot AS (
SELECT json_build_object(
'problems',coalesce((SELECT json_agg(p ORDER BY p.id) FROM old p),'[]'::json),
'occurrences',coalesce((SELECT json_agg(o ORDER BY o.id_log) FROM tb_error_occurrence o WHERE problem_id IN(SELECT id FROM old)),'[]'::json),
'history',coalesce((SELECT json_agg(h ORDER BY h.id) FROM tb_error_history h WHERE problem_id IN(SELECT id FROM old)),'[]'::json))::text AS payload)
SELECT payload,md5(payload) AS checksum FROM snapshot"""
def cfstr(s):return '"'+s.replace('"','""')+'"'
if mode=='prepare':
 stage.mkdir(mode=0o700,exist_ok=False)
 result=bridge(root,'q=queryExecute('+cfstr(snapshot)+',{}, {datasource="runner_dba",timeout=15});report={snapshot=q.payload[1],checksum=q.checksum[1]};')
 data=json.loads(result['SNAPSHOT']);checksum=result['CHECKSUM']
 (stage/'backup.json').write_text(json.dumps(data,ensure_ascii=False));os.chmod(stage/'backup.json',0o600)
 # Verify the backup can be decoded before enabling application.
 assert json.loads((stage/'backup.json').read_text())==data
 counts={k:len(v) for k,v in data.items()}
 (stage/'manifest.json').write_text(json.dumps({'checksum':checksum,'counts':counts,'cutoff':'2026-09-26 00:00:00','timezone':'America/Sao_Paulo'}))
 restore="BEGIN;\nSET LOCAL lock_timeout='2s';\n"
 for name,key in [('tb_error_problem','problems'),('tb_error_occurrence','occurrences'),('tb_error_history','history')]:
  value=json.dumps(data[key],ensure_ascii=False).replace("'","''")
  restore+='INSERT INTO public.'+name+' SELECT * FROM json_populate_recordset(NULL::public.'+name+", '"+value+"'::json);\n"
 restore+='COMMIT;\n'
 (stage/'restore.sql').write_text(restore);os.chmod(stage/'restore.sql',0o600)
 print(json.dumps({'backed_up':counts,'backup':str(stage),'checksum':checksum}))
elif mode=='validate':
 data=json.loads((stage/'backup.json').read_text());m=json.loads((stage/'manifest.json').read_text())
 checks=[]
 for name,key in [('tb_error_problem','problems'),('tb_error_occurrence','occurrences'),('tb_error_history','history')]:
  checks.append("(SELECT count(*) FROM json_populate_recordset(NULL::public."+name+",payload::json->'"+key+"')) AS "+key)
 sql=snapshot.replace('SELECT payload,md5(payload) AS checksum FROM snapshot','SELECT md5(payload) AS checksum,'+','.join(checks)+' FROM snapshot')
 result=bridge(root,'q=queryExecute('+cfstr(sql)+',{}, {datasource="runner_dba",timeout=15});report={};for(k in listToArray(q.columnList))report[k]=q[k][1];')
 assert result['CHECKSUM']==m['checksum'] and all(result[k.upper()]==len(v) for k,v in data.items())
 (stage/'validated.json').write_text(json.dumps(result));print(json.dumps({'restore_rows_validated':result}))
elif mode=='apply':
 if (stage/'applied.json').exists():raise RuntimeError('Cleanup already applied; use verify')
 assert (stage/'validated.json').exists(),'Validate backup first'
 m=json.loads((stage/'manifest.json').read_text());assert (stage/'backup.json').is_file() and (stage/'restore.sql').is_file()
 body="""transaction {
 queryExecute("SET LOCAL lock_timeout='2s'",{},{datasource="runner_dba"});
 queryExecute("SET LOCAL statement_timeout='15s'",{},{datasource="runner_dba"});
 c=queryExecute("SELECT started_at FROM tb_error_collector WHERE id=1 FOR UPDATE",{},{datasource="runner_dba"});
 if(c.recordCount!=1 || dateCompare(c.started_at[1],createDateTime(2026,9,26,0,0,0))<0)throw(message="Collector cutoff would reimport deleted problems");
 queryExecute("LOCK TABLE tb_error_problem,tb_error_occurrence,tb_error_history IN SHARE ROW EXCLUSIVE MODE",{},{datasource="runner_dba"});
 q=queryExecute(SNAPSHOT,{}, {datasource="runner_dba"});
 if(compare(q.checksum[1],CHECKSUM)!=0)throw(message="Data changed after backup; no deletion performed");
 guard=queryExecute("SELECT count(*) AS n FROM tb_error_occurrence WHERE occurred_at >= timestamp '2026-09-26 00:00:00' AND problem_id IN(SELECT id FROM tb_error_problem WHERE last_seen < timestamp '2026-09-26 00:00:00')",{},{datasource="runner_dba"});
 if(guard.n[1]!=0)throw(message="Recent occurrence in an old problem; aborting");
 retained=queryExecute("SELECT count(*) AS n FROM tb_error_problem WHERE last_seen >= timestamp '2026-09-26 00:00:00' OR last_seen IS NULL",{},{datasource="runner_dba"});
 report={deleted={},retained_problems=retained.n[1],original_logs_preserved=true};
 for(t in ["tb_error_history","tb_error_occurrence"]) {
  d=queryExecute("DELETE FROM " & t & " WHERE problem_id IN(SELECT id FROM tb_error_problem WHERE last_seen < timestamp '2026-09-26 00:00:00') RETURNING 1",{},{datasource="runner_dba"});
  report.deleted[t]=d.recordCount;
 }
 d=queryExecute("DELETE FROM tb_error_problem WHERE last_seen < timestamp '2026-09-26 00:00:00' RETURNING 1",{},{datasource="runner_dba"});report.deleted.tb_error_problem=d.recordCount;
 remaining=queryExecute("SELECT count(*) AS n FROM tb_error_problem",{},{datasource="runner_dba"});
 if(remaining.n[1]!=retained.n[1])throw(message="Unexpected remaining count");
}""".replace('SNAPSHOT',cfstr(snapshot)).replace('CHECKSUM',cfstr(m['checksum']))
 result=bridge(root,body);(stage/'applied.json').write_text(json.dumps(result));print(json.dumps(result))
else:
 result=bridge(root,"""q=queryExecute("SELECT count(*) AS total,count(*) FILTER(WHERE last_seen < timestamp '2026-09-26 00:00:00') AS old_problems FROM tb_error_problem",{},{datasource="runner_dba"});report={remaining=q.total[1],old_problems=q.old_problems[1]};""")
 ids=','.join(str(int(row['id_log'])) for row in json.loads((stage/'backup.json').read_text())['occurrences'])
 if ids:
  sql='SELECT count(*) AS n FROM tb_log WHERE id_log IN ('+ids+')'
  logs=bridge(root,'q=queryExecute('+cfstr(sql)+',{}, {datasource="runner_dba",timeout=15});report={preserved=q.n[1]};')
  result['original_logs_still_present']=logs['PRESERVED']
 print(json.dumps(result))
'''.replace('mode=MODE','mode='+repr(MODE))
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
p=subprocess.run(ssh+['python3 -c '+shlex.quote(source)],capture_output=True,text=True,timeout=110)
print(p.stdout)
if p.returncode:print(p.stderr[-2000:]);sys.exit(p.returncode)
(ROOT/'_codex/staging/error-triage-resources'/('cleanup-'+MODE+'.json')).write_text(p.stdout)
