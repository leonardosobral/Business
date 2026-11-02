from pathlib import Path
import hashlib,json,os
S=Path(__file__).resolve().parent;b=json.loads((S/'baseline.json').read_text());receipt=json.loads((S/'candidate-verified.json').read_text());jobs=[]
for k,v in b.items():
 for p in (S/'candidate'/k).rglob('*.cfm'):
  name=str(p.relative_to(S/'candidate'/k));target=Path('/Users/Shared/Projects/RunnerHub')/v['local']/name
  actual=hashlib.sha256(target.read_bytes()).hexdigest() if target.exists() else None
  want=receipt['hashes'][k][name]
  assert actual in (v['localHashes'].get(name),want),('Concurrent local edit',str(target))
  assert hashlib.sha256(p.read_bytes()).hexdigest()==want
  jobs.append((p,target,want))
for source,target,want in jobs:
 target.parent.mkdir(parents=True,exist_ok=True);temp=target.with_name(target.name+'.aracaju-sync-tmp')
 with temp.open('xb') as f:f.write(source.read_bytes())
 if target.exists():os.chmod(temp,target.stat().st_mode & 0o777)
 os.replace(temp,target)
 assert hashlib.sha256(target.read_bytes()).hexdigest()==want
print(json.dumps({'synced':len(jobs),'localGuardsPassed':True}))
