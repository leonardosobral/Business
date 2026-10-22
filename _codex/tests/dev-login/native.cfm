<cfscript>
checks=0;
function check(required boolean passed,required string message) {
    if(!arguments.passed) throw(type="Test.Failed",message=arguments.message);
    checks++;
}
function attemptAction(struct fields={}) {
    structClear(FORM);
    structAppend(FORM,{user_id=VARIABLES.actorId,dev_login_confirmed="0",user_manager_csrf="fixture-csrf"});
    structAppend(FORM,arguments.fields,true);
    VARIABLES.userManagerActionUserId=val(FORM.user_id);
    VARIABLES.userManagerActorId=VARIABLES.actorId;
    VARIABLES.userManagerCsrf="fixture-csrf";
    VARIABLES.businessAccountSimulationActive=false;
    REQUEST.capturedAudit={};
    try {include "manager-action.cfm";}
    catch(Test.HandoffReady ready) {return {allowed=true};}
    catch(any denied) {return {allowed=false,message=denied.message};}
    return {allowed=false,message="No handoff"};
}
include "manager-functions.cfm";
actualActor=queryExecute("SELECT usr.id FROM tb_usuarios usr
 LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario=usr.id
 WHERE coalesce(usr.is_admin,false)=true AND coalesce(gest.ativo,true)=true
 AND coalesce(gest.excluido,false)=false AND EXISTS(SELECT 1 FROM tb_paginas_usuarios pu
 JOIN tb_paginas pag ON pag.id_pagina=pu.id_pagina
 LEFT JOIN tb_paginas_gestao pg ON pg.id_pagina=pag.id_pagina
 WHERE pu.id_usuario=usr.id AND coalesce(pg.ativo,true)=true AND coalesce(pg.excluido,false)=false)
 ORDER BY usr.id LIMIT 1",{},{datasource="runner_dba"});
check(actualActor.recordCount EQ 1,"Read-only fixture found an eligible administrator");
actorId=actualActor.id;
APPLICATION.notificationDispatch={secret=repeatString("test-only-secret-",4)};
result=attemptAction();
check(!result.allowed,"DEV login requires explicit confirmation before issuing a token");
check(!structCount(REQUEST.capturedAudit),"Missing confirmation never records a successful login");
result=attemptAction({dev_login_confirmed="1"});
check(result.allowed,"Confirmed admin POST reaches the actual manager handoff");
check(REQUEST.capturedAudit.actionName EQ "usuario_impersonado_dev" AND REQUEST.capturedAudit.targetUserId EQ actorId,"Successful action binds the audit to the selected account");
check(!findNoCase("token",serializeJSON(REQUEST.capturedAudit)) AND !find(APPLICATION.notificationDispatch.secret,serializeJSON(REQUEST.capturedAudit)),"Audit never includes a credential or token");

service=new services.BusinessDevLogin();
actor={id=900001,is_admin=true,is_dev=false,gestao_ativo=true,gestao_excluido=false,has_active_page=true};
target={id=900002,email="athlete@example.test",is_admin=false,is_dev=false,gestao_ativo=true,gestao_excluido=false,has_active_page=true};
requestFields={actor=actor,target=target,secret=APPLICATION.notificationDispatch.secret,method="POST",expectedCsrf="fixture-csrf",postedCsrf="fixture-csrf",confirmed="1",simulationActive=false};
handoff=service.createHandoff(argumentCollection=requestFields);
check(left(handoff.url,64) CONTAINS "https://dev.roadrunners.run/?action=handoff_consume&token=","Destination is fixed to HTTPS DEV");
check(!find(target.email,handoff.url),"Email is not a plaintext URL parameter");
receiver=new ReceiverFixture();
APPLICATION.handoff={secret=APPLICATION.notificationDispatch.secret};
APPLICATION.baseCanonica="https://roadrunners.run";
claims=receiver.validate(handoff.token,"dev");
check(claims.success AND claims.payload.originalUsuarioId EQ actor.id AND claims.payload.impersonateUsuarioId EQ target.id AND claims.payload.impersonateEmail EQ target.email,"DEV validator accepts the real issuer token and binds both identities by ID");
check(dateDiff("s",claims.payload.issuedAt,claims.payload.expiresAt) EQ 180 AND dateDiff("s",now(),claims.payload.expiresAt) LTE 180,"Token has a short fixed 180-second lifetime");
check(claims.payload.target EQ "dev" AND claims.payload.origin EQ "business" AND claims.payload.redirectPath EQ "/atleta/","Token cannot request a different environment or redirect");
check(!receiver.validate(handoff.token & "changed","dev").success,"Tampered signature remains blocked");
check(!receiver.validate(handoff.token,"prod").success AND !receiver.validate(handoff.token,"beta").success,"Token cannot validate for production or beta");
expired=duplicate(claims.payload);expired.expiresAt=dateTimeFormat(dateAdd("s",-1,now()),"yyyy-mm-dd HH:nn:ss");
encoded=toBase64(serializeJSON(expired));
check(!receiver.validate(encoded & "." & lCase(hmac(encoded,APPLICATION.handoff.secret,"HmacSHA256")),"dev").success,"Expired signed token remains blocked");
for(bad in [
 {field="method",value="GET"},{field="method",value="PUT"},{field="postedCsrf",value=""},
 {field="postedCsrf",value="FIXTURE-CSRF"},{field="postedCsrf",value="wrong"},{field="expectedCsrf",value=""},
 {field="confirmed",value="0"},{field="confirmed",value="true"},{field="simulationActive",value=true},
 {field="secret",value=""},{field="secret",value=hash("RoadRunners::handoff::roadrunners.run::v1","SHA-256")}
]) {
 fields=duplicate(requestFields);fields[bad.field]=bad.value;denied=false;
 try {service.createHandoff(argumentCollection=fields);}catch(BusinessDevLogin.Denied e){denied=true;}
 check(denied,"Issuer denies unsafe " & bad.field);
}
for(bad in [
 {side="actor",field="is_admin",value=false},{side="actor",field="gestao_ativo",value=false},
 {side="actor",field="gestao_excluido",value=true},{side="actor",field="has_active_page",value=false},
 {side="actor",field="id",value=0},{side="target",field="id",value="900002junk"},
 {side="target",field="gestao_ativo",value=false},{side="target",field="gestao_excluido",value=true},
 {side="target",field="has_active_page",value=false},{side="target",field="email",value=""}
]) {
 fields=duplicate(requestFields);fields[bad.side][bad.field]=bad.value;fields.actor.is_dev=true;denied=false;
 try {service.createHandoff(argumentCollection=fields);}catch(BusinessDevLogin.Denied e){denied=true;}
 check(denied,"Issuer rejects invalid identity: " & bad.side & "." & bad.field);
}
for(fields in [{user_id=actorId & "junk",dev_login_confirmed="1"},{user_id="0",dev_login_confirmed="1"},{user_manager_csrf="FIXTURE-CSRF",dev_login_confirmed="1"}]) {
 check(!attemptAction(fields).allowed,"Actual manager action rejects malformed target or case-altered CSRF");
}
received=receiver.consume(handoff.token,"dev",actor,target);
check(received.redirect EQ "/atleta/" AND received.loggedInId EQ target.id,"Real DEV consume flow selects the athlete, not the administrator");
check(received.devAuth.originalUsuarioId EQ actor.id AND received.devAuth.impersonatedUsuarioId EQ target.id AND received.devAuth.isImpersonating,"DEV keeps the original admin for returning from impersonation");
check(!received.loggedInAdmin,"Impersonation does not elevate the athlete's permissions");
resolved=receiver.resolveIdentity(actor.id,"dev");
check(resolved.id EQ target.id AND !resolved.is_admin,"A stale administrator cookie cannot override the authenticated support session");
resolved=receiver.resolveIdentity(actor.id,"prod");
check(resolved.id EQ actor.id,"DEV support session never overrides production identity");
returned=receiver.returnToAdmin(target.id);
check(returned.id EQ actor.id AND returned.origin EQ "business" AND !returned.impersonating,"Return restores the original admin even when a conflicting athlete cookie remains");
for(badClaim in ["missing","wrong-email","dev-only-actor"]) {
    invalid=duplicate(claims.payload);unprivileged=duplicate(actor);
    if(badClaim EQ "missing") structDelete(invalid,"impersonateUsuarioId");
    if(badClaim EQ "wrong-email") invalid.impersonateEmail="other@example.test";
    if(badClaim EQ "dev-only-actor") {unprivileged.is_admin=false;unprivileged.is_dev=true;}
    encoded=toBase64(serializeJSON(invalid));
    received=receiver.consume(encoded & "." & lCase(hmac(encoded,APPLICATION.handoff.secret,"HmacSHA256")),"dev",unprivileged,target);
    check(received.loggedInId EQ 0,"DEV consumer rejects misbound identity or non-global actor: " & badClaim);
}
received=receiver.consume(handoff.token,"prod",actor,target);
check(received.loggedInId EQ 0,"Real production consume flow never signs in through this token");
for(headerCase in [{dev=true,impersonating=true,admin=true,visible=true},{dev=false,impersonating=true,admin=true,visible=false},{dev=true,impersonating=false,admin=true,visible=false},{dev=true,impersonating=true,admin=false,visible=false}]) {
 VARIABLES.devMode=headerCase.dev;VARIABLES.headerHomePath="/";
 SESSION.devAuth={origin="business",isImpersonating=headerCase.impersonating};
 qCheckOriginalId=queryNew("is_admin","bit",[{is_admin=headerCase.admin}]);
 savecontent variable="returnButton" {include "header-return.cfm";}
 check((find("?action=dev_auth_back",returnButton)>0) EQ headerCase.visible,"Return-to-admin control remains available to the original admin without elevating the athlete");
}
writeOutput(serializeJSON({ok=true,checks=checks,live_account_writes=0}));
</cfscript>
