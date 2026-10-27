"""Isolated, localhost-only CF2025 tests. No writes to user records or providers."""
import base64,json,pathlib,shlex,subprocess,sys,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
MODE=sys.argv[1] if len(sys.argv)>1 else 'source'
if MODE=='refresh-preview' and len(sys.argv)>2:
    preview=pathlib.Path(sys.argv[2]).resolve()
    if not preview.name.startswith('business-user-acquisition-preview-') or not (preview/'index.html').is_file():raise SystemExit('Unknown preview directory')
    for name in ['acquisition.js','acquisition.css']:
        (preview/'administracao/usuarios/assets'/name).write_bytes((ROOT/'administracao/usuarios/assets'/name).read_bytes())
    (preview/'mobile.html').write_bytes((ROOT/'_codex/tests/user-acquisition/mobile.html').read_bytes())
    print(json.dumps({'ok':True,'preview_path':str(preview)}));raise SystemExit(0)
REMOTE=r'''
import json,os,pathlib,secrets,subprocess,sys,tempfile
p=json.load(sys.stdin);mode=p.pop('mode');root=pathlib.Path('/var/www/business.roadrunners.run')
name='user_acquisition_'+secrets.token_hex(8);stage=root/'_codex'/name
archive=pathlib.Path(tempfile.mkdtemp(prefix='business-user-acquisition-test-',dir='/var/backups'));os.chmod(archive,0o700)
nonce=secrets.token_hex(24);result={'ok':False}
try:
 stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n')
 (stage/'Application.cfc').write_text('component {this.name="'+name+'";this.datasource="runner_dba";this.sessionManagement=true;this.setClientCookies=false;}')
 for rel,body in p.items():
  dest=stage/rel;dest.parent.mkdir(parents=True,exist_ok=True)
  body=body.replace('new services.UserAcquisitionMetrics','new _codex.'+name+'.services.UserAcquisitionMetrics')
  dest.write_text(body,encoding='utf-8-sig');os.chmod(dest,0o644)
 wrapper='<cfsetting showdebugoutput="false" requesttimeout="40"><cfscript>if(!listFind("127.0.0.1,::1",CGI.remote_addr) OR (CGI.http_x_acquisition_test ?: "") NEQ "'+nonce+'") {cfheader(statuscode=404);abort;}cfcontent(type="text/plain; charset=utf-8",reset=true);cfheader(name="Cache-Control",value="no-store");try{include "tests/'+mode+'.cfm";}catch(any failed){writeOutput("TEST_FAILED " & encodeForHTML(failed.type & ": " & failed.message & " " & left(failed.detail ?: "",600)));if(structKeyExists(failed,"tagContext"))for(frame in failed.tagContext)writeOutput(chr(10) & encodeForHTML(listLast(frame.template,"/") & ":" & frame.line));}</cfscript>'
 (stage/'run.cfm').write_text(wrapper,encoding='utf-8-sig');os.chmod(stage/'run.cfm',0o644)
 run=subprocess.run(['curl','--silent','--show-error','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','--header','X-Acquisition-Test: '+nonce,'https://business.roadrunners.run/_codex/'+name+'/run.cfm'],capture_output=True,timeout=50)
 raw=run.stdout.decode(errors='replace');(archive/'result.txt').write_text(raw);os.chmod(archive/'result.txt',0o600)
 result={'ok':not run.returncode and 'USER_ACQUISITION_'+mode.upper()+'_PASSED' in raw and 'TEST_FAILED' not in raw,'output':raw[-5000:] if '<!doctype' not in raw.lower() else 'Unexpected HTML; inspect private archive'}
 if mode=='preview' and result['ok']:
  import base64
  result['html']=base64.b64encode(raw.encode()).decode();result['output']='Aggregate preview compiled successfully'
finally:
 if stage.exists():stage.rename(archive/'fixture')
 result.update({'archive':str(archive),'stage_removed':not stage.exists()})
print(json.dumps(result))
'''
payload={'mode':MODE}
for rel in ['services/UserAcquisitionMetrics.cfc','administracao/usuarios/includes/backend.cfm','administracao/usuarios/home.cfm']:
    path=ROOT/rel
    if path.exists():payload[rel]=path.read_text()
for path in (ROOT/'administracao/usuarios/includes').glob('*.cfm'):
    payload[str(path.relative_to(ROOT))]=path.read_text()
for path in (ROOT/'_codex/tests/user-acquisition').glob('*.cfm'):
    payload['tests/'+path.name]=path.read_text()
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=65)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-600:] or 'Native transport failed'}
if result.get('ok') and 'html' in result:
    preview=pathlib.Path(tempfile.mkdtemp(prefix='business-user-acquisition-preview-'))
    (preview/'index.html').write_bytes(base64.b64decode(result.pop('html')))
    (preview/'mdb.min.css').write_bytes((ROOT/'assets/css/mdb.min.css').read_bytes())
    (preview/'mobile.html').write_bytes((ROOT/'_codex/tests/user-acquisition/mobile.html').read_bytes())
    for name in ['acquisition.js','acquisition.css']:
        target=preview/'administracao/usuarios/assets'/name;target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes((ROOT/'administracao/usuarios/assets'/name).read_bytes())
    result['preview_path']=str(preview)
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
