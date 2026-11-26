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
q=service.overview({status='unclassified'});check(q.total==128,'Unclassified baseline');
check(!service.classificationReady() OR q.ready,'Readiness detected');
writeOutput(serializeJSON({ok=true,checks=checks,manual_id=q.rows[1].profile_id,unclassified=q.total,ready=q.ready}));
</cfscript><cftransaction action="rollback"/></cftransaction>
