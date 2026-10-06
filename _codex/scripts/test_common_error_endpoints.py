"""Exercise actual CFML endpoints using isolated services and synthetic database state."""
from pathlib import Path
import json,subprocess,shlex,sys
ROOT=Path(__file__).resolve().parents[2];RR=ROOT.parent/'RoadRunners';STAGE=ROOT/'_codex/staging/common-errors-20261004'
mode=sys.argv[1] if len(sys.argv)>1 else 'before'
files={f:(RR/f).read_text() for f in ['api/analytics/collect.cfm','services/ErrorReporter.cfc','carteira/check_transacao.cfm']}
helpers=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=r"""
import secrets
payload=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='common-errors-test-',dir=root/'_codex'));os.chmod(work,0o755)
schema='common_test_'+secrets.token_hex(8)
bridge(root,'queryExecute("CREATE SCHEMA '+schema+'; CREATE TABLE '+schema+'.tb_transacoes(id_usuario integer,codigo_transacao text,status_atual varchar(100)); INSERT INTO '+schema+'.tb_transacoes VALUES(1,\'paid\',\'order.paid\'),(1,\'pending\',\'charge.pending\'),(1,\'declined\',\'charge.payment_failed\'),(2,\'other-user\',\'order.paid\')",{},{datasource="runner_dba"});report={created=true};')
try:
 token=secrets.token_hex(20)
 app='''component {this.name="APPNAME";this.datasource="runner_dba";this.mappings["/services"]=getDirectoryFromPath(getCurrentTemplatePath()) & "services";
 boolean function onRequestStart(string target){if(cgi.remote_addr!="127.0.0.1" || compare(getHTTPRequestData(false).headers["X-Test-Key"] ?: "","TOKEN")!=0){cfheader(statuscode=403);abort;}REQUEST.Usuario={logado=true,id=1};return true;}
 void function onError(any exception,string eventname){var data={type=arguments.exception.type,message=arguments.exception.message,detail=arguments.exception.detail};var source=arguments.exception.tagContext[1].template;var frame={template="/var/www/roadrunners.com.br/" & (find("collect.cfm",source) ? "api/analytics/collect.cfm" : "carteira/check_transacao.cfm"),line=arguments.exception.tagContext[1].line};var e={type=data.type,message=data.message,detail=data.detail,tagContext=[frame]};data.fingerprint=new services.ErrorReporter().describe(e,"","roadrunners.run","/").fingerprint;fileWrite(getDirectoryFromPath(getCurrentTemplatePath()) & "caught.json",serializeJSON(data));}

}'''.replace('APPNAME',work.name).replace('TOKEN',token)
 (work/'Application.cfc').write_text(app);(work/'.htaccess').write_text('Require local\n')
 for rel,content in payload['files'].items():
  f=work/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(content.replace('FROM tb_transacoes','FROM '+schema+'.tb_transacoes'))
 (work/'services/AudienceRequestControlService.cfc').write_text('''component {any function init(any config){return this;} struct function evaluate(any cgi,any headers){return {allowed=true,hostConfig={secret="synthetic-only",host="local.invalid"}};} struct function consumeRateLimit(any state,any decision,any cgi){return {allowed=true};}}''')
 (work/'services/AudienceMeasurementService.cfc').write_text('''component {any function init(any config){return this;} boolean function isEnabled(){return true;} struct function validateBatch(any payload,any host,any headers){if((URL.scenario ?: "")=="invalid")throw(type="Audience.Invalid",message="Synthetic invalid input");return {};} numeric function persist(any batch){if((URL.scenario ?: "")=="committed"){writeOutput(repeatString(".",9000));cfflush();throw(message="Synthetic unavailable");}if((URL.scenario ?: "")=="unavailable")throw(message="Synthetic unavailable");return 0;}}''')
 checks=[]
 for scenario in ['valid','invalid','unavailable','committed']:
  caught=work/'caught.json';caught.write_text('');os.chmod(caught,0o666)
  p=subprocess.run(['curl','-sS','--max-time','20','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Test-Key: '+token,'-H','Content-Type: application/json','--data','{}','-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/api/analytics/collect.cfm?scenario='+scenario],capture_output=True,text=True,check=True)
  body,status=p.stdout.rsplit('\n',1);item={'endpoint':'analytics','scenario':scenario,'status':int(status),'body':body if len(body)<100 else '<flushed>'}
  if caught.stat().st_size:item['caught']=json.loads(caught.read_text())
  
  if '<html' in body.lower() or 'cferror' in body.lower():
   import re,html
   plain=re.sub(r'\s+',' ',html.unescape(re.sub('<[^>]+>',' ',body)));pos=plain.find('Error Occurred While Processing Request');item['error_text']=plain[max(0,pos):max(0,pos)+1300]
  checks.append(item)
 for tid in ['paid','pending','declined','missing','other-user']:
  caught=work/'caught.json';caught.write_text('');os.chmod(caught,0o666)
  p=subprocess.run(['curl','-sS','--max-time','20','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Test-Key: '+token,'-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/carteira/check_transacao.cfm?tid='+tid],capture_output=True,text=True,check=True)
  body,status=p.stdout.rsplit('\n',1);item={'endpoint':'wallet','tid':tid,'status':int(status),'body':body.strip()[:200]}
  if caught.stat().st_size:item['caught']=json.loads(caught.read_text())
  
  if '<html' in body.lower() or 'cferror' in body.lower():
   import re,html
   plain=re.sub(r'\s+',' ',html.unescape(re.sub('<[^>]+>',' ',body)));pos=plain.find('Error Occurred While Processing Request');item['error_text']=plain[max(0,pos):max(0,pos)+1300]
  checks.append(item)
 if payload['mode']=='after':
  assert all('caught' not in c for c in checks),checks
  assert [c['status'] for c in checks[:4]]==[200,400,503,200],checks
  assert [json.loads(c['body'])['STATUS'] for c in checks[4:]]==['APPROVED','PENDING','DECLINED','CHECK','CHECK'],checks
 print(json.dumps({'mode':payload['mode'],'checks':checks,'passed':True}))
finally:
 shutil.rmtree(work)
 bridge(root,'queryExecute("DROP SCHEMA '+schema+' CASCADE",{},{datasource="runner_dba"});report={removed=true};')
"""
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(helpers+remote)],input=json.dumps({'files':files,'mode':mode}),capture_output=True,text=True,timeout=160)
print(p.stdout);print(p.stderr[-1600:]);(STAGE/('test-endpoints-'+mode+'.json')).write_text(p.stdout);sys.exit(p.returncode)
