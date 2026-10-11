from pathlib import Path
import base64,hashlib,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[2];mode=sys.argv[1];assert mode in ['red','green']
name='includes/card_evento_individual.cfm';src=S/('baseline' if mode=='red' else 'candidate')/'rr'/name
# Exercise the actual card path block; the route builder mirrors the current Application implementation.
block=src.read_text().split('<cfset VARIABLES.eventCardSearchPath')[0]
tags=['2026-"3-corrida-de-nossa-senhora-aparecida"','2026-1-corrida-de-aniversario-do-grupo-corrida-#038;-resenha','2026-rock-n-run\n----nashville-2026','2026-normal-fixture','2023-jurerê-night-run-2023']
run='''<cfsetting showdebugoutput="false"/><cfscript>
request.Usuario={};request.currentBaseUrl="https://roadrunners.run";checks=[];paths=[];
tags=deserializeJSON(toString(binaryDecode("__TAGS__","base64")));
for(prefix in ["/evento/","/en/event/","/es/evento/","fallback"]){
 request.testPrefix=prefix;
 for(tag in tags){
  request.currentRouteParams={other="preserved"};
  if(prefix=="fallback"){structDelete(request,"i18nBuildPath");}
  else{request.i18nBuildPath=function(required string routeKey){return request.testPrefix & lCase(trim(request.currentRouteParams.tag)) & "/";};}
  savecontent variable="discarded" {include "card-path.cfm";}
  expected=(prefix=="fallback" ? "/evento/" : prefix) & replace(encodeForURL(tag),"+","%20","all") & "/";
  arrayAppend(checks,{name=prefix & " " & tag & " exact encoded path",passed=compareNoCase(variables.eventCardDetailPath,expected)==0});
  arrayAppend(checks,{name=prefix & " " & tag & " restore route params",passed=serializeJSON(request.currentRouteParams)==serializeJSON({other="preserved"})});
  arrayAppend(paths,{tag=tag,path=variables.eventCardDetailPath});
 }
}
</cfscript><cfcontent type="application/json" reset="true"/><cfoutput>#serializeJSON({checks=checks,paths=paths})#</cfoutput>'''.replace('__TAGS__',base64.b64encode(json.dumps(tags).encode()).decode())
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/roadrunners.com.br');work=Path(tempfile.mkdtemp(prefix='seo-card-paths-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for n,v in p.items():(work/n).write_text(v)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','35','--resolve','roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=40)
 if cp.returncode:raise RuntimeError(cp.stdout[:2500])
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'card-path.cfm':block,'run.cfm':run}),capture_output=True,text=True,timeout=60)
if cp.returncode:raise RuntimeError(cp.stderr[-2800:])
r=json.loads(cp.stdout);failed=[x['NAME'] for x in r['CHECKS'] if not x['PASSED']]
r.update(source_hash=hashlib.sha256(src.read_bytes()).hexdigest(),failed=failed)
(S/('card-tests-'+mode+'.json')).write_text(json.dumps(r,indent=2,ensure_ascii=False))
print(json.dumps({'checks':len(r['CHECKS']),'failed':len(failed)},ensure_ascii=False));assert bool(failed)==(mode=='red')
