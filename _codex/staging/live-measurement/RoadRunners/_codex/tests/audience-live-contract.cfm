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
writeOutput("PASS: LIVE outbound contract, signed circuit context and profile privacy");
</cfscript>
