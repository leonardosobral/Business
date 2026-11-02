from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1]
assert mode in ['prepare','publish','verify','rollback']
b=json.loads((S/'baseline.json').read_text());verified=json.loads((S/'candidate-verified.json').read_text())
projects={}
for k,v in b.items():
 files={str(p.relative_to(S/'candidate'/k)):p.read_text() for p in (S/'candidate'/k).rglob('*.cfm')}
 hashes={n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()}
 assert hashes==verified['hashes'][k]
 projects[k]={'root':v['root'],'files':dict(sorted(files.items(),key=lambda p:p[0] in v['files'])),'hashes':hashes,'before':{n:f['sha'] for n,f in v['files'].items() if f},'original':{n:f['text'] for n,f in v['files'].items() if f},'watch':v['watch']}
assert verified['compiledTemplates']==7 and verified['scenarios']==17
helpers=Path('_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+r'''
import datetime
p=json.load(sys.stdin);result={}
for k,v in p['projects'].items():
 root=Path(v['root']);stage=Path('/var/backups/seo-aracaju-20261031-rr')
 # A missing dependency is guarded as missing, without weakening production conflict detection.
 for n,want in v['watch'].items():
  target=root/n;actual=digest(target.read_bytes()) if target.exists() else None
  if actual!=want:raise RuntimeError('Dependency changed: '+k+'/'+n)
 if p['mode']=='prepare':
  if k=='rr':
   m=prepare(root,stage,v['files'],v['before']);result[k]={'files':len(m['order']),'backup':str(stage/'baseline')}
  else:
   baseline(root,v['files'],v['before']);result[k]={'files':len(v['files']),'recovery':'Exact source baseline retained in task workspace; no persistent server backup, per OpenResults preference.'}
 elif p['mode']=='publish':
  if k=='rr':
   m=json.loads((stage/'manifest.json').read_text());assert m['candidate']==v['hashes'];result[k]=publish(root,stage)
  else:
   baseline(root,v['files'],v['before']);reference=(root/next(iter(v['before']))).stat()
   with tempfile.TemporaryDirectory(prefix='seo-aracaju-transport-',dir='/var/tmp') as d:
    transport=Path(d)
    try:
     for n,c in v['files'].items():
      f=transport/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c);replace_file(f,root/n,reference)
     for n,want in v['hashes'].items():assert digest((root/n).read_bytes())==want,n
    except Exception:
     for n,c in v['original'].items():
      f=transport/'restore'/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c);replace_file(f,root/n,reference)
     for n in v['files']:
      if n not in v['before'] and (root/n).exists() and digest((root/n).read_bytes())==v['hashes'][n]:(root/n).unlink()
     raise
   result[k]={'published':list(v['files']),'persistentServerBackup':False,'recovery':'local exact baseline'}
 elif p['mode']=='verify':
  for n,want in v['hashes'].items():assert (root/n).is_file() and digest((root/n).read_bytes())==want,(k,n)
  result[k]={'verified_hashes':len(v['hashes']),'preserved_dependencies':len(v['watch'])}
 elif k=='rr':result[k]=rollback(root,stage)
 else:
  for n,want in v['hashes'].items():
   f=root/n
   if f.exists() and digest(f.read_bytes()) not in (want,v['before'].get(n)):raise RuntimeError('Concurrent change: '+n)
  reference=(root/next(iter(v['before']))).stat()
  with tempfile.TemporaryDirectory(prefix='seo-aracaju-restore-',dir='/var/tmp') as d:
   for n,c in v['original'].items():
    f=Path(d)/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c);replace_file(f,root/n,reference)
   for n in v['files']:
    if n not in v['before'] and (root/n).exists():(root/n).unlink()
  result[k]={'restored':list(v['before'])}
result['at']=datetime.datetime.now(datetime.timezone.utc).isoformat();print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'projects':projects}),text=True,capture_output=True,timeout=70)
assert cp.returncode==0,cp.stderr[-2200:]
d=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(d,indent=2)+'\n');print(json.dumps(d))
