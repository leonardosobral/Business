"""Run the real timer lookup prefix in an isolated CFML app and synthetic schema."""
from pathlib import Path
import json, subprocess, shlex,sys
ROOT=Path(__file__).resolve().parents[2];RR=ROOT.parent/'RoadRunners';stage=ROOT/'_codex/staging/common-errors-20261004'
mode=sys.argv[1];assert mode in ('before','after')
content=(RR/'org/index.cfm').read_text();end='<cfset logQueryDebug("qTema", qTemaMeta, "org/tema", "sem cache", qTema)/>'
content=content[:content.index(end)+len(end)]
import re
content=re.sub(r'<cfset logQueryDebug\([^\n]+\)/>','',content)
for inc in ['../includes/estrutura/variaveis.cfm','../includes/backend/backend.cfm','../includes/backend/backend_login.cfm','../includes/backend/backend_feed.cfm']:
 content=content.replace('<cfinclude template="'+inc+'"/>','')
content+='<cfoutput>VALID:#qFornecedor.id_fornecedor#</cfoutput>'
payload={'route':content,'notfound':(RR/'includes/errors/notfound.cfm').read_text(),'page':(RR/'errors/404.html').read_text(),'mode':mode}
helpers=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=r'''
import secrets,re
payload=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');schema='timer_test_'+secrets.token_hex(8)
bridge(root,'queryExecute("CREATE SCHEMA '+schema+'; CREATE TABLE '+schema+'.tb_agrega_eventos(tag text); CREATE TABLE '+schema+'.tb_fornecedores(id_fornecedor integer,tag_fornecedor text,id_tema integer); INSERT INTO '+schema+'.tb_fornecedores VALUES(1,\'valid-timer\',1); CREATE TABLE '+schema+'.tb_temas(id_tema integer); INSERT INTO '+schema+'.tb_temas VALUES(1); CREATE TABLE '+schema+'.tb_log(log_item text,log_item_id text,log_user text,site text)",{},{datasource="runner_dba"});report={created=true};')
work=Path(tempfile.mkdtemp(prefix='timer-route-test-',dir=root/'_codex'));os.chmod(work,0o755)
try:
 token=secrets.token_hex(20)
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runner_dba"; boolean function onRequestStart(string target){if(cgi.remote_addr!="127.0.0.1" || cgi.request_method!="POST" || compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=403);abort;}return true;} void function onError(any exception,string eventname){cfheader(statuscode=500);cfcontent(type="text/plain",reset=true);writeOutput("TEST_ERROR:" & exception.type);} }')
 route=payload['route']
 for table in ['tb_agrega_eventos','tb_fornecedores','tb_temas']:route=route.replace(table,schema+'.'+table)
 for rel,body in {'org/index.cfm':route,'includes/errors/notfound.cfm':payload['notfound'].replace('datasource="runnerhub"','datasource="runner_dba"').replace('INSERT INTO tb_log','INSERT INTO '+schema+'.tb_log'),'errors/404.html':payload['page']}.items():
  f=work/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(body)
 checks=[]
 for tag in [None,'','   ','missing-timer','valid-timer']:
  url='https://business.roadrunners.run/_codex/'+work.name+'/org/index.cfm'
  if tag is not None:
   import urllib.parse
   url+='?tag='+urllib.parse.quote(tag)
  p=subprocess.run(['curl','-sS','--max-time','20','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'-w','\n%{http_code}',url],capture_output=True,text=True,check=True)
  body,status=p.stdout.rsplit('\n',1);expected=200 if tag=='valid-timer' else (500 if payload['mode']=='before' else 404)
  assert int(status)==expected,(tag,status,body[:150])
  if expected==200:assert 'VALID:1' in body
  if expected==404:assert '<html' in body and 'VALID:' not in body
  checks.append({'tag':tag,'status':int(status)})
 print(json.dumps({'mode':payload['mode'],'passed':True,'checks':checks}))
finally:
 shutil.rmtree(work)
 bridge(root,'queryExecute("DROP SCHEMA '+schema+' CASCADE",{},{datasource="runner_dba"});report={removed=true};')
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(helpers+remote)],input=json.dumps(payload),text=True,capture_output=True,timeout=170)
print(p.stdout);print(p.stderr[-2000:]);(stage/('test-org-'+mode+'.json')).write_text(p.stdout);sys.exit(p.returncode)
