"""Read aggregate Pagar.me event field shapes via an ephemeral Business-only probe."""
from pathlib import Path
import json
import secrets
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / '.superpowers/sdd/2026-09-24-crm-interno-evolucao'
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
       '-o', 'StrictHostKeyChecking=yes', '-i', '/Users/leonardosobral/.ssh/webs',
       'root@ssh.runnerhub.run']
nonce = secrets.token_hex(32)
name = '__crm_pagarme_shape_' + secrets.token_hex(12) + '.cfm'
source = '''<cfsetting showdebugoutput="false" requesttimeout="60"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function q(required string sql){return queryExecute(sql,{}, {datasource='runner_dba',timeout=45});}
try{
 transaction {
  q('SET TRANSACTION READ ONLY');
  totals=q("WITH src AS (SELECT status_atual,json_transacao->'data' AS data FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual IN ('order.paid','charge.refunded','charge.chargedback','chargeback.received')) SELECT status_atual,count(*) AS total,count(*) FILTER(WHERE jsonb_typeof(data->'charges')='array') AS charges_array,count(*) FILTER(WHERE jsonb_typeof(data->'order'->'charges')='array') AS order_charges_array,count(*) FILTER(WHERE jsonb_typeof(data->'amount')='number') AS amount_number,count(*) FILTER(WHERE jsonb_typeof(data->'paid_amount')='number') AS paid_amount_number,count(*) FILTER(WHERE jsonb_typeof(data->'refunded_amount')='number') AS refunded_amount_number,count(*) FILTER(WHERE jsonb_typeof(data->'last_transaction'->'paid_amount')='number') AS transaction_paid_number,count(*) FILTER(WHERE jsonb_typeof(data->'last_transaction'->'refunded_amount')='number') AS transaction_refunded_number,count(*) FILTER(WHERE jsonb_typeof(data->'order'->'amount')='number') AS order_amount_number,count(*) FILTER(WHERE jsonb_typeof(data->'currency')='string') AS currency_string,count(*) FILTER(WHERE jsonb_typeof(data->'order'->'currency')='string') AS order_currency_string,count(*) FILTER(WHERE jsonb_typeof(data->'updated_at')='string') AS updated_at_string FROM src GROUP BY status_atual ORDER BY status_atual");
  keys=q("WITH src AS (SELECT status_atual,json_transacao->'data' AS data FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual IN ('order.paid','charge.refunded','charge.chargedback','chargeback.received')), paths AS (SELECT status_atual,'data' AS path,jsonb_object_keys(CASE WHEN jsonb_typeof(data)='object' THEN data ELSE '{}'::jsonb END) AS field FROM src UNION ALL SELECT status_atual,'last_transaction',jsonb_object_keys(CASE WHEN jsonb_typeof(data->'last_transaction')='object' THEN data->'last_transaction' ELSE '{}'::jsonb END) FROM src UNION ALL SELECT status_atual,'order',jsonb_object_keys(CASE WHEN jsonb_typeof(data->'order')='object' THEN data->'order' ELSE '{}'::jsonb END) FROM src) SELECT status_atual,path,field,count(*) AS rows_with_field FROM paths GROUP BY status_atual,path,field ORDER BY status_atual,path,field LIMIT 300");
  refundStats=q("WITH src AS (SELECT status_atual,json_transacao->'data' AS data FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual IN ('charge.refunded','charge.chargedback')), amounts AS (SELECT status_atual,CASE WHEN (data->>'paid_amount') ~ '^[0-9]+$' THEN (data->>'paid_amount')::bigint END AS paid,CASE WHEN (data->>'canceled_amount') ~ '^[0-9]+$' THEN (data->>'canceled_amount')::bigint END AS canceled,data->>'id' AS charge_id,data->'order'->>'id' AS order_id FROM src) SELECT status_atual,count(*) AS total,count(*) FILTER(WHERE paid IS NOT NULL) AS paid_numeric,count(*) FILTER(WHERE paid>0) AS paid_positive,count(*) FILTER(WHERE canceled IS NOT NULL) AS canceled_numeric,count(*) FILTER(WHERE canceled>0) AS canceled_positive,count(*) FILTER(WHERE canceled>paid) AS canceled_over_paid,count(*) FILTER(WHERE canceled=paid AND paid>0) AS fully_canceled,count(*) FILTER(WHERE canceled>0 AND canceled<paid) AS partially_canceled,count(DISTINCT charge_id) AS distinct_charges,count(DISTINCT order_id) AS distinct_orders FROM amounts GROUP BY status_atual ORDER BY status_atual");
  matches=q("WITH refunds AS (SELECT json_transacao->'data'->>'id' AS charge_id,json_transacao->'data'->'order'->>'id' AS order_id FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual='charge.refunded'), paid AS (SELECT json_transacao->'data'->>'id' AS order_id,c->>'id' AS charge_id FROM public.tb_transacoes CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(json_transacao->'data'->'charges')='array' THEN json_transacao->'data'->'charges' ELSE '[]'::jsonb END) c WHERE origem_transacao='pagarme' AND status_atual='order.paid') SELECT (SELECT count(*) FROM paid) AS paid_charge_rows,count(*) AS refund_rows,count(*) FILTER(WHERE EXISTS(SELECT 1 FROM paid p WHERE p.charge_id=r.charge_id AND p.order_id=r.order_id)) AS matched_charge_and_order FROM refunds r");
  accountStats=q("SELECT status_atual,count(*) AS total,count(*) FILTER(WHERE jsonb_typeof(json_transacao->'account'->'id')='string') AS account_id_rows,count(DISTINCT json_transacao->'account'->>'id') AS distinct_accounts FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual IN ('order.paid','charge.refunded','charge.chargedback','chargeback.received') GROUP BY status_atual ORDER BY status_atual");
  reversals=q("WITH paid AS (SELECT DISTINCT json_transacao->'data'->>'id' AS order_id,c->>'id' AS charge_id,json_transacao->'account'->>'id' AS account_id,json_transacao->'data'->>'currency' AS currency FROM public.tb_transacoes CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(json_transacao->'data'->'charges')='array' THEN json_transacao->'data'->'charges' ELSE '[]'::jsonb END) c WHERE origem_transacao='pagarme' AND status_atual='order.paid'), reverse AS (SELECT status_atual,json_transacao->'data'->>'id' AS charge_id,json_transacao->'data'->'order'->>'id' AS order_id,json_transacao->'account'->>'id' AS account_id,json_transacao->'data'->>'currency' AS currency FROM public.tb_transacoes WHERE origem_transacao='pagarme' AND status_atual IN ('charge.refunded','charge.chargedback','chargeback.received')) SELECT r.status_atual,count(*) AS total,count(*) FILTER(WHERE p.charge_id IS NOT NULL) AS matched,count(*) FILTER(WHERE p.charge_id IS NOT NULL AND p.account_id=r.account_id) AS same_account,count(*) FILTER(WHERE p.charge_id IS NOT NULL AND p.currency=r.currency) AS same_currency FROM reverse r LEFT JOIN paid p ON p.charge_id=r.charge_id AND p.order_id=r.order_id GROUP BY r.status_atual ORDER BY r.status_atual");
 }
 report={totals=[],fields=[],refund_stats=[],account_stats=[],reversals=[],matches={paid_charge_rows=matches.paid_charge_rows,refund_rows=matches.refund_rows,matched_charge_and_order=matches.matched_charge_and_order}};
 for(item in totals)arrayAppend(report.totals,{event=item.status_atual,total=item.total,charges_array=item.charges_array,order_charges_array=item.order_charges_array,amount_number=item.amount_number,paid_amount_number=item.paid_amount_number,refunded_amount_number=item.refunded_amount_number,transaction_paid_number=item.transaction_paid_number,transaction_refunded_number=item.transaction_refunded_number,order_amount_number=item.order_amount_number,currency_string=item.currency_string,order_currency_string=item.order_currency_string,updated_at_string=item.updated_at_string});
 for(item in keys)arrayAppend(report.fields,{event=item.status_atual,path=item.path,field=item.field,rows=item.rows_with_field});
 for(item in refundStats)arrayAppend(report.refund_stats,{event=item.status_atual,total=item.total,paid_numeric=item.paid_numeric,paid_positive=item.paid_positive,canceled_numeric=item.canceled_numeric,canceled_positive=item.canceled_positive,canceled_over_paid=item.canceled_over_paid,fully_canceled=item.fully_canceled,partially_canceled=item.partially_canceled,distinct_charges=item.distinct_charges,distinct_orders=item.distinct_orders});
 for(item in accountStats)arrayAppend(report.account_stats,{event=item.status_atual,total=item.total,account_id_rows=item.account_id_rows,distinct_accounts=item.distinct_accounts});
 for(item in reversals)arrayAppend(report.reversals,{event=item.status_atual,total=item.total,matched=item.matched,same_account=item.same_account,same_currency=item.same_currency});
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfheader(statuscode=500);cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type}));}
</cfscript>'''.replace('NONCE', nonce)
remote = f'''from pathlib import Path
import json,os,subprocess
p=Path('/var/www/business.roadrunners.run')/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--fail','--silent','--show-error','--max-time','60','--resolve','business.roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://business.roadrunners.run/'+{name!r}],capture_output=True,text=True,timeout=65)
 assert r.returncode==0,r.stderr
 print(json.dumps(json.loads(r.stdout)))
finally:p.unlink(missing_ok=True)
'''
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], capture_output=True,
                        text=True, timeout=75)
if result.returncode:
    raise SystemExit(result.stderr[-1500:])
def lower_keys(value):
    if isinstance(value, dict):
        return {key.lower(): lower_keys(item) for key, item in value.items()}
    if isinstance(value, list):
        return [lower_keys(item) for item in value]
    return value
data = lower_keys(json.loads(result.stdout))
if not isinstance(data, dict) or 'totals' not in data or 'fields' not in data:
    raise SystemExit('invalid_probe_response')
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / 'pagarme-field-shape-business.json').write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps({'totals': data['totals'], 'field_count': len(data['fields']), 'refund_stats': data['refund_stats'], 'matches': data['matches'], 'account_stats': data['account_stats'], 'reversals': data['reversals']}))
