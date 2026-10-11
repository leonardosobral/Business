from pathlib import Path
import hashlib,json,sys
S=Path(__file__).resolve().parent;project=sys.argv[1];assert project in ['rr','business']
if project=='rr':
 root=Path('/Users/Shared/Projects/RunnerHub/RoadRunners');before=json.loads((S/'before.json').read_text());candidate=S/'candidate'
 assert json.loads((S/'public-passed.json').read_text())['passed'];assert json.loads((S/'release-verify.json').read_text())['verified_hashes']==2
else:
 root=Path('/Users/Shared/Projects/RunnerHub/Business');candidate=S/'candidate/business'
 before={n:hashlib.sha256((S/'baseline/business'/n).read_bytes()).hexdigest() for n in ['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm']}
 assert json.loads((S/'published-render-passed.json').read_text())['scenarios']==19
for n,sha in before.items():
 old=(root/n).read_bytes();new=(candidate/n).read_bytes()
 assert hashlib.sha256(old).hexdigest()==sha or old==new,n+' local drift'
for n in before:(root/n).write_bytes((candidate/n).read_bytes())
print(json.dumps({'local_files_updated':len(before),'project':project}))
