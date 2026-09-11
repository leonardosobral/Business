<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
if (!structKeyExists(REQUEST, "audienceNativeHttpFixtureAuthorized")
    || !REQUEST.audienceNativeHttpFixtureAuthorized
    || !structKeyExists(REQUEST, "audienceNativeHttpRunId")
    || REQUEST.audienceNativeHttpRunId != "__RUN_ID__") {
    cfcontent(type="application/json; charset=utf-8", reset=true);
    cfheader(statuscode=403);
    writeOutput('{"error":"fixture_guard"}');
    abort;
}

fixtureAdmin = structKeyExists(URL, "admin") && isSimpleValue(URL.admin)
    ? trim(URL.admin & "") : "0";
if (!listFind("0,1", fixtureAdmin)) {
    cfcontent(type="application/json; charset=utf-8", reset=true);
    cfheader(statuscode=400);
    writeOutput('{"error":"fixture_admin"}');
    abort;
}
if (structKeyExists(URL, "ambiente") && lCase(trim(URL.ambiente & "")) != "dev") {
    cfcontent(type="application/json; charset=utf-8", reset=true);
    cfheader(statuscode=400);
    writeOutput('{"error":"fixture_environment"}');
    abort;
}

// This identity exists only inside the guarded fixture route. Direct copied
// includes do not receive it and must be rejected by the real require_admin.
VARIABLES.businessEffectiveIsAdmin = fixtureAdmin == "1";
URL.ambiente = "dev";
</cfscript>
<cfinclude template="portal/includes/audience_backend.cfm"/>
<cfscript>
fixtureSummary = {
    "environment" = VARIABLES.audienceEnvironment,
    "ready" = VARIABLES.audienceReady,
    "unavailable" = VARIABLES.audienceUnavailable,
    "summary" = {}
};
if (VARIABLES.audienceUnavailable) {
    fixtureSummary["failedQuery"] = structKeyExists(VARIABLES,"audienceQueryName") ? VARIABLES.audienceQueryName : "before_queries";
    if (structKeyExists(VARIABLES,"audienceReadError")) {
        fixtureSummary["errorType"] = left(VARIABLES.audienceReadError.type,100);
        fixtureSummary["detail"] = left(replace(replace(VARIABLES.audienceReadError.message & " " & VARIABLES.audienceReadError.detail,"__TEST_TOKEN__","[redacted]","all"),"__PG_PASSWORD__","[redacted]","all"),500);
    } else if (structKeyExists(VARIABLES,"audienceSql")) {
        // Adobe removes the catch variable afterwards. Replay only this same SELECT
        // as the verified disposable reader, keeping the public backend unchanged.
        try {
            fixtureReplay = queryExecute(VARIABLES.audienceSql,VARIABLES.audienceParams,{
                "datasource"="__DATASOURCE_BUSINESS__","timeout"=15,"cachedwithin"=createTimeSpan(0,0,1,0)
            });
            fixtureSummary["diagnosticReplaySucceeded"]=true;
        } catch(any fixtureReadFailure) {
            fixtureSummary["errorType"]=left(fixtureReadFailure.type,100);
            fixtureSummary["detail"]=left(replace(replace(fixtureReadFailure.message & " " & fixtureReadFailure.detail,"__TEST_TOKEN__","[redacted]","all"),"__PG_PASSWORD__","[redacted]","all"),500);
        }
    }
}
if (VARIABLES.audienceReady && structKeyExists(VARIABLES, "audienceSummary")) {
    for (fixtureSummaryKey in [
        "pageviews", "active_pages", "visitors", "sessions", "engaged_sessions",
        "opportunities", "renders", "slot_views", "ad_renders", "ad_views",
        "unknown_location", "unknown_market"
    ]) {
        fixtureSummary.summary[fixtureSummaryKey] = val(VARIABLES.audienceSummary[fixtureSummaryKey]);
    }
}
fixtureSummaryJson = serializeJSON(fixtureSummary);
fixtureSummaryJson = replace(fixtureSummaryJson, "<", "\u003c", "all");
fixtureSummaryJson = replace(fixtureSummaryJson, ">", "\u003e", "all");
fixtureSummaryJson = replace(fixtureSummaryJson, "&", "\u0026", "all");
</cfscript>
<!doctype html>
<html lang="pt-br">
<head><meta charset="utf-8"/><title>Audience report native HTTP fixture</title></head>
<body data-fixture-run-id="<cfoutput>#encodeForHTMLAttribute(REQUEST.audienceNativeHttpRunId)#</cfoutput>" data-audience-environment="<cfoutput>#encodeForHTMLAttribute(VARIABLES.audienceEnvironment)#</cfoutput>">
    <script type="application/json" id="audience-test-summary"><cfoutput>#fixtureSummaryJson#</cfoutput></script>
    <main id="audience-report-fixture">
        <cfinclude template="portal/audiencia/home.cfm"/>
    </main>
</body>
</html>
