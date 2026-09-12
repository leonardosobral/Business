<!--- Explicit local-process opt-in; never set this in a web-server environment. --->
<cfset offlineClickEnvironment=createObject("java","java.lang.System").getenv()/>
<cfif NOT offlineClickEnvironment.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS")
    OR offlineClickEnvironment.get("RUNNERHUB_OFFLINE_CFML_TESTS") NEQ "1">
    <cfheader statuscode="404" statustext="Not Found"/><cfabort/>
</cfif>
<!--- Offline CFML contract: runs the real endpoint with only HTTP, database and
      log adapters replaced. No application bootstrap, datasource or paid click. --->
<cfscript>
cpcTestRoot = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../RoadRunners/";
cpcTestScratch = getTempDirectory() & "ads-cpc-click-" & createUUID();
directoryCreate(cpcTestScratch);
cpcTestSource = fileRead(cpcTestRoot & "api/ads/v1/cpc-click.cfm", "utf-8");
cpcTestSource = reReplaceNoCase(cpcTestSource, "\bCGI\b", "VARIABLES.cpcTestCgi", "all");
cpcTestSource = reReplaceNoCase(cpcTestSource, "\bURL\.", "VARIABLES.cpcTestUrl.", "all");
for (cpcTestAdapter in ["queryExecute", "cfheader", "getHTTPRequestData", "writeLog"]) {
    cpcTestSource = reReplaceNoCase(cpcTestSource, "\b" & cpcTestAdapter & "\s*\(", "cpcTest" & cpcTestAdapter & "(", "all");
}
cpcTestSource = reReplaceNoCase(cpcTestSource, "\babort\s*;", 'throw(type="CpcTestResponseComplete");', "all");
cpcTestFragment = cpcTestScratch & "/endpoint.cfm";
fileWrite(cpcTestFragment, cpcTestSource, "utf-8");
cpcTestFailures = [];
cpcTestChecks = 0;
cpcTestToken = repeatString("a", 64);
cpcTestDestination = "https://roadrunners.run/evento/frozen-event/";
cpcTestBrowser = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/132.0.0.0 Safari/537.36";

