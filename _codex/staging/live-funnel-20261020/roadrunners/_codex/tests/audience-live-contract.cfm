<!--- Isolated CFML only: no application bootstrap, datasource or network. --->
<cfscript>
liveEnv=createObject("java","java.lang.System").getenv();
if (!liveEnv.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS") || liveEnv.get("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") { cfheader(statuscode=404); abort; }
function liveAssert(required boolean condition, required string label) {
    if (!arguments.condition) throw(type="AudienceLiveTestFailure",message=arguments.label);
}
liveSvc=createObject("component","services.AudienceMeasurementService").init({"enabled"=true,"secret"=createUUID()});
liveCircuit=queryNew("id_agrega_evento,tag","integer,varchar",[{"id_agrega_evento"=42,"tag"="live-run-xp"}]);
liveContext=liveSvc.buildContext({"template"="/circuito/","qAgrega"=liveCircuit,"canonical"="https://roadrunners.run/circuito/live-run-xp/?utm_source=google"},{},{"HTTP_HOST"="roadrunners.run"});
liveAssert(liveContext.pageFamily=="circuit" && liveContext.contentType=="circuit" && liveContext.contentId=="42", "circuit context has a stable database identity");
liveAssert(liveContext.pagePath=="/circuito/live-run-xp/", "circuit canonical path excludes attribution queries");
liveProfile=queryNew("id_pagina","integer",[{"id_pagina"=42}]);
liveProfileContext=liveSvc.buildContext({"template"="/atleta/","qPagina"=liveProfile,"canonical"="https://roadrunners.run/atleta/private-person/"},{},{"HTTP_HOST"="roadrunners.run"});
liveAssert(liveProfileContext.pagePath=="/atleta/", "adding public circuits never exposes profile canonical slugs");
liveSigned=liveSvc.signContext(liveContext);
livePayload={"contextToken"=liveSigned.contextToken,"signature"=liveSigned.signature,
    "visitorId"="22222222-2222-4222-8222-222222222222","sessionId"="33333333-3333-4333-8333-333333333333",
    "source"="google","medium"="cpc","campaign"="live_run_retomada","creative"="smart_retomada",
    "events"=[{"kind"="outbound_click","key"="outbound_click:live_registration:304","contentType"="event","contentId"="304"}]};
liveHeaders={"Origin"="https://roadrunners.run","Sec-Fetch-Site"="same-origin"};
liveBatch=liveSvc.validateBatch(livePayload,"roadrunners.run",liveHeaders);
liveAssert(liveBatch.events[1].contentId=="304" && liveBatch.client.campaign=="live_run_retomada", "event identity and session campaign survive validation from a circuit page");
for (liveBad in [
    {"contentType"="circuit"},{"contentId"="wrong"},{"contentId"="0"},{"key"="outbound_click:live_registration:305"},
    {"slotKey"="inventory"},{"campaignId"="44444444-4444-4444-8444-444444444444"},{"activeMs"=1},{"ratio"=0.5}
]) {
    liveRejected=false;
    try {
        liveInvalid=duplicate(livePayload); structAppend(liveInvalid.events[1],liveBad,true);
        liveSvc.validateBatch(liveInvalid,"roadrunners.run",liveHeaders);
    } catch (Audience.Invalid invalid) { liveRejected=true; }
    liveAssert(liveRejected,"malformed LIVE identity or invented Ads/engagement data is rejected");
}
liveOther=duplicate(livePayload); liveOther.events=[{"kind"="outbound_click","key"="outbound_click:other"}];
liveAssert(arrayLen(liveSvc.validateBatch(liveOther,"roadrunners.run",liveHeaders).events)==1,"other existing outbound keys remain compatible");
// LIVE funnel uses existing kinds so the SQL editorial contract stays unchanged.
liveEventContext=duplicate(liveContext); liveEventContext.pageFamily="event"; liveEventContext.contentType="event"; liveEventContext.contentId="304"; liveEventContext.pagePath="/evento/live-test/";
liveEventSigned=liveSvc.signContext(liveEventContext);
function liveCheckEvent(required struct event, boolean accepted=true, boolean circuit=false) {
    var payload=duplicate(livePayload);
    if (!arguments.circuit) { payload.contextToken=liveEventSigned.contextToken; payload.signature=liveEventSigned.signature; }
    payload.events=[arguments.event]; var rejected=false;
    try { liveSvc.validateBatch(payload,"roadrunners.run",liveHeaders); } catch(Audience.Invalid error) { rejected=true; }
    liveAssert(rejected != arguments.accepted,"LIVE funnel event validation: " & arguments.event.key);
}
liveView={"kind"="content_open","key"="content_open:live_coupon_viewable:304","contentType"="event","contentId"="304","visibleMs"=1000,"maxContinuousMs"=1000,"ratio"=0.5};
liveCheckEvent(liveView);
for(liveChanges in [{"ratio"=0.49},{"maxContinuousMs"=999},{"visibleMs"=999},{"activeMs"=1},{"kind"="outbound_click"},{"contentId"="305"},{"contentType"="news"},{"slotKey"="ad"},{"campaignId"="44444444-4444-4444-8444-444444444444"}]) {
    liveInvalid=duplicate(liveView); structAppend(liveInvalid,liveChanges,true); liveCheckEvent(liveInvalid,false);
}
liveCheckEvent(liveView,false,true);
for(liveAction in ["coupon_copy_attempt","coupon_copy_success","coupon_copy_error","information"]) {
    liveKind=liveAction=="information" ? "outbound_click" : "content_open";
    liveActionEvent={"kind"=liveKind,"key"=liveKind & ":live_" & liveAction & ":304","contentType"="event","contentId"="304"};
    liveCheckEvent(liveActionEvent);
    liveCheckEvent(liveActionEvent,false,true);
    for(liveChanges in [{"contentId"="305"},{"contentType"="circuit"},{"activeMs"=1},{"ratio"=0.5},{"visibleMs"=1},{"slotKey"="ad"},{"deliveryId"="44444444-4444-4444-8444-444444444444"}]) {
        liveInvalid=duplicate(liveActionEvent); structAppend(liveInvalid,liveChanges,true); liveCheckEvent(liveInvalid,false);
    }
}
liveCity={"kind"="content_open","key"="content_open:live_city_select:42:campinas-sp","contentType"="circuit","contentId"="42"};
liveCheckEvent(liveCity,true,true); liveCheckEvent(liveCity,false);
liveAllCity=duplicate(liveCity);liveAllCity.key="content_open:live_city_select:42:all"; liveCheckEvent(liveAllCity,true,true);
for(liveChanges in [{"key"="content_open:live_city_select:42:campinas-zz"},{"key"="content_open:live_city_select:42:11999999999"},{"key"="content_open:live_city_select:42:person.example.com"},{"key"="content_open:live_city_select:43:campinas-sp"},{"contentId"="43"},{"kind"="outbound_click"},{"ratio"=0.5}]) {
    liveInvalid=duplicate(liveCity); structAppend(liveInvalid,liveChanges,true); liveCheckEvent(liveInvalid,false,true);
}
liveCheckEvent({"kind"="content_open","key"="content_open:live_coupon_copy_purchase:304","contentType"="event","contentId"="304"},false);
writeOutput("PASS: LIVE registration, signed context, coupon exposure/copy, city selection, information exits and profile privacy");
</cfscript>
