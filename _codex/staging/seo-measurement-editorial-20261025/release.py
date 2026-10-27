from pathlib import Path
import json,hashlib,subprocess,shlex,sys
S=Path(__file__).resolve().parent;B=S.parents[2];b=json.loads((S/'baseline.json').read_text());v=json.loads((S/'candidate-verified.json').read_text());mode=sys.argv[1];assert mode in ('prepare','publish','verify')
for g,d in b.items():
 names=sorted(d['names'],key=lambda n:n in d['before']);d['files']={n:(S/'candidate'/g/n).read_text() for n in names};d['hashes']={n:hashlib.sha256(c.encode()).hexdigest() for n,c in d['files'].items()};assert d['hashes']==v['hashes'][g]
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
import datetime
p=json.load(sys.stdin);results={};mode=p['mode']
for g,d in p['groups'].items():
 root=Path(d['root']);stage=Path('/var/backups/seo-measurement-editorial-20261025')/g
 baseline(root,d['watch'],d['watch'])
 if mode=='prepare':
  m=prepare(root,stage,d['files'],d['before']);results[g]={'backup':str(stage/'baseline'),'files':len(m['order'])}
 elif mode=='publish':
  m=json.loads((stage/'manifest.json').read_text());assert m['candidate']==d['hashes'];results[g]=publish(root,stage)
 else:results[g]=verify(root,stage)
results['at']=datetime.datetime.now(datetime.timezone.utc).isoformat();print(json.dumps(results))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'groups':b}),capture_output=True,text=True,timeout=60)
assert cp.returncode==0,cp.stderr[-2500:];r=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
