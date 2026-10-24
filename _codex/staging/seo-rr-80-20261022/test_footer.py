from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import parse_qs,urlsplit
import hashlib,json,re,shlex,subprocess,sys
S=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ('red','green')
src=S/('baseline' if mode=='red' else 'candidate')/'includes/estrutura/footer.cfm'
fixture='''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry>
<cfscript>
REQUEST.t=function(string key){return key;};
REQUEST.i18nBuildPath=function(string route){
 var prefix=REQUEST.lang=="pt-BR" ? "/" : "/" & REQUEST.lang & "/";
 return prefix & route & "/" & (route=="athlete" ? REQUEST.currentRouteParams.tag & "/" : "");
};
VARIABLES.devMode=false;rows=[];
</cfscript>
<cfloop array="#["pt-BR","en","es"]#" item="language">
 <cfloop array="#[false,true]#" item="signedIn">
  <cfset REQUEST.lang=language/><cfset REQUEST.Usuario={logado=signedIn,tag="fixture-atleta",is_admin=false,is_dev=false}/><cfset REQUEST.currentRouteParams={tag="unrelated-page"}/>
  <cfsavecontent variable="markup"><cfinclude template="includes/estrutura/footer.cfm"/></cfsavecontent>
  <cfset arrayAppend(rows,{lang=language,signedIn=signedIn,markup=markup,routeTag=REQUEST.currentRouteParams.tag})/>
 </cfloop>
</cfloop>
<cfoutput>#serializeJSON(rows)#</cfoutput>
<cfcatch><cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>'''
files={'run.cfm':fixture,'includes/estrutura/footer.cfm':src.read_text(),'includes/estrutura/footer_assets.cfm':Path('/Users/Shared/Projects/RunnerHub/RoadRunners/includes/estrutura/footer_assets.cfm').read_text(),'includes/modal/modal_beta.cfm':'','includes/analytics/privacy_controls.cfm':''}
remote='''
from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-footer-test-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,v in p.items():
  t=work/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_text(v)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','35','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=40)
 if cp.returncode:raise RuntimeError(cp.stdout[:1600]+cp.stderr)
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=65)
assert cp.returncode==0,cp.stderr[-2200:]
rows=json.loads(cp.stdout);assert isinstance(rows,list),rows
class Links(HTMLParser):
 def __init__(self):super().__init__();self.values=[]
 def handle_starttag(self,t,a):
  if t=='a':self.values.append(dict(a)['href'])
checks=[]
for row in rows:
 row={k.lower():v for k,v in row.items()};lang=row['lang'];logged=row['signedin'];prefix='/' if lang=='pt-BR' else '/'+lang+'/'
 p=Links();p.feed(re.search(r'<nav class="rr-footer-navigation"[\s\S]*?</nav>',row['markup']).group())
 private=[prefix+'feed/',('/atleta/' if not logged else prefix+'athlete/fixture-atleta/'),prefix+'agenda/',prefix+'results/',prefix+'challenges/',prefix+'support/']
 for destination in private:
  expected=destination if logged else '/login/'
  found=destination in p.values if logged else any(urlsplit(h).path=='/login/' and parse_qs(urlsplit(h).query).get('redirect')==[destination] for h in p.values)
  checks.append({'name':f'{lang} {logged} private {destination}','passed':found})
 for destination in [prefix+'search/?busca_tipo=eventos',prefix+'radar/',prefix+'news/',prefix+'videos/',prefix+'about/',prefix+'help/',prefix+'terms/',prefix+'privacy/']:
  checks.append({'name':f'{lang} {logged} public {destination}','passed':destination in p.values})
 checks.append({'name':f'{lang} {logged} route params preserved','passed':row['routetag']=='unrelated-page'})
failed=[c['name'] for c in checks if not c['passed']]
(S/f'footer-tests-{mode}.json').write_text(json.dumps({'checks':checks,'failed':failed,'source_hash':hashlib.sha256(src.read_bytes()).hexdigest()},indent=2))
print(json.dumps({'checks':len(checks),'failed':failed}))
assert bool(failed)==(mode=='red')
