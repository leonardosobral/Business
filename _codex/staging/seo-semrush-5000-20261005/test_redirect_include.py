from pathlib import Path
import hashlib,json,shlex,subprocess,sys,re
P=Path(__file__).resolve().parent;mode=sys.argv[1];assert mode in ['red','green']
source=(P/('redirect-baseline' if mode=='red' else 'redirect-candidate')/'includes/estrutura/event_redirect.cfm').read_text()
cases=[{'tag':tag,'prefix':prefix,'expected':prefix+target+'/'} for tag,target in [('2025-live-run-xp-brasilia-i-2025','2025-live-run-xp-brasilia-I-2025'),('2025-live-run-xp-brasilia-ii-2025','2025-live-run-xp-brasilia-II-2025'),('2026-endorfina-run-santo-andre-ii','2026-endorfina-run-santo-andre-II')] for prefix in ['/evento/','/en/event/','/es/evento/']]
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile,re
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');w=Path(tempfile.mkdtemp(prefix='seo-redirect-test-',dir=root/'_codex'));os.chmod(w,0o755);key=secrets.token_hex(24)
try:
 (w/'.htaccess').write_text('Require local\\n')
 (w/'Application.cfc').write_text('component{this.name="'+w.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.http_x_seo_verify!="'+key+'"){cfheader(statuscode=404);abort;}return true;}}')
 (w/'services').mkdir();shutil.copyfile(Path('/var/www/roadrunners.com.br/services/EventRedirectService.cfc'),w/'services/EventRedirectService.cfc');(w/'event_redirect.cfm').write_text(p['source'])
 rows=[]
 for i,c in enumerate(p['cases']):
  (w/(str(i)+'.cfm')).write_text('<cfsetting showdebugoutput="false"/><cfscript>REQUEST.currentRouteParams={};REQUEST.i18nBuildPath=function(required string k){return "'+c['prefix']+'" & lCase(REQUEST.currentRouteParams.tag) & "/";};</cfscript><cfinclude template="event_redirect.cfm"/><cfoutput>##serializeJSON({params=URL,method=CGI.REQUEST_METHOD,read=VARIABLES.eventRedirectService.isReadRequest(CGI.REQUEST_METHOD,URL),target=VARIABLES.eventRedirectService.resolveTarget(URL.tag),hasBuilder=structKeyExists(REQUEST,"i18nBuildPath")})##</cfoutput>'.replace('##','#'))
  cp=subprocess.run(['curl','-sS','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-D','-','-w','\\n%{http_code}','https://business.roadrunners.run/_codex/'+w.name+'/'+str(i)+'.cfm?tag='+c['tag']],capture_output=True,text=True,timeout=35)
  body,_,status=cp.stdout.rpartition('\\n');loc=re.search(r'^location:\\s*(.+)$',body,re.I|re.M)
  rows.append(dict(c,status=status,location=loc.group(1).strip() if loc else None,returncode=cp.returncode,body=body.replace(key,'[redacted]')[:5000]))
 print(json.dumps(rows))
finally:shutil.rmtree(w)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'source':source,'cases':cases}),capture_output=True,text=True,timeout=120);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);failed=[x for x in r if x['status']!='301' or x['returncode'] or x['location']!=x['expected']]
(P/('redirect-tests-'+mode+'.json')).write_text(json.dumps(r,indent=2))
assert all(x['status']=='301' and x['returncode']==0 and x['location'] for x in r),r
assert bool(failed)==(mode=='red'),failed
if mode=='green':(P/'redirect-tests-passed.json').write_text(json.dumps({'passed':len(r),'hashes':{'includes/estrutura/event_redirect.cfm':hashlib.sha256(source.encode()).hexdigest()}}))
print(json.dumps({'tests':len(r),'failed':len(failed)}))
