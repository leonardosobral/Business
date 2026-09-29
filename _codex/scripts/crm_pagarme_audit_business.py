"""Read only aggregate Pagar.me metadata through a temporary Business endpoint."""
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
name = '__crm_pagarme_audit_' + secrets.token_hex(12) + '.cfm'
source = '''<cfsetting showdebugoutput="false" requesttimeout="60"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function q(required string sql){return queryExecute(sql,{}, {datasource='runner_dba',timeout=45});}
try{
 transaction {
  q('SET TRANSACTION READ ONLY');
  stats=q("SELECT count(*) AS total,count(DISTINCT codigo_transacao) AS distinct_codes,count(*) FILTER(WHERE id_usuario>0) AS linked_rows,count(*) FILTER(WHERE jsonb_exists(json_transacao,'id')) AS envelope_id_rows,count(DISTINCT json_transacao->>'id') AS distinct_envelope_ids,count(*) FILTER(WHERE jsonb_exists(json_transacao->'data','currency')) AS data_currency_rows,count(*) FILTER(WHERE jsonb_exists(json_transacao->'data'->'order','currency')) AS order_currency_rows,count(*) FILTER(WHERE jsonb_exists(json_transacao->'data'->'metadata','user_id')) AS data_user_id_rows,count(*) FILTER(WHERE jsonb_exists(json_transacao->'data'->'order'->'metadata','user_id')) AS order_user_id_rows FROM public.tb_transacoes WHERE origem_transacao='pagarme'");
  statuses=q("SELECT status_atual,count(*) AS total,count(*) FILTER(WHERE id_usuario>0) AS linked,count(*) FILTER(WHERE jsonb_exists(json_transacao->'data','currency') OR jsonb_exists(json_transacao->'data'->'order','currency')) AS currency_rows,count(*) FILTER(WHERE json_transacao::text LIKE '%id_pagina%') AS page_marker_rows FROM public.tb_transacoes WHERE origem_transacao='pagarme' GROUP BY status_atual ORDER BY total DESC LIMIT 30");
  revisions=q("SELECT count(*) AS codes_with_multiple_statuses FROM (SELECT codigo_transacao FROM public.tb_transacoes WHERE origem_transacao='pagarme' GROUP BY codigo_transacao HAVING count(DISTINCT status_atual)>1) x");
  correlations=q("WITH per_code AS (SELECT codigo_transacao,bool_or(status_atual='order.paid') AS paid,bool_or(status_atual='order.created' AND json_transacao::text LIKE '%id_pagina%') AS page_created,bool_or(status_atual='charge.refunded') AS refunded,bool_or(status_atual='charge.chargedback') AS charged_back FROM public.tb_transacoes WHERE origem_transacao='pagarme' GROUP BY codigo_transacao) SELECT count(*) FILTER(WHERE paid) AS paid_codes,count(*) FILTER(WHERE paid AND page_created) AS paid_with_page_created,count(*) FILTER(WHERE paid AND refunded) AS paid_with_refund_code,count(*) FILTER(WHERE paid AND charged_back) AS paid_with_chargeback_code FROM per_code");
 }
 report={stats={total=stats.total,distinct_codes=stats.distinct_codes,linked_rows=stats.linked_rows,envelope_id_rows=stats.envelope_id_rows,distinct_envelope_ids=stats.distinct_envelope_ids,data_currency_rows=stats.data_currency_rows,order_currency_rows=stats.order_currency_rows,data_user_id_rows=stats.data_user_id_rows,order_user_id_rows=stats.order_user_id_rows},codes_with_multiple_statuses=revisions.codes_with_multiple_statuses,correlations={paid_codes=correlations.paid_codes,paid_with_page_created=correlations.paid_with_page_created,paid_with_refund_code=correlations.paid_with_refund_code,paid_with_chargeback_code=correlations.paid_with_chargeback_code},statuses=[]};
 for(row in statuses)arrayAppend(report.statuses,{status=row.status_atual,total=row.total,linked=row.linked,currency_rows=row.currency_rows,page_marker_rows=row.page_marker_rows});
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfheader(statuscode=500);cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message}));}
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
if not isinstance(data, dict) or 'stats' not in data or 'statuses' not in data:
    raise SystemExit(data)
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / 'pagarme-audit-business.json').write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps(data))
