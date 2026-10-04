"""Verify published templates on Adobe; auth fixture is local-only and temporary."""
from pathlib import Path
from html import unescape
import json,shlex,subprocess
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
import secrets
root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-institutional-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="GET"||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 body='<cfsetting requesttimeout="45" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cfset VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}])/><cfset VARIABLES.businessEffectiveIsAdmin=true/><cfset URL.aba="ia"/><cfsavecontent variable="html"><cfinclude template="/portal/conteudo/seo.cfm"/></cfsavecontent><cfscript>report={total=VARIABLES.seoQueueTotal,pending=VARIABLES.seoQueueOpenTotal,resolved=VARIABLES.seoQueueResolvedTotal,items=[],sites=[],html=toBase64(html,"utf-8")};for(item in VARIABLES.seoQueueSnapshot.items)arrayAppend(report.items,{id=item.id,resolved=item.resolved});for(site in VARIABLES.seoScoreSnapshot.sites)arrayAppend(report.sites,{id=site.id,auditAt=site.auditAt,score=site.score,checks=site.aiChecks});writeOutput(serializeJSON(report));</cfscript>'
 (work/'run.cfm').write_text(body)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','50','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=55)
 if cp.returncode:raise RuntimeError('Panel fixture failed: '+cp.stdout[-1700:])
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=75)
if cp.returncode:raise RuntimeError(cp.stderr[-2400:])
def lower(v):return {k.lower():lower(x) for k,x in v.items()} if isinstance(v,dict) else [lower(x) for x in v] if isinstance(v,list) else v
r=lower(json.loads(cp.stdout));html=__import__('base64').b64decode(r.pop('html')).decode('utf-8');snapshot=json.loads((STAGE/'snapshot.json').read_text())
assert r['total']==15 and r['pending']==3 and r['resolved']==12
assert next(i for i in r['items'] if i['id']=='RR-09')['resolved']
assert not next(i for i in r['items'] if i['id']=='RR-08')['resolved']
assert next(i for i in r['items'] if i['id']=='RR-10')['resolved']
for site in r['sites']:
 expected=next(s for s in snapshot['sites'] if s['id']==site['id'])
 assert site['auditat']==expected['auditAt'] and site['score']==expected['score']
 assert next(c for c in site['checks'] if c['id']=='hreflang-reciprocity')['pass']==next(c for c in expected['aiChecks'] if c['id']=='hreflang-reciprocity')['pass']
 assert next(c for c in site['checks'] if c['id']=='translations')['status']=='unknown'
assert 'Reciprocidade entre idiomas' in unescape(html) and 'Tradução do conteúdo principal' in unescape(html)
(STAGE/'panel-verification.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));(STAGE/'panel-ai-adobe.html').write_text('<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SEO — validação dos templates publicados</title><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/business-ui.css"></head><body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4 py-4">'+html+'</main></body></html>')
print(json.dumps({'total':r['total'],'pending':r['pending'],'resolved':r['resolved'],'sites_verified':len(r['sites']),'ai_checks_rendered':True,'auth':'isolated fixture; not a real admin login'},ensure_ascii=False))
