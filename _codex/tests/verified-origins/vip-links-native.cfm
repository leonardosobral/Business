<cftransaction isolation="read_committed"><cfquery>SET TRANSACTION READ ONLY</cfquery><cfscript>
checks=0;service=new services.VerifiedAdmin();
function check(required boolean condition,required string message){if(!condition)throw(message=arguments.message);checks++;}
function rejects(required any callback,required string message){var rejected=false;try{arguments.callback();}catch(any e){rejected=true;}check(rejected,arguments.message);}
check(service.quickReason('imprensa','')=='Imprensa','Category is enough');
check(service.quickReason('imprensa','GE')=='Imprensa — GE','Short organization name is allowed');
check(service.quickReason('influencer',' @canal ')=='Influencer / criador — @canal','Trim optional reference');
rejects(function(){service.quickReason('outro','');},'Other must explain');
rejects(function(){service.quickReason('vip','');},'Paid origin cannot be relabeled');
rejects(function(){service.quickReason('nao_informado','');},'Quick save requires a known category');
rejects(function(){service.quickReason('imprensa',repeatString('a',1801));},'Note length bound');
entries=service.quickSelection('20:2,10:0');check(entries[1].profileId==10 AND entries[2].profileId==20,'Deterministic lock order');
check(entries[2].revision==2,'Expected revision preserved');
for(bad in ['', '0:0','1:0,1:1','1:0,,2:0','1:x','1:0 OR true','-1:0','1:-1']){
 rejected=false;try{service.quickSelection(bad);}catch(any e){rejected=true;}check(rejected,'Reject malformed selection');
}
tokens=[];for(i=1;i<=41;i++)arrayAppend(tokens,i & ':0');rejects(function(){service.quickSelection(arrayToList(tokens));},'Bounded batch');
fake=createObject('component','QuickFake');
check(fake.classifyQuick('20:2,10:0','imprensa','GE',139)==2,'Batch size');
check(arrayLen(fake.calls)==2 AND fake.calls[1].profileId==10 AND fake.calls[2].profileId==20,'Each selected profile once');
check(fake.calls[1].reason=='Imprensa — GE' AND fake.calls[2].actorId==139,'Reason and actor passed to guarded writer');
fake.failProfile=20;rejects(function(){fake.classifyQuick('10:0,20:2','imprensa','',139);},'Conflict propagates to transaction');
q=service.overview({status='unclassified'});check(q.total==61,'107 original pending minus 46 confirmed VIP links');
check(q.totals.active==418 AND q.totals.permanent==128 AND q.totals.annual==290,'Entitlements unchanged');
check(q.totals.reconcile>=46,'Financial reconciliation includes the 46 unknown VIPs plus already classified profiles');
for(id in [53854,15644,17923]) {
  pending=service.overview({status='unclassified',search=id & ''});check(pending.total==0,'Named paid VIP leaves unknown queue');
  found=service.overview({status='all',search=id & ''});check(found.total==1 AND found.rows[1].registered_vip AND found.rows[1].registration_review,'Named VIP relationship and reconciliation visible');
  check(!found.rows[1].needs_classification AND found.rows[1].permanent,'No new manual reason needed; permanent preserved');
  detail=service.detail(id);check(arrayLen(detail.registrations)>0 AND !detail.registrations[1].reconciled,'Detail distinguishes registration from payment');
}
review=service.overview({status='reconcile'});check(review.total==q.totals.reconcile,'Review tab remains actionable');
upgraded=service.overview({status='all',search='2651'});check(upgraded.rows[1].upgrade AND !upgraded.rows[1].registration_review,'Paid upgrade covers the resulting VIP registration');
filtered=service.overview({status='all',origin='registered_vip'});check(filtered.total>=46,'VIP registration filter works');
unknown=service.overview({status='all',origin='nao_informado'});check(unknown.total==q.total,'Unknown origin matches queue');
for(id in [27813,13937]) {pending=service.overview({status='unclassified',search=id & ''});check(pending.total==1,'No challenge link stays unknown');}
gabi=service.detail(53296);check(arrayLen(gabi.registrations)>0 AND gabi.registrations[1].cancellation_note,'Canceled registration remains flagged');
// Every visible pending profile must still require classification, even on later pages.
for(page=1;page<=q.pages;page++) {
 rows=service.overview({status='unclassified',page=page}).rows;
 for(row in rows)check(row.needs_classification AND !row.registered_vip AND !row.registered_upgrade,'Queue cannot hide a confirmed VIP relationship');
}
check(!service.classificationReady() OR q.ready,'Readiness detected');
writeOutput(serializeJSON({ok=true,checks=checks,manual_id=q.rows[1].profile_id,unclassified=q.total,reconcile=q.totals.reconcile,ready=q.ready}));
</cfscript><cftransaction action="rollback"/></cftransaction>
