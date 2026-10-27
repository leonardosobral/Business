from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent;B=S.parents[2];v=json.loads((S/'candidate-verified.json').read_text());b=json.loads((S/'baseline.json').read_text())
names=['assets/js/runnerhub-pace.js','assets/js/runnerhub-pace.min.js','calculadora-de-pace/index.cfm'];files={n:(S/'candidate'/n).read_text() for n in names};before={n:v['hashes'][n] for n in names}
for n in b['names']:
 if n not in names:assert hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest()==v['hashes'][n]
cp=subprocess.run(['node','--test',str(S/'pace.test.cjs')],capture_output=True,text=True);assert cp.returncode==0,cp.stdout
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
remote=helpers+'''
import pwd
p=json.load(sys.stdin);main=Path('/var/backups/seo-regionais-pace-20261025');stage=main/'updates/national-context';root=ROOT
baseline(root,p['watch'],p['watch']);prepare(root,stage,p['files'],p['before'])
with tempfile.TemporaryDirectory(prefix='pace-context-compile-',dir='/var/tmp') as d:
 os.chmod(d,0o755);src=Path(d)/'src';shutil.copytree(stage/'candidate',src);out=Path(d)/'out';out.mkdir();os.chmod(out,0o777);exe=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'))[0];user=pwd.getpwuid((exe.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
 cp=subprocess.run([str(exe),'-deploy','-cfruntimeuser',user,'-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170);output=cp.stdout+cp.stderr;assert cp.returncode==0 and 'Error compiling' not in output and len(list(out.rglob('*.cfm')))==1,output[-2000:]
result=publish(root,stage);m=json.loads((main/'manifest.json').read_text());update=json.loads((stage/'manifest.json').read_text())
for n,h in update['candidate'].items():
 shutil.copyfile(stage/'candidate'/n,main/'candidate'/n);m['candidate'][n]=h
(main/'manifest.json').write_text(json.dumps(m,indent=2));verify(root,main);result['compiled_templates']=1;print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files,'before':before,'watch':b['watch']}),capture_output=True,text=True,timeout=210);assert cp.returncode==0,cp.stderr[-2500:]
r=json.loads(cp.stdout);(S/'release-national-context.json').write_text(json.dumps(r,indent=2)+'\n')
v['hashes'].update({n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()});v['followup']='National calendar context: 10 Node tests and calculator recompiled; public UI verification follows.';(S/'candidate-verified.json').write_text(json.dumps(v,indent=2)+'\n');print(json.dumps(r,indent=2))
