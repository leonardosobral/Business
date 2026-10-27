"""Scoped release. No database writes or unrelated repository operations."""
from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[2];mode=sys.argv[1];assert mode in ('prepare','publish','verify','rollback','patch')
b=json.loads((S/'baseline.json').read_text());v=json.loads((S/'candidate-verified.json').read_text())
order=[n for n in b['names'] if n not in b['before']]+[n for n in b['names'] if n in b['before'] and n not in ['includes/backend/backend.cfm','api/eventos.cfm','estado/index.cfm']]+['includes/backend/backend.cfm','api/eventos.cfm','estado/index.cfm']
files={n:(S/'candidate'/n).read_text() for n in order};hashes={n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()}
assert hashes==v['hashes'] and v['compiledTemplates']==10 and v['scenarios']==21,'Candidate lacks current verification'
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
remote=helpers+'''
import datetime
p=json.load(sys.stdin);stage=Path('/var/backups/seo-regionais-pagination-20261025');root=ROOT
if p['mode']=='prepare':
 baseline(root,p['watch'],p['watch']);m=prepare(root,stage,p['files'],p['before']);result={'backup':str(stage/'baseline'),'files':len(m['order'])}
elif p['mode']=='publish':
 m=json.loads((stage/'manifest.json').read_text());assert m['candidate']==p['hashes'];baseline(root,p['watch'],p['watch']);result=publish(root,stage);result['published_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();(stage/'published.json').write_text(json.dumps(result,indent=2))
elif p['mode']=='patch':
 m=json.loads((stage/'manifest.json').read_text());baseline(root,m['order'],m['candidate']);baseline(root,p['watch'],p['watch'])
 changes={n:c for n,c in p['files'].items() if p['hashes'][n]!=m['candidate'][n]};assert len(changes)==3
 update=stage/'slider-fix';prepare(root,update,changes,{n:m['candidate'][n] for n in changes});result=publish(root,update)
 for n,c in changes.items():(stage/'candidate'/n).write_text(c)
 m['candidate']=p['hashes'];(stage/'manifest.json').write_text(json.dumps(m,indent=2));result['verified_hashes']=verify(root,stage)['verified_hashes']
elif p['mode']=='verify':
 result=verify(root,stage);baseline(root,p['watch'],p['watch']);result['preserved_dependencies']=len(p['watch'])
else:result=rollback(root,stage)
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'files':files,'before':b['before'],'watch':b['watch'],'hashes':hashes}),capture_output=True,text=True,timeout=60)
assert cp.returncode==0,cp.stderr[-2500:]
r=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2))
