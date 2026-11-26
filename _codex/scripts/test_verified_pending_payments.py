"""Bounded, loopback-only CF tests. No provider calls or entitlement writes."""
from pathlib import Path
import base64,json,shlex,subprocess,sys,hashlib
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/'_codex/staging/verified-pending-payments-20261124'
FILES=['services/VerifiedAdmin.cfc','portal/includes/verified_backend.cfm','portal/verificados/home.cfm','portal/verificados/index.cfm','portal/verificados/verified.css','portal/verificados/verified.js','portal/verificados/evidence.cfm']
SSH=['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=10','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
REMOTE=r'''
from pathlib import Path
import base64,json,os,secrets,shutil,subprocess,sys,tempfile,time
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');stage=Path(tempfile.mkdtemp(prefix='verified-payments-test-',dir=root/'_codex'));token=secrets.token_hex(32);out={}
try:
 os.chmod(stage,0o755)
 (stage/'.htaccess').write_text('Require local\n')
 for rel,data in p['files'].items():
  path=stage/rel;path.parent.mkdir(parents=True,exist_ok=True)
  if rel.endswith('.cfm') or rel.endswith('.cfc'):data=data.replace('new services.VerifiedAdmin()','createObject("component","_codex.'+stage.name+'.services.VerifiedAdmin")').replace('extends="services.VerifiedAdmin"','extends="_codex.'+stage.name+'.services.VerifiedAdmin"').replace("createObject('component','QuickFake')","createObject('component','_codex."+stage.name+".QuickFake')")
  path.write_text(data,encoding='utf-8-sig')
 (stage/'Application.cfc').write_text('component {this.name="'+stage.name+'";this.datasource="runner_dba";this.sessionManagement=true;this.setClientCookies=false;boolean function onRequestStart(string t){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||(cgi.http_x_verified_test ?: "")!="'+token+'") {cfheader(statuscode=404);abort;}return true;}}')
 # Replace constructor parentheses after createObject in staged CF only.
 for path in stage.rglob('*.cf*'):
  text=path.read_text(encoding='utf-8-sig');text=text.replace('VerifiedAdmin")()','VerifiedAdmin")');path.write_text(text,encoding='utf-8-sig')
 wrapper='<cfsetting showdebugoutput="false" requesttimeout="55"/><cftry><cfinclude template="native.cfm"/><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({ok=false,error=cfcatch.message,detail=cfcatch.detail,context=cfcatch.tagContext})#</cfoutput></cfcatch></cftry>'
 (stage/'run.cfm').write_text(wrapper)
 out['timings']={}
 def call(page,form=None):
  began=time.monotonic()
  args=['curl','-sS','--max-time','60','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Verified-Test: '+token,'https://business.roadrunners.run/_codex/'+stage.name+'/'+page,'-w','\n%{http_code}']
  if form:args+=['-X','POST','--data',form]
  r=subprocess.run(args,capture_output=True,text=True,timeout=65)
  out['timings'][page]=round(time.monotonic()-began,3)
  if r.returncode:raise RuntimeError('Loopback transport failed')
  raw,status=r.stdout.rsplit('\n',1)
  out.setdefault('statuses',{})[page]=int(status)
  return raw.strip('\ufeff \n\r\t')
 out['tests']=json.loads(call('run.cfm'))
 if not out['tests'].get('OK',out['tests'].get('ok',False)):raise RuntimeError(json.dumps(out['tests']))
 # Render the actual templates under a test-only authenticated context.
 (stage/'includes/backend').mkdir(parents=True,exist_ok=True)
 (stage/'includes/backend/require_real_platform_context.cfm').write_text((root/'includes/backend/require_real_platform_context.cfm').read_text())
 render="""<cfsetting showdebugoutput="false" requesttimeout="55"/><cftry><cfscript>qPerfil=queryNew("id,is_admin","integer,bit",[{id=139,is_admin=true}]);requireAdminAllowed=(URL.test_denied ?: "") != "1";</cfscript><cftransaction isolation="read_committed"><cfquery>SET TRANSACTION READ ONLY</cfquery><cfinclude template="portal/includes/verified_backend.cfm"/><cftransaction action="rollback"/></cftransaction><cfif (URL.fixture_ready ?: "") EQ "1"><cfset verifiedData.ready=true/></cfif><!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"></head><body data-mdb-theme="dark" style="background:rgb(34,34,34);padding:20px"><cfinclude template="portal/verificados/home.cfm"/></body></html><cfcatch><cfoutput>RENDER_ERROR #encodeForHTML(cfcatch.message & ' ' & cfcatch.detail)#<cfloop array="#cfcatch.tagContext#" index="f"> #f.template#:#f.line#</cfloop></cfoutput></cfcatch></cftry>"""
 (stage/'render.cfm').write_text(render)
 manual_id=out['tests']['MANUAL_ID'];rendered=call('render.cfm?filter_status=unclassified&fixture_ready=1');detail=call('render.cfm?filter_status=unclassified&page_id=53887')
 denied=call('render.cfm?test_denied=1')
 if out['statuses']['render.cfm?test_denied=1']!=403:raise RuntimeError('Admin gate failed')
 csrf=call('render.cfm?case=csrf','verified_action=classify&verified_csrf=invalid')
 if out['statuses']['render.cfm?case=csrf']!=403:raise RuntimeError('CSRF gate failed')
 legacy=call('render.cfm?case=legacy','verified_action=toggle&verified_page_id=0&verified_status=true')
 if out['statuses']['render.cfm?case=legacy']!=409:raise RuntimeError('Legacy grant action not blocked')
 if 'RENDER_ERROR' in rendered or 'RENDER_ERROR' in detail:raise RuntimeError((rendered if 'RENDER_ERROR' in rendered else detail)[-4000:])
 if '61 perfis encontrados' not in rendered or 'verified-bulk-form' not in rendered:raise RuntimeError('Rendered quick controls missing')
 import html as htmlmod
 decoded=htmlmod.unescape(detail)
 if not all(term in decoded for term in ['Conferido na API da Pagar.me','Vínculo do comprador a revisar','Pagamentos e pedidos','R$','Sem vencimento']):raise RuntimeError('Review context missing')
 # Encoded profile and provider text, using in-memory fixture only.
 xss="""<cfsetting showdebugoutput="false"/><cfscript>requireAdminAllowed=true;verifiedContext={profile={bio='<script>alert(1)</script>',instagram='<img src=x onerror=alert(1)>'},accounts=[],registrations=[{challenge_name='<b>unsafe</b>',product_name='VIP',status='I',registered_at='',order_ref='<iframe src=x>',note='',challenge_code='test',product_code='test'}],legacy=[],payments=[]};</cfscript><cfinclude template="portal/verificados/evidence.cfm"/>"""
 (stage/'xss.cfm').write_text(xss)
 escaped=call('xss.cfm')
 if '<script>' in escaped or '<iframe' in escaped or '<img src=x' in escaped or '<b>unsafe</b>' in escaped:raise RuntimeError('Unescaped context')
 if 'alert' not in escaped or 'iframe' not in escaped:raise RuntimeError('XSS fixture not rendered')
 out['xss_escaped']=True
 out['render_html']=base64.b64encode(rendered.encode()).decode();out['detail_html']=base64.b64encode(detail.encode()).decode();out['ok']=True
finally:
 shutil.rmtree(stage);out['stage_removed']=not stage.exists()
print(json.dumps(out))
'''
if __name__=='__main__':
    payload={'files':{p:(ROOT/p).read_text() for p in FILES}}
    payload['files']['native.cfm']=(ROOT/'_codex/tests/verified-origins/payment-scan-native.cfm').read_text()
    payload['files']['QuickFake.cfc']=(ROOT/'_codex/tests/verified-origins/QuickFake.cfc').read_text()
    tested_hashes={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in FILES}
    r=subprocess.run(SSH+['python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
    if r.returncode:print(r.stderr[-6500:]);raise SystemExit(1)
    result=json.loads(r.stdout);result['tested_hashes']=tested_hashes
    for key,filename in [('render_html','preview.html'),('detail_html','detail.html')]:
        if key in result:(STAGE/filename).write_bytes(base64.b64decode(result.pop(key)))
    (STAGE/'native-tests.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
    print(json.dumps(result,ensure_ascii=False,indent=2))