function cpcTestAssert(required boolean condition, required string label) {
    variables.cpcTestChecks++;
    if (!arguments.condition) arrayAppend(variables.cpcTestFailures, arguments.label);
}
function cpcTestgetHTTPRequestData() { return {headers = variables.cpcTestRequestHeaders}; }
function cpcTestcfheader(string name="", string value="", numeric statuscode=0, string statustext="") {
    if (len(arguments.name)) variables.cpcTestResponseHeaders[arguments.name] = arguments.value;
    if (arguments.statuscode) variables.cpcTestStatus = arguments.statuscode;
}
function cpcTestwriteLog(required string file, required string type, required string text) {
    if (variables.cpcTestLogFails) throw(message="Synthetic log unavailable");
    arrayAppend(variables.cpcTestLogs, deserializeJSON(arguments.text));
}
function cpcTestqueryExecute(required string sql, required struct params, required struct options) {
    arrayAppend(variables.cpcTestQueries, {sql=arguments.sql, params=arguments.params, options=arguments.options});
    if (variables.cpcTestDatabaseFails) throw(message="Synthetic database unavailable");
    if (findNoCase("ads.charge_cpc_click_token", arguments.sql)) {
        variables.cpcTestChargeCalls++;
        if (arguments.params.raw_token.value != variables.cpcTestToken) throw(message="Synthetic invalid token");
        return queryNew("result_status,destination_url", "varchar,varchar", [{
            result_status=variables.cpcTestRetry ? "already_recorded" : "charged",
            destination_url=variables.cpcTestStoredDestination
        }]);
    }
    if (findNoCase("ads.deliveries", arguments.sql)) {
        cpcTestAssert(arguments.options.datasource == "runnerhub", "frozen destination uses operational datasource");
        cpcTestAssert(reFindNoCase("token_hash\s*=\s*:token_hash", arguments.sql) > 0,
            "frozen destination SQL binds the token hash");
        cpcTestAssert(findNoCase("expires_at", arguments.sql) > 0 AND findNoCase("clock_timestamp()", arguments.sql) > 0,
            "frozen destination SQL checks expiration against server time");
        cpcTestAssert(reFindNoCase("billing_model\s*=\s*'CPC'", arguments.sql) > 0
            AND reFindNoCase("ad_type\s*=\s*'EVENT'", arguments.sql) > 0
            AND reFindNoCase("price_snapshot\s*>\s*0", arguments.sql) > 0,
            "frozen destination SQL stays within valid EVENT/CPC deliveries");
        var result = queryNew("result_status,destination_url", "varchar,varchar");
        if (structKeyExists(arguments.params, "token_hash")
            AND arguments.params.token_hash.value == lCase(hash(variables.cpcTestToken, "SHA-256", "UTF-8"))
            AND !variables.cpcTestExpired) {
            queryAddRow(result, {result_status="rejected", destination_url=variables.cpcTestStoredDestination});
        }
        return result;
    }
    throw(message="Unexpected SQL outside CPC test boundary");
}
function cpcTestRun(required struct specimen) {
    variables.cpcTestCgi = {REQUEST_METHOD=structKeyExists(arguments.specimen, "method") ? arguments.specimen.method : "GET",
        HTTP_USER_AGENT=arguments.specimen.ua};
    variables.cpcTestRequestHeaders = structKeyExists(arguments.specimen, "headers") ? arguments.specimen.headers : {};
    variables.cpcTestUrl = {delivery="00000000-0000-4000-8000-000000000001", event="00000000-0000-4000-8000-000000000002",
        token=structKeyExists(arguments.specimen, "token") ? arguments.specimen.token : variables.cpcTestToken};
    variables.cpcTestExpired = structKeyExists(arguments.specimen, "expired") AND arguments.specimen.expired;
    variables.cpcTestRetry = structKeyExists(arguments.specimen, "retry") AND arguments.specimen.retry;
    variables.cpcTestLogFails = structKeyExists(arguments.specimen, "logFails") AND arguments.specimen.logFails;
    variables.cpcTestDatabaseFails = structKeyExists(arguments.specimen, "databaseFails") AND arguments.specimen.databaseFails;
    variables.cpcTestStoredDestination = structKeyExists(arguments.specimen, "destination") ? arguments.specimen.destination : variables.cpcTestDestination;
    variables.cpcTestQueries = [];
    variables.cpcTestChargeCalls = 0;
    variables.cpcTestLogs = [];
    variables.cpcTestResponseHeaders = {};
    variables.cpcTestStatus = 0;
    try { include variables.cpcTestFragment; }
    catch (CpcTestResponseComplete expected) {}
    cpcTestAssert(variables.cpcTestChargeCalls == arguments.specimen.charges, arguments.specimen.label & ": debit invocation count");
    cpcTestAssert(variables.cpcTestStatus == 302, arguments.specimen.label & ": redirect status");
    cpcTestAssert(variables.cpcTestResponseHeaders.Location == arguments.specimen.location, arguments.specimen.label & ": frozen destination/fallback");
    cpcTestAssert(variables.cpcTestResponseHeaders["Referrer-Policy"] == "no-referrer"
        AND variables.cpcTestResponseHeaders["Cache-Control"] == "no-store", arguments.specimen.label & ": private noncached redirect");
    if (structKeyExists(arguments.specimen, "reason") AND !variables.cpcTestLogFails) {
        cpcTestAssert(arrayLen(variables.cpcTestLogs) == 1, arguments.specimen.label & ": one rejection observation");
        if (arrayLen(variables.cpcTestLogs)) {
            cpcTestAssert(variables.cpcTestLogs[1].reason == arguments.specimen.reason, arguments.specimen.label & ": stable rejection reason");
            cpcTestAssert(listSort(structKeyList(variables.cpcTestLogs[1]), "textnocase") == "reason,stage,status",
                arguments.specimen.label & ": observation contains no token, destination, identifier or raw headers");
        }
    }
    if (arguments.specimen.charges == 1 AND arrayLen(variables.cpcTestQueries)) {
        cpcTestAssert(variables.cpcTestQueries[1].params.event_id.value == variables.cpcTestUrl.event
            AND variables.cpcTestQueries[1].params.raw_token.value == variables.cpcTestToken,
            arguments.specimen.label & ": original idempotency key and token reach canonical charge");
    }
}
try {
    // Regression after incident containment. Synthetic token and database
    // adapter: the real endpoint must take its read-only redirect branch.
    cpcTestRun({label="incident Firefox/x.x cannot reach charge adapter",
        ua="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:x.x.x) Gecko/20041107 Firefox/x.x",
        charges=0, location=cpcTestDestination, reason="known_automated_traffic"});
    writeOutput("CONTAINED: incident User-Agent redirects without invoking the canonical charge adapter." & chr(10));
    for (cpcTestUa in ["Googlebot/2.1", "facebookexternalhit/1.1", "Slackbot-LinkExpanding 1.0", "Twitterbot/1.0",
        "TelegramBot", "WhatsApp/2.0", "Microsoft Office/16.0 (Microsoft Outlook 16.0; SafeLinks)",
        "Proofpoint URL Defense", "Mimecast URL Scanner", "HeadlessChrome/132.0", "curl/8.0", "python-requests/2.32"]) {
        cpcTestRun({label=cpcTestUa, ua=cpcTestUa, charges=0, location=cpcTestDestination, reason="known_automated_traffic"});
    }
    for (cpcTestHeaders in [{"Sec-Purpose"="prefetch"}, {"sec-purpose"="prefetch;prerender"},
        {"Purpose"="prefetch"}, {"X-Purpose"="preview"}, {"X-Moz"="prefetch"}]) {
        cpcTestRun({label="speculative " & structKeyList(cpcTestHeaders), ua=cpcTestBrowser, headers=cpcTestHeaders,
            charges=0, location=cpcTestDestination, reason="speculative_request"});
    }
    cpcTestRun({label="HEAD scanner", ua=cpcTestBrowser, method="HEAD", charges=0, location=cpcTestDestination, reason="non_get_request"});
    cpcTestRun({label="immediate human click without viewable", ua=cpcTestBrowser, charges=1, location=cpcTestDestination});
    cpcTestRun({label="human retry retains event id", ua=cpcTestBrowser, retry=true, charges=1, location=cpcTestDestination});
    cpcTestRun({label="privacy browser without UA", ua="", charges=1, location=cpcTestDestination});
    cpcTestRun({label="ordinary navigation purpose", ua=cpcTestBrowser, headers={"Purpose"="navigate"}, charges=1, location=cpcTestDestination});
    cpcTestRun({label="bot invalid token", ua="Googlebot", token=repeatString("b",64), charges=0, location="https://roadrunners.run/", reason="known_automated_traffic"});
    cpcTestRun({label="bot expired delivery", ua="Googlebot", expired=true, charges=0, location="https://roadrunners.run/", reason="known_automated_traffic"});
    cpcTestRun({label="bot destination cannot inject header", ua="Googlebot", destination="https://example.test/" & chr(13) & chr(10) & "X-Test: injected",
        charges=0, location="https://roadrunners.run/", reason="known_automated_traffic"});
    cpcTestRun({label="bot database unavailable", ua="Googlebot", databaseFails=true, charges=0, location="https://roadrunners.run/", reason="known_automated_traffic"});
    cpcTestRun({label="bot logging unavailable", ua="Googlebot", logFails=true, charges=0, location=cpcTestDestination, reason="known_automated_traffic"});
    cpcTestRun({label="POST never debits", ua=cpcTestBrowser, method="POST", charges=0, location="https://roadrunners.run/"});
    if (arrayLen(cpcTestFailures)) throw(message=arrayToList(cpcTestFailures, chr(10)), type="CpcTrafficContractFailed");
    writeOutput("PASS: " & cpcTestChecks & " CPC click traffic checks; no datasource or financial call executed." & chr(10));
} finally {
    directoryDelete(cpcTestScratch, true);
}
</cfscript>
