"""Runs on the server; ephemeral loopback-only diagnostics, no messages sent."""
from pathlib import Path
import hashlib,json,os,secrets,shutil,subprocess,tempfile
root=Path('/var/www/business.roadrunners.run')
work=Path(tempfile.mkdtemp(prefix='storage-validation-',dir=root/'_codex'));os.chmod(work,0o755)
key=secrets.token_hex(32)
try:
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.mappings["/services"]="/var/www/roadrunners.com.br/services";this.mappings["/inc"]="/var/www/conteudo.roadrunners.run/inc";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 (work/'run.cfm').write_text('''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cfscript>
 result={};
 result.mailCredentialAvailable=createObject("component","services.MedicalConfirmationMailer").init().available();
 result.trainingCredentialAvailable=createObject("component","services.TrainingConfirmationMailer").init().available();
 config=createObject("component","inc.content_local_config").loadFileConfig();
 result.oauthConfigured=true;
 for(k in ["googleOAuthClientId","googleOAuthClientSecret","googleOAuthRedirectUri"]){result.oauthConfigured=result.oauthConfigured AND structKeyExists(config,k) AND len(trim(config[k]&"")) GT 0;}
 result.oauthFallbackReadable=fileExists("/var/lib/runnerhub-secrets/content-google-oauth.local.cfm") AND len(fileRead("/var/lib/runnerhub-secrets/content-google-oauth.local.cfm")) GT 0;
 logHandle=fileOpen("/var/log/apache2/api.roadrunners.run-telemetry.log","read");fileClose(logHandle);result.telemetryReadable=true;
 reportRoot="/var/lib/runnerhub/reports/mif-2026/";manifest=deserializeJSON(fileRead(reportRoot&"manifest.json"));result.reportArtifacts=0;result.reportIntegrity=true;
 for(path in manifest.artifacts){receipt=manifest.artifacts[path];bytes=fileReadBinary(reportRoot&path);result.reportIntegrity=result.reportIntegrity AND lcase(hash(bytes,"SHA-256")) EQ lcase(receipt.sha256) AND arrayLen(bytes) EQ receipt.bytes;result.reportArtifacts++;}
 writeOutput(serializeJSON(result));
 </cfscript>''')
 for p in work.iterdir():os.chmod(p,0o644)
 r=subprocess.run(['curl','-sS','--max-time','40','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=45)
 try:out=json.loads(r.stdout)
 except ValueError:raise RuntimeError('Diagnostic did not return JSON; no response printed to avoid exposing configuration')
 print(json.dumps(out,indent=2))
 assert out.get('MAILCREDENTIALAVAILABLE') and out.get('TRAININGCREDENTIALAVAILABLE') and out.get('OAUTHCONFIGURED') and out.get('OAUTHFALLBACKREADABLE') and out.get('TELEMETRYREADABLE') and out.get('REPORTINTEGRITY')
finally:shutil.rmtree(work)
