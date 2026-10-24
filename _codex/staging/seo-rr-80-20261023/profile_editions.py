"""Read-only timings; return only row counts and fingerprints, no athlete records."""
from pathlib import Path
import base64,json,shlex,subprocess,sys
S=Path(__file__).resolve().parent;B=S.parents[2]
mode=sys.argv[1];assert mode in ('baseline','candidate')
source=(S/'runtime'/mode/'includes/backend/backend_evento.cfm').read_text()
query=source.split('<cfquery name="qEventoEdicoes"')[1].split('</cfquery>')[0]
query='<cfquery name="qEventoEdicoes"'+query+'</cfquery>'
cases=['2015-91-corrida-internacional-de-sao-silvestre','2007-83-corrida-internacional-de-sao-silvestre','2021-96-corrida-internacional-de-sao-silvestre','2026-101-corrida-internacional-de-sao-silvestre','2026-together-run-pe']
tags=','.join("'"+x+"'" for x in cases)
body='''<cfsetting showdebugoutput="false" requesttimeout="120"/><cfcontent type="application/json" reset="true"/>
<cfset report=[]/><cfset VARIABLES.eventRecordAssetsBaseUrl="https://roadrunners.run/assets/paginas/"/>
<cftransaction><cfquery>SET TRANSACTION READ ONLY; SET LOCAL statement_timeout='20s'</cfquery>
<cfquery name="cases">SELECT id_evento,tag,id_agrega_evento FROM tb_evento_corridas WHERE tag IN (TAGS) ORDER BY id_evento</cfquery>
<cfloop query="cases"><cfset qEvento=queryNew("id_agrega_evento","integer",[{id_agrega_evento=val(cases.id_agrega_evento)}])/>
<cfif val(qEvento.id_agrega_evento) GT 0><cfset started=getTickCount()/>
QUERY
<cfset arrayAppend(report,{event=cases.id_evento,tag=cases.tag,aggregator=cases.id_agrega_evento,query_ms=qEventoEdicoesMeta.executionTime,elapsed_ms=getTickCount()-started,rows=qEventoEdicoes.recordCount,hash=hash(serializeJSON(qEventoEdicoes),"SHA-256")})/>
</cfif></cfloop></cftransaction><cfoutput>#serializeJSON(report)#</cfoutput>'''.replace('TAGS',tags).replace('QUERY',query)
remote='''from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
body=json.load(sys.stdin)['body'];r=Path('/var/www/business.roadrunners.run');w=Path(tempfile.mkdtemp(prefix='seo-editions-profile-',dir=r/'_codex'));os.chmod(w,0o755);key=secrets.token_hex(24)
try:
 (w/'.htaccess').write_text('Require local\\n')
 (w/'Application.cfc').write_text('component{this.name="'+w.name+'";this.datasource="runnerhub";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 (w/'run.cfm').write_text(body)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','125','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+w.name+'/run.cfm'],capture_output=True,text=True,timeout=130)
 if cp.returncode:raise RuntimeError('Private profiling failed; inspect diagnostic without exporting records. '+cp.stderr[-200:])
 print(cp.stdout)
finally:shutil.rmtree(w)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(dict(body=body)),capture_output=True,text=True,timeout=150);assert cp.returncode==0,cp.stderr[-1000:]
r=json.loads(cp.stdout);assert isinstance(r,list);r=[{k.lower():v for k,v in x.items()} for x in r];(S/('profile-editions-'+mode+'.json')).write_text(json.dumps(r,indent=2))
print(json.dumps(r,ensure_ascii=False,indent=2))
