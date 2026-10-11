from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[2];R=B.parent/'RoadRunners';mode=sys.argv[1];assert mode in ['prepare','publish','verify','rollback']
names=['.htaccess','atleta/.htaccess']
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/roadrunners.com.br')")
remote=helpers+'''
p=json.load(sys.stdin);root=ROOT;stage=Path('/var/backups/seo-athlete-route-20261008');mode=p['mode']
if mode=='prepare':
 baseline(root,p['watch'],p['watch']);result=prepare(root,stage,p['files'],p['before']);(stage/'watch.json').write_text(json.dumps(p['watch']))
 cp=subprocess.run(['apache2ctl','-t'],capture_output=True,text=True,timeout=30)
 if cp.returncode:raise RuntimeError('Apache config invalid: '+cp.stderr[-2000:])
 result={'prepared_files':2,'apache_syntax':'passed','backup':str(stage/'baseline'),'watched_dependencies':len(p['watch'])}
elif mode=='publish':
 m=json.loads((stage/'manifest.json').read_text());w=json.loads((stage/'watch.json').read_text())
 if p['tested_hashes']!=m['candidate']:raise RuntimeError('Apache fixture receipt differs')
 baseline(root,w,w);result=publish(root,stage)
 cp=subprocess.run(['apache2ctl','-t'],capture_output=True,text=True,timeout=30)
 if cp.returncode:
  rollback(root,stage);raise RuntimeError('Apache config invalid; rolled back: '+cp.stderr[-2000:])
 result['apache_syntax']='passed'
elif mode=='verify':
 result=verify(root,stage);w=json.loads((stage/'watch.json').read_text());baseline(root,w,w);result['preserved_dependencies']=len(w)
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode}
if mode=='prepare':
 watch=json.loads((S/'watch.json').read_text())
 for n in ['includes/backend/backend_require_login.cfm','includes/backend/backend_login.cfm']:watch[n]=hashlib.sha256((R/n).read_bytes()).hexdigest()
 payload.update(files={n:(S/'candidate'/n).read_text() for n in names},before=json.loads((S/'before.json').read_text()),watch=watch)
if mode=='publish':
 receipt=json.loads((S/'apache-tests.json').read_text());assert len(receipt['checks'])==24 and not receipt['failed'];assert len(json.loads((S/'public-before.json').read_text())['rows'])==22
 for n in names:assert hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest()==receipt['hashes'][n]
 # Guard the narrow edit independently of the rewrite fixture.
 for n in names:
  old=(S/'baseline'/n).read_text();new=(S/'candidate'/n).read_text();expected=old
  for line in old.splitlines():
   if n=='atleta/.htaccess' and 'index.cfm?tag=$1' in line or n=='.htaccess' and ('^en/athlete/([^/]+)/?$ ' in line or '^es/atleta/([^/]+)/?$ ' in line):expected=expected.replace(line,line.replace('[NC,L,QSA]','[B,NC,L,QSA]'))
  assert expected==new,n+' unexpected change'
 payload['tested_hashes']=receipt['hashes']
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=90)
if cp.returncode:raise RuntimeError(cp.stderr[-4000:])
r=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
