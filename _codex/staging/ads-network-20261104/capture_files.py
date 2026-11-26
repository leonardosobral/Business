from pathlib import Path
import json,subprocess,shlex,hashlib
stage=Path(__file__).resolve().parent;root=stage.parents[2]
names=json.loads((stage/'files.json').read_text())
code='''from pathlib import Path
import json,hashlib,stat
root=Path('/var/www/business.roadrunners.run');out={}
for n in '''+repr(names)+''':
 p=(Path('/var/www/ads.roadrunners.run')/n.removeprefix('ads-network/')) if n.startswith('ads-network/') else root/n
 if not p.exists():out[n]={'exists':False,'sha256':None};continue
 s=p.stat();out[n]={'exists':True,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'mode':stat.S_IMODE(s.st_mode),'uid':s.st_uid,'gid':s.st_gid}
print(json.dumps({'files':out,'watch':{}}))
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],capture_output=True,text=True,check=True)
a=json.loads(r.stdout)
for name,row in a['files'].items():
 head=subprocess.run(['git','show','HEAD:'+name],cwd=root,capture_output=True)
 if head.returncode==0:
  if hashlib.sha256(head.stdout).hexdigest()!=row['sha256']:print('Production differs from HEAD: '+name)
 elif row['exists']:raise SystemExit('New path exists in production: '+name)
(stage/'production-baseline.json').write_text(json.dumps(a,indent=2));print('Production baseline captured; differences printed above require explicit review.')
