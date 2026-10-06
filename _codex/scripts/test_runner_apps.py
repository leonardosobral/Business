"""Isolated CFML tests: menu latency, cache concurrency and catalogue contract."""
from pathlib import Path
import json,subprocess,shlex,sys
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/runner-apps-20261004'
mode=sys.argv[1]
files={}
if mode=='red':
 files['menu.cfm']=(ROOT.parent/'RoadRunners/includes/estrutura/menu_apps_data.cfm').read_text()
else:
 for p in (STAGE/'candidate').rglob('*'):
  if p.is_file():files[str(p.relative_to(STAGE/'candidate'))]=p.read_text()
for p in (ROOT/'_codex/tests/runner-apps').rglob('*'):
 if p.is_file():files[str(p.relative_to(ROOT/'_codex/tests/runner-apps'))]=p.read_text()
remote=r"""
from pathlib import Path
import json,sys,tempfile,secrets,os,subprocess,shutil,concurrent.futures,time
payload=json.load(sys.stdin);root=Path('/opt/ColdFusion/cfusion/wwwroot');work=Path(tempfile.mkdtemp(prefix='runner-apps-test-',dir=root));os.chmod(work,0o755)
token=secrets.token_hex(24);base='http://127.0.0.1:8500/'+work.name+'/'
def request(path,method="GET"):
 p=subprocess.run(['curl','-sS','--max-time','20','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Test-Key: '+token,'-X',method,'-w','\n%{http_code}\n%{redirect_url}',base+path],capture_output=True,text=True,timeout=25)
 body,status,redirect=p.stdout.rsplit('\n',2)
 try:out=json.loads(body)
 except:out={'invalid_response':body[:1800]}
 return {'status':int(status),'body':out,'curl_error':p.stderr,'redirect':redirect}
try:
 for rel,s in payload['files'].items():
  f=work/rel;f.parent.mkdir(parents=True,exist_ok=True)
  f.write_text(s)
 app='''component {this.name="APPNAME";this.datasource="runner_dba";this.sessionManagement=false;this.serialization.preserveCaseForStructKey=true;
 this.mappings["/services"]=getDirectoryFromPath(getCurrentTemplatePath()) & "rr/services";
 this.mappings["/runnerAppsCatalog"]=getDirectoryFromPath(getCurrentTemplatePath()) & "business/api/portal/runner-apps";
 this.mappings["/fixtures"]=getDirectoryFromPath(getCurrentTemplatePath());
 boolean function onRequestStart(string target){setting showdebugoutput=false;if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(getHTTPRequestData(false).headers["X-Test-Key"] ?: "", "TOKEN")!=0){cfheader(statuscode=403);abort;}return true;}
 void function onError(any exception,string eventName){cfcontent(type="application/json",reset=true);cfheader(statuscode=500);writeOutput(serializeJSON({error=arguments.exception.message,detail=arguments.exception.detail,frames=arguments.exception.tagContext}));}}'''.replace('APPNAME',work.name).replace('TOKEN',token)
 (work/'Application.cfc').write_text(app);(work/'.htaccess').write_text('Require local\n')
 if payload['mode']=='red':
  s=(work/'menu.cfm').read_text().replace('https://business.roadrunners.run/api/portal/runner-apps/',base+'upstream.cfm')
  s=s.replace('<cfhttpparam type="header" name="Accept" value="application/json"/>','<cfhttpparam type="header" name="X-Test-Key" value="'+token+'"/>')
  (work/'menu.cfm').write_text(s)
  (work/'upstream.cfm').write_text('<cfset sleep(900)/><cfheader statuscode="503"/><cfoutput>{"success":false}</cfoutput>')
  result=request('red.cfm');assert result['body'].get('stale_preserved') is False,result
  print(json.dumps({'mode':'red','expected_failure':result}))
 else:
  result=request('cache.cfm') if payload['mode']!='routes' else {'status':200,'body':{'passed':True,'skipped':True}};assert result['status']==200 and result['body'].get('passed'),result
  catalog=request('catalog.cfm');assert catalog['status']==200 and catalog['body'].get('passed'),catalog
  # Verify the actual public API bootstrap against production read-only catalogue data.
  api=work/'rr/public-api';a=(api/'Application.cfc').read_text().replace('this-does-not-match','unused')
  a=a.replace('"RoadRunnersPublicApi"','"'+work.name+'-api"')
  a=a.replace('"/var/www/business.roadrunners.run/api/portal/runner-apps"',json.dumps(str(work/'business/api/portal/runner-apps')))
  a=a.replace('getDirectoryFromPath(getCurrentTemplatePath()) & "../services"','"/var/www/roadrunners.com.br/services"')
  a=a.replace('getDirectoryFromPath(getCurrentTemplatePath()) & "../includes"','"/var/www/roadrunners.com.br/includes"')
  a=a.replace('<cfset var routePath = getApiRoutePath()/>','<cfif NOT listFind("127.0.0.1,::1",CGI.remote_addr) OR compare(getHTTPRequestData(false).headers["X-Test-Key"] ?: "","'+token+'") NEQ 0><cfheader statuscode="403"/><cfabort/></cfif><cfset var routePath = getApiRoutePath()/>')
  (api/'Application.cfc').write_text(a)
  endpoint=api/'v1/discovery/runner-apps.cfm';endpoint.write_text(endpoint.read_text().replace("'message'='Catalogo temporariamente indisponivel.'","'message'=catalogError.message,'detail'=catalogError.detail"))
  (work/'rr/config').mkdir(exist_ok=True)
  (work/'rr/config/settings.cfm').write_text('<cfset APPLICATION.apiIntegrations={tokens=[]}/><cfset APPLICATION.pwaPush={}/><cfset APPLICATION.mobileAuth={}/>')
  guards=[]
  for path,method,status in [('v1/discovery/runner-apps.cfm','GET',200),('v1/discovery/runner-apps.cfm?linha=principal','GET',200),('v1/discovery/runner-apps.cfm?linha=invalid','GET',400),('v1/discovery/runner-apps.cfm?incluir_ocultos=1','GET',400),('v1/discovery/runner-apps.cfm','POST',405),('v1/discovery/runner-apps.cfm','OPTIONS',204),('v1/me/profile-settings.cfm','GET',401),('v1/discovery/search.cfm','GET',401)]:
   f=api/path.split('?')[0]
   if not f.exists():f.parent.mkdir(parents=True,exist_ok=True);f.write_text('<cfoutput>{"unexpected_access":true}</cfoutput>')
   r=request('rr/public-api/'+path,method);assert r['status']==status,(path,r)
   if status==200:assert r['body']['success'] and len(r['body']['items'])>0,r
   guards.append({'path':path,'method':method,'status':r['status']})
  legacy=[]
  for suffix,method,status in [('', 'GET',308),('?linha=principal','GET',308),('?incluir_ocultos=1','GET',400),('','POST',405),('','OPTIONS',204)]:
   r=request('business/api/portal/runner-apps/index.cfm'+suffix,method);assert r['status']==status,r
   if status==308:assert r['redirect']=='https://api.roadrunners.run/v1/discovery/runner-apps.cfm'+suffix,r
   legacy.append({'suffix':suffix,'method':method,'status':r['status']})
  # Independent HTTP requests share one refresh, with no waiting on the loader.
  (work/'parallel-init.cfm').write_text('<cfscript>APPLICATION.testSource=new fixtures.FixtureSource();APPLICATION.testSource.delay=1500;APPLICATION.testCache=createObject("component","services.RunnerAppsMenuCache").init(source=APPLICATION.testSource,initialPayload={success=true,groups=[],items=[{label="last-known",href="/"}]});cfcontent(type="application/json");writeOutput("{}");</cfscript>')
  (work/'parallel-read.cfm').write_text('<cfscript>started=getTickCount();data=APPLICATION.testCache.get();cfcontent(type="application/json");writeOutput(serializeJSON({label=data.items[1].label,elapsed=getTickCount()-started,count=APPLICATION.testSource.calls.get()}));</cfscript>')
  assert request('parallel-init.cfm')['status']==200
  with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:parallel=list(pool.map(request,['parallel-read.cfm']*4))
  assert all(r['status']==200 and r['body']['label']=='last-known' and r['body']['elapsed']<300 for r in parallel),parallel
  time.sleep(1.8);fresh=request('parallel-read.cfm');assert fresh['body']['label']=='fresh' and fresh['body']['count']==1,fresh
  print(json.dumps({'mode':payload['mode'],'cache':result,'catalog':catalog,'guards':guards,'legacy':legacy,'parallel':parallel,'fresh':fresh}))
finally:
 time.sleep(1);shutil.rmtree(work)
"""
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'files':files}),capture_output=True,text=True,timeout=100)
print(p.stdout);print(p.stderr[-4500:]);(STAGE/('tests-'+mode+'.json')).write_text(p.stdout);sys.exit(p.returncode)
