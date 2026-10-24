"""Run the existing initializer in an isolated application, then remove probe files."""
from pathlib import Path
import json
import os
import secrets
import shutil
import subprocess
import tempfile

root = Path('/var/www/business.roadrunners.run')
work = Path(tempfile.mkdtemp(prefix='cron-init-audit-', dir=root / '_codex'))
token = secrets.token_hex(32)
os.chmod(work, 0o755)
try:
    (work / '.htaccess').write_text('Require local\n')
    (work / 'Application.cfc').write_text('component { this.name="' + work.name + '"; this.mappings["/auditBusinessRoot"]="' + str(root) + '"; boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","' + token + '")!=0){cfheader(statuscode=404);abort;}return true;} }')
    (work / 'run.cfm').write_text('''<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfcontent type="application/json" reset="true"/>
<cftry><cfscript>
instance = createObject("component", "auditBusinessRoot.Application");
instance.OnApplicationStart();
writeOutput(serializeJSON({
    applicationName=getApplicationMetadata().name,
    isolatedApplication=find("cron-init-audit-",getApplicationMetadata().name)==1,
    cronPresent=structKeyExists(APPLICATION,"cronJobs"),
    cronEnabled=APPLICATION.cronJobs.enabled,
    cronTokenPresent=len(APPLICATION.cronJobs.runnerToken)>0,
    cronSecretCount=structCount(APPLICATION.cronJobs.secrets),
    accountDelegationEnabled=APPLICATION.businessAccountDelegationEnabled,
    notificationSecretLength=len(APPLICATION.notificationDispatch.secret)
}));
</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message})#</cfoutput></cfcatch></cftry>''')
    for file in work.iterdir():
        os.chmod(file, 0o644)
    result = subprocess.run(['curl', '-sS', '--max-time', '35', '--resolve', 'business.roadrunners.run:443:127.0.0.1', '-X', 'POST', '--data-urlencode', 'key=' + token, 'https://business.roadrunners.run/_codex/' + work.name + '/run.cfm'], capture_output=True, text=True, timeout=40)
    try:
        print(json.dumps(json.loads(result.stdout), indent=2))
    except ValueError:
        print(json.dumps({'curl_rc': result.returncode, 'json_response': False, 'stderr': result.stderr[:300]}))
finally:
    shutil.rmtree(work)
