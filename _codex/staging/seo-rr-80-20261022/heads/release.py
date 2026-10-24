from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[3];mode=sys.argv[1];assert mode in ('prepare','publish','verify','rollback')
b=json.loads((S/'baseline.json').read_text());t=json.loads((S/'tests-green.json').read_text());assert not t['failed'] and len(t['checks'])==20
for key in b:
 b[key]['files']={n:(S/'candidate'/key/n).read_text() for n in b[key]['before']}
 b[key]['hashes']={n:hashlib.sha256(v.encode()).hexdigest() for n,v in b[key]['files'].items()}
 assert b[key]['hashes']==t['hashes'][key]
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
import datetime,pwd
p=json.load(sys.stdin);results={}
for key,item in p['projects'].items():
 root=Path(item['root']);stage=Path('/var/backups/seo-rr-80-20261022-heads-'+key)
 if p['mode']=='prepare':
  baseline(root,item['watch'],item['watch']);prepare(root,stage,item['files'],item['before'])
  with tempfile.TemporaryDirectory(prefix='seo-heads-compile-',dir='/var/tmp') as d:
   work=Path(d);os.chmod(work,0o755);src=work/'source';shutil.copytree(stage/'candidate',src);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
   exe=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'));assert len(exe)==1;exe=exe[0];user=pwd.getpwuid((exe.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
   cp=subprocess.run([str(exe),'-deploy','-cfruntimeuser',user,'-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
   output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')));assert cp.returncode==0 and 'Error compiling' not in output and count==1,output[-2000:]
  (stage/'compiled.json').write_text(json.dumps({'templates':count,'manifest_sha':digest((stage/'manifest.json').read_bytes())}));result={'compiled':count,'backup':str(stage/'baseline')}
 elif p['mode']=='publish':
  c=json.loads((stage/'compiled.json').read_text());m=json.loads((stage/'manifest.json').read_text());assert c['manifest_sha']==digest((stage/'manifest.json').read_bytes()) and m['candidate']==item['hashes']
  baseline(root,item['watch'],item['watch']);result=publish(root,stage);baseline(root,item['watch'],item['watch']);result['published_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();(stage/'published.json').write_text(json.dumps(result))
 elif p['mode']=='rollback':result=rollback(root,stage)
 else:result=verify(root,stage);baseline(root,item['watch'],item['watch']);result['preserved_dependencies']=len(item['watch'])
 results[key]=result
print(json.dumps(results))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(dict(mode=mode,projects=b)),capture_output=True,text=True,timeout=400);assert cp.returncode==0,cp.stderr[-2500:]
r=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,indent=2))
