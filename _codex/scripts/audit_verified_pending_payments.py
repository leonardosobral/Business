"""Read-only provider scan. No captures, refunds, badge changes, or credentials in output."""
from pathlib import Path
import ast,importlib.util,json,os,shlex,subprocess,sys,signal
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'_codex/analyses/verified-pending-payments-20261124';OUT.mkdir(parents=True,exist_ok=True)
spec=importlib.util.spec_from_file_location('operator',ROOT.parent/'RoadRunners/_codex/scripts/verified_dev_operator.py');op=importlib.util.module_from_spec(spec);spec.loader.exec_module(op);op.REMOTE=op.REMOTE.replace('dev.roadrunners.run','business.roadrunners.run')
body='''report={};transaction isolation="repeatable_read" {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});queryExecute("SET LOCAL statement_timeout=20000",{},{datasource="runner_dba"});s=new services.VerifiedAdmin();a=s.overview({status="unclassified",evidence="vip_unconfirmed"});b=s.overview({status="unclassified",evidence="vip_unconfirmed",page=2});report.profiles=a.rows;for(r in b.rows)arrayAppend(report.profiles,r);report.totals=a.totals;ids=[];for(r in report.profiles)arrayAppend(ids,r.profile_id);report.registrations=queryExecute("SELECT DISTINCT pu.id_pagina AS profile_id,d.produto,d.status FROM tb_paginas_usuarios pu JOIN desafios d ON d.id_usuario=pu.id_usuario WHERE pu.id_usuario>0 AND pu.id_pagina IN (:ids)",{ids={value=arrayToList(ids),cfsqltype="cf_sql_integer",list=true}},{datasource="runner_dba",returntype="array"});report.identities=queryExecute("SELECT DISTINCT pu.id_pagina AS profile_id,u.id AS user_id,trim(u.email) AS email,
coalesce((SELECT json_agg(DISTINCT ref) FROM (SELECT trim(num_pedido) ref FROM desafios WHERE id_usuario=u.id UNION SELECT trim(num_pedido) ref FROM desafio_cna WHERE id_usuario=u.id) d WHERE coalesce(ref,'')<>''),'[]')::text AS refs,
coalesce((SELECT json_agg(DISTINCT t.json_transacao->'data'->>'id') FROM tb_transacoes t WHERE t.id_usuario=u.id AND t.origem_transacao='pagarme' AND t.json_transacao->'data'->>'id' ~ '^or_[A-Za-z0-9]+$'),'[]')::text AS order_ids
FROM tb_paginas_usuarios pu JOIN tb_usuarios u ON u.id=pu.id_usuario WHERE u.id>0 AND pu.id_pagina IN (:ids)",{ids={value=arrayToList(ids),cfsqltype="cf_sql_integer",list=true}},{datasource="runner_dba",returntype="array"});report.badge_orders=queryExecute("SELECT provider_order_id,profile_id,product_code,state,amount_cents,paid_at::text,ends_at::text FROM rr_verified.challenge_orders",{},{datasource="runner_dba",returntype="array"});report.audit_columns=queryExecute("SELECT column_name,data_type,is_nullable,column_default FROM information_schema.columns WHERE table_schema='crm_interno' AND table_name='audit' ORDER BY ordinal_position",{},{datasource="runner_dba",returntype="array"});transaction action="rollback";}'''
if '--reuse-cohort' in sys.argv:data=json.loads((OUT/'cohort-private.json').read_text())
else:
 data={k.lower():v for k,v in op.run(body).items()};assert len(data['profiles'])==57 and len({p['profile_id'] for p in data['profiles']})==57
 (OUT/'cohort-private.json').write_text(json.dumps(data,ensure_ascii=False,indent=2));os.chmod(OUT/'cohort-private.json',0o600)
# Reuse only the established GET transport; don't execute the previous audit module.
module=ast.parse((ROOT/'_codex/scripts/audit_verified_vip_api.py').read_text());old=next(ast.literal_eval(n.value) for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets));transport=old[:old.index('def sanitize(')]
REMOTE=transport+(ROOT/'_codex/scripts/verified_pending_provider_scan.pyfrag').read_text()
identities=data['identities']
if '--retry' in sys.argv:
 previous=json.loads((OUT/'api-scan.json').read_text());retry={(r['profile_id'],r['user_id']) for r in previous['results'] if r['errors']};identities=[i for i in identities if (i['profile_id'],i['user_id']) in retry]
else:previous=None
proc=subprocess.Popen(op.SSH+['python3 -c '+shlex.quote(REMOTE)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
def stop(signum,frame):raise KeyboardInterrupt()
for sig in [signal.SIGTERM,signal.SIGINT]:signal.signal(sig,stop)
try:
 proc.stdin.write(json.dumps(identities));proc.stdin.close()
 for line in proc.stdout:
  result=json.loads(line)
  if 'results' not in result:print(json.dumps(result),flush=True);continue
  if previous:
   merged={(r['profile_id'],r['user_id']):r for r in previous['results']};merged.update({(r['profile_id'],r['user_id']):r for r in result['results']});result['results']=list(merged.values())
  path=OUT/'api-scan.json';path.write_text(json.dumps(result,ensure_ascii=False,indent=2));os.chmod(path,0o600)
  print(json.dumps({'file':str(path),'identities':len(result['results']),'orders':sum(len(r['orders']) for r in result['results']),'errors':sum(bool(r['errors']) for r in result['results'])}),flush=True)
 if proc.wait(timeout=30):raise RuntimeError('Provider audit process failed: '+proc.stderr.read()[-200:])
finally:
 if proc.poll() is None:proc.terminate();proc.wait(timeout=30)
 proc.stdout.close();proc.stderr.close()
 assert proc.poll() is not None
