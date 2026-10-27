"""Publish only the watchlist feature with independent recoverable baselines."""
from pathlib import Path
import hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;ROOT=S.parents[2]
mode=sys.argv[1];assert mode in ('prepare','publish','verify','rollback')
b=json.loads((S/'baseline.json').read_text());files={n:(ROOT/n).read_text() for n in b['names']}
v=json.loads((S/'candidate-verified.json').read_text())
hashes={n:hashlib.sha256(content.encode()).hexdigest() for n,content in files.items()}
assert v['domains']==27 and v['metricCellsVerified']==162 and v['accessChecks']==8 and v['scenarios']==16
assert hashes==v['hashes'],'Candidate changed since validation'
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
import datetime,pwd
p=json.load(sys.stdin);root=ROOT;stage=Path('/var/backups/seo-domains-20261025')
if p['mode']=='prepare':
 baseline(root,p['watch'],p['watch']);prepare(root,stage,p['files'],p['before'])
 with tempfile.TemporaryDirectory(prefix='seo-domains-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);out=work/'compiled';out.mkdir(mode=0o777);os.chmod(out,0o777)
  executables=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'));assert len(executables)==1;exe=executables[0];user=pwd.getpwuid((exe.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
  cp=subprocess.run([str(exe),'-deploy','-cfruntimeuser',user,'-webroot',str(source),'-dir',str(source),'-deploydir',str(out)],capture_output=True,text=True,timeout=170)
  output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
  assert cp.returncode==0 and 'Error compiling' not in output and count==3,output[-3000:]
 (stage/'compiled.json').write_text(json.dumps({'templates':count,'manifest_sha':digest((stage/'manifest.json').read_bytes())}))
 result={'compiled_templates':count,'backup':str(stage/'baseline')}
elif p['mode']=='publish':
 c=json.loads((stage/'compiled.json').read_text());m=json.loads((stage/'manifest.json').read_text());assert c['templates']==3 and c['manifest_sha']==digest((stage/'manifest.json').read_bytes()) and m['candidate']==p['hashes']
 baseline(root,p['watch'],p['watch']);result=publish(root,stage);baseline(root,p['watch'],p['watch']);result['published_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();(stage/'published.json').write_text(json.dumps(result,indent=2))
elif p['mode']=='verify':result=verify(root,stage);baseline(root,p['watch'],p['watch']);result['preserved_dependencies']=len(p['watch'])
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':mode,'files':files,'before':b['before'],'watch':b['watch'],'hashes':hashes}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=210)
assert cp.returncode==0,cp.stderr[-3000:]
result=json.loads(cp.stdout);(S/('release-'+mode+'.json')).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
