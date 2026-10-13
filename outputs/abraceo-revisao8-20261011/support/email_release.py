from pathlib import Path
import base64,hashlib,json,os,shlex,shutil,subprocess,sys,tempfile,uuid
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
STAGE='/var/backups/business-email-long-tld-20261011'
NAMES=['services/EmailAddress.cfc','services/GoogleIdentityVerifier.cfc','services/BusinessAuthSession.cfc','services/BusinessRememberDevice.cfc','estudos/includes/StudyAccess.cfc']
def state(root):
 return bridge(root,"q=queryExecute(\"SELECT md5(coalesce(jsonb_agg(to_jsonb(v) ORDER BY id)::text,'[]')) hash FROM estudo.vouchers v\",{}, {datasource='runner_dba'});report={hash=q.hash[1]};")
def run_tests(root,stage,p,live=False):
 before=state(root);work=root/'_codex'/('email_candidate_'+uuid.uuid4().hex);work.mkdir(mode=0o755)
 try:
  (work/'.htaccess').write_text('Require local\n')
  paths={}
  for n in NAMES:
   name=Path(n).stem
   if live:paths[name]=n[:-4].replace('/','.');continue
   content=p['files'][n].replace('new services.EmailAddress()','createObject("component","_codex.'+work.name+'.EmailAddress")');(work/(name+'.cfc')).write_text(content);paths[name]='_codex.'+work.name+'.'+name
  tests=p['tests']
  for token,name in [('__EMAIL__','EmailAddress'),('__GOOGLE__','GoogleIdentityVerifier'),('__SESSION__','BusinessAuthSession'),('__STUDY__','StudyAccess')]:tests=tests.replace(token,paths[name])
  result=bridge(root,tests);assert state(root)==before,'Voucher regression was not rolled back';(stage/('live-tests.json' if live else 'tests.json')).write_text(json.dumps(result));return result
 finally:shutil.rmtree(work)
def remote(mode,p):
 root=Path('/var/www/business.roadrunners.run');stage=Path(STAGE)
 if mode=='prepare':
  prepare(root,stage,p['files'],p['before']);(stage/'payload.json').write_text(json.dumps(p));return {'prepared':5,'backup':STAGE}
 p=json.loads((stage/'payload.json').read_text())
 if mode=='compile':
  with tempfile.TemporaryDirectory(prefix='email-compile-',dir='/var/tmp') as d:
   w=Path(d);os.chmod(w,0o755);src=w/'source';shutil.copytree(stage/'candidate',src);dst=w/'compiled';dst.mkdir(mode=0o777);os.chmod(dst,0o777)
   r=subprocess.run(['/opt/coldfusion2025/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','coldfusion','-webroot',str(src),'-dir',str(src),'-deploydir',str(dst)],capture_output=True,text=True,timeout=160)
   result={'returncode':r.returncode,'compiled':len([f for f in dst.rglob('*') if f.is_file()]),'output':r.stdout+r.stderr};assert r.returncode==0 and result['compiled']>=5 and 'Error compiling' not in result['output'],result
   (stage/'compile.json').write_text(json.dumps(result));return {'compiled':result['compiled'],'returncode':0}
 if mode=='test':return run_tests(root,stage,p)
 if mode=='publish':
  assert (stage/'compile.json').exists() and (stage/'tests.json').exists();result=publish(root,stage);(stage/'published.json').write_text(json.dumps(result));return result
 if mode=='verify':
  result=verify(root,stage);result['runtime_tests']=run_tests(root,stage,p,True);return result
 raise ValueError(mode)
def main():
 mode=sys.argv[1]
 if mode=='--remote':
  p=json.load(sys.stdin);exec(p.pop('helpers'),globals());print(json.dumps(remote(sys.argv[2],p)));return
 s=(ROOT/'_codex/scripts/deploy_estudo.py').read_text();p={'helpers':s[s.index('def digest('):s.index('\ndef raw_query(')]}
 if mode=='prepare':p.update(files={n:(ROOT/n).read_text() for n in NAMES},before=json.loads((OUT/'email-baseline.json').read_text()),tests=(ROOT/'_codex/tests/business_email_long_tld.cfscript').read_text())
 source=Path(__file__).read_text().replace('ROOT=Path(__file__).resolve().parents[3]',"ROOT=Path('/var/www/business.roadrunners.run')",1).replace('OUT=Path(__file__).resolve().parent',"OUT=Path('/var/backups/business-email-long-tld-20261011')",1)
 r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)+' --remote '+shlex.quote(mode)],input=json.dumps(p),capture_output=True,text=True,timeout=180)
 if r.returncode:raise SystemExit(r.stderr[-3000:])
 result=json.loads(r.stdout);(OUT/('email-'+mode+'.json')).write_text(json.dumps(result));print(json.dumps(result))
if __name__=='__main__':main()
