from pathlib import Path
import json,shlex,subprocess,sys,hashlib
from html.parser import HTMLParser
from html import unescape
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');P=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ['red','green']
src=P/('baseline' if mode=='red' else 'candidate')/'rr'
files={'card.cfm':(src/'includes/card_evento_individual.cfm').read_text().split('    <!--- CARREGA O CSS')[0], 'theme.cfm':(src/'includes/estrutura/header_tema.cfm').read_text(), 'EventRedirectService.cfc':(src/'services/EventRedirectService.cfc').read_text(),'run.cfm':(P/'fixture.cfm').read_text(), 'title.cfm':'' if mode=='red' else (src/'includes/estrutura/event_title_date.cfm').read_text()}
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-5000-test-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.http_x_seo_verify!="'+key+'"){cfheader(statuscode=404);abort;}return true;}}')
 for name,body in p.items():(work/name).write_text(body)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=50)
 if cp.returncode:raise RuntimeError(cp.stdout[:4000])
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=75)
if cp.returncode:raise RuntimeError(cp.stderr[-4500:])
r=json.loads(cp.stdout);checks=r['CHECKS']
class Links(HTMLParser):
 def handle_starttag(self,t,a):
  if t=='a':self.hrefs.append(dict(a).get('href',''))
for h in r['HEADERS']:
 parser=Links();parser.hrefs=[];parser.feed(h['HTML'])
 checks.append({'NAME':'Timer header uses existing route, theme '+str(h['THEME']),'PASSED':'/timer/branca-esportes-saude-e-lazer/' in parser.hrefs and not any(x.startswith('/assessoria/') for x in parser.hrefs)})
for t in r['TITLES']:
 checks.append({'NAME':'Bounded and escaped repeated title','PASSED':len(unescape(t['VALUE']))<=70 and '<race>' not in t['VALUE']})
checks.append({'NAME':'Dates distinguish two editions of each repeated event','PASSED':len(set(t['VALUE'] for t in r['TITLES']))==len(r['TITLES'])})
failed=[x['NAME'] for x in checks if not x['PASSED']];(P/('tests-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps({'checks':len(checks),'failed':failed},ensure_ascii=False))
assert bool(failed)==(mode=='red')
