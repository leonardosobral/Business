<cfsetting showdebugoutput="false" requesttimeout="10"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
if (!structKeyExists(REQUEST, "audienceNativeHttpFixtureAuthorized")
    || !REQUEST.audienceNativeHttpFixtureAuthorized) {
    cfheader(statuscode=403);
    writeOutput('{"error":"fixture_guard"}');
    abort;
}

contextMode = structKeyExists(URL, "mode") && isSimpleValue(URL.mode)
    ? lCase(trim(URL.mode & "")) : "valid";
expiredContext = (structKeyExists(URL, "expired")
    && isSimpleValue(URL.expired)
    && trim(URL.expired & "") == "1")
    || contextMode == "expired";
if (structKeyExists(URL, "expired")
    && (!isSimpleValue(URL.expired) || !listFind("0,1", trim(URL.expired & "")))) {
    cfheader(statuscode=400);
    writeOutput('{"error":"fixture_mode"}');
    abort;
}
if (!listFind("valid,expired", contextMode)) {
    cfheader(statuscode=400);
    writeOutput('{"error":"fixture_mode"}');
    abort;
}

audienceService = createObject("component", "services.AudienceMeasurementService").init({
    "enabled" = true,
    "secret" = "__TEST_TOKEN__"
});
audienceContext = audienceService.buildContext(
    {
        "template" = "/busca/",
        "adContextUf" = "SC"
    },
    {
        "currentEnvironment" = "dev",
        "LocationContext" = {"uf" = "SP"},
        "Usuario" = {
            "logado" = true,
            "uf" = "SP",
            "estado" = "SP",
            "is_admin" = false,
            "is_dev" = false
        }
    },
    CGI
);
if (expiredContext) {
    audienceContext.issuedAt = fix(
        createObject("java", "java.lang.System").currentTimeMillis() / 1000
    ) - 86401;
}
writeOutput(audienceService.configJson(audienceContext));
</cfscript>
