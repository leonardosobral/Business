"""Scoped Estudo release. Backup, compile and migrate before exposing the admin route."""
from pathlib import Path
import base64, hashlib, json, os, shlex, shutil, subprocess, sys, tempfile
ROOT=Path(__file__).resolve().parents[2]
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
BASELINES={'includes/estrutura/sidenav.cfm':'b22a14ca770a329966610bb73c741d8d2f126b152251c5d7e54a3881e4ae0141'}
def digest(data):return hashlib.sha256(data).hexdigest()
def check_paths(root,files):
 for name in files:
  rel=Path(name)
  if rel.is_absolute() or '..' in rel.parts:raise RuntimeError('Invalid path')
  target=root/rel
  current=target
  while current!=root.parent:
   if current.is_symlink():raise RuntimeError('Symlink: '+name)
   current=current.parent
def baseline(root,files,before):
 check_paths(root,files)
 for name in files:
  p=root/name
  if name in before:
   if not p.is_file() or digest(p.read_bytes())!=before[name]:raise RuntimeError('Production conflict: '+name)
  elif p.exists():raise RuntimeError('New target already exists: '+name)
def prepare(root,stage,files,before):
 baseline(root,files,before)
 stage.mkdir(mode=0o700,parents=True,exist_ok=False)
 manifest={'before':before,'candidate':{},'order':list(files)}
 for name,content in files.items():
  source=stage/'candidate'/name;source.parent.mkdir(parents=True,exist_ok=True);source.write_text(content)
  manifest['candidate'][name]=digest(source.read_bytes())
  if name in before:
   backup=stage/'baseline'/name;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/name,backup)
 (stage/'manifest.json').write_text(json.dumps(manifest,indent=2))
 return manifest
def replace_file(source,target,reference):
 target.parent.mkdir(parents=True,exist_ok=True)
 temp=target.with_name(target.name+'.triage-new')
 with temp.open('xb') as out:out.write(source.read_bytes())
 os.chmod(temp,reference.st_mode & 0o777)
 if os.geteuid()==0:os.chown(temp,reference.st_uid,reference.st_gid)
 os.replace(temp,target)
def publish(root,stage):
 m=json.loads((stage/'manifest.json').read_text());baseline(root,m['order'],m['before'])
 for name,want in m['candidate'].items():
  if digest((stage/'candidate'/name).read_bytes())!=want:raise RuntimeError('Candidate changed: '+name)
 reference=(root/next(iter(m['before']))).stat()
 # New entry works with both old and new home; switch it before the new view.
 tail=[n for n in ['estudo/home.cfm','estudo/api.cfm','estudo/index.cfm','includes/estrutura/sidenav.cfm'] if n in m['order']]
 order=[n for n in m['order'] if n not in tail]+tail
 try:
  for name in order:replace_file(stage/'candidate'/name,root/name,reference)
  verify(root,stage)
 except Exception:
  rollback(root,stage);raise
 return {'published':order,'backup':str(stage/'baseline')}
def verify(root,stage):
 m=json.loads((stage/'manifest.json').read_text())
 for name,want in m['candidate'].items():
  if not (root/name).is_file() or digest((root/name).read_bytes())!=want:raise RuntimeError('Runtime hash mismatch: '+name)
 return {'verified_hashes':len(m['candidate'])}
def rollback(root,stage):
 m=json.loads((stage/'manifest.json').read_text());check_paths(root,m['order'])
 for name,want in m['candidate'].items():
  target=root/name
  if target.exists() and digest(target.read_bytes()) not in (want,m['before'].get(name)):raise RuntimeError('Concurrent change; manual recovery: '+name)
 for name in reversed(m['order']):
  target=root/name
  if name in m['before']:replace_file(stage/'baseline'/name,target,(stage/'baseline'/name).stat())
  elif target.exists():target.unlink()
 return {'restored':list(m['before']),'database_preserved':True}
