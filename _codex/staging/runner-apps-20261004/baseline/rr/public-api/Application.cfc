<cfcomponent displayname="RoadRunnersPublicApi" output="false">

    <cfset THIS.Name = "RoadRunnersPublicApi"/>
    <cfset THIS.ApplicationTimeout = createTimeSpan(2, 0, 0, 0)/>
    <cfset THIS.SessionManagement = false/>
    <cfset THIS.SetClientCookies = false/>
    <cfset THIS.SearchImplicitScopes = true/>
    <cfset THIS.datasource = "runnerhub"/>
    <cfset THIS.serialization.preservecaseforstructkey = true/>
    <cfset THIS.mappings = {
        "/config" = getDirectoryFromPath(getCurrentTemplatePath()) & "../config",
        "/includes" = getDirectoryFromPath(getCurrentTemplatePath()) & "../includes",
        "/repositories" = getDirectoryFromPath(getCurrentTemplatePath()) & "../repositories",
        "/services" = getDirectoryFromPath(getCurrentTemplatePath()) & "../services"
    }/>

    <cfsetting requesttimeout="20" showdebugoutput="false" enablecfoutputonly="false"/>

    <cffunction name="OnApplicationStart" access="public" returntype="boolean" output="false">
        <cfset var environment = createObject("java", "java.lang.System").getenv()/>
        <cfset var corsOrigins = structKeyExists(environment, "RR_API_CORS_ORIGINS")
            ? trim(environment["RR_API_CORS_ORIGINS"] & "")
            : "https://roadrunners.run,https://www.roadrunners.run,https://beta.roadrunners.run,https://dev.roadrunners.run"/>
        <cfset var rateLimit = structKeyExists(environment, "RR_API_RATE_LIMIT_PER_MINUTE")
            ? val(environment["RR_API_RATE_LIMIT_PER_MINUTE"])
            : 120/>

        <cfset APPLICATION.codSite = "RR"/>
        <cfset APPLICATION.nomeSite = "Road Runners API"/>
        <cfset APPLICATION.dominio = "roadrunners.run"/>
        <cfset APPLICATION.baseCanonica = "https://roadrunners.run"/>
        <cfset APPLICATION.apiCorsOrigins = corsOrigins/>
        <cfset APPLICATION.apiRateLimitPerMinute = rateLimit GT 0 ? rateLimit : 120/>
        <cfset APPLICATION.apiRateLimits = structNew()/>
        <cfset APPLICATION.apiPreAuthRateLimits = structNew()/>
        <cfset ensureAppSettings()/>

        <cfreturn true/>
    </cffunction>

    <cffunction name="OnRequestStart" access="public" returntype="boolean" output="false">
        <cfargument name="TargetPage" type="string" required="true"/>
        <cfset var routePath = getApiRoutePath()/>
        <cfset var requestMethod = structKeyExists(CGI, "REQUEST_METHOD") ? uCase(trim(CGI.REQUEST_METHOD & "")) : "GET"/>
        <cfset var requiredScope = ""/>

        <cfset ensureAppSettings()/>
        <cfset ensureApiRuntime()/>

        <cfset REQUEST.requestId = lCase(replace(createUUID(), "-", "", "all"))/>
        <cfset REQUEST.currentEnvironment = getCurrentEnvironment()/>
        <cfset REQUEST.currentBaseUrl = "https://roadrunners.run"/>
        <cfset REQUEST.Usuario = buildEmptyUsuario()/>
        <cfset REQUEST.apiIntegration = buildEmptyApiIntegration()/>
        <cfset REQUEST.queryDebug = []/>

        <cfset applySecurityHeaders()/>
        <cfset applyCorsHeaders()/>

        <cfif requestMethod EQ "OPTIONS">
            <cfset handleOptionsRequest()/>
        </cfif>

        <cfif isPublicDocumentRequest(routePath)>
            <cfif requestMethod NEQ "GET" AND requestMethod NEQ "HEAD">
                <cfset abortJson(405, "method_not_allowed", "Documentacao disponivel somente para leitura.")/>
            </cfif>

            <cfreturn true/>
        </cfif>

        <cfif NOT isMethodAllowed(routePath, requestMethod)>
            <cfset abortJson(405, "method_not_allowed", "Metodo nao permitido para este endpoint.")/>
        </cfif>

        <cfset requiredScope = getRequiredScope(routePath, requestMethod)/>

        <cfif NOT len(requiredScope)>
            <cfset abortJson(404, "not_found", "Endpoint nao encontrado.")/>
        </cfif>

        <cfset applyPreAuthRateLimit()/>
        <cfif createObject("component", "services.PublicApiReadPolicy").allowsAnonymous(routePath, requestMethod, getAuthorizationHeaderValue(), hasAuthorizationHeader())>
            <cfset applyGuestCalendarRateLimit()/>
            <cfreturn true/>
        </cfif>
        <cfset REQUEST.apiIntegration = buildRequestApiIntegration()/>
        <cfset applyApiClientHeader()/>
        <cfset enforceBearerAccess(requiredScope)/>
        <cfset applyRateLimit()/>
        <cfset hydrateRequestUsuario(requiredScope)/>

        <cfif isCurrentUserRoute(routePath) AND NOT isAuthenticatedUserIntegration()>
            <cfset abortJson(401, "not_authenticated", "Token de usuario valido e obrigatorio para este endpoint.")/>
        </cfif>

        <cfreturn true/>
    </cffunction>

    <cffunction name="OnError" access="public" returntype="void" output="false">
        <cfargument name="Exception" required="true"/>
        <cfargument name="EventName" type="string" required="false" default=""/>
        <cfset var requestId = structKeyExists(REQUEST, "requestId") ? REQUEST.requestId : lCase(replace(createUUID(), "-", "", "all"))/>

        <cftry>
            <cflog
                file="roadrunners-api"
                type="error"
                text="requestId=#requestId# event=#arguments.EventName# error=#arguments.Exception.message#"/>
            <cfcatch type="any">
            </cfcatch>
        </cftry>

        <cfset REQUEST.requestId = requestId/>
        <cfset applySecurityHeaders()/>
        <cfset applyCorsHeaders()/>
        <cfset abortJson(500, "internal_error", "Erro interno ao processar a requisicao.")/>
    </cffunction>

    <cffunction name="ensureAppSettings" access="private" returntype="void" output="false">
        <cfset var mobileConfigPath = expandPath("/config/mobile_auth.local.cfm")/>
        <cfset var mobileConfigVersion = fileExists(mobileConfigPath)
            ? lCase(hash(fileRead(mobileConfigPath), "SHA-256")) : "missing"/>

        <cfset var localConfigPath = expandPath("/config/api.local.cfm")/>
        <cfset var localConfigVersion = fileExists(localConfigPath)
            ? lCase(hash(fileRead(localConfigPath), "SHA-256"))
            : "missing"/>
        <cfset var shouldReload = NOT structKeyExists(APPLICATION, "apiIntegrations")
            OR NOT isStruct(APPLICATION.apiIntegrations)
            OR NOT structKeyExists(APPLICATION, "pwaPush")
            OR NOT isStruct(APPLICATION.pwaPush)
            OR NOT structKeyExists(APPLICATION,"mobileAuth")
            OR NOT isStruct(APPLICATION.mobileAuth)
            OR NOT structKeyExists(APPLICATION,"mobileAuthConfigVersion")
            OR APPLICATION.mobileAuthConfigVersion NEQ mobileConfigVersion
            OR NOT structKeyExists(APPLICATION, "apiLocalConfigVersion")
            OR APPLICATION.apiLocalConfigVersion NEQ localConfigVersion/>

        <cfif shouldReload>
            <cflock name="RoadRunnersPublicApiSettings" type="exclusive" timeout="5">
                <cfinclude template="/config/settings.cfm"/>
                <cfset APPLICATION.mobileAuthConfigVersion = mobileConfigVersion/>
                <cfset APPLICATION.apiLocalConfigVersion = localConfigVersion/>
            </cflock>
        </cfif>
    </cffunction>

    <cffunction name="ensureApiRuntime" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(APPLICATION, "apiCorsOrigins")>
            <cfset APPLICATION.apiCorsOrigins = "https://roadrunners.run,https://www.roadrunners.run,https://beta.roadrunners.run,https://dev.roadrunners.run"/>
        </cfif>

        <cfif NOT structKeyExists(APPLICATION, "apiRateLimitPerMinute") OR val(APPLICATION.apiRateLimitPerMinute) LTE 0>
            <cfset APPLICATION.apiRateLimitPerMinute = 120/>
        </cfif>

        <cfif NOT structKeyExists(APPLICATION, "apiRateLimits") OR NOT isStruct(APPLICATION.apiRateLimits)>
            <cfset APPLICATION.apiRateLimits = structNew()/>
        </cfif>

        <cfif NOT structKeyExists(APPLICATION, "apiPreAuthRateLimitPerMinute") OR val(APPLICATION.apiPreAuthRateLimitPerMinute) LTE 0>
            <cfset APPLICATION.apiPreAuthRateLimitPerMinute = 300/>
        </cfif>

        <cfif NOT structKeyExists(APPLICATION, "apiPreAuthRateLimits") OR NOT isStruct(APPLICATION.apiPreAuthRateLimits)>
            <cfset APPLICATION.apiPreAuthRateLimits = structNew()/>
        </cfif>
    </cffunction>

    <cffunction name="applySecurityHeaders" access="private" returntype="void" output="false">
        <cfheader name="Cache-Control" value="no-store, private, max-age=0"/>
        <cfheader name="Pragma" value="no-cache"/>
        <cfheader name="X-Content-Type-Options" value="nosniff"/>
        <cfheader name="Referrer-Policy" value="no-referrer"/>
        <cfheader name="X-Request-Id" value="#REQUEST.requestId#"/>
    </cffunction>

    <cffunction name="applyCorsHeaders" access="private" returntype="void" output="false">
        <cfset var origin = structKeyExists(CGI, "HTTP_ORIGIN") ? trim(CGI.HTTP_ORIGIN & "") : ""/>

        <cfif NOT len(origin)>
            <cfreturn/>
        </cfif>

        <cfif NOT listFindNoCase(APPLICATION.apiCorsOrigins, origin)>
            <cfreturn/>
        </cfif>

        <cfheader name="Access-Control-Allow-Origin" value="#origin#"/>
        <cfheader name="Access-Control-Allow-Methods" value="GET, POST, DELETE, OPTIONS"/>
        <cfheader name="Access-Control-Allow-Headers" value="Authorization, Content-Type, Idempotency-Key, X-Request-Id"/>
        <cfheader name="Access-Control-Expose-Headers" value="X-Request-Id, X-Api-Client-Id, X-Api-Error-Code, RateLimit-Limit, RateLimit-Remaining, RateLimit-Reset, Retry-After"/>
        <cfheader name="Access-Control-Max-Age" value="600"/>
        <cfheader name="Vary" value="Origin"/>
    </cffunction>

    <cffunction name="handleOptionsRequest" access="private" returntype="void" output="false">
        <cfset var origin = structKeyExists(CGI, "HTTP_ORIGIN") ? trim(CGI.HTTP_ORIGIN & "") : ""/>

        <cfif len(origin) AND NOT listFindNoCase(APPLICATION.apiCorsOrigins, origin)>
            <cfset abortJson(403, "cors_origin_denied", "Origem nao permitida.")/>
        </cfif>

        <cfheader statuscode="204" statustext="No Content"/>
        <cfcontent type="text/plain; charset=utf-8" reset="true"/>
        <cfabort/>
    </cffunction>

    <cffunction name="getApiRoutePath" access="private" returntype="string" output="false">
        <cfset var scriptName = structKeyExists(CGI, "SCRIPT_NAME") ? lCase(trim(CGI.SCRIPT_NAME & "")) : ""/>
        <cfset var versionPosition = find("/v1/", scriptName)/>

        <cfif versionPosition GT 0>
            <cfreturn mid(scriptName, versionPosition, len(scriptName) - versionPosition + 1)/>
        </cfif>

        <cfif right(scriptName, 10) EQ "/index.cfm">
            <cfreturn "/index.cfm"/>
        </cfif>

        <cfif right(scriptName, 11) EQ "/health.cfm">
            <cfreturn "/health.cfm"/>
        </cfif>

        <cfreturn scriptName/>
    </cffunction>

    <cffunction name="isPublicDocumentRequest" access="private" returntype="boolean" output="false">
        <cfargument name="routePath" type="string" required="true"/>
        <cfreturn listFindNoCase("/index.cfm,/health.cfm", arguments.routePath) GT 0/>
    </cffunction>

    <cffunction name="getRequiredScope" access="private" returntype="string" output="false">
        <cfargument name="routePath" type="string" required="true"/>
        <cfargument name="requestMethod" type="string" required="false" default="GET"/>
        <cfset var route = lCase(trim(arguments.routePath))/>

        <cfif left(route, len("/v1/result-imports/")) EQ "/v1/result-imports/">
            <cfreturn "results:submit"/>
        </cfif>

        <cfif route EQ "/v1/athletes/suggested-results.cfm" OR route EQ "/v1/athletes/mobile-profile.cfm" OR route EQ "/v1/athletes/mobile-feed.cfm">
            <cfreturn "me:read"/>
        </cfif>

        <cfif left(route, len("/v1/athletes/")) EQ "/v1/athletes/">
            <cfreturn "athletes:read_public"/>
        </cfif>

        <cfif left(route, len("/v1/events/")) EQ "/v1/events/">
            <cfreturn "events:read_public"/>
        </cfif>

        <cfif left(route, len("/v1/results/")) EQ "/v1/results/">
            <cfreturn "results:read_public"/>
        </cfif>

        <cfif left(route, len("/v1/discovery/")) EQ "/v1/discovery/">
            <cfreturn "discovery:read_public"/>
        </cfif>

        <cfif left(route, len("/v1/editorial/")) EQ "/v1/editorial/">
            <cfreturn "editorial:read_public"/>
        </cfif>

        <cfif route EQ "/v1/feed/me.cfm" OR route EQ "/v1/feed/mobile.cfm">
            <cfreturn "me:read"/>
        </cfif>

        <cfif left(route, len("/v1/feed/")) EQ "/v1/feed/">
            <cfreturn "feed:read_public"/>
        </cfif>

        <cfif left(route, len("/v1/challenges/")) EQ "/v1/challenges/">
            <cfreturn "challenges:read_public"/>
        </cfif>

        <cfif left(route, len("/v1/training/")) EQ "/v1/training/">
            <cfreturn "training:read_public"/>
        </cfif>

        <cfif left(route, len("/v1/coupons/")) EQ "/v1/coupons/">
            <cfreturn "coupons:read_public"/>
        </cfif>

        <cfif left(route, len("/v1/session/")) EQ "/v1/session/">
            <cfreturn "session:read"/>
        </cfif>

        <cfif listFind("/v1/me/profile-settings.cfm,/v1/me/profile-photo.cfm",route) AND uCase(arguments.requestMethod) EQ "POST">
            <cfreturn "profile:write"/>
        </cfif>
        <cfif route EQ "/v1/me/profile-privacy.cfm" AND uCase(arguments.requestMethod) EQ "POST">
            <cfreturn "privacy:write"/>
        </cfif>

        <cfif route EQ "/v1/me/profile-links.cfm" AND uCase(arguments.requestMethod) EQ "POST">
            <cfreturn "links:write"/>
        </cfif>
        <cfif route EQ "/v1/me/perfilrun-settings.cfm" AND uCase(arguments.requestMethod) EQ "POST">
            <cfreturn "perfilrun:write"/>
        </cfif>
        <cfif route EQ "/v1/me/perfilrun-links.cfm" AND uCase(arguments.requestMethod) EQ "POST">
            <cfreturn "perfilrun-links:write"/>
        </cfif>

        <cfif route EQ "/v1/me/event-agenda.cfm" AND uCase(arguments.requestMethod) EQ "POST"><cfreturn "agenda:write"/></cfif>

        <cfif route EQ "/v1/me/connections.cfm" AND uCase(arguments.requestMethod) EQ "POST"><cfreturn "connections:write"/></cfif>

        <cfif left(route, len("/v1/me/")) EQ "/v1/me/">
            <cfreturn "me:read"/>
        </cfif>

        <cfreturn ""/>
    </cffunction>

    <cffunction name="isMethodAllowed" access="private" returntype="boolean" output="false">
        <cfargument name="routePath" type="string" required="true"/>
        <cfargument name="requestMethod" type="string" required="true"/>
        <cfset var route = lCase(trim(arguments.routePath))/>
        <cfset var method = uCase(trim(arguments.requestMethod))/>

        <cfif route EQ "/v1/result-imports/submissions.cfm">
            <cfreturn method EQ "POST"/>
        </cfif>

        <cfif listFind("/v1/me/profile-settings.cfm,/v1/me/profile-privacy.cfm,/v1/me/profile-links.cfm,/v1/me/perfilrun-settings.cfm,/v1/me/perfilrun-links.cfm,/v1/me/profile-photo.cfm,/v1/me/event-agenda.cfm,/v1/me/connections.cfm",route)>
            <cfreturn method EQ "GET" OR method EQ "POST"/>
        </cfif>
        <cfif route EQ "/v1/me/sessions.cfm">
            <cfreturn method EQ "GET" OR method EQ "DELETE"/>
        </cfif>
        <cfreturn method EQ "GET"/>
    </cffunction>

    <cffunction name="isCurrentUserRoute" access="private" returntype="boolean" output="false">
        <cfargument name="routePath" type="string" required="true"/>
        <cfset var route = lCase(trim(arguments.routePath))/>

        <cfreturn left(route, len("/v1/me/")) EQ "/v1/me/"
            OR left(route, len("/v1/session/")) EQ "/v1/session/"
            OR route EQ "/v1/feed/me.cfm"
            OR route EQ "/v1/athletes/suggested-results.cfm"
            OR route EQ "/v1/athletes/mobile-profile.cfm"
            OR route EQ "/v1/athletes/mobile-feed.cfm"
            OR route EQ "/v1/feed/mobile.cfm"/>
    </cffunction>

    <cffunction name="buildEmptyApiIntegration" access="private" returntype="struct" output="false">
        <cfreturn {
            "authenticated" = false,
            "clientId" = "",
            "source" = "",
            "userId" = 0,
            "scopes" = [],
            "tokenHash" = "",
            "rateLimitPerMinute" = 0,
            "timerCode" = "",
            "allowedResultHosts" = [],
            "allowedResultPathPrefixes" = [],
            "allowedPublicResultHosts" = [],
            "allowedPublicResultPathPrefixes" = []
        }/>
    </cffunction>

    <cffunction name="buildRequestApiIntegration" access="private" returntype="struct" output="false">
        <cfset var apiIntegration = buildEmptyApiIntegration()/>
        <cfset var authorizationHeader = getAuthorizationHeaderValue()/>
        <cfset var bearerToken = ""/>
        <cfset var bearerTokenHash = ""/>
        <cfset var tokenConfig = {}/>
        <cfset var configuredTokens = []/>

        <cfif left(lCase(authorizationHeader), 7) NEQ "bearer ">
            <cfreturn apiIntegration/>
        </cfif>

        <cfset bearerToken = trim(mid(authorizationHeader, 8, len(authorizationHeader)))/>

        <cfif NOT len(bearerToken)>
            <cfreturn apiIntegration/>
        </cfif>

        <cfset bearerTokenHash = lCase(hash(bearerToken, "SHA-256"))/>

        <cfif structKeyExists(APPLICATION.apiIntegrations, "tokens") AND isArray(APPLICATION.apiIntegrations.tokens)>
            <cfset configuredTokens = APPLICATION.apiIntegrations.tokens/>

            <cfloop array="#configuredTokens#" index="tokenConfig">
                <cfif isStruct(tokenConfig)
                    AND structKeyExists(tokenConfig, "tokenHash")
                    AND lCase(trim(tokenConfig.tokenHash & "")) EQ bearerTokenHash>
                    <cfset apiIntegration.authenticated = true/>
                    <cfset apiIntegration.clientId = structKeyExists(tokenConfig, "clientId") ? trim(tokenConfig.clientId & "") : "integration"/>
                    <cfset apiIntegration.source = "config"/>
                    <cfset apiIntegration.scopes = structKeyExists(tokenConfig, "scopes") AND isArray(tokenConfig.scopes)
                        ? duplicate(tokenConfig.scopes)
                        : []/>
                    <cfset apiIntegration.tokenHash = bearerTokenHash/>
                    <cfset apiIntegration.rateLimitPerMinute = structKeyExists(tokenConfig, "rateLimitPerMinute")
                        ? val(tokenConfig.rateLimitPerMinute)
                        : 0/>
                    <cfset apiIntegration.timerCode = structKeyExists(tokenConfig, "timerCode")
                        ? trim(tokenConfig.timerCode & "")
                        : ""/>
                    <cfset apiIntegration.allowedResultHosts = structKeyExists(tokenConfig, "allowedResultHosts")
                        AND isArray(tokenConfig.allowedResultHosts)
                        ? duplicate(tokenConfig.allowedResultHosts)
                        : []/>
                    <cfset apiIntegration.allowedResultPathPrefixes = structKeyExists(tokenConfig, "allowedResultPathPrefixes")
                        AND isArray(tokenConfig.allowedResultPathPrefixes)
                        ? duplicate(tokenConfig.allowedResultPathPrefixes)
                        : []/>
                    <cfset apiIntegration.allowedPublicResultHosts = structKeyExists(tokenConfig, "allowedPublicResultHosts")
                        AND isArray(tokenConfig.allowedPublicResultHosts)
                        ? duplicate(tokenConfig.allowedPublicResultHosts)
                        : []/>
                    <cfset apiIntegration.allowedPublicResultPathPrefixes = structKeyExists(tokenConfig, "allowedPublicResultPathPrefixes")
                        AND isArray(tokenConfig.allowedPublicResultPathPrefixes)
                        ? duplicate(tokenConfig.allowedPublicResultPathPrefixes)
                        : []/>
                    <cfreturn apiIntegration/>
                </cfif>
            </cfloop>
        </cfif>

        <cfset apiIntegration = buildUserApiIntegration(bearerTokenHash)/>
        <cfif NOT apiIntegration.authenticated>
            <cfset apiIntegration = buildMobileApiIntegration(bearerTokenHash)/>
        </cfif>
        <cfreturn apiIntegration/>
    </cffunction>

    <cffunction name="buildMobileApiIntegration" access="private" returntype="struct" output="false">
        <cfargument name="tokenHash" type="string" required="true"/>
        <cfset var result = buildEmptyApiIntegration()/>
        <cfset var resolved = createObject("component","services.MobileApiIdentityService").init(
            createObject("component","repositories.MobileAuthRepository").init("runnerhub"),APPLICATION.mobileAuth).resolve(
                arguments.tokenHash,
                structKeyExists(CGI,"REMOTE_ADDR") ? CGI.REMOTE_ADDR & "" : "",
                structKeyExists(CGI,"HTTP_USER_AGENT") ? CGI.HTTP_USER_AGENT & "" : "")/>
        <cfif resolved.authenticated><cfset structAppend(result,resolved,true)/></cfif>
        <cfreturn result/>
    </cffunction>

    <cffunction name="buildUserApiIntegration" access="private" returntype="struct" output="false">
        <cfargument name="tokenHash" type="string" required="true"/>
        <cfset var apiIntegration = buildEmptyApiIntegration()/>
        <cfset var repository = ""/>
        <cfset var tokenRecord = {}/>

        <cftry>
            <cfset repository = createObject("component", "repositories.ApiTokenRepository").init("runnerhub")/>
            <cfset tokenRecord = repository.findActiveByTokenHash(arguments.tokenHash)/>

            <cfif isStruct(tokenRecord) AND structKeyExists(tokenRecord, "found") AND tokenRecord.found>
                <cfset apiIntegration.authenticated = true/>
                <cfset apiIntegration.clientId = tokenRecord.clientId/>
                <cfset apiIntegration.source = "user"/>
                <cfset apiIntegration.userId = tokenRecord.userId/>
                <cfset apiIntegration.scopes = tokenRecord.scopes/>
                <cfset apiIntegration.tokenHash = arguments.tokenHash/>

                <cftry>
                    <cfset repository.markUsed(
                        tokenRecord.id,
                        structKeyExists(CGI, "REMOTE_ADDR") ? trim(CGI.REMOTE_ADDR & "") : "",
                        structKeyExists(CGI, "HTTP_USER_AGENT") ? trim(CGI.HTTP_USER_AGENT & "") : ""
                    )/>
                    <cfcatch type="any">
                        <cflog file="roadrunners-api" type="warning" text="Falha ao atualizar uso do token #tokenRecord.id#: #cfcatch.message#"/>
                    </cfcatch>
                </cftry>
            </cfif>

            <cfcatch type="any">
                <cflog file="roadrunners-api" type="error" text="Falha ao validar token de usuario: #cfcatch.message#"/>
                <cfreturn buildEmptyApiIntegration()/>
            </cfcatch>
        </cftry>

        <cfreturn apiIntegration/>
    </cffunction>

    <cffunction name="hasAuthorizationHeader" access="private" returntype="boolean" output="false">
        <cfset var requestData = getHttpRequestData(false)/>
        <cfreturn len(getAuthorizationHeaderValue()) GT 0 OR (structKeyExists(requestData, "headers") AND structKeyExists(requestData.headers, "Authorization"))/>
    </cffunction>

    <cffunction name="getAuthorizationHeaderValue" access="private" returntype="string" output="false">
        <cfset var requestData = {}/>
        <cfset var headerName = ""/>

        <cfif structKeyExists(CGI, "HTTP_AUTHORIZATION") AND len(trim(CGI.HTTP_AUTHORIZATION & ""))>
            <cfreturn trim(CGI.HTTP_AUTHORIZATION & "")/>
        </cfif>

        <cfif structKeyExists(CGI, "REDIRECT_HTTP_AUTHORIZATION") AND len(trim(CGI.REDIRECT_HTTP_AUTHORIZATION & ""))>
            <cfreturn trim(CGI.REDIRECT_HTTP_AUTHORIZATION & "")/>
        </cfif>

        <cftry>
            <cfset requestData = getHttpRequestData()/>
            <cfcatch type="any">
                <cfset requestData = {}/>
            </cfcatch>
        </cftry>

        <cfif isStruct(requestData) AND structKeyExists(requestData, "headers") AND isStruct(requestData.headers)>
            <cfloop collection="#requestData.headers#" item="headerName">
                <cfif lCase(trim(headerName)) EQ "authorization">
                    <cfreturn trim(requestData.headers[headerName] & "")/>
                </cfif>
            </cfloop>
        </cfif>

        <cfreturn ""/>
    </cffunction>

    <cffunction name="enforceBearerAccess" access="private" returntype="void" output="false">
        <cfargument name="requiredScope" type="string" required="true"/>
        <cfset var authorizationHeader = getAuthorizationHeaderValue()/>

        <cfif NOT len(authorizationHeader)>
            <cfset abortJson(401, "missing_token", "Authorization Bearer obrigatorio.")/>
        </cfif>

        <cfif NOT REQUEST.apiIntegration.authenticated>
            <cfset abortJson(401, "invalid_token", "Credencial de integracao invalida.")/>
        </cfif>

        <cfif NOT apiIntegrationHasScope(REQUEST.apiIntegration, arguments.requiredScope)>
            <cfset abortJson(403, "insufficient_scope", "Credencial sem o escopo necessario.")/>
        </cfif>
    </cffunction>

    <cffunction name="apiIntegrationHasScope" access="private" returntype="boolean" output="false">
        <cfargument name="apiIntegration" type="struct" required="true"/>
        <cfargument name="scope" type="string" required="true"/>
        <cfset var scopeValue = ""/>

        <cfif NOT structKeyExists(arguments.apiIntegration, "authenticated")
            OR NOT arguments.apiIntegration.authenticated
            OR NOT structKeyExists(arguments.apiIntegration, "scopes")
            OR NOT isArray(arguments.apiIntegration.scopes)>
            <cfreturn false/>
        </cfif>

        <cfloop array="#arguments.apiIntegration.scopes#" index="scopeValue">
            <cfif trim(scopeValue & "") EQ "*"
                OR lCase(trim(scopeValue & "")) EQ lCase(trim(arguments.scope))>
                <cfreturn true/>
            </cfif>
        </cfloop>

        <cfreturn false/>
    </cffunction>

    <cffunction name="hydrateRequestUsuario" access="private" returntype="void" output="false">
        <cfargument name="requiredScope" type="string" required="true"/>
        <cfset var qUsuarioCore = ""/>

        <cfif NOT listFindNoCase("user,mobile",REQUEST.apiIntegration.source)
            OR val(REQUEST.apiIntegration.userId) LTE 0
            OR NOT (
                arguments.requiredScope EQ "me:read"
                OR arguments.requiredScope EQ "links:write"
                OR arguments.requiredScope EQ "perfilrun:write"
                OR arguments.requiredScope EQ "perfilrun-links:write"
                OR arguments.requiredScope EQ "profile:write"
                OR arguments.requiredScope EQ "connections:write"
                OR arguments.requiredScope EQ "agenda:write"
                OR arguments.requiredScope EQ "privacy:write"
                OR arguments.requiredScope EQ "session:read"
                OR apiIntegrationHasScope(REQUEST.apiIntegration, "me:read")
            )>
            <cfreturn/>
        </cfif>

        <cftry>
            <cfset qUsuarioCore = getUsuarioCoreById(REQUEST.apiIntegration.userId)/>

            <cfif qUsuarioCore.recordCount>
                <cfset REQUEST.Usuario = createObject("component", "includes.models.Usuario").init(QueryGetRow(qUsuarioCore, 1))/>
                <cfset REQUEST.Usuario.logado = true/>
            </cfif>

            <cfcatch type="any">
                <cflog file="roadrunners-api" type="error" text="Falha ao carregar usuario do token: #cfcatch.message#"/>
            </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getUsuarioCoreById" access="private" returntype="query" output="false">
        <cfargument name="userId" type="numeric" required="true"/>
        <cfset var schemaQuery = queryExecute(
            "SELECT to_regclass('public.tb_usuarios_gestao') IS NOT NULL AS has_user_state,
                    to_regclass('public.tb_paginas_gestao') IS NOT NULL AS has_page_state",
            {},
            { "datasource" = "runnerhub" }
        )/>
        <cfset var hasManagementState = booleanValue(schemaQuery.has_user_state[1]) AND booleanValue(schemaQuery.has_page_state[1])/>
        <cfset var sql = "
            SELECT
                usr.id,
                usr.email,
                usr.is_admin,
                usr.is_partner,
                usr.is_dev,
                usr.strava_id,
                usr.name,
                usr.aka,
                usr.fonte_lead,
                usr.ano_nascimento,
                usr.assessoria,
                coalesce(:assetsBaseUrl || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') AS imagem_usuario,
                pag.tag,
                pag.id_pagina,
                coalesce(pag.nome, usr.name) AS nome,
                pag.verificado,
                pag.verificado AS beta_verificado,
                pag.cidade,
                pag.uf,
                usr.estado,
                usr.pais,
                pag.perfil_publico,
                pag.instagram,
                pag.instagram_publico,
                pag.youtube,
                pag.youtube_publico,
                pag.tiktok,
                pag.tiktok_publico,
                pag.website,
                pag.website_publico,
                pag.loja,
                pag.loja_publico,
                pag.whatsapp,
                pag.whatsapp_publico,
                pag.descricao,
                usr.inscricao_366,
                (
                    SELECT produto
                    FROM desafios
                    WHERE desafio = 'desafio365'
                      AND id_usuario = usr.id
                      AND status = 'C'
                    LIMIT 1
                ) AS inscricao_365
            FROM tb_usuarios usr
            INNER JOIN tb_paginas_usuarios pgusr ON usr.id = pgusr.id_usuario
            INNER JOIN tb_paginas pag ON pag.id_pagina = pgusr.id_pagina
        "/>

        <cfif hasManagementState>
            <cfset sql = sql & "
                LEFT JOIN tb_usuarios_gestao usrgest ON usrgest.id_usuario = usr.id
                LEFT JOIN tb_paginas_gestao paggest ON paggest.id_pagina = pag.id_pagina
            "/>
        </cfif>

        <cfset sql = sql & " WHERE usr.id = :userId "/>

        <cfif hasManagementState>
            <cfset sql = sql & "
                AND coalesce(usrgest.ativo, true) = true
                AND coalesce(usrgest.excluido, false) = false
                AND coalesce(paggest.ativo, true) = true
                AND coalesce(paggest.excluido, false) = false
            "/>
        </cfif>

        <cfset sql = sql & " ORDER BY pag.id_pagina LIMIT 1 "/>

        <cfreturn queryExecute(
            sql,
            {
                "userId" = { "value" = int(arguments.userId), "cfsqltype" = "cf_sql_integer" },
                "assetsBaseUrl" = { "value" = "https://roadrunners.run/assets/paginas/", "cfsqltype" = "cf_sql_varchar" }
            },
            { "datasource" = "runnerhub" }
        )/>
    </cffunction>

    <cffunction name="isAuthenticatedUserIntegration" access="private" returntype="boolean" output="false">
        <cfreturn REQUEST.apiIntegration.authenticated
            AND listFindNoCase("user,mobile",REQUEST.apiIntegration.source) GT 0
            AND isObject(REQUEST.Usuario)
            AND structKeyExists(REQUEST.Usuario, "logado")
            AND REQUEST.Usuario.logado/>
    </cffunction>

    <cffunction name="applyRateLimit" access="private" returntype="void" output="false">
        <cfset var configuredLimit = structKeyExists(REQUEST.apiIntegration, "rateLimitPerMinute")
            ? val(REQUEST.apiIntegration.rateLimitPerMinute)
            : 0/>
        <cfset var rateLimit = configuredLimit GT 0
            ? min(10000, max(1, int(configuredLimit)))
            : APPLICATION.apiRateLimitPerMinute/>
        <cfset var clientId = safeApiClientId(REQUEST.apiIntegration.clientId)/>
        <cfset var result = consumeRateLimit(
            "apiRateLimits",
            REQUEST.apiIntegration.tokenHash,
            rateLimit
        )/>

        <cfset applyRateLimitHeaders(result)/>

        <cfif result.exceeded>
            <cflog
                file="roadrunners-api"
                type="warning"
                text="requestId=#REQUEST.requestId# clientId=#clientId# token rate limit exceeded"/>
            <cfheader name="Retry-After" value="#result.retryAfter#"/>
            <cfset abortJson(429, "rate_limit_exceeded", "Limite de requisicoes excedido.")/>
        </cfif>
    </cffunction>

    <cffunction name="applyApiClientHeader" access="private" returntype="void" output="false">
        <cfset var clientId = ""/>

        <cfif NOT structKeyExists(REQUEST, "apiIntegration")
            OR NOT isStruct(REQUEST.apiIntegration)
            OR NOT structKeyExists(REQUEST.apiIntegration, "authenticated")
            OR NOT REQUEST.apiIntegration.authenticated>
            <cfreturn/>
        </cfif>

        <cfset clientId = safeApiClientId(REQUEST.apiIntegration.clientId)/>

        <cfif len(clientId)>
            <cfheader name="X-Api-Client-Id" value="#clientId#"/>
        </cfif>
    </cffunction>

    <cffunction name="safeApiClientId" access="private" returntype="string" output="false">
        <cfargument name="rawValue" required="false" default=""/>
        <cfset var clientId = reReplace(trim(arguments.rawValue & ""), "[^a-zA-Z0-9._:-]", "-", "all")/>

        <cfreturn left(clientId, 80)/>
    </cffunction>

    <cffunction name="applyPreAuthRateLimit" access="private" returntype="void" output="false">
        <cfset var clientAddress = getClientAddress()/>
        <cfset var rateLimitKey = lCase(hash(clientAddress, "SHA-256"))/>
        <cfset var result = consumeRateLimit(
            "apiPreAuthRateLimits",
            rateLimitKey,
            APPLICATION.apiPreAuthRateLimitPerMinute
        )/>

        <cfif result.exceeded>
            <cflog
                file="roadrunners-api"
                type="warning"
                text="requestId=#REQUEST.requestId# clientAddress=#clientAddress# pre-auth rate limit exceeded"/>
            <cfset applyRateLimitHeaders(result)/>
            <cfheader name="Retry-After" value="#result.retryAfter#"/>
            <cfset abortJson(429, "pre_auth_rate_limit_exceeded", "Limite de tentativas excedido.")/>
        </cfif>
    </cffunction>

    <cffunction name="applyGuestCalendarRateLimit" access="private" returntype="void" output="false">
        <cfset var result = consumeRateLimit("apiGuestCalendarRateLimits", lCase(hash(getClientAddress(), "SHA-256")), 30)/>
        <cfset applyRateLimitHeaders(result)/>
        <cfif result.exceeded>
            <cfheader name="Retry-After" value="#result.retryAfter#"/>
            <cfset abortJson(429, "rate_limit_exceeded", "Limite de consultas publicas excedido.")/>
        </cfif>
    </cffunction>

    <cffunction name="consumeRateLimit" access="private" returntype="struct" output="false">
        <cfargument name="bucketCollection" type="string" required="true"/>
        <cfargument name="bucketKey" type="string" required="true"/>
        <cfargument name="limit" type="numeric" required="true"/>
        <cfset var nowValue = now()/>
        <cfset var safeLimit = min(10000, max(1, int(arguments.limit)))/>
        <cfset var retryAfter = 60/>
        <cfset var requestCount = 1/>
        <cfset var exceeded = false/>
        <cfset var cleanupKey = arguments.bucketCollection & "LastCleanupAt"/>
        <cfset var currentKey = ""/>
        <cfset var staleKeys = []/>

        <cflock name="RoadRunnersPublicApiRateLimit" type="exclusive" timeout="3">
            <cfif NOT structKeyExists(APPLICATION, arguments.bucketCollection)
                OR NOT isStruct(APPLICATION[arguments.bucketCollection])>
                <cfset APPLICATION[arguments.bucketCollection] = structNew()/>
            </cfif>

            <cfif NOT structKeyExists(APPLICATION[arguments.bucketCollection], arguments.bucketKey)
                OR dateDiff("s", APPLICATION[arguments.bucketCollection][arguments.bucketKey].windowStartedAt, nowValue) GTE 60>
                <cfset APPLICATION[arguments.bucketCollection][arguments.bucketKey] = {
                    "windowStartedAt" = nowValue,
                    "count" = 1
                }/>
            <cfelse>
                <cfset APPLICATION[arguments.bucketCollection][arguments.bucketKey].count =
                    APPLICATION[arguments.bucketCollection][arguments.bucketKey].count + 1/>
                <cfset requestCount = APPLICATION[arguments.bucketCollection][arguments.bucketKey].count/>
                <cfset retryAfter = max(
                    1,
                    60 - dateDiff(
                        "s",
                        APPLICATION[arguments.bucketCollection][arguments.bucketKey].windowStartedAt,
                        nowValue
                    )
                )/>
            </cfif>

            <cfset exceeded = requestCount GT safeLimit/>

            <cfif NOT structKeyExists(APPLICATION, cleanupKey)
                OR dateDiff("s", APPLICATION[cleanupKey], nowValue) GTE 300>
                <cfloop collection="#APPLICATION[arguments.bucketCollection]#" item="currentKey">
                    <cfif dateDiff(
                        "s",
                        APPLICATION[arguments.bucketCollection][currentKey].windowStartedAt,
                        nowValue
                    ) GTE 300>
                        <cfset arrayAppend(staleKeys, currentKey)/>
                    </cfif>
                </cfloop>

                <cfloop array="#staleKeys#" index="currentKey">
                    <cfset structDelete(APPLICATION[arguments.bucketCollection], currentKey)/>
                </cfloop>

                <cfset APPLICATION[cleanupKey] = nowValue/>
            </cfif>
        </cflock>

        <cfreturn {
            "limit" = safeLimit,
            "remaining" = max(0, safeLimit - requestCount),
            "retryAfter" = retryAfter,
            "exceeded" = exceeded
        }/>
    </cffunction>

    <cffunction name="applyRateLimitHeaders" access="private" returntype="void" output="false">
        <cfargument name="result" type="struct" required="true"/>
        <cfheader name="RateLimit-Limit" value="#arguments.result.limit#"/>
        <cfheader name="RateLimit-Remaining" value="#arguments.result.remaining#"/>
        <cfheader name="RateLimit-Reset" value="#arguments.result.retryAfter#"/>
    </cffunction>

    <cffunction name="getClientAddress" access="private" returntype="string" output="false">
        <cfset var clientAddress = ""/>

        <cfif structKeyExists(CGI, "REMOTE_ADDR") AND len(trim(CGI.REMOTE_ADDR & ""))>
            <cfset clientAddress = trim(CGI.REMOTE_ADDR & "")/>
        <cfelse>
            <cfset clientAddress = "unknown"/>
        </cfif>

        <cfreturn left(clientAddress, 64)/>
    </cffunction>

    <cffunction name="getCurrentEnvironment" access="private" returntype="string" output="false">
        <cfset var host = structKeyExists(CGI, "HTTP_HOST") ? lCase(trim(CGI.HTTP_HOST & "")) : ""/>

        <cfif host CONTAINS "dev.">
            <cfreturn "dev"/>
        </cfif>

        <cfif host CONTAINS "beta.">
            <cfreturn "beta"/>
        </cfif>

        <cfreturn "prod"/>
    </cffunction>

    <cffunction name="buildEmptyUsuario" access="private" returntype="any" output="false">
        <cfreturn createObject("component", "includes.models.Usuario")/>
    </cffunction>

    <cffunction name="booleanValue" access="private" returntype="boolean" output="false">
        <cfargument name="rawValue" required="false" default="false"/>

        <cfif isBoolean(arguments.rawValue)>
            <cfreturn arguments.rawValue/>
        </cfif>

        <cfif isNumeric(arguments.rawValue)>
            <cfreturn val(arguments.rawValue) GT 0/>
        </cfif>

        <cfreturn listFindNoCase("1,true,yes,on,sim,s", trim(arguments.rawValue & "")) GT 0/>
    </cffunction>

    <cffunction name="abortJson" access="private" returntype="void" output="false">
        <cfargument name="statusCode" type="numeric" required="true"/>
        <cfargument name="status" type="string" required="true"/>
        <cfargument name="message" type="string" required="true"/>

        <cfheader statuscode="#arguments.statusCode#" statustext=""/>
        <cfheader name="X-Api-Error-Code" value="#reReplace(arguments.status, '[^a-zA-Z0-9._:-]', '-', 'all')#"/>
        <cfcontent type="application/json; charset=utf-8" reset="true"/>
        <cfoutput>#serializeJSON({
            "success" = false,
            "status" = arguments.status,
            "message" = arguments.message,
            "requestId" = structKeyExists(REQUEST, "requestId") ? REQUEST.requestId : ""
        })#</cfoutput>
        <cfabort/>
    </cffunction>

</cfcomponent>
