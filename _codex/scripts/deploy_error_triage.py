"""Scoped release with immutable baseline, recoverable backup and atomic file replacement."""
from pathlib import Path
import base64, hashlib, json, os, shlex, shutil, subprocess, sys, tempfile
ROOT=Path(__file__).resolve().parents[2]
BASELINES={
 'portal/erros/index.cfm':'246184b8c8e9142701b6f2bfa56970f89d2e35e3ad19c62255172a7442adbff2',
 'portal/erros/home.cfm':'36237d7d7a18d3a86ffeb6059f968a7eb26bf51f2bc5a53ea474ed3372726d98',
 'portal/includes/error_log_backend.cfm':'dfdc2e0e7d5e8df53676cef63172c31cef3f56d96cc4610415e1815105657141'}
FILES=['portal/erros/includes/'+f for f in ['ErrorNormalizer.cfc','ErrorTriage.cfc','init.cfm','actions.cfm','workspace.cfm']]+['portal/erros/assets/triage.css','portal/erros/assets/triage.js','portal/erros/export.cfm','portal/includes/error_log_backend.cfm','portal/erros/home.cfm','portal/erros/index.cfm']
SSH=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
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
 tail=[n for n in ['portal/erros/index.cfm','portal/erros/home.cfm'] if n in m['order']]
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
def remote(mode,payload):
 root=Path('/var/www/business.roadrunners.run');stage=Path('/var/backups/business-error-triage-20260926')
 if mode=='prepare':return prepare(root,stage,payload['files'],BASELINES)
 if mode=='compile':
  with tempfile.TemporaryDirectory(prefix='error-triage-compile-',dir='/var/tmp') as d:
   work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
   p=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=160)
   result={'returncode':p.returncode,'output':p.stdout+p.stderr,'compiled_files':len([p for p in compiled.rglob('*') if p.is_file()])}
   (stage/'compile.json').write_text(json.dumps(result));return result
 if mode=='migrate':
  if (stage/'migration.json').exists():return json.loads((stage/'migration.json').read_text())
  compiled=json.loads((stage/'compile.json').read_text())
  if compiled['returncode']!=0 or compiled['compiled_files']==0:raise RuntimeError('Compilation not confirmed')
  encoded=base64.b64encode(payload['sql'].encode()).decode()
  result=bridge(root,'transaction {existing=queryExecute("SELECT count(*) AS n FROM information_schema.tables WHERE table_schema=\'public\' AND table_name IN (\'tb_error_problem\',\'tb_error_occurrence\',\'tb_error_history\',\'tb_error_collector\')",{},{datasource="runner_dba"});if(existing.n[1]!=0)throw(message="Existing triage objects: review required");queryExecute(toString(binaryDecode("'+encoded+'","base64")),{},{datasource="runner_dba"});}q=queryExecute("SELECT count(*) AS n FROM information_schema.tables WHERE table_schema=\'public\' AND table_name IN (\'tb_error_problem\',\'tb_error_occurrence\',\'tb_error_history\',\'tb_error_collector\')",{},{datasource="runner_dba"});report={tables=q.n[1]};')
  if result.get('TABLES',result.get('tables'))!=4:raise RuntimeError('Schema incomplete')
  (stage/'migration.json').write_text(json.dumps(result));return result
 if mode=='publish':
  if not (stage/'migration.json').exists():raise RuntimeError('Migration not verified')
  result=publish(root,stage);(stage/'published.json').write_text(json.dumps(result));return result
 if mode=='verify':return verify(root,stage)
 if mode=='rollback':return rollback(root,stage)
 raise RuntimeError('Unknown operation')
def main():
 mode=sys.argv[1]
 if mode=='--remote':
  payload=json.load(sys.stdin);print(json.dumps(remote(sys.argv[2],payload)));return
 payload={}
 if mode=='prepare':payload['files']={f:(ROOT/f).read_text() for f in FILES}
 if mode=='migrate':payload['sql']=(ROOT/'_codex/sql/2026-09-26_error_triage.sql').read_text()
 source=Path(__file__).read_text().replace("ROOT=Path(__file__).resolve().parents[2]","ROOT=Path('/var/www/business.roadrunners.run')")
 command='python3 -c '+shlex.quote(source)+' --remote '+shlex.quote(mode)
 p=subprocess.run(SSH+[command],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
 if p.returncode:print(p.stderr[-4000:]);sys.exit(p.returncode)
 data=json.loads(p.stdout);(ROOT/'_codex/staging/error-triage'/('release-'+mode+'.json')).write_text(json.dumps(data,indent=2));print(json.dumps(data))
 if mode=='compile' and (data['returncode']!=0 or data['compiled_files']==0):sys.exit(1)
if __name__=='__main__':main()
