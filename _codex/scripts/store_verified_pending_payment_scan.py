"""Append the GET-only scan to the admin audit. Never updates payment ledgers or badges."""
from pathlib import Path
import json,base64,hashlib,importlib.util
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'_codex/analyses/verified-pending-payments-20261124';data=(OUT/'display-snapshots.json').read_bytes();payload=json.loads(data);assert len(payload['profiles'])==57 and all(p['complete'] for p in payload['profiles'])
spec=importlib.util.spec_from_file_location('op',ROOT.parent/'RoadRunners/_codex/scripts/verified_dev_operator.py');op=importlib.util.module_from_spec(spec);spec.loader.exec_module(op)
b64=base64.b64encode(data).decode();encoded='arrayToList(['+','.join('"'+b64[i:i+18000]+'"' for i in range(0,len(b64),18000))+'],"")'
body='''function q(sql,params={}){return queryExecute(sql,params,{datasource="runner_dba"});}function ensure(ok,message){if(!ok)throw(message=message);}
function protectedState(){return q("SELECT md5(jsonb_build_object(
'grants',(SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM rr_verified.grants x),
'dev_grants',(SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM rr_verified_dev.grants x),
'orders',(SELECT jsonb_agg(to_jsonb(x) ORDER BY id) FROM rr_verified.orders x),
'sources',(SELECT jsonb_agg(to_jsonb(x) ORDER BY provider_order_id) FROM rr_verified.challenge_orders x),
'reclassifications',(SELECT jsonb_agg(to_jsonb(x) ORDER BY profile_id) FROM rr_verified.legacy_reclassifications x),
'classification',(SELECT jsonb_agg(to_jsonb(x) ORDER BY revision) FROM rr_verified.admin_classifications x),
'flags',(SELECT jsonb_agg(jsonb_build_array(id_pagina,verificado) ORDER BY id_pagina) FROM tb_paginas)
)::text) AS hash").hash[1];}
input=deserializeJSON(toString(binaryDecode(__ENCODED__,"base64")));requestId="payments57-__HASH__";report={};
ensure(input.batch=="verified-pending-payments-20261124" AND arrayLen(input.profiles)==57,"Unexpected audit cohort");
transaction isolation="serializable" {
q("SET LOCAL statement_timeout='20s'");q("SET LOCAL lock_timeout='5s'");q("SELECT pg_advisory_xact_lock(hashtext('verified.payment_scan:20261124'))");
ensure(q("SELECT current_database()='runnerhub' AND current_user='runner_dba' AND EXISTS(SELECT 1 FROM tb_usuarios WHERE id=139 AND is_admin) AS ok").ok[1],"Wrong database or audit actor");
beforeHash=protectedState();inserted=0;
for(item in input.profiles){
ensure(item.complete AND q("SELECT CAST(:verified AS timestamptz)>now()-interval '2 hours' AND CAST(:verified AS timestamptz)<now()+interval '5 minutes' AS ok",{verified={value=item.verified_at,cfsqltype="cf_sql_varchar"}}).ok[1],"Stale or partial scan");
ensure(q("SELECT EXISTS(SELECT 1 FROM tb_paginas_usuarios WHERE id_pagina=:profile AND id_usuario=:user AND id_usuario>0) AS ok",{profile={value=item.profile_id,cfsqltype="cf_sql_integer"},user={value=item.user_id,cfsqltype="cf_sql_integer"}}).ok[1],"Account link changed");
res=q("INSERT INTO crm_interno.audit(actor_id,action,entity_id,revision,request_id,details)
SELECT 139,'verified.payment_scan',:profile,0,:request,CAST(:details AS jsonb)
WHERE NOT EXISTS(SELECT 1 FROM crm_interno.audit WHERE action='verified.payment_scan' AND entity_id=:profile AND request_id=:request) RETURNING id",
{profile={value=item.profile_id & "",cfsqltype="cf_sql_varchar"},request={value=requestId,cfsqltype="cf_sql_varchar"},details={value=serializeJSON(item),cfsqltype="cf_sql_longvarchar"}});inserted+=res.recordCount;
}
ensure(beforeHash==protectedState(),"Badge state changed during audit storage");
count=q("SELECT count(*) AS n FROM crm_interno.audit WHERE action='verified.payment_scan' AND request_id=:request",{request={value=requestId,cfsqltype="cf_sql_varchar"}}).n[1];ensure(count==57,"Incomplete persisted audit");
report={ok=true,inserted=inserted,records=count,request_id=requestId,protected_state_hash=beforeHash,badges_changed=false,payment_ledger_changed=false,provider_writes=false};
}
'''.replace('__ENCODED__',encoded).replace('__HASH__',hashlib.sha256(data).hexdigest())
result=op.run(body);(OUT/'stored.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
