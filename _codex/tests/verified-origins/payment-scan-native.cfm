<cftransaction isolation="repeatable_read"><cfquery>SET TRANSACTION READ ONLY</cfquery><cfquery>SET LOCAL statement_timeout=20000</cfquery><cfscript>
checks=0;service=new services.VerifiedAdmin();function check(condition,message){if(!condition)throw(message=message);checks++;}
q=service.overview({status='unclassified',evidence='vip_unconfirmed'});p2=service.overview({status='unclassified',evidence='vip_unconfirmed',page=2});
check(q.total==57 AND q.totals.unclassified==61,'Queues unchanged');check(q.totals.active==418 AND q.totals.permanent==86 AND q.totals.annual==332,'Rights unchanged');check(q.totals.divergent==4 AND q.totals.reconcile==6,'Other reviews unchanged');
contexts={};structAppend(contexts,q.context);structAppend(contexts,p2.context);check(structCount(contexts)==57,'All profiles checked');
orders=0;approved=0;refunds=0;amount=0;unlinked=0;review=0;upgrades=0;
for(id in contexts){ctx=contexts[id];check(structKeyExists(ctx,'payment_scan') AND ctx.payment_scan.complete,'API audit available');seen={};
 for(p in ctx.payments){check(!structKeyExists(seen,p.order_id),'One row per order');seen[p.order_id]=true;check(isNumeric(p.amount_cents) AND p.amount_cents>=0,'Amount in cents');
 if(p.provider_checked){orders++;if(p.classification=='confirmed'){approved++;amount+=p.amount_cents;check(!p.badge_eligible,'No confirmed TSD VIP in audited cohort');}if(p.classification=='refunded_or_partial')refunds++;if(p.product_code=='todosantodiaupg')upgrades++;}
 }
 unlinked+=ctx.payment_totals.unlinked_vip;review+=ctx.payment_totals.review;
}
check(orders==105 AND approved==36 AND refunds==6,'Exact provider counts');check(amount==173839,'Approved values exact');check(upgrades==7,'Upgrade orders retained without checking basic registration');check(unlinked==0,'No new confirmed TSD VIP');check(review==1,'Buyer identity conflict flagged');
check(arrayLen(contexts['15398'].payment_scan.ambiguous_refs)==1 AND arrayLen(contexts['15398'].payments)==2,'Shared upgrade code does not import third party payments');check(contexts['53887'].payment_totals.review==1,'Buyer mismatch not silently matched');
other=service.detail(53854);check(other.profile.active AND !other.profile.permanent AND other.profile.valid_until=='31/12/2026','Prior VIP reconciliation intact');
writeOutput(serializeJSON({ok=true,checks=checks,manual_id=q.rows[1].profile_id,profiles=57,orders=orders,approved=approved,refunds=refunds,unlinked_vip=unlinked}));
</cfscript><cftransaction action="rollback"/></cftransaction>
