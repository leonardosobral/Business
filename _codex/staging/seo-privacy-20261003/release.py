"""Publish and verify noindex before allowing crawler access to athlete histories."""
from pathlib import Path
import hashlib,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent;MODE=sys.argv[1]
assert MODE in ['prepare','publish-head','publish-robots','verify','rollback']
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+r'''
from html.parser import HTMLParser
from urllib.request import Request,urlopen
payload=json.load(sys.stdin);mode=payload['mode'];result={}
root=Path('/var/www/openresults.run');stage=Path('/var/backups/seo-noindex-openresults-20261003')
class Meta(HTMLParser):
 def __init__(self):super().__init__();self.inhead=False;self.robots=[]
 def handle_starttag(self,tag,attrs):
  if tag=='head':self.inhead=True
  a=dict(attrs)
  if self.inhead and tag=='meta' and a.get('name','').lower()=='robots':self.robots.extend(a.get('content','').lower().split(','))
 def handle_endtag(self,tag):
  if tag=='head':self.inhead=False
def head_evidence():
 evidence=[]
 for path,want in [('/resultados/seo-verificacao-nome-inexistente/',True),('/resultados/index.cfm?tag=seo-verificacao-nome-inexistente',True),('/',False),('/evento/2026-maratona-salvador-2026/',False)]:
  with urlopen(Request('https://openresults.run'+path,headers={'User-Agent':'RunnerHub-SEO-noindex/20261003','Cache-Control':'no-cache'}),timeout=25) as response:
   parser=Meta();parser.feed(response.read(3*1024*1024).decode('utf8',errors='replace'))
   actual='noindex' in [v.strip() for v in parser.robots]
   evidence.append({'path':path,'status':response.status,'noindex':actual,'expected':want,'ok':response.status==200 and actual==want})
 if not all(row['ok'] for row in evidence):raise RuntimeError('Public noindex mismatch: '+json.dumps(evidence))
 return evidence
if mode=='prepare':
 result=prepare(root,stage,payload['files'],payload['before'])
 watch={name:digest((root/name).read_bytes()) for name in ['Application.cfc','.htaccess','resultados/index.cfm','index.cfm','evento/index.cfm','perfil/index.cfm'] if (root/name).is_file()}
 (stage/'watch.json').write_text(json.dumps(watch,indent=2))
 with tempfile.TemporaryDirectory(prefix='seo-noindex-compile-',dir='/var/tmp') as directory:
  work=Path(directory);os.chmod(work,0o755);source=work/'source';shutil.copytree(stage/'candidate',source);compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=120)
  output=cp.stdout+cp.stderr
  if cp.returncode or 'Error compiling' in output or len(list(compiled.rglob('*.cfm')))!=1:raise RuntimeError('Compile failed: '+output)
  result['compile']={'returncode':cp.returncode,'output':output,'templates':1}
  (stage/'compiled.json').write_text(json.dumps({'manifest_sha256':digest((stage/'manifest.json').read_bytes())}))
elif mode in ['publish-head','publish-robots']:
 m=json.loads((stage/'manifest.json').read_text());compiled=json.loads((stage/'compiled.json').read_text())
 if compiled['manifest_sha256']!=digest((stage/'manifest.json').read_bytes()):raise RuntimeError('Current candidate not compiled')
 for name,want in m['candidate'].items():
  if digest((stage/'candidate'/name).read_bytes())!=want:raise RuntimeError('Candidate changed '+name)
 if mode=='publish-head':
  baseline(root,m['order'],m['before'])
  replace_file(stage/'candidate/includes/head.cfm',root/'includes/head.cfm',(root/'includes/head.cfm').stat())
  try:
   evidence=head_evidence()
   (stage/'head-verified.json').write_text(json.dumps({'sha256':digest((root/'includes/head.cfm').read_bytes()),'evidence':evidence}))
   result={'published':['includes/head.cfm'],'head_evidence':evidence}
  except Exception:
   rollback(root,stage);raise
 else:
  marker=json.loads((stage/'head-verified.json').read_text())
  if marker['sha256']!=m['candidate']['includes/head.cfm'] or digest((root/'includes/head.cfm').read_bytes())!=marker['sha256']:raise RuntimeError('Live noindex was not verified')
  baseline(root,['robots.txt'],{'robots.txt':m['before']['robots.txt']})
  replace_file(stage/'candidate/robots.txt',root/'robots.txt',(root/'robots.txt').stat());verify(root,stage)
  result={'published':['robots.txt'],'backup':str(stage/'baseline')}
elif mode=='verify':
 result=verify(root,stage);result['head_evidence']=head_evidence()
 watch=json.loads((stage/'watch.json').read_text());changed=[name for name,want in watch.items() if digest((root/name).read_bytes())!=want]
 if changed:raise RuntimeError('Unrelated runtime changed: '+str(changed))
 result['unrelated_files_unchanged']=len(watch)
 with urlopen(Request('https://openresults.run/robots.txt',headers={'User-Agent':'RunnerHub-SEO-noindex/20261003','Cache-Control':'no-cache'}),timeout=20) as response:result['robots']={'status':response.status,'body':response.read().decode()}
 if result['robots']['body']!=(stage/'candidate/robots.txt').read_text():raise RuntimeError('Public robots differs from candidate')
else:result=rollback(root,stage)
print(json.dumps(result))
'''
payload={'mode':MODE}
if MODE=='prepare':
 names=['includes/head.cfm','robots.txt'];payload['files']={name:(STAGE/'candidate'/name).read_text() for name in names};payload['before']={name:hashlib.sha256((STAGE/'baseline'/name).read_bytes()).hexdigest() for name in names}
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=240)
if p.returncode:raise RuntimeError(p.stderr[-2400:])
r=json.loads(p.stdout);(STAGE/('release-'+MODE+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
print(json.dumps({k:v for k,v in r.items() if k not in ['before','candidate','order','compile']}|({'compiled_templates':r['compile']['templates']} if 'compile' in r else {}),ensure_ascii=False))
