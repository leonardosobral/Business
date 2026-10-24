from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[3];mode=sys.argv[1];assert mode in ('prepare','publish','verify','rollback')
names=['portal/includes/seo_semrush_data.cfm','portal/conteudo/seo_semrush.cfm'];files={n:(S/'candidate'/n).read_text() for n in names}
b=json.loads((S/'baseline.json').read_text());t=json.loads((S/'candidate-render-passed.json').read_text());assert t['scenarios']==19 and t['access_checks']==8
assert t['hashes']=={n:hashlib.sha256(v.encode()).hexdigest() for n,v in files.items()}
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
import datetime,pwd
p=json.load(sys.stdin);root=ROOT;stage=Path('/var/backups/seo-rr-80-20261022-panel')
if p['mode']=='prepare':
 baseline(root,p['watch'],p['watch']);prepare(root,stage,p['files'],p['before'])
 with tempfile.TemporaryDirectory(prefix='seo-metadata-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  executables=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'));assert len(executables)==1;executable=executables[0];user=pwd.getpwuid((executable.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
  cp=subprocess.run([str(executable),'-deploy','-cfruntimeuser',user,'-webroot',str(source),'-dir',str(source),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  assert cp.returncode==0 and 'Error compiling' not in output and count==2,output[-2500:]
 (stage/'compiled.json').write_text(json.dumps({'templates':count,'manifest_sha':digest((stage/'manifest.json').read_bytes())}));result={'compiled_templates':count,'backup':str(stage/'baseline')}
elif p['mode']=='publish':
 c=json.loads((stage/'compiled.json').read_text());m=json.loads((stage/'manifest.json').read_text());assert c['templates']==2 and c['manifest_sha']==digest((stage/'manifest.json').read_bytes()) and m['candidate']==p['hashes']
 baseline(root,p['watch'],p['watch']);result=publish(root,stage);baseline(root,p['watch'],p['watch']);result['published_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();(stage/'published.json').write_text(json.dumps(result,indent=2))
elif p['mode']=='verify':result=verify(root,stage);baseline(root,p['watch'],p['watch']);result['preserved_dependencies']=len(p['watch'])
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode,'files':files,**b,'hashes':t['hashes']}
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=210);assert cp.returncode==0,cp.stderr[-2200:]
r=json.loads(cp.stdout);(S/f'release-{mode}.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
