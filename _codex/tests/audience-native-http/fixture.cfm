<cfsetting showdebugoutput="false" requesttimeout="10"/>
<cfscript>
if (!structKeyExists(REQUEST, "audienceNativeHttpFixtureAuthorized")
    || !REQUEST.audienceNativeHttpFixtureAuthorized) {
    cfcontent(type="application/json; charset=utf-8", reset=true);
    cfheader(statuscode=403);
    writeOutput('{"error":"fixture_guard"}');
    abort;
}

VARIABLES.template = "/busca/";
VARIABLES.adContextUf = "SC";
REQUEST.currentEnvironment = "dev";
REQUEST.LocationContext = {"uf" = "SP"};
REQUEST.Usuario = {
    "logado" = true,
    "uf" = "SP",
    "estado" = "SP",
    "is_admin" = false,
    "is_dev" = false
};
</cfscript>
<!doctype html>
<html lang="pt-br">
<head><meta charset="utf-8"/><title>Audience native HTTP fixture</title></head>
<body data-fixture-run-id="<cfoutput>#encodeForHTMLAttribute(REQUEST.audienceNativeHttpRunId)#</cfoutput>">
    <main id="audience-fixture">RoadRunners Audience native HTTP fixture</main>
    <cfinclude template="includes/analytics/bootstrap.cfm"/>
</body>
</html>
