from pathlib import Path
import json,os,secrets,shutil,subprocess,tempfile
root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='crm-config-audit-',dir=root/'_codex'));key=secrets.token_hex(32);os.chmod(work,0o755)
source=(root/'services/CrmCommerceService.cfc').read_text()
source=source.replace('private struct function config()','public struct function config()',1)
source=source.replace(' private any function field',' public struct function scopeDiagnostic(){return {variables_config_present=structKeyExists(variables,"pagarMeLocalConfig"),variables_key_count=structKeyExists(variables,"pagarMeLocalConfig") ? structCount(variables.pagarMeLocalConfig):0};}\n private any function field',1)
try:
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.mappings["/config"]="'+str(root/'config')+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 (work/'ProbeService.cfc').write_text(source)
 (work/'run.cfm').write_text('''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cfscript>p=createObject("component","ProbeService");out={};try{c=p.config();out.config={secret_present=len(c.secretKey)>0};}catch(any e){out.config={error=e.message,type=e.type};}out.scopes=p.scopeDiagnostic();writeOutput(serializeJSON(out));</cfscript>''')
 for p in work.iterdir():os.chmod(p,0o644)
 result=subprocess.run(['curl','-sS','--max-time','15','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=20)
 try:print(json.dumps(json.loads(result.stdout),indent=2))
 except ValueError:print(json.dumps({'rc':result.returncode,'json':False}))
finally:shutil.rmtree(work)
