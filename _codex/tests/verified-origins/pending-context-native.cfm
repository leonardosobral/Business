<cftransaction isolation="repeatable_read"><cfquery>SET TRANSACTION READ ONLY</cfquery><cfquery>SET LOCAL statement_timeout=20000</cfquery><cfscript>
checks=0;service=new services.VerifiedAdmin();
function check(required boolean condition,required string message){if(!condition)throw(message=arguments.message);checks++;}
function rejects(required any callback,required string message){var rejected=false;try{arguments.callback();}catch(any e){rejected=true;}check(rejected,arguments.message);}
q=service.overview({status='unclassified'});
check(q.total==61,'61 remaining');check(arrayLen(q.rows)==40 AND structCount(q.context)==40,'Context scoped to displayed page');
check(q.totals.active==418 AND q.totals.permanent==86 AND q.totals.annual==332,'Rights preserved');
check(q.totals.reconcile==6 AND q.totals.divergent==4,'Reconciliation queues preserved');
expected={vip_unconfirmed=57,historic_vip=12,basic=12,none=2,bio=26,social=7};
for(key in expected){check(q.totals['pending_' & key]==expected[key],'Evidence total ' & key);filtered=service.overview({status='unclassified',evidence=key});check(filtered.total==expected[key],'Evidence filter ' & key);for(row in filtered.rows)check(row['evidence_' & key],'Filter matches every row');}
p2=service.overview({status='unclassified',page=2});check(arrayLen(p2.rows)==21 AND structCount(p2.context)==21,'Second page context');
for(row in p2.rows)check(!structKeyExists(q.context,row.profile_id & ''),'No repeated profiles');
for(ctx in q.context){for(acct in q.context[ctx].accounts)check(acct.user_id>0,'Exclude legacy user zero');}
unsafe=service.overview({status='unclassified',evidence='none OR true'});check(unsafe.total==61,'Evidence filter whitelisted');
check(structCount(service.contextForProfiles([]))==0,'Empty context');
rejects(function(){service.contextForProfiles([0]);},'No zero ID');rejects(function(){service.contextForProfiles(['1 OR true']);},'No SQL fragment ID');
large=[];for(i=1;i<=101;i++)arrayAppend(large,i);rejects(function(){service.contextForProfiles(large);},'Bounded context');
check(structCount(service.contextForProfiles([27813,27813]))==1,'Deduplicate profiles');
d=service.detail(27813);check(!arrayLen(d.context.registrations) AND !arrayLen(d.context.legacy) AND len(d.context.profile.bio)>0,'Bio available without invented challenge');
d=service.detail(16181);legacyVip=false;currentVip=false;for(r in d.context.legacy)if(r.product_code=='inscricao365vip' AND r.status=='C')legacyVip=true;for(r in d.context.registrations)if(r.product_code=='inscricao365vip' AND r.status=='C')currentVip=true;
check(legacyVip AND !currentVip,'Legacy-only VIP evidence retained');
for(r in d.context.legacy)if(r.product_code=='inscricao365vip')check(r.product_name=='Desafio 365 · VIP','Readable legacy product label');
basic=service.contextForProfiles([12418]);paid=false;for(pmt in basic['12418'].payments)if(pmt.product_code=='todosantodia' AND pmt.paid_event){paid=true;check(pmt.product_name=='Todo Santo Dia · Anuidade Básica','Basic payment is not VIP');}
check(paid,'Local paid event available');
reviews=service.overview({status='divergent'});check(reviews.total==4,'Four divergences');for(row in reviews.rows)check(row.permanent AND !row.needs_classification,'Divergences remain separate and permanent');
for(id in [53854,15644,17923]){d=service.detail(id);check(d.profile.active AND !d.profile.permanent AND d.profile.valid_until=='31/12/2026','Reconciled VIP unchanged');}
d=service.detail(15305);check(!d.profile.active,'Refunded test inactive');
check(service.classificationReady() AND q.ready,'Classification editor available');
writeOutput(serializeJSON({ok=true,checks=checks,manual_id=q.rows[1].profile_id,unclassified=q.total,evidence=expected}));
</cfscript><cftransaction action="rollback"/></cftransaction>
