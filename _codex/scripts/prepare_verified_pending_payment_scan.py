from pathlib import Path
import json,datetime,collections,importlib.util,hashlib,base64,os
from zoneinfo import ZoneInfo
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'_codex/analyses/verified-pending-payments-20261124';scan=json.loads((OUT/'api-scan.json').read_text());cohort=json.loads((OUT/'cohort-private.json').read_text());ids=sorted(r['profile_id'] for r in scan['results']);assert len(ids)==len(set(ids))==57
spec=importlib.util.spec_from_file_location('op',ROOT.parent/'RoadRunners/_codex/scripts/verified_dev_operator.py');op=importlib.util.module_from_spec(spec);spec.loader.exec_module(op)
orders=sorted({o['id'] for r in scan['results'] for o in r['orders']});orderlist=','.join(orders)
sql="""SELECT json_transacao->'data'->>'id' AS order_id,json_agg(DISTINCT id_usuario)::text AS users_json
FROM tb_transacoes WHERE origem_transacao='pagarme' AND id_usuario>0 AND json_transacao->'data'->>'id' IN (:orders) GROUP BY json_transacao->'data'->>'id'"""
body='report={};transaction{queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});report.owners=queryExecute("'+sql.replace('"','""')+'",{orders={value="'+orderlist+'",cfsqltype="cf_sql_varchar",list=true}},{datasource="runner_dba",returntype="array"});report.constraints=queryExecute("SELECT pg_get_constraintdef(oid) AS definition FROM pg_constraint WHERE conrelid=\'crm_interno.audit\'::regclass",{},{datasource="runner_dba",returntype="array"});transaction action="rollback";}'
context={k.lower():v for k,v in op.run(body).items()};(OUT/'ownership-check.json').write_text(json.dumps(context,indent=2));owners={r['order_id']:json.loads(r['users_json']) for r in context['owners']}
seen=collections.defaultdict(set)
for r in scan['results']:
 for o in r['orders']:seen[o['id']].add(r['profile_id'])
labels={'todosantodia':'Todo Santo Dia · Anuidade Básica','todosantodiavip':'Todo Santo Dia · Anuidade VIP','todosantodiaupg':'Todo Santo Dia · Upgrade para VIP','inscricao365':'Desafio 365 · Inscrição','inscricao365vip':'Desafio 365 · VIP','inscricao366':'Desafio 366 · Inscrição'}
def date(s):
 return datetime.datetime.fromisoformat(s.replace('Z','+00:00')).astimezone(ZoneInfo('America/Sao_Paulo')).strftime('%d/%m/%Y %H:%M') if s else ''
profiles=[];stats=collections.Counter();types=collections.Counter();amounts=collections.Counter();linked={r['provider_order_id']:r['profile_id'] for r in cohort['badge_orders']}
for r in scan['results']:
 result={'profile_id':r['profile_id'],'user_id':r['user_id'],'batch':'verified-pending-payments-20261124','version':1,'verified_at':r['verified_at'],'verified_at_display':date(r['verified_at']),'complete':not r['errors'],'ambiguous_refs':r['ambiguous_refs'],'orders':[]}
 has_basic=any(o['classification']=='confirmed' and any(i['code']=='todosantodia' for i in o['items']) for o in r['orders'])
 for o in r['orders']:
  items=o['items'];code=items[0]['code'] if len(items)==1 else '';eligible=code in ('todosantodiavip','todosantodiaupg') and len(items)==1 and items[0]['quantity']==1 and items[0]['amount']==o['amount']
  conflict=not o['customer_email_matches'] or any(u!=r['user_id'] for u in owners.get(o['id'],[])) or len(seen[o['id']])>1
  paid=[c['paid_at'] for c in o['charges'] if c['paid_at']];methods=sorted({c['method'] for c in o['charges'] if c['method']})
  p={'order_id':o['id'],'order_code':o['code'],'product_code':code,'product_name':labels.get(code,' + '.join(i['description'] or i['code'] or 'Produto não informado' for i in items)),'amount_cents':o['amount'],'amount_known':True,'currency':o['currency'],'paid_amount_cents':sum(c['paid_amount'] for c in o['charges']),'refunded_amount_cents':sum(c['refunded_amount'] for c in o['charges']),'classification':o['classification'],'provider_status':o['status'],'method':', '.join(methods),'paid_at':date(min(paid)) if paid else '', 'created_at':date(o['created_at']),'sort_date':o['created_at'],'verified_at':date(r['verified_at']),'recorded_at':'','reconciled_status':'','paid_event':o['classification']=='confirmed','cancellation_event':o['classification']=='refunded_or_partial','failed_event':o['status']=='failed','badge_eligible':eligible,'upgrade_without_basic':eligible and code=='todosantodiaupg' and not has_basic,'match_conflict':conflict,'match_basis':o['match_basis'],'customer_email_matches':o['customer_email_matches']}
  result['orders'].append(p);stats[o['classification']]+=1
  if conflict:stats['identity_review']+=1
  if o['classification']=='confirmed':types[code]+=1;amounts[code]+=o['amount']
  if eligible and o['classification']=='confirmed' and o['id'] not in linked:stats['approved_unlinked_vip']+=1
 profiles.append(result)
payload={'batch':'verified-pending-payments-20261124','profiles':profiles,'audited_at':scan['audited_at'],'source_sha256':hashlib.sha256((OUT/'api-scan.json').read_bytes()).hexdigest()}
(OUT/'display-snapshots.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2));os.chmod(OUT/'display-snapshots.json',0o600)
summary={'profiles':len(profiles),'with_orders':sum(bool(p['orders']) for p in profiles),'orders':sum(len(p['orders']) for p in profiles),'stats':dict(stats),'confirmed_by_product':dict(types),'approved_cents_by_product':dict(amounts),'ambiguous_profiles':[p['profile_id'] for p in profiles if p['ambiguous_refs']],'identity_review_profiles':[p['profile_id'] for p in profiles if any(o['match_conflict'] for o in p['orders'])]};(OUT/'summary.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary,indent=2))
