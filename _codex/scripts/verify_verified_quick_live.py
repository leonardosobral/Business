"""Read-only verification of the deployed service/templates, in a private fixture."""
from pathlib import Path
import base64,json,shlex,subprocess
ROOT=Path(__file__).resolve().parents[2];STAGE=ROOT/'_codex/staging/verified-quick-20261124'
SSH=['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=10','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
REMOTE=r'''
from pathlib import Path
import base64,json,os,secrets,shutil,subprocess,sys,tempfile,hashlib
root=Path('/var/www/business.roadrunners.run');p=json.load(sys.stdin);stage=Path(tempfile.mkdtemp(prefix='verified-live-',dir=root/'_codex'));token=secrets.token_hex(32);out={}
try:
 os.chmod(stage,0o755);(stage/'.htaccess').write_text('Require local\n')
 for rel,expected in p['hashes'].items():
  if hashlib.sha256((root/rel).read_bytes()).hexdigest()!=expected:raise RuntimeError('Deployed hash differs: '+rel)
 (stage/'Application.cfc').write_text('component {this.name="'+stage.name+'";this.datasource="runner_dba";this.sessionManagement=true;this.setClientCookies=false;this.mappings["/services"]="'+str(root)+'/services";boolean function onRequestStart(string t){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||(cgi.http_x_verified_test ?: "")!="'+token+'") {cfheader(statuscode=404);abort;}return true;}}')
 body="""<cfprocessingdirective pageencoding="utf-8"/><cfsetting requesttimeout="30" showdebugoutput="false"/><cftransaction isolation="read_committed"><cfquery>SET TRANSACTION READ ONLY</cfquery><cfscript>qPerfil=queryNew("id,is_admin","integer,bit",[{id=139,is_admin=true}]);requireAdminAllowed=true;</cfscript><cfinclude template="/portal/includes/verified_backend.cfm"/><!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"></head><body data-mdb-theme="dark" style="background:rgb(34,34,34);padding:20px"><cfinclude template="/portal/verificados/home.cfm"/></body></html><cftransaction action="rollback"/></cftransaction>"""
 (stage/'render.cfm').write_text(body,encoding='utf-8-sig')
 for name,query,expected in [('list','', ['418 perfis encontrados','128','290']),('quick','?filter_status=unclassified',['Classificação rápida','128 perfis encontrados','Motivo em comum']),('vip','?page_id=53893',['ORIGENS DO SELO','Pagamento','Validade concedida','Todo Santo Dia']),('manual','?page_id=54048',['Concessão permanente','Motivo não informado']),('refund','?page_id=15305&filter_status=all',['Selo inativo','Estornado'])]:
  r=subprocess.run(['curl','-sS','--max-time','35','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Verified-Test: '+token,'-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+stage.name+'/render.cfm'+query],capture_output=True,text=True,timeout=40)
  html,status=r.stdout.rsplit('\n',1)
  # Encoded dynamic text is decoded only for assertions; original HTML remains escaped.
  import html as htmlmod
  decoded=htmlmod.unescape(html)
  if r.returncode or status!='200' or not all(term in decoded for term in expected):raise RuntimeError('Live verification failed: '+name+' '+status)
  out[name]={'status':int(status),'verified':True};out[name+'_html']=base64.b64encode(html.encode()).decode()
 out['ok']=True
finally:
 shutil.rmtree(stage);out['stage_removed']=not stage.exists()
print(json.dumps(out))
'''
receipt=json.loads((STAGE/'release.json').read_text());payload={'hashes':{p:v['after'] for p,v in receipt['files'].items()}}
r=subprocess.run(SSH+['python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload),capture_output=True,text=True,timeout=175)
if r.returncode:print(r.stderr[-1800:]);raise SystemExit(1)
out=json.loads(r.stdout)
for name in ['list','quick','vip','manual','refund']:
 (STAGE/('live-'+name+'.html')).write_bytes(base64.b64decode(out.pop(name+'_html')))
(STAGE/'live-verification.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
