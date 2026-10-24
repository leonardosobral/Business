#!/usr/bin/env python3
"""Proposed real service/SQL verification. Default prints plan; --execute is required to run."""
import argparse
import hashlib
import json
import shlex
import subprocess
from release_support import BASE, SSH, load_package

REMOTE = r'''
import hashlib,json,os,secrets,shutil,subprocess,sys,tempfile
from pathlib import Path
payload=json.load(sys.stdin)
root=Path('/var/www/business.roadrunners.run')
service=Path('/var/www/roadrunners.com.br/services/AudienceMeasurementService.cfc')
assert not service.is_symlink() and service.is_file()
actual=hashlib.sha256(service.read_bytes()).hexdigest()
assert actual==payload['expected_service_sha256'],'Published service does not match reviewed release'
work=Path(tempfile.mkdtemp(prefix='live-funnel-verify-',dir=root/'_codex'))
os.chmod(work,0o755)
token=secrets.token_hex(32)
try:
    (work/'.htaccess').write_text('Require local\n')
    app='component {this.name="'+work.name+'";this.datasource="runnerhub";this.sessionManagement=false;this.mappings["/liveVerifyServices"]="/var/www/roadrunners.com.br/services";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}'
    (work/'Application.cfc').write_text(app)
    body='<cfsetting requesttimeout="40" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cfheader name="Cache-Control" value="no-store"/><cftry><cfscript>'+payload['cfml']+'writeOutput(serializeJSON(report));</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>'
    (work/'run.cfm').write_text(body)
    for name in ['.htaccess','Application.cfc','run.cfm']:os.chmod(work/name,0o644)
    result=subprocess.run(['curl','-sS','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=50)
    if result.returncode:raise RuntimeError('Private verification HTTP failed; inspect before retry')
    report=json.loads(result.stdout)
    report={k.lower():v for k,v in report.items()}
    if 'error' in report:raise RuntimeError(json.dumps(report))
    assert report.get('verified') is True and report.get('rows_after_rollback')==0,'Verification did not prove rollback'
    assert hashlib.sha256(service.read_bytes()).hexdigest()==actual,'Service changed during verification'
    report['deployed_service_sha256']=actual
    print(json.dumps(report))
finally:
    shutil.rmtree(work)
'''


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--execute',action='store_true',help='Execute eight synthetic INTERNAL events in one rollback-only transaction via private loopback bridge')
    args=parser.parse_args()
    rows,_,_=load_package(BASE/'release')
    match=[r for r in rows if r['site']=='RoadRunners' and r['path']=='services/AudienceMeasurementService.cfc']
    if len(match)!=1:raise RuntimeError('Reviewed deployed service absent from release manifest')
    body=(BASE/'verify_tracking_transaction.cfm').read_text()
    plan={'operation':'live-funnel-service-sql-verification','execute':args.execute,'fixture_rows':8,'internal':True,'rollback_only':True,
          'datasource':'runnerhub','public_http_collector_tested':False,'expected_service_sha256':match[0]['after'],
          'fixture_sha256':hashlib.sha256(body.encode()).hexdigest()}
    if not args.execute:
        print(json.dumps(plan,indent=2));return
    result=subprocess.run(SSH+['python3 -c '+shlex.quote(REMOTE)],input=json.dumps({'cfml':body,'expected_service_sha256':match[0]['after']}),capture_output=True,text=True,timeout=70)
    if result.returncode:raise RuntimeError(result.stderr[-4000:])
    report=json.loads(result.stdout)
    (BASE/'tracking-transaction-verification.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))


if __name__=='__main__':main()
