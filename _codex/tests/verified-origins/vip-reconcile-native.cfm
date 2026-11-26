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
q=service.overview({status='unclassified'});check(q.total==61,'Unknown queue preserved');
check(q.totals.active==418 AND q.totals.permanent==86 AND q.totals.annual==332,'Approved VIP terms applied');
check(q.totals.reconcile==6 AND q.totals.divergent==4,'Four divergences separated from other six reviews');
for(id in [53854,15644,17923]) {
 pending=service.overview({status='unclassified',search=id & ''});check(pending.total==0,'Confirmed VIP not unknown');
 found=service.overview({status='all',search=id & ''});row=found.rows[1];
 check(found.total==1 AND row.vip AND !row.registration_review AND !row.vip_review,'Named VIP fully reconciled');
 check(row.active AND !row.permanent AND row.valid_until=='31/12/2026','Named VIP term follows actual payment');
 detail=service.detail(id);check(arrayLen(detail.sources)==1 AND detail.sources[1].kind=='vip' AND detail.sources[1].active,'Exact paid origin replaces permanent source');
 check(arrayLen(detail.registrations)>0 AND detail.registrations[1].reconciled AND !arrayLen(detail.vipReview),'Detail shows financial reconciliation');
}
review=service.overview({status='divergent'});check(review.total==4,'Four review cases only');
expectedIds=[53015,53067,53296,53742];seen=[];
for(row in review.rows) {
 check(arrayFind(expectedIds,row.profile_id)>0,'Only approved review IDs');arrayAppend(seen,row.profile_id);
 check(row.permanent AND row.vip_review AND !row.reconciliation_pending,'Review badge remains permanent and isolated');
 detail=service.detail(row.profile_id);check(arrayLen(detail.vipReview)==1,'Review explanation available');
}
check(arrayLen(seen)==4,'No duplicated review profiles');
other=service.overview({status='reconcile'});check(other.total==6,'Other reviews remain independent');
for(row in other.rows)check(!row.vip_review,'Divergence not duplicated in general review');
elite=service.detail(28882);check(elite.current.category=='elite' AND !elite.profile.permanent,'Elite annotation preserved with owner-approved VIP term');
refund=service.detail(15305);check(!refund.profile.active,'Refunded Caua remains inactive');
check(service.classificationReady() AND q.ready,'Existing editor remains enabled');
writeOutput(serializeJSON({ok=true,checks=checks,manual_id=q.rows[1].profile_id,unclassified=q.total,reconcile=q.totals.reconcile,divergent=q.totals.divergent,ready=q.ready}));
</cfscript><cftransaction action="rollback"/></cftransaction>
