from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('prepare','publish','verify')
n='includes/estrutura/footer.cfm';candidate=(S/'candidate'/n).read_text();b=json.loads((S/'nav-baseline.json').read_text());tests=json.loads((S/'footer-tests-green.json').read_text())
assert len(tests['checks'])==90 and not tests['failed'] and tests['source_hash']==hashlib.sha256(candidate.encode()).hexdigest()
remote='''
from pathlib import Path
import datetime,hashlib,json,os,pwd,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');stage=Path('/var/backups/seo-rr-80-20261022-nav');name='includes/estrutura/footer.cfm';target=root/name
def digest(t):return hashlib.sha256(t.read_bytes()).hexdigest()
def unchanged():
 for n,h in p['watch'].items():assert digest(root/n)==h,'Dependency changed: '+n
def baseline():
 assert digest(target)==p['before'][name],'Footer production conflict'
 unchanged()
if p['mode']=='prepare':
 baseline();stage.mkdir(mode=0o700,exist_ok=False);shutil.copy2(target,stage/'footer-before.cfm');(stage/'footer-candidate.cfm').write_text(p['candidate'])
 with tempfile.TemporaryDirectory(prefix='seo-footer-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);source=work/'source';source.mkdir();(source/'footer.cfm').write_text(p['candidate']);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  paths=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'));assert len(paths)==1
  executable=paths[0];user=pwd.getpwuid((executable.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
  cp=subprocess.run([str(executable),'-deploy','-cfruntimeuser',user,'-webroot',str(source),'-dir',str(source),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  assert cp.returncode==0 and 'Error compiling' not in output and count==1,output[-2000:]
 manifest={'before':p['before'],'after':p['hash'],'watch':p['watch'],'compiled_templates':count};(stage/'manifest.json').write_text(json.dumps(manifest,indent=2));result={'compiled_templates':count,'backup':str(stage/'footer-before.cfm')}
elif p['mode']=='publish':
 baseline();m=json.loads((stage/'manifest.json').read_text());assert m['after']==p['hash'] and digest(stage/'footer-candidate.cfm')==p['hash'];assert m['compiled_templates']==1
 ref=target.stat();fd,tmp=tempfile.mkstemp(prefix='.footer-seo-',dir=target.parent)
 try:
  with os.fdopen(fd,'wb') as f:f.write((stage/'footer-candidate.cfm').read_bytes())
  os.chmod(tmp,ref.st_mode & 0o777);os.chown(tmp,ref.st_uid,ref.st_gid);os.replace(tmp,target)
 finally:
  if Path(tmp).exists():Path(tmp).unlink()
 assert digest(target)==p['hash'];unchanged();result={'published':[name],'verified_hash':p['hash'],'preserved_dependencies':len(p['watch']),'published_at':datetime.datetime.now(datetime.timezone.utc).isoformat()};(stage/'published.json').write_text(json.dumps(result,indent=2))
else:
 assert digest(target)==p['hash'];unchanged();result={'verified_files':1,'preserved_dependencies':len(p['watch'])}
print(json.dumps(result))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({**b,'mode':mode,'candidate':candidate,'hash':tests['source_hash']}),capture_output=True,text=True,timeout=210)
assert cp.returncode==0,cp.stderr[-2500:]
r=json.loads(cp.stdout);(S/f'nav-{mode}.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
