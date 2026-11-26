from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[2];mode=sys.argv[1];assert mode in ('prepare','restage','publish','verify','rollback')
names=['portal/includes/seo_semrush_archive_backend.cfm','portal/conteudo/seo_semrush_archive.cfm','portal/seo/arquivo.cfm','portal/conteudo/seo_semrush.cfm']
files={n:(B/n).read_text() for n in names};b=json.loads((S/'baseline.json').read_text())
hashes={n:hashlib.sha256(v.encode()).hexdigest() for n,v in files.items()}
if mode=='publish':
 t=json.loads((S/'candidate-verified.json').read_text());assert t['scenarios']>=28 and t['cleanup'] and t['hashes']==hashes
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+r'''
import datetime,pwd
p=json.load(sys.stdin);root=ROOT;stage=Path('/var/backups/seo-semrush-archive-20261104')
if p['mode'] in ('prepare','restage'):
 baseline(root,p['watch'],p['watch'])
 if p['mode']=='prepare':prepare(root,stage,p['files'],p['before'])
 else:
  assert not (stage/'published.json').exists();baseline(root,p['files'],p['before'])
  m=json.loads((stage/'manifest.json').read_text())
  for n,h in m['candidate'].items():assert digest((stage/'candidate'/n).read_bytes())==h
  for n,body in p['files'].items():(stage/'candidate'/n).write_text(body)
  m['candidate']=p['hashes'];m['order']=list(p['files']);(stage/'manifest.json').write_text(json.dumps(m,indent=2))
 with tempfile.TemporaryDirectory(prefix='seo-archive-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  ex=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'));assert len(ex)==1
  user=pwd.getpwuid((ex[0].parent.parent/'lib/seed.properties').stat().st_uid).pw_name
  cp=subprocess.run([str(ex[0]),'-deploy','-cfruntimeuser',user,'-webroot',str(source),'-dir',str(source),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  assert cp.returncode==0 and 'Error compiling' not in output and count==4,output[-3000:]
 (stage/'compiled.json').write_text(json.dumps({'templates':count,'manifest_sha':digest((stage/'manifest.json').read_bytes())}))
 result={'compiled_templates':count,'backup':str(stage/'baseline')}
elif p['mode']=='publish':
 c=json.loads((stage/'compiled.json').read_text());m=json.loads((stage/'manifest.json').read_text())
 assert c['templates']==4 and c['manifest_sha']==digest((stage/'manifest.json').read_bytes()) and m['candidate']==p['hashes']
 baseline(root,p['watch'],p['watch']);result=publish(root,stage);baseline(root,p['watch'],p['watch']);result['published_at']=datetime.datetime.now(datetime.timezone.utc).isoformat()
 (stage/'published.json').write_text(json.dumps(result))
elif p['mode']=='verify':
 result=verify(root,stage);baseline(root,p['watch'],p['watch']);result['preserved_dependencies']=len(p['watch'])
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode,'files':files,'before':b['before'],'watch':b['watch'],'hashes':hashes}
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=210)
assert cp.returncode==0,cp.stderr[-4000:]
r=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
