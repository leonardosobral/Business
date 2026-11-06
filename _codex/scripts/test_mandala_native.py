"""Private localhost-only CF checks. Transactional delivery writes are rolled back."""
import ast,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2];mode=sys.argv[1] if len(sys.argv)>1 else 'source'
tree=ast.parse((ROOT/'_codex/scripts/test_user_acquisition_native.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
remote=remote.replace('user_acquisition_','cbg_mandala_').replace('business-user-acquisition-test-','business-cbg-mandala-test-').replace('USER_ACQUISITION_','CBG_MANDALA_')
remote=remote.replace("body=body.replace('new services.UserAcquisitionMetrics','new _codex.'+name+'.services.UserAcquisitionMetrics')", "body=body.replace('desafios.includes.MandalaDelivery','_codex.'+name+'.desafios.includes.MandalaDelivery').replace('__MANDALA__','_codex.'+name+'.desafios.includes.MandalaDelivery')")
if mode=='guards':
 original=next(line for line in remote.splitlines() if line.startswith(" run=subprocess.run(['curl'"))
 replacement=''' from types import SimpleNamespace
 checks=[]
 cases=[('POST','0','id_usuario=1',403),('GET','1','id_usuario=1&challenge_medal_csrf=fixture-token&confirmar_mandala=1',200),('POST','1','id_usuario=1',200),('POST','1','id_usuario=1&challenge_medal_csrf=wrong&confirmar_mandala=1',200),('POST','1','id_usuario=1&challenge_medal_csrf=fixture-token&mandala_numero=123',200),('POST','1','id_usuario=1&challenge_medal_csrf=fixture-token&confirmar_mandala=1&mandala_numero=0',200)]
 for method,admin,body,expected in cases:
  url='https://business.roadrunners.run/_codex/'+name+'/run.cfm?admin='+admin
  if method=='GET':url+='&'+body
  command=['curl','-sS','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','--request',method,'--header','X-Acquisition-Test: '+nonce,'--write-out','\\n%{http_code}',url]
  if method=='POST':command+=['--data',body]
  response=subprocess.run(command,capture_output=True,timeout=35);content,_,status=response.stdout.rpartition(b'\\n');valid=not response.returncode and status==str(expected).encode()
  if expected==200:valid=valid and b'CBG_MANDALA_GUARDS_PASSED' in content
  checks.append({'method':method,'admin':admin,'status':status.decode(),'ok':valid})
 raw=('CBG_MANDALA_GUARDS_PASSED ' if all(c['ok'] for c in checks) else 'TEST_FAILED ')+json.dumps(checks)
 run=SimpleNamespace(returncode=0,stdout=raw.encode())'''
 remote=remote.replace(original,replacement,1)
payload={'mode':mode}
for rel in ['desafios/includes/MandalaDelivery.cfc','desafios/includes/backend.cfm','desafios/includes/brasil_gigante_mandala_action.cfm','desafios/includes/brasil_gigante_table.cfm','desafios/includes/catarinense_contact_modal.cfm']:
 if (ROOT/rel).exists():payload[rel]=(ROOT/rel).read_text()
backend=(ROOT/'desafios/includes/backend.cfm').read_text();start=backend.index('SELECT max(history.data_obs) FILTER');end=backend.index(') mandala ON true',start)
payload['tests/lookup.cfm']='<cfquery name="lookup" datasource="runner_dba">SELECT mandala.* FROM tb_usuarios usr LEFT JOIN LATERAL ('+backend[start:end]+') mandala ON true WHERE usr.id=<cfqueryparam value="#users.id_usuario[1]#" cfsqltype="cf_sql_integer"/></cfquery>'
for p in (ROOT/'_codex/tests/cbg-mandala').glob('*.cfm'):payload['tests/'+p.name]=p.read_text()
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=65)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-1000:]}
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
