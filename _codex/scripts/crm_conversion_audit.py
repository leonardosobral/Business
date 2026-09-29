"""Read aggregate metadata for the candidate order producer; emit no personal rows."""
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
name = '__crm_conversion_audit_' + secrets.token_hex(12) + '.cfm'
source = '''<cfsetting showdebugoutput="false" requesttimeout="90"><cfscript>
req=getHttpRequestData(false);
if(!listFind('127.0.0.1,::1',CGI.REMOTE_ADDR)||!structKeyExists(req.headers,'X-CRM-Probe')||req.headers['X-CRM-Probe']!='NONCE'){cfheader(statuscode=404);abort;}
function q(required string sql){return queryExecute(sql,{}, {datasource='runner_dba',timeout=75});}
try{
 cols=q("SELECT table_name,column_name,data_type FROM information_schema.columns WHERE table_schema='crm' AND table_name IN ('tb_crm_pedidos','tb_crm_participacoes','tb_crm_pessoas') ORDER BY table_name,ordinal_position");
 orderStats=q('SELECT count(*) AS total,count(*) FILTER(WHERE data_pagamento IS NOT NULL) AS dated,count(*) FILTER(WHERE valor_total>0) AS valued,count(*) FILTER(WHERE cod_evento_externo IS NULL) AS no_external_event FROM crm.tb_crm_pedidos');
 personStats=q("SELECT count(*) AS total,count(*) FILTER(WHERE id_usuario IS NOT NULL) AS linked,count(*) FILTER(WHERE match_usuario_status='confirmado') AS confirmed_match FROM crm.tb_crm_pessoas");
 multi=q('SELECT count(*) AS orders_with_multiple_participants FROM (SELECT id_crm_pedido FROM crm.tb_crm_participacoes WHERE id_crm_pedido IS NOT NULL GROUP BY id_crm_pedido HAVING count(*)>1) d');
 statuses=q("SELECT coalesce(status_pedido,'<null>') AS status,count(*) AS total FROM crm.tb_crm_pedidos GROUP BY 1 ORDER BY total DESC LIMIT 30");
 report={columns=[] ,orders={total=orderStats.total,dated=orderStats.dated,valued=orderStats.valued,no_external_event=orderStats.no_external_event},persons={total=personStats.total,linked=personStats.linked,confirmed_match=personStats.confirmed_match},multi_participant_orders=multi.orders_with_multiple_participants,statuses=[]};
 for(row in cols)arrayAppend(report.columns,{table=row.table_name,column=row.column_name,type=row.data_type});
 for(row in statuses)arrayAppend(report.statuses,{status=row.status,total=row.total});
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON(report));
}catch(any e){cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({error=e.type,message=e.message}));}
</cfscript>'''.replace('NONCE', nonce)
remote = f'''from pathlib import Path
import json,os,subprocess
p=Path('/var/www/roadrunners.com.br')/{name!r};assert not p.exists()
try:
 p.write_text({source!r});os.chmod(p,0o644)
 r=subprocess.run(['curl','--silent','--show-error','--max-time','90','--resolve','roadrunners.run:443:127.0.0.1','-H',{'X-CRM-Probe: '+nonce!r},'https://roadrunners.run/'+{name!r}],capture_output=True,text=True,timeout=95)
 assert r.returncode==0,r.stderr
 print(json.dumps(json.loads(r.stdout)))
finally:p.unlink(missing_ok=True)
'''
result = subprocess.run(SSH + ['python3 -c ' + shlex.quote(remote)], capture_output=True,
                        text=True, timeout=105)
if result.returncode:
    raise SystemExit(result.stderr[-2000:])
data = json.loads(result.stdout)
if 'error' in data:
    raise SystemExit(data)
LEDGER.mkdir(parents=True, exist_ok=True)
(LEDGER / 'conversion-audit.json').write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps({key: value for key, value in data.items() if key != 'columns'}))
