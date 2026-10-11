from pathlib import Path
import json,shlex,subprocess,base64,hashlib,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
mode=sys.argv[1] if len(sys.argv)>1 else 'candidate'
names=['portal/conteudo/seo.cfm','portal/conteudo/seo_ga4.cfm','portal/seo/ga4_service.cfm','portal/seo/ga4_api.cfm','administracao/agenda/includes/service.cfm','includes/backend/require_admin.cfm','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_queue_data.cfm','portal/includes/seo_score_data.cfm','portal/includes/seo_search_evidence.cfm','portal/conteudo/seo_report.cfm','portal/conteudo/seo_ai.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']
remote=r'''
from pathlib import Path
import json,sys,os,secrets,tempfile,shutil,subprocess,base64
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');key=secrets.token_hex(24)
work=Path(tempfile.mkdtemp(prefix='ga4-verify-',dir=root/'_codex'));os.chmod(work,0o755)
try:
 for name,content in p['files'].items():
  dest=work/name;dest.parent.mkdir(parents=True,exist_ok=True)
  dest.write_text(content if p['mode']=='candidate' else (root/name).read_text())
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.sessionManagement=true;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 auth='<cfset qPerfil=queryNew("id,is_admin","integer,bit",[{id=1,is_admin=true}])/>'
 auth+='<cfset VARIABLES.businessEffectiveIsAdmin=true/>'
 # Stub only identity acquisition, never the real admin guard; all external access is mocked.
 (work/'includes/backend/backend_login.cfm').write_text('<cfset qPerfil=queryNew("id,is_admin","integer,bit",[{id=1,is_admin=true}])/><cfset VARIABLES.businessEffectiveIsAdmin=!(structKeyExists(URL,"denied"))/>')
 (work/'tests.cfm').write_text('<cfsetting showdebugoutput="false"/>'+auth+'<cfinclude template="administracao/agenda/includes/service.cfm"/><cfinclude template="portal/seo/ga4_service.cfm"/><cfscript>'+p['test']+'writeOutput(serializeJSON(report));</cfscript>')
 (work/'view.cfm').write_text('<cfsetting showdebugoutput="false"/>'+auth+'<cfset URL.aba="ga4"/><cfinclude template="portal/conteudo/seo.cfm"/>')
 (work/'openresults.cfm').write_text('<cfsetting showdebugoutput="false"/>'+auth+'<cfset URL.aba="ga4"/><cfset URL.site="openresults"/><cfinclude template="portal/conteudo/seo.cfm"/>')
 (work/'denied.cfm').write_text('<cfset VARIABLES.businessEffectiveIsAdmin=false/><cfinclude template="portal/conteudo/seo_ga4.cfm"/>')
 def get(path,method='GET',form=None):
  args=['curl','-sS','--max-time','40','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Verify: '+key,'-X',method,'-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/'+path]
  if form:args+=['--data',form]
  cp=subprocess.run(args,capture_output=True,text=True,timeout=45)
  html,status=cp.stdout.rsplit('\n',1)
  return {'status':int(status),'body':html}
 results={n:get(n+'.cfm') for n in ['tests','view','openresults','denied']}
 results['direct']=get('portal/seo/ga4_service.cfm')
 results['post_view']=get('view.cfm','POST')
 results['api_csrf']=get('portal/seo/ga4_api.cfm','POST','action=connect&csrf_token=wrong')
 results['api_get']=get('portal/seo/ga4_api.cfm')
 results['api_nonadmin']=get('portal/seo/ga4_api.cfm?denied=1','POST')
 print(json.dumps(results))
finally:shutil.rmtree(work)
'''
payload={'mode':mode,'files':{n:(ROOT/n).read_text() for n in names},'test':(ROOT/'_codex/tests/seo_ga4_service.cfscript').read_text()}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=160)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout)
(STAGE/(mode+'-verification.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
assert r['tests']['status']==200,r['tests']['body'][:1800]
tests=json.loads(r['tests']['body']);passed=tests.get('PASSED',tests.get('passed'))
assert len(passed)>=25,tests
for name in ['view','openresults']:assert r[name]['status']==200 and 'Error Occurred' not in r[name]['body'],(name,r[name]['body'][:2000])
assert 'ga4-app' in r['view']['body']
assert 'ga4-app' not in r['openresults']['body']
for n in ['denied','direct','api_csrf','api_get','api_nonadmin']:assert r[n]['status']==403,(n,r[n])
assert r['post_view']['status']==405
(STAGE/'preview.html').write_text('<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>'+r['view']['body']+'</body></html>')
print(json.dumps({'mode':mode,'service_checks':len(passed),'http_checks':8}))
