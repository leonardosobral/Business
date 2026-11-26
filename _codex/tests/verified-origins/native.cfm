<cfscript>
service=new services.VerifiedAdmin();
checks=0;
function check(required boolean condition,required string message){if(!condition)throw(message=arguments.message);checks++;}
active=service.overview();
check(active.totals.active==418 AND active.totals.permanent==128 AND active.totals.annual==290,"Shared entitlement totals changed");
check(active.total==418 AND arrayLen(active.rows)==40,"Active pagination");
manual=service.overview({origin="manual"});check(manual.total==128,"Manual count");
unknown=service.overview({status="unclassified"});check(unknown.total<=128,"Manual-only classification");
annual=service.overview({origin="annual"});check(annual.total==0,"Refunded annual payments excluded");
last=service.overview({page=9999});check(last.page==last.pages AND arrayLen(last.rows)==18,"Clamped pagination");
empty=service.overview({search="%_' OR 1=1 --"});check(empty.total==0,"Parameterized literal search");
vip=service.overview({origin="vip"});check(vip.total>0 AND vip.total<=290,"Confirmed VIP only");
upgrade=service.overview({origin="upgrade"});check(upgrade.total>0 AND upgrade.total<vip.total,"Separate upgrade source");
role=service.overview({admin=true,dev=true,logic="all"});for(row in role.rows)check(row.is_admin AND row.is_dev,"Combined role filters");
challenge=service.overview({produto="todosantodiavip",logic="all"});check(challenge.total<=418,"Legacy product filter");
for(row in vip.rows){check(row.active AND row.vip,"Active VIP rows");check(len(row.valid_until)>0 OR row.permanent,"VIP validity");}
detail=service.detail(manual.rows[1].profile_id);check(detail.profile.permanent AND detail.sources[1].kind=="manual","Permanent detail");
revoked=service.overview({status="all",search="caua-fraga-sobral"});check(revoked.total==1,"Test athlete lookup");
d=service.detail(revoked.rows[1].profile_id);check(!d.profile.active,"Refunded athlete inactive");
refunds=0;for(source in d.sources)if(source.kind=="annual"){check(!source.active,"No active annual source after refund");if(source.source_state=="refunded")refunds++;}check(refunds==2,"Both real refund records preserved");
check(!structCount(service.detail(2147483647)),"Missing profile");
writeOutput(serializeJSON({ok=true,checks=checks,active=active.totals,manual=manual.total,vip=vip.total,upgrade=upgrade.total,manual_id=manual.rows[1].profile_id,vip_id=vip.rows[1].profile_id,refund_id=revoked.rows[1].profile_id,classification_ready=active.ready}));
</cfscript>
