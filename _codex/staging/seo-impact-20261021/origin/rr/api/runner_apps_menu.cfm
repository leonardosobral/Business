<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting enablecfoutputonly="true"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfheader name="Cache-Control" value="no-store, max-age=0"/>
<cfheader name="Pragma" value="no-cache"/>
<cfinclude template="discovery/_helpers.cfm"/>

<cfscript>
function runnerAppsMenuValidPayload(required any payload) {
    return isStruct(arguments.payload)
        && structKeyExists(arguments.payload, "success")
        && isBoolean(arguments.payload.success)
        && arguments.payload.success
        && structKeyExists(arguments.payload, "groups")
        && isArray(arguments.payload.groups)
        && structKeyExists(arguments.payload, "items")
        && isArray(arguments.payload.items);
}

try {
    if (ucase(trim(CGI.REQUEST_METHOD & "")) NEQ "GET") {
        cfheader(name="Allow", value="GET");
        discoveryApiWriteError(405, "method_not_allowed", "Apenas requisicoes GET sao permitidas.");
        abort;
    }

    runnerAppsCacheKey = "runnerAppsMenuLazyPayloadV1";
    runnerAppsCacheLock = "RunnerAppsMenuLazyPayload-#APPLICATION.applicationName#";
    runnerAppsPayload = {};
    runnerAppsFetchNow = false;

    lock name=runnerAppsCacheLock type="exclusive" timeout=2 {
        if (!structKeyExists(APPLICATION, runnerAppsCacheKey)
            || !isStruct(APPLICATION[runnerAppsCacheKey])) {
            APPLICATION[runnerAppsCacheKey] = {
                "payload" = {},
                "expiresAt" = now(),
                "retryAt" = now(),
                "refreshing" = false
            };
        }

        runnerAppsPayload = duplicate(APPLICATION[runnerAppsCacheKey].payload);
        if (!APPLICATION[runnerAppsCacheKey].refreshing
            && now() GTE APPLICATION[runnerAppsCacheKey].expiresAt
            && now() GTE APPLICATION[runnerAppsCacheKey].retryAt) {
            APPLICATION[runnerAppsCacheKey].refreshing = true;
            runnerAppsFetchNow = true;
        }
    }

    if (runnerAppsFetchNow) {
        try {
            runnerAppsResponse = {};
            cfhttp(
                url="https://api.roadrunners.run/v1/discovery/runner-apps.cfm",
                method="get",
                timeout=3,
                result="runnerAppsResponse",
                redirect=false
            ) {
                cfhttpparam(type="header", name="Accept", value="application/json");
            }

            if (left(runnerAppsResponse.statusCode & "", 3) NEQ "200"
                || !isJSON(runnerAppsResponse.fileContent)) {
                throw(type="RunnerApps.Unavailable", message="Runner apps catalog unavailable");
            }

            runnerAppsFreshPayload = deserializeJSON(runnerAppsResponse.fileContent);
            if (!runnerAppsMenuValidPayload(runnerAppsFreshPayload)) {
                throw(type="RunnerApps.InvalidPayload", message="Invalid runner apps catalog");
            }

            lock name=runnerAppsCacheLock type="exclusive" timeout=2 {
                APPLICATION[runnerAppsCacheKey] = {
                    "payload" = duplicate(runnerAppsFreshPayload),
                    "expiresAt" = dateAdd("s", 300, now()),
                    "retryAt" = dateAdd("s", 300, now()),
                    "refreshing" = false
                };
            }
            runnerAppsPayload = runnerAppsFreshPayload;
        } catch (any runnerAppsFetchError) {
            lock name=runnerAppsCacheLock type="exclusive" timeout=2 {
                APPLICATION[runnerAppsCacheKey].retryAt = dateAdd("s", 60, now());
                APPLICATION[runnerAppsCacheKey].refreshing = false;
                runnerAppsPayload = duplicate(APPLICATION[runnerAppsCacheKey].payload);
            }
        }
    }

    if (!runnerAppsMenuValidPayload(runnerAppsPayload)) {
        discoveryApiWriteError(503, "catalog_unavailable", "Catalogo Runner Apps indisponivel.");
        abort;
    }

    discoveryApiWriteJson(200, runnerAppsPayload);
} catch (any exception) {
    discoveryApiWriteException(exception);
}
</cfscript>
