from pathlib import Path
import json,shlex,subprocess,sys,hashlib,html as html_module
p=Path(__file__).parent; mode=sys.argv[1];assert mode in ['candidate','published']
files={str(n.relative_to(p/'candidate/Business')):n.read_text() for n in (p/'candidate/Business').rglob('*') if n.is_file()}
remote=r'''
from pathlib import Path
import json,os,shutil,tempfile,secrets,subprocess,sys
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='ads-acquisition-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
try:
 shutil.copytree(root/'portal/audiencia',work/'portal/audiencia');(work/'portal/includes').mkdir(parents=True);shutil.copyfile(root/'portal/includes/audience_backend.cfm',work/'portal/includes/audience_backend.cfm');(work/'includes/backend').mkdir(parents=True);shutil.copyfile(root/'includes/backend/require_admin.cfm',work/'includes/backend/require_admin.cfm')
 if p['mode']=='candidate':
  for n,s in p['files'].items():
   target=work/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(s)
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_ads_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 auth='<cfset VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}])/><cfset VARIABLES.businessEffectiveIsAdmin=true/>'
 (work/'render.cfm').write_text('<cfsetting showdebugoutput="false"/>'+auth+'<cfinclude template="portal/includes/audience_backend.cfm"/><cfinclude template="portal/audiencia/home.cfm"/>')
 (work/'denied.cfm').write_text('<cfinclude template="portal/audiencia/advertiser_acquisition.cfm"/>')
 result={}
 for n in ['render','denied']:
  cp=subprocess.run(['curl','-sS','--max-time','60','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Ads-Verify: '+key,'-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/'+n+'.cfm'],capture_output=True,text=True,timeout=65)
  if cp.returncode:raise RuntimeError('HTTP failed')
  html,status=cp.stdout.rsplit('\n',1);result[n]={'html':html,'status':int(status)}
 print(json.dumps(result))
finally:shutil.rmtree(work)
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'files':files}),capture_output=True,text=True,timeout=160)
if r.returncode:raise SystemExit(r.stderr[-3000:])
r=json.loads(r.stdout);html=html_module.unescape(r['render']['html']);(p/(mode+'-render.html')).write_text(r['render']['html'])
assert r['render']['status']==200, (r['render']['status'],html[:2000])
assert 'Relatório indisponível no momento' not in html and 'Error Occurred' not in html
for text in ['id="audience-advertisers"','Da campanha de aquisição ao anunciante','MIM | Campanha 01','rr_teste_e_corridas_interior_sp_202610','Caminho até a inscrição LIVE!','id="audience-overview"']:assert text in html,text
assert 'Acesso restrito' in r['denied']['html'] or r['denied']['status'] in [401,403]
assert 'MIM | Campanha 01' not in r['denied']['html']
(p/(mode+'-checks.json')).write_text(json.dumps({'passed':10,'hashes':{n:hashlib.sha256(s.encode()).hexdigest() for n,s in files.items()}}));print(mode+': 10 render, data and access checks passed')
