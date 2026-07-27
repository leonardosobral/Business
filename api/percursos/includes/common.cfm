<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="60"/>

<cfscript>
function percursoApiWrite(required any payload, numeric statusCode = 200, string statusText = "OK") output="true" {
    cfheader(statuscode = arguments.statusCode, statustext = arguments.statusText);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function percursoApiBaseUrl() {
    return VARIABLES.percursoApiConfiguredBaseUrl;
}

function percursoApiDate(any value = "") {
    return isDate(arguments.value) ? dateFormat(arguments.value, "yyyy-mm-dd") : "";
}

function percursoApiNumber(any value = "") {
    return isNumeric(arguments.value) ? val(arguments.value) : javacast("null", "");
}

function percursoApiNullableString(any value = "") {
    return len(trim(arguments.value & "")) ? trim(arguments.value & "") : javacast("null", "");
}

function percursoApiGeometryUrl(required numeric eventRouteId, required numeric fileId, required string checksum) {
    return percursoApiBaseUrl()
        & "/api/percursos/geometria.cfm?id_evento_percurso=" & int(arguments.eventRouteId)
        & "&arquivo=" & int(arguments.fileId)
        & "&rev=" & lCase(left(trim(arguments.checksum), 12));
}

function percursoApiOriginAllowed(required string origin, required array allowedOrigins) {
    var allowedOrigin = "";

    if (!len(arguments.origin)) {
        return true;
    }

    for (allowedOrigin in arguments.allowedOrigins) {
        if (compareNoCase(trim(allowedOrigin & ""), arguments.origin) EQ 0) {
            return true;
        }
    }

    return false;
}
</cfscript>

<cfset VARIABLES.percursoApiEnvironment = createObject("java", "java.lang.System").getenv()/>
<cfset VARIABLES.percursoApiConfig = {}/>
<cfset VARIABLES.percursoApiConfigPath = expandPath("/config/percursos.local.cfm")/>

<cfif fileExists(VARIABLES.percursoApiConfigPath)>
    <cfinclude template="../../../config/percursos.local.cfm"/>
    <cfif isDefined("percursoLocalConfig") AND isStruct(percursoLocalConfig)>
        <cfset VARIABLES.percursoApiConfig = percursoLocalConfig/>
    </cfif>
</cfif>

<cfset VARIABLES.percursoApiKey = structKeyExists(VARIABLES.percursoApiEnvironment, "BUSINESS_PERCURSOS_API_KEY")
    ? trim(VARIABLES.percursoApiEnvironment["BUSINESS_PERCURSOS_API_KEY"] & "")
    : (structKeyExists(VARIABLES.percursoApiConfig, "apiKey") ? trim(VARIABLES.percursoApiConfig.apiKey & "") : "")/>
<cfset VARIABLES.percursoApiConfiguredBaseUrl = structKeyExists(VARIABLES.percursoApiEnvironment, "BUSINESS_PERCURSOS_API_BASE_URL")
    ? trim(VARIABLES.percursoApiEnvironment["BUSINESS_PERCURSOS_API_BASE_URL"] & "")
    : (structKeyExists(VARIABLES.percursoApiConfig, "apiBaseUrl")
        ? trim(VARIABLES.percursoApiConfig.apiBaseUrl & "")
        : "https://business.roadrunners.run")/>
<cfset VARIABLES.percursoApiConfiguredBaseUrl = reReplace(VARIABLES.percursoApiConfiguredBaseUrl, "/+$", "")/>
<cfif NOT reFindNoCase("^https://[a-z0-9.-]+(:[0-9]+)?$", VARIABLES.percursoApiConfiguredBaseUrl)>
    <cfset VARIABLES.percursoApiConfiguredBaseUrl = "https://business.roadrunners.run"/>
</cfif>
<cfset VARIABLES.percursoApiAllowedOrigins = []/>

<cfif structKeyExists(VARIABLES.percursoApiEnvironment, "BUSINESS_PERCURSOS_API_ALLOWED_ORIGINS")
    AND len(trim(VARIABLES.percursoApiEnvironment["BUSINESS_PERCURSOS_API_ALLOWED_ORIGINS"] & ""))>
    <cfloop list="#VARIABLES.percursoApiEnvironment["BUSINESS_PERCURSOS_API_ALLOWED_ORIGINS"]#" index="VARIABLES.percursoApiAllowedOrigin">
        <cfset arrayAppend(VARIABLES.percursoApiAllowedOrigins, trim(VARIABLES.percursoApiAllowedOrigin))/>
    </cfloop>
<cfelseif structKeyExists(VARIABLES.percursoApiConfig, "apiAllowedOrigins")
    AND isArray(VARIABLES.percursoApiConfig.apiAllowedOrigins)>
    <cfset VARIABLES.percursoApiAllowedOrigins = VARIABLES.percursoApiConfig.apiAllowedOrigins/>
</cfif>

<cfset VARIABLES.percursoApiHeaders = getHTTPRequestData().headers/>
<cfset VARIABLES.percursoApiOrigin = structKeyExists(VARIABLES.percursoApiHeaders, "Origin")
    ? trim(VARIABLES.percursoApiHeaders.Origin & "")
    : ""/>

<cfheader name="Cache-Control" value="private, max-age=60"/>
<cfheader name="Vary" value="Origin"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>

<cfif NOT percursoApiOriginAllowed(VARIABLES.percursoApiOrigin, VARIABLES.percursoApiAllowedOrigins)>
    <cfset percursoApiWrite({
        success = false,
        error = "origin_not_allowed",
        message = "Esta origem nao esta autorizada a consultar a API."
    }, 403, "Forbidden")/>
</cfif>

<cfif len(VARIABLES.percursoApiOrigin)>
    <cfheader name="Access-Control-Allow-Origin" value="#VARIABLES.percursoApiOrigin#"/>
</cfif>
<cfheader name="Access-Control-Allow-Methods" value="GET, OPTIONS"/>
<cfheader name="Access-Control-Allow-Headers" value="Authorization, X-API-Key, Content-Type"/>
<cfheader name="Access-Control-Max-Age" value="600"/>

<cfif uCase(trim(CGI.request_method & "")) EQ "OPTIONS">
    <cfset percursoApiWrite({success = true}, 200, "OK")/>
</cfif>

<cfif uCase(trim(CGI.request_method & "")) NEQ "GET">
    <cfheader name="Allow" value="GET, OPTIONS"/>
    <cfset percursoApiWrite({
        success = false,
        error = "method_not_allowed",
        message = "Use GET para consultar esta API."
    }, 405, "Method Not Allowed")/>
</cfif>

<cfif NOT len(VARIABLES.percursoApiKey)>
    <cfset percursoApiWrite({
        success = false,
        error = "api_not_configured",
        message = "A credencial da API de percursos ainda nao foi configurada."
    }, 503, "Service Unavailable")/>
</cfif>

<cfset VARIABLES.percursoApiProvidedKey = ""/>
<cfif structKeyExists(VARIABLES.percursoApiHeaders, "X-API-Key")>
    <cfset VARIABLES.percursoApiProvidedKey = trim(VARIABLES.percursoApiHeaders["X-API-Key"] & "")/>
<cfelseif structKeyExists(VARIABLES.percursoApiHeaders, "Authorization")
    AND reFindNoCase("^Bearer[[:space:]]+", trim(VARIABLES.percursoApiHeaders.Authorization & ""))>
    <cfset VARIABLES.percursoApiProvidedKey = reReplaceNoCase(
        trim(VARIABLES.percursoApiHeaders.Authorization & ""),
        "^Bearer[[:space:]]+",
        ""
    )/>
</cfif>

<cfif NOT len(VARIABLES.percursoApiProvidedKey)
    OR hash(VARIABLES.percursoApiProvidedKey, "SHA-256") NEQ hash(VARIABLES.percursoApiKey, "SHA-256")>
    <cfheader name="WWW-Authenticate" value='Bearer realm="Business Percursos API"'/>
    <cfset percursoApiWrite({
        success = false,
        error = "unauthorized",
        message = "Credencial ausente ou invalida."
    }, 401, "Unauthorized")/>
</cfif>
