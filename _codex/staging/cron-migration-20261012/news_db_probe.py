from pathlib import Path
import json, os, secrets, shutil, subprocess, tempfile
root=Path('/var/www/conteudo.roadrunners.run')
work=Path(tempfile.mkdtemp(prefix='cron-database-audit-',dir=root))
key=secrets.token_hex(32)
os.chmod(work,0o755)
code='''<cfsetting showdebugoutput="false" requesttimeout="30"/><cfcontent type="application/json" reset="true"/><cfscript>
function failure(e){var context=[];for(var frame in (e.tagContext ?: [])){arrayAppend(context,{template=frame.template,line=frame.line});}return {message=e.message,detail=e.detail ?: "",type=e.type,context=context};}
out={};
try { q=queryExecute("SELECT current_database() AS db,current_user AS db_user,to_regclass('news.tb_runtime_settings')::text AS runtime_table",{},{datasource="runner_dba"});out.database={name=q.db[1],user=q.db_user[1],runtime_table=q.runtime_table[1]};}catch(any e){out.database=failure(e);}
try { c=createObject("component","inc.content_local_config").loadFileConfig();application.importerHandoffSecret=c.importerHandoffSecret ?: "";out.file_config={secret_present=len(application.importerHandoffSecret)>0};}catch(any e){out.file_config=failure(e);}
try { c=createObject("component","inc.content_local_config").loadConfig();out.loaded_config={keys=structKeyArray(c),encrypted_gmail_present=len(c.sixCommGmailRefreshTokenEncrypted ?: "")>0};}catch(any e){out.loaded_config=failure(e);}
try { c=createObject("component","inc.sixcomm_mail_config").loadConfig();out.mail_config={refresh_token_present=len(c.sixCommGmailRefreshToken ?: "")>0};}catch(any e){out.mail_config=failure(e);}
try { out.channel=createObject("component","inc.channel_publication_policy").load(1);}catch(any e){out.channel=failure(e);}
writeOutput(serializeJSON(out));
</cfscript>'''
try:
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component { this.name="'+work.name+'";this.datasource="runner_dba";this.mappings["/inc"]="'+str(root/'inc')+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;} }')
 (work/'run.cfm').write_text(code)
 for p in work.iterdir():os.chmod(p,0o644)
 r=subprocess.run(['curl','-sS','--max-time','35','--resolve','conteudo.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+key,'https://conteudo.roadrunners.run/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=40)
 try: print(json.dumps(json.loads(r.stdout),indent=2))
 except ValueError:print(json.dumps({'rc':r.returncode,'json':False,'error':r.stderr[:200]}))
finally:shutil.rmtree(work)
