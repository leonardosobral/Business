"""Test actual Apache rules in a loopback-only disposable directory with synthetic data."""
from pathlib import Path
import json,shlex,subprocess,sys
ROOT=Path(__file__).resolve().parents[2];site=sys.argv[1];assert site in ('business','openresults');stage=ROOT/'_codex/staging/sites-probe-block'/site
source=r'''
from pathlib import Path
import json,sys,tempfile,shutil,os,subprocess
candidate=json.load(sys.stdin)['candidate']
root=Path(tempfile.mkdtemp(prefix='probe-block-test-',dir='/var/www/business.roadrunners.run/_codex'));os.chmod(root,0o755)
guard='Require local\nErrorDocument 404 "Fixture missing"\n'
try:
 (root/'.htaccess').write_text(guard)
 for relative in ['.env','.env.local','nested/.env.production','.environment','normal.env','.well-known/assetlinks.json','ok.txt','.git/config','.git/logs/HEAD','.aws/config','.netrc','key.json','aws-exports.js','docker-compose.yml','local_settings.py','phpinfo.php','graphql','actuator/health','graphql-news.txt','assets/key.json.svg','assets/aws-exports.js.map','local_settings.py.txt','api/openapi.json','.well-known/security.txt','assets/config.json']:
  p=root/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_text('SYNTHETIC FIXTURE ONLY\n');os.chmod(p,0o644)
 def request(path,method='GET'):
  cmd=['curl','-sS','--path-as-is','--max-time','15','--resolve','business.roadrunners.run:443:127.0.0.1','-X',method,'-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+root.name+path]
  p=subprocess.run(cmd,capture_output=True,text=True,check=True);body,code=p.stdout.rsplit('\n',1);return body,int(code)
 baseline=request('/.env');assert baseline[1]==200,'Synthetic baseline did not reach static fixture'
 (root/'.htaccess').write_text('Require local\n'+candidate+'\nErrorDocument 404 "Fixture missing"\n')
 results=[]
 for path in ['/.github/workflows/deploy.yml', '/.gitlab-ci.yml', '/.npmrc', '/ai/config.json', '/assets/env.js', '/config.json', '/serviceAccountKey.json', '/token.json', '/env.js', '/vercel.json', '/debug/vars', '/appsettings.json', '/secrets.json', '/credentials.json', '/env.json', '/firebase.json', '/firebase-adminsdk.json', '/application.yml', '/api/config', '/service-account.json', '/keys.json', '/instance/config.py', '/web.config', '/serverless.yml', '/api/env', '/amplifyconfiguration.json', '/application.properties', '/awsconfiguration.json', '/terraform.tfvars', '/terraform.tfstate', '/service_account.json', '/graphql','/graphql/','/graphql?query=test','/actuator','/actuator/health','/actuator/env','/.git/config','/.git/logs/HEAD','/nested/.git/config','/.GIT/config','/%2egit/config','/.aws/config','/nested/.aws/credentials','/.netrc','/.netrc.bak','/wp/.env','/phpinfo.php','/phpinfo.php/extra','/aws-exports.js','/docker-compose.yml','/key.json','/local_settings.py','/.env','/.env?probe=1','/.ENV','/.env.local','/.env.bak','/.env~','/.env_backup','/.env-prod','/nested/.env.production','/missing/.env','/.env/child','/%2eenv','/.%65nv']:
  body,code=request(path);assert code==403 and body.strip()=='Access denied',(path,code,body[:80]);results.append({'path':path,'status':code})
 body,code=request('/graphql','POST');assert code==403 and body.strip()=='Access denied';results.append({'path':'POST /graphql','status':code})
 for path in ['/.environment','/normal.env','/.well-known/assetlinks.json','/ok.txt','/ok.txt?file=.env','/graphql-news.txt','/assets/key.json.svg','/assets/aws-exports.js.map','/local_settings.py.txt','/ok.txt?query=/graphql','/api/openapi.json','/.well-known/security.txt','/assets/config.json']:
  body,code=request(path);assert code==200 and 'SYNTHETIC FIXTURE ONLY' in body,(path,code);results.append({'path':path,'status':code})
 body,code=request('/missing-normal');assert code==404 and body.strip()=='Fixture missing';results.append({'path':'/missing-normal','status':code})
 print(json.dumps({'baseline_env_status':baseline[1],'checks':results,'passed':True}))
finally:shutil.rmtree(root)
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)],input=json.dumps({'candidate':(stage/'candidate/.htaccess').read_text()}),capture_output=True,text=True,timeout=65)
print(p.stdout);print(p.stderr[-1800:] if p.returncode else '')
if p.returncode:sys.exit(p.returncode)
(stage/'test-apache.json').write_text(p.stdout)
