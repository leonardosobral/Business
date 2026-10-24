<cfprocessingdirective pageencoding="utf-8"/>

<cfscript>
function discoveryApiWriteJson(required numeric statusCode, required struct payload) {
    cfheader(statuscode=arguments.statusCode);
    writeOutput(serializeJSON(arguments.payload));
}

function discoveryApiWriteError(required numeric statusCode, required string status, required string message, string detail = "") {
    var payload = {
        "success" = false,
        "status" = arguments.status,
        "message" = arguments.message
    };

    if (len(trim(arguments.detail))) {
        payload["detail"] = arguments.detail;
    }

    discoveryApiWriteJson(arguments.statusCode, payload);
}

function discoveryApiWriteException(required any exception) {
    discoveryApiWriteJson(500, {
        "success" = false,
        "status" = "error",
        "message" = arguments.exception.message,
        "detail" = structKeyExists(arguments.exception, "detail") ? arguments.exception.detail : ""
    });
}

function discoveryApiGetBaseUrl() {
    if (structKeyExists(REQUEST, "currentBaseUrl") && len(trim(REQUEST.currentBaseUrl & ""))) {
        return trim(REQUEST.currentBaseUrl & "");
    }

    if (structKeyExists(CGI, "HTTP_HOST") && len(trim(CGI.HTTP_HOST))) {
        return "https://" & trim(CGI.HTTP_HOST);
    }

    return "https://roadrunners.run";
}

function discoveryApiGetParam(string primaryName, string fallbackName = "", string defaultValue = "") {
    if (len(trim(arguments.primaryName)) && structKeyExists(URL, arguments.primaryName)) {
        return trim(URL[arguments.primaryName] & "");
    }

    if (len(trim(arguments.fallbackName)) && structKeyExists(URL, arguments.fallbackName)) {
        return trim(URL[arguments.fallbackName] & "");
    }

    return arguments.defaultValue;
}

function discoveryApiLimitParam() {
    var rawLimit = discoveryApiGetParam("limit", "per_page", "10");
    var limitValue = isNumeric(rawLimit) ? int(rawLimit) : 10;

    if (limitValue LTE 0) {
        limitValue = 10;
    }

    if (limitValue GT 25) {
        limitValue = 25;
    }

    return limitValue;
}

function discoveryApiService() {
    return createObject("component", "services.DiscoveryService").init("runnerhub", discoveryApiGetBaseUrl());
}
</cfscript>