def bridge(root,body):
 import secrets
 work=Path(tempfile.mkdtemp(prefix='error-triage-op-',dir=root/'_codex'));os.chmod(work,0o755)
 token=secrets.token_hex(24)
 try:
  (work/'.htaccess').write_text('Require local\n')
  (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
  (work/'run.cfm').write_text('<cfsetting requesttimeout="90" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>'+body+'writeOutput(serializeJSON(report));</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>')
  p=subprocess.run(['curl','-sS','--max-time','95','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=100)
  result=json.loads(p.stdout)
  if any(k.lower()=='error' for k in result):raise RuntimeError(json.dumps(result))
  return result
 finally:shutil.rmtree(work)

def raw_query(sql,target='q'):
 encoded=base64.b64encode(sql.encode()).decode()
 return 'cfquery(name="'+target+'",datasource="runner_dba",timeout=50){writeOutput(toString(binaryDecode("'+encoded+'","base64")));}'
def legacy_sql(schema='public'):
 n='SELECT notebook_id,notebook_title,tag,call_order FROM '+schema+'.notebooks'+(" WHERE source_key IS NULL" if schema=='estudo' else '')
 c='SELECT id,notebook_id,cell_order,cell_type,lang,content,updated_at FROM '+schema+'.notebook_cells'+(" WHERE source_key IS NULL" if schema=='estudo' else '')
 return "SELECT jsonb_build_object('notebooks',(SELECT coalesce(jsonb_agg(to_jsonb(n) ORDER BY notebook_id),'[]') FROM ("+n+") n),'cells',(SELECT coalesce(jsonb_agg(to_jsonb(c) ORDER BY id),'[]') FROM ("+c+") c))::text AS payload"
def remote(mode,payload):
 root=Path('/var/www/business.roadrunners.run');stage=Path('/var/backups/business-estudo-20260928')
 if mode=='prepare':return prepare(root,stage,payload['files'],BASELINES)

 if mode=='source-metadata':
  return bridge(root,'transaction {'+raw_query(payload['sql'])+'}report={registered=true};')
 if mode=='evidence':
  sql="""SELECT jsonb_build_object(
   'source_details',(SELECT jsonb_agg(jsonb_build_object('id',id,'source_key',source_key,'file',origem->>'arquivo','file_sha',origem->>'sha256_copia','text_sha',encode(sha256(convert_to(content,'UTF8')),'hex'))) FROM estudo.notebook_cells WHERE source_key LIKE '%-cell-2'),
   'source_files',(SELECT count(*) FROM estudo.notebook_cells WHERE source_key LIKE '%-cell-2'),
   'source_text_hashes_match',(SELECT bool_and(encode(sha256(convert_to(content,'UTF8')),'hex')=coalesce(origem->>'sha256_texto_importado',origem->>'sha256_copia')) FROM estudo.notebook_cells WHERE source_key LIKE '%-cell-2'),
   'runs',(SELECT jsonb_agg(jsonb_build_object('id',id,'cell_id',cell_id,'revision',cell_version,'status',status,'frozen',frozen,'rows',row_count,'duration_ms',duration_ms) ORDER BY id) FROM estudo.notebook_runs),
   'writer_role',current_user,
   'reader',(SELECT jsonb_build_object('name',rolname,'superuser',rolsuper,'login',rolcanlogin,'create_role',rolcreaterole) FROM pg_roles WHERE rolname='estudo_reader'),
   'validation_cell',(SELECT jsonb_build_object('id',id,'revision',version,'archived',archived) FROM estudo.notebook_cells WHERE id=115)
  )::text AS payload"""
  return bridge(root,raw_query(sql)+'report=deserializeJSON(q.payload[1]);')
 if mode=='close-initial-run':
  return bridge(root,raw_query("UPDATE estudo.notebook_runs SET status='error',finished_at=clock_timestamp(),duration_ms=(extract(epoch FROM (clock_timestamp()-started_at))*1000)::integer,error_message='Execução interrompida durante a validação inicial da migração (tipo booleano do Adobe). Execute novamente.' WHERE id=3 AND status='running' RETURNING id")+'report={closed=q.recordCount};')
 if mode=='diagnose':
  body=raw_query("SELECT id,status,error_message FROM estudo.notebook_runs ORDER BY id DESC LIMIT 3")
  body+='report={runs=[]};for(i=1;i<=q.recordCount;i++)arrayAppend(report.runs,{id=q.id[i],status=q.status[i],error=q.error_message[i]});'
  body+='function testEmptyQuery(){var emptyResult=queryNew("");transaction{cfquery(name="local.emptyResult",datasource="runner_dba"){writeOutput("SET LOCAL statement_timeout=\'45s\'");}}return {exists=!isNull(local.emptyResult),is_query=!isNull(local.emptyResult)&&isQuery(local.emptyResult)};}report.empty_command=testEmptyQuery();'
  return bridge(root,body)
 if mode=='update':
  import time
  current=json.loads((stage/'manifest.json').read_text())
  update_stage=stage/'updates'/str(time.time_ns())
  prepare(root,update_stage,payload['files'],current['candidate'])
  with tempfile.TemporaryDirectory(prefix='estudo-update-compile-',dir='/var/tmp') as d:
   work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(update_stage/'candidate',source);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
   p=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=160)
   output=p.stdout+p.stderr
   if p.returncode!=0 or 'Error compiling' in output or not any(compiled.rglob('*.cfm')):raise RuntimeError('Compilation failed: '+output)
  result=publish(root,update_stage)
  updated=json.loads((update_stage/'manifest.json').read_text());current['candidate']=updated['candidate'];current['order']=updated['order']
  (stage/'manifest.json').write_text(json.dumps(current,indent=2))
  result['compile']=output;return result
 if mode=='restage':
  if (stage/'migration.json').exists():raise RuntimeError('Already migrated; use explicit patch deployment')
  m=json.loads((stage/'manifest.json').read_text());baseline(root,payload['files'],m['before'])
  for name,want in m['candidate'].items():
   if digest((stage/'candidate'/name).read_bytes())!=want:raise RuntimeError('Candidate drift: '+name)
  for name,content in payload['files'].items():
   target=stage/'candidate'/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(content)
  m['order']=list(payload['files']);m['candidate']={n:digest((stage/'candidate'/n).read_bytes()) for n in m['order']}
  (stage/'manifest.json').write_text(json.dumps(m,indent=2))
  if (stage/'compile.json').exists():(stage/'compile.json').unlink()
  return {'restaged':len(m['order'])}
 if mode=='compile':
  with tempfile.TemporaryDirectory(prefix='estudo-compile-',dir='/var/tmp') as d:
   work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
   p=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=160)
   result={'returncode':p.returncode,'output':p.stdout+p.stderr,'compiled_files':len([p for p in compiled.rglob('*') if p.is_file()])}
   (stage/'compile.json').write_text(json.dumps(result));return result
 if mode=='backup':
  if (stage/'database-before.json').exists():raise RuntimeError('Backup already exists; inspect before repeating')
  sql=legacy_sql()
  body='transaction isolation="repeatable_read" {'+raw_query("SET TRANSACTION READ ONLY")+raw_query("SET LOCAL TIME ZONE 'UTC'")+raw_query(sql)+'report={legacy_json=q.payload[1]};'+raw_query("SELECT coalesce(jsonb_agg(jsonb_build_object('id',id_snapshot,'sha',conteudo_sha256) ORDER BY id_snapshot),'[]')::text AS payload FROM estudo.snapshots")+'report.snapshots_json=q.payload[1];'+raw_query("SELECT coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'name',p.proname,'security_definer',p.prosecdef,'volatility',p.provolatile,'definition',pg_get_functiondef(p.oid))),'[]')::text AS payload FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE p.proname='extrair_faixa_etaria'")+'report.function_json=q.payload[1];}'
  result=bridge(root,body);result={k.lower():v for k,v in result.items()}
  (stage/'database-before.json').write_text(json.dumps(result,ensure_ascii=False));os.chmod(stage/'database-before.json',0o600)
  legacy=json.loads(result['legacy_json'])
  return {'backup':str(stage/'database-before.json'),'notebooks':len(legacy['notebooks']),'cells':len(legacy['cells']),'snapshot_count':len(json.loads(result['snapshots_json'])),'functions':json.loads(result['function_json'])}
 if mode=='migrate':
  if (stage/'migration.json').exists():return json.loads((stage/'migration.json').read_text())
  compiled=json.loads((stage/'compile.json').read_text())
  if compiled['returncode']!=0 or compiled['compiled_files']==0 or 'Error compiling' in compiled['output']:raise RuntimeError('Compilation not confirmed')
  saved=json.loads((stage/'database-before.json').read_text())
  before_hash=hashlib.sha256(saved['legacy_json'].encode()).hexdigest()
  body='transaction {'+raw_query("SET LOCAL lock_timeout='3s'")+raw_query("SET LOCAL TIME ZONE 'UTC'")+raw_query("LOCK TABLE public.notebooks,public.notebook_cells IN ACCESS EXCLUSIVE MODE")+raw_query(legacy_sql())+'if(lCase(hash(q.payload[1],"SHA-256","UTF-8"))!="'+before_hash+'")throw(message="Legacy changed after backup; review before migrating");'+raw_query(payload['sql'])+raw_query(payload['sources'])+raw_query(legacy_sql('estudo'))+'if(lCase(hash(q.payload[1],"SHA-256","UTF-8"))!="'+before_hash+'")throw(message="Legacy integrity mismatch; rolling back");report={legacy_preserved=true};'+raw_query("SELECT count(*) AS n FROM estudo.notebooks")+'report.sections=q.n[1];'+raw_query("SELECT count(*) AS n FROM estudo.notebook_cells")+'report.cells=q.n[1];}'
  result=bridge(root,body);(stage/'migration.json').write_text(json.dumps(result))
  return result
 if mode=='publish':
  if not (stage/'migration.json').exists():raise RuntimeError('Migration not verified')
  result=publish(root,stage);(stage/'published.json').write_text(json.dumps(result));return result
 if mode=='verify':
  report=verify(root,stage)
  result=bridge(root,raw_query("SELECT jsonb_build_object('books',(SELECT count(*) FROM estudo.cadernos),'sections',(SELECT count(*) FROM estudo.notebooks),'cells',(SELECT count(*) FROM estudo.notebook_cells),'revisions',(SELECT count(*) FROM estudo.notebook_revisions),'old_tables_absent',to_regclass('public.notebooks') IS NULL AND to_regclass('public.notebook_cells') IS NULL,'reader_superuser',(SELECT rolsuper FROM pg_roles WHERE rolname='estudo_reader'),'snapshots',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',id_snapshot,'sha',conteudo_sha256) ORDER BY id_snapshot),'[]') FROM estudo.snapshots))::text AS payload")+'report=deserializeJSON(q.payload[1]);')
  saved=json.loads((stage/'database-before.json').read_text())
  lower={k.lower():v for k,v in result.items()}
  if json.loads(saved['snapshots_json'])!=lower['snapshots']:raise RuntimeError('Snapshot catalog changed; review')
  report['database']=result;(stage/'verified.json').write_text(json.dumps(report));return report
 if mode=='rollback':return rollback(root,stage)
 raise RuntimeError('Unknown operation')
def main():
 mode=sys.argv[1]
 if mode=='--remote':
  payload=json.load(sys.stdin);print(json.dumps(remote(sys.argv[2],payload)));return
 payload={}
 if mode in ('prepare','restage','update'):
  names=[str(p.relative_to(ROOT)) for p in (ROOT/'estudo').rglob('*') if p.is_file()]+list(BASELINES)
  payload['files']={f:(ROOT/f).read_text() for f in names}
 if mode=='source-metadata':payload['sql']=(ROOT/'_codex/sql/2026-09-28_estudo_source_metadata.sql').read_text()
 if mode=='migrate':
  payload['sql']=(ROOT/'_codex/sql/2026-09-28_estudo_notebook.sql').read_text()
  payload['sources']=(ROOT/'_codex/sql/2026-09-28_estudo_sources.sql').read_text()
 source=Path(__file__).read_text().replace("ROOT=Path(__file__).resolve().parents[2]","ROOT=Path('/var/www/business.roadrunners.run')")
 p=subprocess.run(SSH+['python3 -c '+shlex.quote(source)+' --remote '+shlex.quote(mode)],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
 if p.returncode:print(p.stderr[-6000:]);sys.exit(p.returncode)
 data=json.loads(p.stdout);dest=ROOT/'_codex/staging/estudo';dest.mkdir(parents=True,exist_ok=True)
 (dest/('release-'+mode+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2))
 print(json.dumps(data,ensure_ascii=False))
 if mode=='compile' and (data['returncode']!=0 or data['compiled_files']==0 or 'Error compiling' in data['output']):sys.exit(1)
if __name__=='__main__':main()
