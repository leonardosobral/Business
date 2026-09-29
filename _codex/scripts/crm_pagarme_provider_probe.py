"""Check one existing Pagar.me order and hook by authenticated GET only.

The probe runs inside the Business application, emits booleans/status codes only,
and removes its temporary endpoint even when the provider request fails.
"""

from pathlib import Path
import json
import secrets
import shlex
import subprocess


ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / '.superpowers/sdd/2026-09-24-crm-interno-evolucao'
SSH = [
    'ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
    '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
    'root@ssh.runnerhub.run',
]
nonce = secrets.token_hex(32)
name = '__crm_pagarme_provider_' + secrets.token_hex(12) + '.cfm'
source = '''<cfsetting showdebugoutput="false" requesttimeout="60"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
</cfscript><cfinclude template="config/pagarme.local.cfm"><cfscript>
try{
 if(!isStruct(pagarMeLocalConfig)||!pagarMeLocalConfig.enabled||pagarMeLocalConfig.mode!='production'||!len(trim(pagarMeLocalConfig.secretKey))){throw(type='Probe.Configuration');}
 transaction {
  queryExecute('SET TRANSACTION READ ONLY',{}, {datasource='runner_dba'});
  sample=queryExecute("SELECT json_transacao->'data'->>'id' AS order_id,json_transacao->>'id' AS hook_id,json_transacao->'data'->>'currency' AS currency,json_transacao->'data'->>'amount' AS amount FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual='order.paid' AND json_transacao->'data'->>'id' ~ '^or_[A-Za-z0-9_]+$' AND json_transacao->>'id' ~ '^[A-Za-z0-9_-]+$' ORDER BY json_transacao->>'created_at' DESC LIMIT 1",{}, {datasource='runner_dba',timeout=30});
  recent=queryExecute("WITH paid AS (SELECT DISTINCT ON (json_transacao->'data'->>'id') json_transacao->'data'->>'id' AS order_id,json_transacao->'data'->>'code' AS order_code,json_transacao->'data'->'charges'->0->>'id' AS charge_id,json_transacao->'data'->'charges'->0->>'paid_at' AS webhook_paid_at,json_transacao->'data'->'charges'->0->>'updated_at' AS webhook_charge_updated_at,json_transacao->'data'->>'updated_at' AS webhook_order_updated_at,json_transacao->'data'->>'currency' AS currency,json_transacao->'data'->>'amount' AS amount,json_transacao->>'created_at' AS created_at FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual='order.paid' AND json_transacao->'data'->>'id' ~ '^or_[A-Za-z0-9_]+$' ORDER BY json_transacao->'data'->>'id',json_transacao->>'created_at' DESC) SELECT p.order_id,p.order_code,p.charge_id,p.webhook_paid_at,p.webhook_charge_updated_at,p.webhook_order_updated_at,p.currency,p.amount,EXISTS(SELECT 1 FROM public.tb_transacoes r WHERE r.origem_transacao='pagarme' AND r.status_atual IN ('order.canceled','charge.refunded','charge.chargedback','chargeback.received') AND (r.json_transacao->'data'->>'id'=p.order_id OR r.json_transacao->'data'->'order'->>'id'=p.order_id)) AS stored_reverse FROM paid p ORDER BY p.created_at DESC LIMIT 10",{}, {datasource='runner_dba',timeout=30});
  if(sample.recordCount==1){
   flags=queryExecute("SELECT count(*) FILTER(WHERE status_atual='order.canceled') AS order_canceled,count(*) FILTER(WHERE status_atual='charge.refunded') AS charge_refunded,count(*) FILTER(WHERE status_atual='charge.chargedback') AS charge_chargedback FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND (json_transacao->'data'->>'id'=:orderId OR json_transacao->'data'->'order'->>'id'=:orderId)",{orderId={value=sample.order_id,cfsqltype='cf_sql_varchar'}},{datasource='runner_dba',timeout=30});
  }
 }
 if(sample.recordCount!=1){throw(type='Probe.NoSample');}
 auth='Basic ' & toBase64(pagarMeLocalConfig.secretKey & ':');
 orderUrl='https://api.pagar.me/core/v5/orders/' & sample.order_id;
 cfhttp(method='get',url=orderUrl,result='orderResponse',timeout=15,redirect=false){
  cfhttpparam(type='header',name='Authorization',value=auth);
  cfhttpparam(type='header',name='Accept',value='application/json');
 }
 report={order_http_status=val(listFirst(orderResponse.statusCode,' ')),order_id_matches=false,order_paid=false,order_status='unknown',currency_matches=false,amount_matches=false,charge_count=0,charge_status='unknown',charge_paid_positive=false,charge_canceled_positive=false,charge_canceled_equals_paid=false,stored_order_canceled=flags.order_canceled>0,stored_charge_refunded=flags.charge_refunded>0,stored_chargeback=flags.charge_chargedback>0,hook_http_status=0,hook_id_shape='other',hook_id_matches=false,hook_event_matches=false};
 if(report.order_http_status==200){
  o=deserializeJSON(orderResponse.fileContent);
  report.order_id_matches=structKeyExists(o,'id')&&o.id==sample.order_id;
  report.order_paid=structKeyExists(o,'status')&&o.status=='paid';
  if(structKeyExists(o,'status')&&listFindNoCase('paid,closed,pending,canceled,failed,refunded,processing',o.status)){report.order_status=lCase(o.status);}
  report.currency_matches=structKeyExists(o,'currency')&&o.currency==sample.currency;
  report.amount_matches=structKeyExists(o,'amount')&&toString(o.amount)==sample.amount;
  if(structKeyExists(o,'charges')&&isArray(o.charges)){
   report.charge_count=arrayLen(o.charges);
   if(report.charge_count==1){
    ch=o.charges[1];
    if(structKeyExists(ch,'status')&&listFindNoCase('paid,pending,canceled,failed,refunded,chargedback',ch.status)){report.charge_status=lCase(ch.status);}
    if(structKeyExists(ch,'paid_amount')&&isNumeric(ch.paid_amount)){report.charge_paid_positive=ch.paid_amount>0;}
    if(structKeyExists(ch,'canceled_amount')&&isNumeric(ch.canceled_amount)){report.charge_canceled_positive=ch.canceled_amount>0;report.charge_canceled_equals_paid=report.charge_paid_positive&&ch.canceled_amount==ch.paid_amount;}
   }
  }
 }
 if(left(sample.hook_id,5)=='hook_'){report.hook_id_shape='hook';}
 else if(left(sample.hook_id,4)=='evt_'){report.hook_id_shape='event';}
 hookUrl='https://api.pagar.me/core/v5/hooks/' & sample.hook_id;
 cfhttp(method='get',url=hookUrl,result='hookResponse',timeout=15,redirect=false){
  cfhttpparam(type='header',name='Authorization',value=auth);
  cfhttpparam(type='header',name='Accept',value='application/json');
 }
 report.hook_http_status=val(listFirst(hookResponse.statusCode,' '));
 if(report.hook_http_status==200){
  h=deserializeJSON(hookResponse.fileContent);
  report.hook_id_matches=structKeyExists(h,'id')&&h.id==sample.hook_id;
  report.hook_event_matches=structKeyExists(h,'type')&&h.type=='order.paid';
 }
 report.recent={sampled=recent.recordCount,http_200=0,identity_currency_amount_match=0,order_code_matches=0,charge_id_matches=0,charge_currency_matches=0,charge_paid_matches_order=0,items_one=0,items_code_supported=0,items_amount_match=0,items_quantity_one=0,order_updated_is_date=0,charge_updated_is_date=0,charge_paid_is_date=0,charge_id_shape=0,current_paid=0,current_canceled=0,canceled_without_stored_reverse=0,fully_canceled_charge=0,one_charge=0,order_updated_at=0,charge_paid_at=0,charge_updated_at=0,webhook_paid_at_present=0,webhook_charge_updated_at_present=0,webhook_order_updated_at_present=0,paid_at_matches_webhook=0,paid_at_same_instant=0,paid_at_same_clock_second=0,current_paid_at_z=0,webhook_paid_at_z=0,current_paid_before_webhook=0,paid_at_difference_3h=0,charge_updated_nonregressing=0,order_updated_nonregressing=0,canceled_charge_newer_than_paid_webhook=0,canceled_charge_paid_before_update=0,other_status=0};
 for(item in recent){
  if(len(trim(item.webhook_paid_at & ''))){report.recent.webhook_paid_at_present++;}
  if(right(trim(item.webhook_paid_at & ''),1)=='Z'){report.recent.webhook_paid_at_z++;}
  if(len(trim(item.webhook_charge_updated_at & ''))){report.recent.webhook_charge_updated_at_present++;}
  if(len(trim(item.webhook_order_updated_at & ''))){report.recent.webhook_order_updated_at_present++;}
  cfhttp(method='get',url='https://api.pagar.me/core/v5/orders/' & item.order_id,result='recentResponse',timeout=15,redirect=false){
   cfhttpparam(type='header',name='Authorization',value=auth);
   cfhttpparam(type='header',name='Accept',value='application/json');
  }
  if(val(listFirst(recentResponse.statusCode,' '))!=200){continue;}
  report.recent.http_200++;
  current=deserializeJSON(recentResponse.fileContent);
  if(structKeyExists(current,'items')&&isArray(current.items)&&arrayLen(current.items)==1){
   report.recent.items_one++;
   orderItem=current.items[1];
   if(isStruct(orderItem)){
    if(structKeyExists(orderItem,'code')&&listFind('todosantodia,todosantodiavip,todosantodiaupg',orderItem.code & ''))report.recent.items_code_supported++;
    if(structKeyExists(orderItem,'amount')&&toString(orderItem.amount)==item.amount)report.recent.items_amount_match++;
    if(structKeyExists(orderItem,'quantity')&&toString(orderItem.quantity)=='1')report.recent.items_quantity_one++;
   }
  }
  if(structKeyExists(current,'id')&&current.id==item.order_id&&structKeyExists(current,'currency')&&current.currency==item.currency&&structKeyExists(current,'amount')&&toString(current.amount)==item.amount){report.recent.identity_currency_amount_match++;}
  if(structKeyExists(current,'code')&&current.code==item.order_code){report.recent.order_code_matches++;}
  if(structKeyExists(current,'updated_at')&&len(trim(current.updated_at & ''))){report.recent.order_updated_at++;}
  if(structKeyExists(current,'updated_at')&&isDate(current.updated_at)){report.recent.order_updated_is_date++;}
  if(structKeyExists(current,'updated_at')&&isDate(current.updated_at)&&isDate(item.webhook_order_updated_at)&&dateCompare(current.updated_at,item.webhook_order_updated_at)>=0){report.recent.order_updated_nonregressing++;}
  if(structKeyExists(current,'status')&&current.status=='paid'){report.recent.current_paid++;}
  else if(structKeyExists(current,'status')&&current.status=='canceled'){
   report.recent.current_canceled++;
   if(!item.stored_reverse){report.recent.canceled_without_stored_reverse++;}
  }
  else{report.recent.other_status++;}
  if(structKeyExists(current,'charges')&&isArray(current.charges)&&arrayLen(current.charges)==1){
   report.recent.one_charge++;
   c=current.charges[1];
   if(structKeyExists(c,'id')&&c.id==item.charge_id){report.recent.charge_id_matches++;}
   if(structKeyExists(c,'id')&&reFind('^ch_[A-Za-z0-9]{8,80}$',c.id & '')){report.recent.charge_id_shape++;}
   if(structKeyExists(c,'currency')&&c.currency==item.currency){report.recent.charge_currency_matches++;}
   if(structKeyExists(c,'paid_amount')&&isNumeric(c.paid_amount)&&toString(c.paid_amount)==item.amount){report.recent.charge_paid_matches_order++;}
   if(structKeyExists(c,'paid_at')&&len(trim(c.paid_at & ''))){report.recent.charge_paid_at++;}
   if(structKeyExists(c,'paid_at')&&isDate(c.paid_at)){report.recent.charge_paid_is_date++;}
   if(structKeyExists(c,'paid_at')&&right(trim(c.paid_at & ''),1)=='Z'){report.recent.current_paid_at_z++;}
   if(structKeyExists(c,'paid_at')&&c.paid_at==item.webhook_paid_at){report.recent.paid_at_matches_webhook++;}
   if(structKeyExists(c,'paid_at')&&left(c.paid_at & '',19)==left(item.webhook_paid_at & '',19)){report.recent.paid_at_same_clock_second++;}
   if(structKeyExists(c,'paid_at')&&isDate(c.paid_at)&&isDate(item.webhook_paid_at)&&dateCompare(c.paid_at,item.webhook_paid_at)==0){report.recent.paid_at_same_instant++;}
   if(structKeyExists(c,'paid_at')&&isDate(c.paid_at)&&isDate(item.webhook_paid_at)&&dateCompare(c.paid_at,item.webhook_paid_at)==-1){report.recent.current_paid_before_webhook++;}
   if(structKeyExists(c,'paid_at')&&isDate(c.paid_at)&&isDate(item.webhook_paid_at)&&abs(dateDiff('n',c.paid_at,item.webhook_paid_at))==180){report.recent.paid_at_difference_3h++;}
   if(structKeyExists(c,'updated_at')&&len(trim(c.updated_at & ''))){report.recent.charge_updated_at++;}
   if(structKeyExists(c,'updated_at')&&isDate(c.updated_at)){report.recent.charge_updated_is_date++;}
   if(structKeyExists(c,'updated_at')&&isDate(c.updated_at)&&isDate(item.webhook_charge_updated_at)&&dateCompare(c.updated_at,item.webhook_charge_updated_at)>=0){report.recent.charge_updated_nonregressing++;}
   if(structKeyExists(current,'status')&&current.status=='canceled'&&structKeyExists(c,'updated_at')&&isDate(c.updated_at)&&isDate(item.webhook_charge_updated_at)&&dateCompare(c.updated_at,item.webhook_charge_updated_at)==1){report.recent.canceled_charge_newer_than_paid_webhook++;}
   if(structKeyExists(current,'status')&&current.status=='canceled'&&structKeyExists(c,'paid_at')&&structKeyExists(c,'updated_at')&&isDate(c.paid_at)&&isDate(c.updated_at)&&dateCompare(c.paid_at,c.updated_at)==-1){report.recent.canceled_charge_paid_before_update++;}
   if(structKeyExists(c,'paid_amount')&&isNumeric(c.paid_amount)&&c.paid_amount>0&&structKeyExists(c,'canceled_amount')&&isNumeric(c.canceled_amount)&&c.canceled_amount==c.paid_amount){report.recent.fully_canceled_charge++;}
  }
 }
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfheader(statuscode=500);cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type}));}
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
def lower_keys(value):
    if isinstance(value, dict):
        return {str(key).lower(): lower_keys(item) for key, item in value.items()}
    if isinstance(value, list):
        return [lower_keys(item) for item in value]
    return value


data = lower_keys(json.loads(result.stdout))
if not isinstance(data, dict):
    raise SystemExit('invalid_probe_response')
if not ({'order_http_status', 'error'} & set(data)):
    raise SystemExit('invalid_probe_response')
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / 'pagarme-provider-get-business.json').write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps(data))
