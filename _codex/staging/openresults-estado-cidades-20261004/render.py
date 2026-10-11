from pathlib import Path
import json,subprocess,shlex
s=Path(__file__).resolve().parent
payload={'files':{n:(s/'candidate'/n).read_text() for n in json.loads((s/'manifest.json').read_text())['order']}}
remote='''
from pathlib import Path
import tempfile,shutil,os,json,secrets,subprocess
payload=json.load(__import__('sys').stdin);root=Path('/var/www/openresults.run')
work=Path(tempfile.mkdtemp(prefix='or-city-render-',dir=root/'_codex'));os.chmod(work,0o755)
token=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runnerhub";this.sessionManagement=true;this.setClientCookies=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}application.nomeSite="Open Results";application.baseCanonica="https://openresults.run";application.dominio="openresults.run";application.codSite="OR";application.ga="";return true;}}')
 for folder in ['includes','estado','api']:
  target=work/'candidate'/folder;target.mkdir(parents=True,exist_ok=True)
  for source in (root/folder).iterdir():
   if str(source.relative_to(root)) not in payload['files']:(target/source.name).symlink_to(source)
 for name,content in payload['files'].items():
  p=work/'candidate'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(content)
 (work/'run.cfm').write_text('<cfsetting requesttimeout="90" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfset URL.tag="BA"/><cfset URL.cidade="salvador"/><cfset URL.filtro="maratonas"/><cfsavecontent variable="html"><cfinclude template="candidate/estado/index.cfm"/></cfsavecontent><cfoutput>#serializeJSON({html=html,total=qEventos.recordCount,cities=qEstadoCidades.recordCount,selected=VARIABLES.estadoCidadeNome})#</cfoutput><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail,trace=cfcatch.tagContext})#</cfoutput></cfcatch></cftry>')
 cp=subprocess.run(['curl','-sS','--max-time','95','--resolve','openresults.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://openresults.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=100)
 result=json.loads(cp.stdout)
 if any(k.lower()=='error' for k in result):raise RuntimeError(json.dumps(result))
 print(json.dumps(result))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=120)
if cp.returncode:raise RuntimeError(cp.stderr[-4500:])
r={k.lower():v for k,v in json.loads(cp.stdout).items()}
(s/'tests/candidate-render.html').write_text(r.pop('html'))
(s/'tests/candidate-render.json').write_text(json.dumps(r,indent=2))
print(json.dumps(r))
