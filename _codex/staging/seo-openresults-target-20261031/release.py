from pathlib import Path
import hashlib,json,shlex,subprocess,sys,os
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['baseline','publish','verify','sync']
name='includes/aracaju_2026.cfm';local=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')/name
watch=['estado/index.cfm','evento/index.cfm','includes/permanent_race_editorial.cfm']
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
if mode=='baseline':
 assert not (S/'baseline.json').exists()
 remote=helpers+'''\np=json.load(sys.stdin);f=ROOT/p['name'];print(json.dumps({'text':f.read_text(),'sha':digest(f.read_bytes()),'watch':{n:digest((ROOT/n).read_bytes()) for n in p['watch']}}))'''
 payload={'name':name,'watch':watch}
else:
 b=json.loads((S/'baseline.json').read_text());candidate=(S/'candidate.cfm').read_text();want=hashlib.sha256(candidate.encode()).hexdigest()
 if mode=='sync':
  assert hashlib.sha256(local.read_bytes()).hexdigest() in [b['localSha'],want]
  temp=local.with_name(local.name+'.seo-target-tmp')
  with temp.open('xb') as f:f.write(candidate.encode())
  os.chmod(temp,local.stat().st_mode & 0o777);os.replace(temp,local);print('Local source synchronized.');raise SystemExit
 payload={'name':name,'before':b['sha'],'watch':b['watch'],'text':candidate,'want':want,'mode':mode}
 remote=helpers+r'''
import datetime,pwd
p=json.load(sys.stdin);stage=Path('/var/backups/seo-openresults-target-20261031');baseline(ROOT,p['watch'],p['watch'])
if p['mode']=='publish':
 assert digest(p['text'].encode())==p['want']
 m=prepare(ROOT,stage,{p['name']:p['text']},{p['name']:p['before']})
 with tempfile.TemporaryDirectory(prefix='seo-link-compile-',dir='/var/tmp') as d:
  src=Path(d)/'src';src.mkdir();os.chmod(d,0o755);f=src/p['name'];f.parent.mkdir(parents=True);f.write_text(p['text']);out=Path(d)/'out';out.mkdir();os.chmod(out,0o777)
  exe=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'))[0];user=pwd.getpwuid((exe.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
  cp=subprocess.run([str(exe),'-deploy','-cfruntimeuser',user,'-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],text=True,capture_output=True,timeout=140)
  assert cp.returncode==0 and 'Error compiling' not in cp.stdout+cp.stderr and len(list(out.rglob('*.cfm')))==1,(cp.stdout+cp.stderr)[-1500:]
 result=publish(ROOT,stage);result['compiled']=1
else:result=verify(ROOT,stage)
result['at']=datetime.datetime.now(datetime.timezone.utc).isoformat();print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),text=True,capture_output=True,timeout=170)
assert cp.returncode==0,cp.stderr[-2000:]
data=json.loads(cp.stdout)
if mode=='baseline':
 data['localSha']=hashlib.sha256(local.read_bytes()).hexdigest();assert data['localSha']==data['sha'],'Inspect local/production difference before editing'
 original='href="https://openresults.run/evento/2026-maratona-de-aracaju-2026/"'
 assert data['text'].count(original)==1
 (S/'baseline.cfm').write_text(data['text'])
 (S/'candidate.cfm').write_text(data['text'].replace(original,original+' target="_blank" rel="noopener noreferrer"'))
 (S/'baseline.json').write_text(json.dumps(data,indent=2)+'\n');print('Baseline matches local source. Candidate changes one anchor only.')
else:
 (S/(mode+'.json')).write_text(json.dumps(data,indent=2)+'\n');print(json.dumps(data))
