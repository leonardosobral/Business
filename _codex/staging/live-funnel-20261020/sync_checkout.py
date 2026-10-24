import hashlib,json,shutil
from pathlib import Path
B=Path(__file__).resolve().parent
root=Path('/Users/Shared/Projects/RunnerHub/RoadRunners')
rows=[line.split('\t') for line in (B/'release/runtime.tsv').read_text().splitlines()]
rr=[r for r in rows if r[0]=='RoadRunners']
for _,rel,before,after in rr:
 p=root/rel
 observed=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else 'ABSENT'
 assert observed in (before,after), 'Local concurrent change '+rel
 assert hashlib.sha256((B/'release/candidate/RoadRunners'/rel).read_bytes()).hexdigest()==after
for _,rel,before,after in rr:
 p=root/rel;p.parent.mkdir(parents=True,exist_ok=True)
 shutil.copyfile(B/'release/candidate/RoadRunners'/rel,p)
print(json.dumps({'runtime_synced':len(rr),'git_operations':False}))
