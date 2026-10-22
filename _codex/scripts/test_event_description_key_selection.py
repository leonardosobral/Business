"""Run only the real credential-selection block with dummy keys in native CFML."""
import json,pathlib,shlex,subprocess,sys

ROOT=pathlib.Path(__file__).resolve().parents[2]
REMOTE=r'''
import json,os,pathlib,secrets,subprocess,sys,tempfile
payload=json.load(sys.stdin)
stage=pathlib.Path(tempfile.mkdtemp(prefix='rewrite-key-test-',dir='/var/www/business.roadrunners.run/_codex'))
os.chmod(stage,0o755)
nonce=secrets.token_hex(24)
try:
    (stage/'.htaccess').write_text('Require local\n')
    (stage/'run.cfm').write_text(payload['test'].replace('@@NONCE@@',nonce))
    (stage/'selection.cfm').write_text(payload['selection'])
    for item in stage.iterdir():os.chmod(item,0o644)
    proc=subprocess.run(['curl','--silent','--show-error','--max-time','20','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Rewrite-Key-Test: '+nonce,'https://business.roadrunners.run/_codex/'+stage.name+'/run.cfm'],capture_output=True,timeout=25)
    try:result=json.loads(proc.stdout)
    except Exception:result={'ok':False,'error':'Native CFML tests did not return safe JSON'}
finally:
    archive=pathlib.Path(tempfile.mkdtemp(prefix='rewrite-key-test-',dir='/var/backups'));os.chmod(archive,0o700)
    stage.rename(archive/'tests')
print(json.dumps(result))
'''
source=(ROOT/'api/eventos/jobs/rewrite-descriptions.cfm').read_text()
start=source.index('VARIABLES.rewriteApiKey =')
end=source.index('VARIABLES.rewriteModel =',start)
payload={'test':(ROOT/'_codex/tests/event-description-key-selection.cfm').read_text(),'selection':'<cfscript>\n'+source[start:end]+'\n</cfscript>'}
proc=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=40)
try:result=json.loads(proc.stdout)
except Exception:result={'ok':False,'error':'SSH tests failed; details suppressed'}
print(json.dumps(result))
if proc.returncode or not result.get('ok',result.get('OK',False)):sys.exit(1)
