exec(open('_codex/staging/seo-routes-20261003/probe.py').read().split('remote=helpers+')[0])
remote=helpers+'''
import secrets
root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-routes-verify-',dir=root/'_codex'));os.chmod(work,0o755)
key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="GET"||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 body='<cfsetting requesttimeout="45" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cfset VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}])/><cfset VARIABLES.businessEffectiveIsAdmin=true/><cfset URL.aba="fila"/><cfsavecontent variable="html"><cfinclude template="/portal/conteudo/seo.cfm"/></cfsavecontent><cfscript>items=[];for(item in VARIABLES.seoQueueSnapshot.items){arrayAppend(items,{id=item.id,resolved=item.resolved});}report={total=VARIABLES.seoQueueTotal,pending=VARIABLES.seoQueueOpenTotal,resolved=VARIABLES.seoQueueResolvedTotal,items=items,rendered=len(html)>5000,updated=VARIABLES.seoQueueSnapshot.updatedLabel};writeOutput(serializeJSON(report));</cfscript>'
 (work/'run.cfm').write_text(body)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
 if cp.returncode:raise RuntimeError('Panel fixture failed: '+cp.stdout[-1700:])
 report=json.loads(cp.stdout);print(json.dumps(report))
finally:shutil.rmtree(work)
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=75)
if p.returncode:raise RuntimeError(p.stderr[-2400:])
r=json.loads(p.stdout);r={k.lower():v for k,v in r.items()};assert r['total']==11 and r['pending']==3 and r['resolved']==8 and r['rendered']
(STAGE/'panel-verification.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
