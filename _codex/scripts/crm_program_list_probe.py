"""Read-only Pagar.me order-list contract probe; emits aggregate shape only."""
from pathlib import Path
import json
import secrets
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / '.superpowers/sdd/2026-09-25-crm-todo-santo-dia-continuo'
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']
nonce = secrets.token_hex(32)
name = '__crm_program_list_' + secrets.token_hex(12) + '.cfm'
source = '''<cfsetting showdebugoutput="false" requesttimeout="60"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
</cfscript><cfinclude template="config/pagarme.local.cfm"><cfscript>
try{
 if(!isStruct(pagarMeLocalConfig)||!pagarMeLocalConfig.enabled||pagarMeLocalConfig.mode!='production'||!len(trim(pagarMeLocalConfig.secretKey)))throw(message='source_unavailable');
 result={};seen=[];
 for(page in [1,2]){
  response={};
  cfhttp(method='get',url='https://api.pagar.me/core/v5/orders?created_since=2026-09-01&created_until=2026-09-24&page=' & page & '&size=10',result='response',timeout=15,throwOnError=false,redirect=false){
   cfhttpparam(type='header',name='Authorization',value='Basic ' & toBase64(pagarMeLocalConfig.secretKey & ':'));
   cfhttpparam(type='header',name='Accept',value='application/json');
  }
  status=val(listFirst(response.statusCode,' '));
  if(status!=200||!isJSON(response.fileContent))throw(message='provider_list_unavailable');
  data=deserializeJSON(response.fileContent);
  if(!isStruct(data)||!structKeyExists(data,'data')||!isArray(data.data))throw(message='provider_list_shape');
  ids=[];inWindow=0;hasItems=0;supported=0;paid=0;canceled=0;other=0;
  for(order in data.data){
   if(!isStruct(order)||!structKeyExists(order,'id')||!reFind('^or_[A-Za-z0-9]{8,80}$',order.id & ''))throw(message='provider_list_id');
   arrayAppend(ids,order.id);
   if(structKeyExists(order,'created_at')&&left(order.created_at & '',10)>='2026-09-01'&&left(order.created_at & '',10)<='2026-09-24')inWindow++;
   if(structKeyExists(order,'items')&&isArray(order.items))hasItems++;
   if(structKeyExists(order,'items')&&isArray(order.items)&&arrayLen(order.items)==1&&structKeyExists(order.items[1],'code')&&listFind('todosantodia,todosantodiavip,todosantodiaupg',order.items[1].code & ''))supported++;
   if(structKeyExists(order,'status')&&order.status=='paid')paid++;else if(structKeyExists(order,'status')&&order.status=='canceled')canceled++;else other++;
  }
  if(page==2){overlap=0;for(orderId in ids)if(arrayFind(seen,orderId))overlap++;}
  else seen=ids;
  result['page' & page]={status=status,count=arrayLen(ids),in_window=inWindow,items_array=hasItems,supported=supported,paid=paid,canceled=canceled,other=other,paging_present=structKeyExists(data,'paging')&&isStruct(data.paging),paging_total=structKeyExists(data,'paging')&&isStruct(data.paging)&&structKeyExists(data.paging,'total')?data.paging.total:-1};
 }
 result.overlap=overlap;
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(result));
}catch(any e){cfheader(statuscode=503);cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.message}));}
</cfscript>'''.replace('NONCE', nonce)
remote = f'''from pathlib import Path
import json,os,subprocess
p=Path('/var/www/business.roadrunners.run')/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--silent','--show-error','--max-time','60','--resolve','business.roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://business.roadrunners.run/'+{name!r}],capture_output=True,text=True,timeout=65)
 assert r.returncode==0,r.stderr
 print(json.dumps(json.loads(r.stdout)))
finally:p.unlink(missing_ok=True)
'''
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], capture_output=True,
                        text=True, timeout=75)
if result.returncode:
    raise SystemExit(result.stderr[-1000:])
def lower(value):
    if isinstance(value, dict):
        return {str(key).lower(): lower(item) for key, item in value.items()}
    if isinstance(value, list):
        return [lower(item) for item in value]
    return value
data = lower(json.loads(result.stdout))
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / 'provider-list-shape.json').write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps(data))
if 'error' in data or data.get('page1', {}).get('status') != 200:
    raise SystemExit(1)
