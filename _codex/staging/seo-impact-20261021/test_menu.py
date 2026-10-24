from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin
import base64, hashlib, json, shlex, subprocess, sys

S = Path(__file__).resolve().parent
mode = sys.argv[1]
assert mode in ('red', 'green')
root = S / ('origin' if mode == 'red' else 'candidate')
menu = root / 'rr/includes/estrutura/menu_apps.cfm'
helper = Path('/Users/Shared/Projects/RunnerHub/RoadRunners/includes/estrutura/menu_apps_data.cfm')
fixture = '''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry>
<cfscript>
REQUEST.currentBaseUrl="https://roadrunners.run";
REQUEST.i18nBuildPath=function(string route){return "/";};
REQUEST.i18n={common={appsMenu={title="Runner Apps"}}};
REQUEST.runnerAppsMenuItems=[{href="https://roadrunners.run/",target="",rel="",imgSrc="https://roadrunners.run/assets/rr_icon.jpg",imgAlt="Road Runners",labelHtml="Road Runners"}];
REQUEST.runnerAppsMenuGroups=[{items=REQUEST.runnerAppsMenuItems,itemsPerRow=3}];
REQUEST.runnerAppsMenuPoweredBy={label="Powered by",href="https://runnerhub.run/",name="RunnerHub"};
rows=[];
</cfscript>
<cfloop array="#["https://roadrunners.run","https://beta.roadrunners.run","https://dev.roadrunners.run"]#" item="siteBase">
 <cfset REQUEST.currentBaseUrl=siteBase/>
 <cfset structDelete(REQUEST,"runnerAppsMenuLazyScriptLoaded")/>
 <cfsavecontent variable="markup"><cfinclude template="menu_apps.cfm"/><cfinclude template="menu_apps.cfm"/></cfsavecontent>
 <cfset arrayAppend(rows,{base=siteBase,markup=markup})/>
</cfloop>
<cfoutput>#serializeJSON(rows)#</cfoutput><cfcatch><cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>'''
# The fixture supplies the real markup's data contract; no catalog query is needed.
# Re-including CFML global function declarations would fail before testing URLs.
files = {'menu_apps.cfm': menu.read_text(), 'menu_apps_data.cfm': '<!--- Fixture data supplied by run.cfm. --->', 'run.cfm': fixture}
remote = '''
from pathlib import Path
import json, os, secrets, shutil, subprocess, sys, tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-impact-test-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,v in p.items():(work/n).write_text(v)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','35','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=40)
 if cp.returncode:raise RuntimeError(cp.stdout[:2000]+cp.stderr)
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=65)
assert cp.returncode==0,cp.stderr[-2500:]
rows=json.loads(cp.stdout)
assert isinstance(rows,list), rows
class Parser(HTMLParser):
    def __init__(self):super().__init__();self.scripts=[];self.endpoints=[]
    def handle_starttag(self,tag,attrs):
        d=dict(attrs)
        if tag=='script' and 'runner-apps-menu' in d.get('src',''):self.scripts.append(d['src'])
        if 'data-runner-apps-endpoint' in d:self.endpoints.append(d['data-runner-apps-endpoint'])
checks=[]
for row in rows:
    base=row.get('BASE',row.get('base'));html=row.get('MARKUP',row.get('markup'));p=Parser();p.feed(html)
    checks.append({'name':base+' once per request','passed':len(p.scripts)==1})
    for consumer in (base,'https://openresults.run'):
        actual=urljoin(consumer,p.scripts[0]);expected=base+'/assets/js/runner-apps-menu-lazy.min.js?v=20261008seo'
        checks.append({'name':base+' script consumed by '+consumer,'passed':actual==expected,'actual':actual})
    checks.append({'name':base+' endpoint stays same-origin','passed':p.endpoints==['/api/runner_apps_menu.cfm']*2})
proxy=root/'or/api/runner_apps_menu.cfm'
checks.append({'name':'OpenResults same-origin endpoint exists','passed':proxy.exists()})
failed=[c['name'] for c in checks if not c['passed']]
(S/f'menu-tests-{mode}.json').write_text(json.dumps({'checks':checks,'failed':failed,'menu_hash':hashlib.sha256(menu.read_bytes()).hexdigest()},indent=2))
print(json.dumps({'checks':len(checks),'failed':failed}))
assert bool(failed)==(mode=='red')
