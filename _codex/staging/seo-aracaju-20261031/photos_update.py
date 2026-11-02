from pathlib import Path
import json,hashlib,shlex,subprocess,sys,os
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['prepare','publish','verify','sync']
name='includes/aracaju_2026.cfm';source=(S/'candidate/rr'/name).read_text();want=hashlib.sha256(source.encode()).hexdigest();old='f8f89ff4def6b540259d6d99b39fe2540e81bde1f2f8524534776d1dfbc7bbe7'
assert json.loads((S/'candidate-verified.json').read_text())['hashes']['rr'][name]==want
if mode=='sync':
 target=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')/name
 assert hashlib.sha256(target.read_bytes()).hexdigest() in [old,want]
 temp=target.with_name(target.name+'.aracaju-sync-tmp')
 with temp.open('xb') as f:f.write(source.encode())
 os.chmod(temp,target.stat().st_mode & 0o777);os.replace(temp,target);print('Photo include synchronized.');raise SystemExit
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
remote=helpers+'''
import datetime
p=json.load(sys.stdin);stage=Path('/var/backups/seo-aracaju-photos-20261031')
if p['mode']=='prepare':result=prepare(ROOT,stage,{p['name']:p['source']},{p['name']:p['old']})
elif p['mode']=='publish':result=publish(ROOT,stage)
else:result=verify(ROOT,stage)
result['at']=datetime.datetime.now(datetime.timezone.utc).isoformat();print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'name':name,'source':source,'old':old}),text=True,capture_output=True,timeout=60)
assert cp.returncode==0,cp.stderr[-1800:]
data=json.loads(cp.stdout);(S/('photos-'+mode+'.json')).write_text(json.dumps(data,indent=2)+'\n');print(json.dumps(data))
