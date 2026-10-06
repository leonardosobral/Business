"""User-authorized exact exception purge; private compressed backup and per-row checksum guards."""
from pathlib import Path
import subprocess,shlex,json,sys
ROOT=Path(__file__).resolve().parents[2];mode=sys.argv[1];assert mode in ('backup','apply','verify')
source=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/opt/ColdFusion/cfusion/wwwroot')").replace("dir=root/'_codex'","dir=root").replace('https://business.roadrunners.run/_codex/','http://127.0.0.1:8500/').replace('requesttimeout="90"','requesttimeout="300"').replace("'95'","'305'").replace('timeout=100','timeout=310')
remote=r"""
import gzip,pwd,re,html,hashlib
stage=Path('/var/backups/business-purge-problem-26292-20261005')
def cfstr(s):return '"'+s.replace('"','""')+'"'
def call(body):return bridge(ROOT,body)
def sqlq(sql):return 'queryExecute('+cfstr(sql)+',{}, {datasource="runner_dba",timeout=30})'
if MODE=='backup':
 stage.mkdir(mode=0o700,exist_ok=False)
 with tempfile.TemporaryDirectory(prefix='purge-26292-',dir='/var/tmp') as work:
  w=Path(work);uid=pwd.getpwnam('nobody').pw_uid;os.chown(w,uid,-1);os.chmod(w,0o700)
  archive=w/'logs.jsonl.gz'
  sql="SELECT id_log,row_to_json(l)::text AS payload FROM tb_log l WHERE id_log>:after AND id_log<=45741685 AND site='OR' AND log_item='erro' AND log_item_id LIKE '%Could not find the ColdFusion component or interface services.RunnerAppsMenuCache.%' ORDER BY id_log LIMIT 250"
  body='''report={rows=0};after=45700417;out=createObject("java","java.util.zip.GZIPOutputStream").init(createObject("java","java.io.FileOutputStream").init(ARCHIVE));try {while(true){q=queryExecute(SQL,{after={value=after,cfsqltype="cf_sql_integer"}},{datasource="runner_dba",timeout=10});if(!q.recordCount)break;for(r in q){out.write(charsetDecode(r.payload & chr(10),"utf-8"));after=r.id_log;report.rows++;}fileWrite(PROGRESS,serializeJSON({rows=report.rows,last=after}));}}finally{out.close();}'''.replace('ARCHIVE',cfstr(str(archive))).replace('SQL',cfstr(sql)).replace('PROGRESS',cfstr(str(w/'progress.json')))
  (stage/'progress-path.txt').write_text(str(w/'progress.json'))
  result=call(body);shutil.copy2(archive,stage/'logs.jsonl.gz');os.chmod(stage/'logs.jsonl.gz',0o600)
 patterns={label:re.compile(r'<td[^>]*>\s*(?:<[^>]+>\s*)*'+label+r'\s*(?:</[^>]+>\s*)*</td>\s*<td[^>]*>([\s\S]*?)</td>',re.I) for label in ['MESSAGE','TYPE','TEMPLATE','LINE','DETAIL','SQLSTATE','FINGERPRINT']}
 def identity(raw):
  values=[]
  for label,pattern in patterns.items():
   m=pattern.search(raw[:200000]);v=html.unescape(re.sub('<[^>]*>',' ',m.group(1))).strip() if m else ''
   if label in ('MESSAGE','DETAIL'):v=re.sub(r'\s+',' ',v)
   if label=='TYPE':v=v.lower()
   values.append(v)
  return tuple(values)
 expected=None;count=0
 with gzip.open(stage/'logs.jsonl.gz','rt',encoding='utf-8') as f:
  for line in f:
   row=json.loads(line);count+=1
   if row['id_log']==45741685:expected=identity(row['log_item_id'])
 assert expected and expected[0]=='Could not find the ColdFusion component or interface services.RunnerAppsMenuCache.' and expected[1]=='cfml' and expected[2]=='/var/www/roadrunners.com.br/includes/estrutura/menu_apps_data.cfm' and expected[3]=='200' and not expected[6]
 assert count==result['ROWS']==30080,'Candidate count changed'
 plan=[]
 with gzip.open(stage/'logs.jsonl.gz','rt',encoding='utf-8') as f:
  for line in f:
   row=json.loads(line)
   if identity(row['log_item_id'])==expected:plan.append({'id':row['id_log'],'checksum':hashlib.md5(line.rstrip('\n').encode()).hexdigest()})
 assert any(p['id']==45741685 for p in plan)
 (stage/'plan.json').write_text(json.dumps(plan));os.chmod(stage/'plan.json',0o600)
 manifest={'backed_up':count,'selected':len(plan),'skipped':count-len(plan),'sha256':hashlib.sha256((stage/'logs.jsonl.gz').read_bytes()).hexdigest(),'compressed_bytes':(stage/'logs.jsonl.gz').stat().st_size,'backup':str(stage)}
 (stage/'manifest.json').write_text(json.dumps(manifest));print(json.dumps(manifest))
elif MODE=='apply':
 assert not (stage/'applied.json').exists(),'Already applied'
 m=json.loads((stage/'manifest.json').read_text());assert hashlib.sha256((stage/'logs.jsonl.gz').read_bytes()).hexdigest()==m['sha256']
 plan=json.loads((stage/'plan.json').read_text());assert len(plan)==m['selected'] and len({r['id'] for r in plan})==len(plan)
 # All original log rows are backed up already. Snapshot triage inside the same transaction as the deletion.
 setup='queryExecute("CREATE TEMP TABLE purge_26292_ids ON COMMIT DROP AS SELECT * FROM json_to_recordset(CAST(:plan AS json)) AS x(id integer,checksum text)",{plan={value=fileRead(PLANFILE),cfsqltype="cf_sql_longvarchar"}},{datasource="runner_dba",timeout=15})' 
 body='''transaction {
 queryExecute("SET LOCAL lock_timeout='3s'",{},{datasource="runner_dba"});
 queryExecute("SELECT id FROM tb_error_collector WHERE id=1 FOR UPDATE",{},{datasource="runner_dba",timeout=5});
 SETUP;
 q=queryExecute("SELECT count(*) AS n FROM tb_log l JOIN purge_26292_ids p ON p.id=l.id_log WHERE md5(row_to_json(l)::text)=p.checksum",{},{datasource="runner_dba",timeout=45});if(q.n[1]!=EXPECTED)throw(message="Original logs changed after backup; no deletion performed");
 q=queryExecute("SELECT p.id FROM tb_error_problem p WHERE p.id=26292 OR EXISTS(SELECT 1 FROM tb_error_occurrence o JOIN purge_26292_ids d ON d.id=o.id_log WHERE o.problem_id=p.id) ORDER BY p.id FOR UPDATE",{},{datasource="runner_dba",timeout=5});
 queryExecute("CREATE TEMP TABLE purge_26292_problems ON COMMIT DROP AS SELECT DISTINCT problem_id AS id FROM tb_error_occurrence o JOIN purge_26292_ids d ON d.id=o.id_log UNION SELECT 26292",{},{datasource="runner_dba"});
 q=queryExecute("SELECT json_build_object('problems',(SELECT json_agg(p) FROM tb_error_problem p JOIN purge_26292_problems d ON d.id=p.id),'occurrences',(SELECT json_agg(o) FROM tb_error_occurrence o JOIN purge_26292_ids d ON d.id=o.id_log),'history',(SELECT json_agg(h) FROM tb_error_history h JOIN purge_26292_problems d ON d.id=h.problem_id))::text AS snapshot",{},{datasource="runner_dba",timeout=10});
 fileWrite(SNAPSHOT,q.snapshot[1]);
 report={deletedOccurrences=0,deletedLogs=0};
 q=queryExecute("DELETE FROM tb_error_occurrence o USING purge_26292_ids d WHERE o.id_log=d.id RETURNING o.id_log",{},{datasource="runner_dba",timeout=15});report.deletedOccurrences=q.recordCount;
 q=queryExecute("DELETE FROM tb_log l USING purge_26292_ids d WHERE l.id_log=d.id RETURNING l.id_log",{},{datasource="runner_dba",timeout=30});report.deletedLogs=q.recordCount;if(report.deletedLogs!=EXPECTED)throw(message="Unexpected deleted count");
 queryExecute("INSERT INTO tb_error_history(problem_id,action,actor_id,from_status,to_status,note) SELECT p.id,'logs_purged',0,p.status,CASE WHEN EXISTS(SELECT 1 FROM tb_error_occurrence o WHERE o.problem_id=p.id) THEN p.status ELSE 'ignored' END,'Exclusão pontual de logs autorizada pelo administrador no chat; backup em /var/backups/business-purge-problem-26292-20261005. Logs excluídos: EXPECTED.' FROM tb_error_problem p JOIN purge_26292_problems d ON d.id=p.id",{},{datasource="runner_dba"});
 queryExecute("UPDATE tb_error_problem p SET occurrences=s.n,first_seen=s.first_seen,last_seen=s.last_seen,status=CASE WHEN s.n=0 THEN 'ignored' ELSE p.status END,version=version+1,updated_at=now() FROM (SELECT d.id,count(o.id_log) AS n,min(o.occurred_at) AS first_seen,max(o.occurred_at) AS last_seen FROM purge_26292_problems d LEFT JOIN tb_error_occurrence o ON o.problem_id=d.id GROUP BY d.id) s WHERE p.id=s.id",{},{datasource="runner_dba"});
}'''.replace('SETUP',setup).replace('EXPECTED',str(len(plan)))
 with tempfile.TemporaryDirectory(prefix='purge-26292-audit-',dir='/var/tmp') as work:
  w=Path(work);os.chown(w,pwd.getpwnam('nobody').pw_uid,-1);os.chmod(w,0o700)
  (w/'plan.json').write_text(json.dumps(plan));os.chmod(w/'plan.json',0o644)
  try:result=call(body.replace('SNAPSHOT',cfstr(str(w/'triage-before.json'))).replace('PLANFILE',cfstr(str(w/'plan.json'))))
  finally:
   if (w/'triage-before.json').exists():shutil.copy2(w/'triage-before.json',stage/'triage-before.json');os.chmod(stage/'triage-before.json',0o600)
 (stage/'applied.json').write_text(json.dumps(result));print(json.dumps(result))
else:
 assert (stage/'applied.json').exists()
 query="SELECT count(*) AS n FROM tb_log WHERE site='OR' AND log_item='erro' AND log_item_id LIKE '%Could not find the ColdFusion component or interface services.RunnerAppsMenuCache.%'"
 body='q='+sqlq(query)+';report={remainingMatchingLogs=q.n[1]};q=queryExecute("SELECT id,occurrences,status,first_seen,last_seen FROM tb_error_problem WHERE id=26292",{},{datasource="runner_dba"});report.problem=[];for(r in q)arrayAppend(report.problem,r);q=queryExecute("SELECT count(*) AS n FROM tb_error_occurrence WHERE problem_id=26292",{},{datasource="runner_dba"});report.linked=q.n[1];'
 result=call(body);(stage/'verified.json').write_text(json.dumps(result));print(json.dumps(result))
""".replace('MODE',repr(mode))
p=subprocess.run(['ssh','-o','BatchMode=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source+remote)],capture_output=True,text=True,timeout=650)
print(p.stdout);print(p.stderr[-1800:]);stage=ROOT/'_codex/staging/purge-26292-20261005';stage.mkdir(exist_ok=True);(stage/(mode+'.json')).write_text(p.stdout);raise SystemExit(p.returncode)
