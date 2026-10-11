from pathlib import Path
import json,shlex,subprocess,sys
p=Path(__file__).resolve().parent;root=p.parents[2];mode=sys.argv[1];assert mode in ['red','green']
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
import secrets
p=json.load(sys.stdin);work=Path(tempfile.mkdtemp(prefix='seo-regulation-test-',dir=ROOT/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.http_x_seo_verify!="'+key+'"){cfheader(statuscode=404);abort;}return true;}}')
 (work/'run.cfm').write_text('<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/>'+p['fixture'])
 (work/'fact_review.cfm').write_text(p['include'])
 (work/'fact_review_data.cfm').write_text(p['data'])
 (work/'fact_history.cfm').write_text(p['history'])
 (work/'fact_history_data.cfm').write_text(p['history_data'])
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=35)
 if cp.returncode:raise RuntimeError(cp.stdout[:4500])
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'fixture':(p/'fixture.cfm').read_text(),'data':(root.parent/'RoadRunners/evento/parts/fact_review_data.cfm').read_text(),'history':(root.parent/'RoadRunners/evento/parts/fact_history.cfm').read_text(),'history_data':(root.parent/'RoadRunners/evento/parts/fact_history_data.cfm').read_text(),'include':(p/'baseline/roadrunners/evento/parts/fact_review.cfm').read_text() if mode=='red' else (p/'candidate/roadrunners/evento/parts/fact_review.cfm').read_text()}),capture_output=True,text=True,timeout=50)
if cp.returncode:raise RuntimeError(cp.stderr[-4600:])
r=json.loads(cp.stdout);(p/('cfml-'+mode+'.json')).write_text(json.dumps(r,indent=2));failed=[x['NAME'] for x in r['CHECKS'] if not x['PASSED']];print(json.dumps({'checks':len(r['CHECKS']),'failed':failed}));
if mode=='green':assert not failed
else:assert failed
