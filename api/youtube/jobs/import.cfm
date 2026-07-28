<cfsetting showdebugoutput="false" />
<cfparam name="URL.channel" default="" />
<cfparam name="URL.maxResults" default="" />
<cfparam name="URL.pageToken" default="" />
<cfparam name="URL.jobToken" default="" />
<cfparam name="URL.maxPages" default="3" />
<cfparam name="URL.dryRun" default="true" />
<cfscript>
    function readEnvFileValue(required string filePath, required string keyName) {
        var rawLine = "";
        var separatorPosition = 0;
        var parsedKey = "";
        var parsedValue = "";

        if (!len(trim(arguments.filePath)) OR !fileExists(arguments.filePath)) {
            return "";
        }

        try {
            for (rawLine in listToArray(fileRead(arguments.filePath, "utf-8"), chr(10))) {
                rawLine = trim(reReplace(rawLine, chr(13), "", "all"));
                if (!len(rawLine) OR left(rawLine, 1) EQ chr(35)) {
                    continue;
                }
                separatorPosition = find("=", rawLine);
                if (separatorPosition LTE 1) {
                    continue;
                }
                parsedKey = trim(left(rawLine, separatorPosition - 1));
                if (parsedKey EQ arguments.keyName) {
                    parsedValue = trim(mid(rawLine, separatorPosition + 1, len(rawLine)));
                    if (
                        len(parsedValue) GTE 2
                        AND (
                            (left(parsedValue, 1) EQ chr(34) AND right(parsedValue, 1) EQ chr(34))
                            OR (left(parsedValue, 1) EQ "'" AND right(parsedValue, 1) EQ "'")
                        )
                    ) {
                        parsedValue = mid(parsedValue, 2, len(parsedValue) - 2);
                    }
                    return trim(parsedValue);
                }
            }
        } catch (any ignoredEnvFileError) {
            return "";
        }

        return "";
    }

    function readYoutubeApiKey() {
        var businessLocalConfig = {};
        var localConfigPath = expandPath("/config/business.local.cfm");
        var configuredKey = "";
        var environmentKey = "";
        var legacyEnvPaths = [
            "/var/www/runnerhub.run/jobs/runnerhub-jobs.env",
            expandPath("/jobs/runnerhub-jobs.env")
        ];
        var legacyEnvPath = "";
        var legacyKey = "";

        if (fileExists(localConfigPath)) {
            include "../../../config/business.local.cfm";
        }
        configuredKey = structKeyExists(businessLocalConfig, "youtubeApiKey")
            ? trim(businessLocalConfig.youtubeApiKey & "")
            : "";
        if (reFind("^AIza[0-9A-Za-z_-]{35}$", configuredKey) EQ 1) {
            return {value=configuredKey, source="config/business.local.cfm"};
        }

        environmentKey = createObject("java", "java.lang.System").getenv("RUNNERHUB_YOUTUBE_API_KEY");
        environmentKey = isNull(environmentKey) ? "" : trim(environmentKey & "");
        if (!len(environmentKey)
            AND structKeyExists(SERVER, "system")
            AND structKeyExists(SERVER.system, "environment")
            AND structKeyExists(SERVER.system.environment, "RUNNERHUB_YOUTUBE_API_KEY")) {
            environmentKey = trim(SERVER.system.environment.RUNNERHUB_YOUTUBE_API_KEY & "");
        }
        if (reFind("^AIza[0-9A-Za-z_-]{35}$", environmentKey) EQ 1) {
            return {value=environmentKey, source="RUNNERHUB_YOUTUBE_API_KEY"};
        }

        for (legacyEnvPath in legacyEnvPaths) {
            legacyKey = readEnvFileValue(legacyEnvPath, "RUNNERHUB_YOUTUBE_API_KEY");
            if (reFind("^AIza[0-9A-Za-z_-]{35}$", legacyKey) EQ 1) {
                return {value=legacyKey, source=legacyEnvPath};
            }
        }

        return {
            value = configuredKey,
            source = len(configuredKey) ? "config/business.local.cfm (invalida)" : "not-configured"
        };
    }

    function readYoutubeJobToken() {
        var businessLocalConfig = {};
        var localConfigPath = expandPath("/config/business.local.cfm");
        if (fileExists(localConfigPath)) {
            include "../../../config/business.local.cfm";
        }
        if (structKeyExists(businessLocalConfig, "cronSecrets") && isStruct(businessLocalConfig.cronSecrets)) {
            if (structKeyExists(businessLocalConfig.cronSecrets, "business_youtube")
                && len(trim(businessLocalConfig.cronSecrets.business_youtube & ""))) {
                return trim(businessLocalConfig.cronSecrets.business_youtube & "");
            }
            if (structKeyExists(businessLocalConfig.cronSecrets, "runnerhub_youtube")) {
                return trim(businessLocalConfig.cronSecrets.runnerhub_youtube & "");
            }
        }
        return "";
    }

    function getAuthorizationHeader() {
        var requestData = {};

        if (structKeyExists(CGI, "http_authorization") AND len(trim(CGI.http_authorization))) {
            return trim(CGI.http_authorization);
        }

        requestData = getHttpRequestData(false);

        if (
            structKeyExists(requestData, "headers")
            AND isStruct(requestData.headers)
            AND structKeyExists(requestData.headers, "Authorization")
            AND len(trim(requestData.headers.Authorization))
        ) {
            return trim(requestData.headers.Authorization);
        }

        return "";
    }

    function getBearerToken(required string authorizationHeader) {
        var normalizedHeader = trim(arguments.authorizationHeader);

        if (reFindNoCase("^Bearer\s+.+$", normalizedHeader)) {
            return reReplaceNoCase(normalizedHeader, "^Bearer\s+", "", "one");
        }

        return "";
    }

    function getApiKeyHeader() {
        var requestData = {};

        if (structKeyExists(CGI, "http_x_api_key") AND len(trim(CGI.http_x_api_key))) {
            return trim(CGI.http_x_api_key);
        }

        requestData = getHttpRequestData(false);
        if (
            structKeyExists(requestData, "headers")
            AND isStruct(requestData.headers)
            AND structKeyExists(requestData.headers, "X-API-Key")
            AND len(trim(requestData.headers["X-API-Key"]))
        ) {
            return trim(requestData.headers["X-API-Key"]);
        }

        return "";
    }

    function getRequestHeader(required string headerName) {
        var requestData = getHttpRequestData(false);
        var cgiKey = "http_" & lCase(reReplace(arguments.headerName, "-", "_", "all"));

        if (structKeyExists(CGI, cgiKey) AND len(trim(CGI[cgiKey] & ""))) {
            return trim(CGI[cgiKey] & "");
        }
        if (
            structKeyExists(requestData, "headers")
            AND isStruct(requestData.headers)
            AND structKeyExists(requestData.headers, arguments.headerName)
            AND len(trim(requestData.headers[arguments.headerName] & ""))
        ) {
            return trim(requestData.headers[arguments.headerName] & "");
        }
        return "";
    }

    function hasValidHmacSignature(
        required string secret,
        required string rawBody,
        required string timestampHeader,
        required string signatureHeader
    ) {
        var signedAt = "";
        var expectedSignature = "";

        if (
            !len(trim(arguments.secret))
            OR !len(trim(arguments.timestampHeader))
            OR !reFindNoCase("^[a-f0-9]{64}$", trim(arguments.signatureHeader))
        ) {
            return false;
        }

        try {
            signedAt = parseDateTime(trim(arguments.timestampHeader));
            if (abs(dateDiff("s", signedAt, now())) GT 300) {
                return false;
            }
        } catch (any invalidTimestamp) {
            return false;
        }

        expectedSignature = lCase(hmac(
            trim(arguments.timestampHeader) & "." & arguments.rawBody,
            arguments.secret,
            "HmacSHA256"
        ));
        return hash(expectedSignature, "SHA-256") EQ hash(lCase(trim(arguments.signatureHeader)), "SHA-256");
    }

    function requestPrefersHtml() {
        if (!structKeyExists(CGI, "http_accept") OR !len(trim(CGI.http_accept))) {
            return true;
        }

        return findNoCase("text/html", CGI.http_accept) GT 0;
    }

    function jsonAbort(required numeric statusCode, required struct payload) {
        var statusText = "OK";

        if (arguments.statusCode EQ 400) {
            statusText = "Bad Request";
        } else if (arguments.statusCode EQ 401) {
            statusText = "Unauthorized";
        } else if (arguments.statusCode EQ 404) {
            statusText = "Not Found";
        } else if (arguments.statusCode EQ 405) {
            statusText = "Method Not Allowed";
        } else if (arguments.statusCode GTE 500) {
            statusText = "Internal Server Error";
        }

        cfheader(statuscode=arguments.statusCode, statustext=statusText);
        cfcontent(type="application/json; charset=utf-8", reset="true");
        writeOutput(serializeJSON(arguments.payload));
        abort;
    }

    function asBoolean(required any value) {
        if (isBoolean(arguments.value)) {
            return arguments.value;
        }

        return listFindNoCase("true,t,1,yes,on", trim(arguments.value & "")) GT 0;
    }

    function looksLikeGoogleApiKey(required string value) {
        return reFind("^AIza[0-9A-Za-z_-]{35}$", trim(arguments.value)) EQ 1;
    }
</cfscript>

<cfif uCase(trim(CGI.request_method & "")) NEQ "POST">
    <cfheader name="Allow" value="POST" />
    <cfset jsonAbort(405, {success=false, status="method_not_allowed", message="Use POST com corpo JSON."}) />
</cfif>

<cfset VARIABLES.requestPayload = {} />
<cftry>
    <cfset VARIABLES.requestData = getHttpRequestData() />
    <cfset VARIABLES.requestBody = structKeyExists(VARIABLES.requestData, "content")
        ? (isBinary(VARIABLES.requestData.content) ? charsetEncode(VARIABLES.requestData.content, "utf-8") : VARIABLES.requestData.content & "")
        : "" />
    <cfif len(trim(VARIABLES.requestBody))>
        <cfset VARIABLES.requestPayload = deserializeJSON(VARIABLES.requestBody) />
    </cfif>
    <cfcatch type="any">
        <cfset jsonAbort(400, {success=false, status="invalid_json", message="O corpo da requisicao nao contem JSON valido."}) />
    </cfcatch>
</cftry>
<cfif NOT isStruct(VARIABLES.requestPayload)>
    <cfset jsonAbort(400, {success=false, status="validation_error", message="O corpo JSON deve ser um objeto."}) />
</cfif>
<cfif structKeyExists(VARIABLES.requestPayload, "channel")><cfset URL.channel = trim(VARIABLES.requestPayload.channel & "") /></cfif>
<cfif structKeyExists(VARIABLES.requestPayload, "maxResults")><cfset URL.maxResults = trim(VARIABLES.requestPayload.maxResults & "") /></cfif>
<cfif structKeyExists(VARIABLES.requestPayload, "pageToken")><cfset URL.pageToken = trim(VARIABLES.requestPayload.pageToken & "") /></cfif>
<cfif structKeyExists(VARIABLES.requestPayload, "maxPages")><cfset URL.maxPages = trim(VARIABLES.requestPayload.maxPages & "") /></cfif>
<cfif structKeyExists(VARIABLES.requestPayload, "dryRun")><cfset URL.dryRun = VARIABLES.requestPayload.dryRun /></cfif>

<cfset VARIABLES.jobToken = readYoutubeJobToken() />
<cfset VARIABLES.authorizationHeader = getAuthorizationHeader() />
<cfset VARIABLES.bearerToken = getBearerToken(VARIABLES.authorizationHeader) />
<cfset VARIABLES.apiKeyHeader = getApiKeyHeader() />
<cfset VARIABLES.presentedJobToken = len(trim(VARIABLES.apiKeyHeader))
    ? trim(VARIABLES.apiKeyHeader)
    : trim(VARIABLES.bearerToken) />
<cfset VARIABLES.hmacTimestamp = getRequestHeader("X-RR-Handoff-Timestamp") />
<cfset VARIABLES.hmacSignature = getRequestHeader("X-RR-Handoff-Signature") />
<cfset VARIABLES.hasValidLegacyJobToken = len(trim(VARIABLES.jobToken))
    AND len(VARIABLES.presentedJobToken)
    AND hash(VARIABLES.presentedJobToken, "SHA-256") EQ hash(VARIABLES.jobToken, "SHA-256") />
<cfset VARIABLES.hasValidJobToken = VARIABLES.hasValidLegacyJobToken
    OR hasValidHmacSignature(
        VARIABLES.jobToken,
        VARIABLES.requestBody,
        VARIABLES.hmacTimestamp,
        VARIABLES.hmacSignature
    ) />
<cfset VARIABLES.isTechnicalRun = true />
<cfset VARIABLES.lockId = 2026062202 />
<cfset VARIABLES.lockAcquired = false />
<cfset VARIABLES.executadoEm = DateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss") />
<cfset VARIABLES.maxPages = min(20, max(1, val(URL.maxPages))) />
<cfset VARIABLES.dryRun = asBoolean(URL.dryRun) />

<cfif NOT len(VARIABLES.jobToken)>
    <cfset jsonAbort(
        500,
        {
            success = false,
            status = "configuration_error",
            message = "Configure cronSecrets.business_youtube ou cronSecrets.runnerhub_youtube em config/business.local.cfm."
        }
    ) />
</cfif>
<cfif NOT VARIABLES.hasValidJobToken>
    <cfset jsonAbort(401, {success=false, status="unauthorized", message="Token invalido ou ausente."}) />
</cfif>

<cfset VARIABLES.youtubeApiKeyInfo = readYoutubeApiKey() />
<cfset VARIABLES.youtubeApiKey = VARIABLES.youtubeApiKeyInfo.value />
<cfset VARIABLES.apiKeySource = VARIABLES.youtubeApiKeyInfo.source />

<cfif NOT len(trim(VARIABLES.youtubeApiKey))>
    <cfif VARIABLES.isTechnicalRun>
        <cfset jsonAbort(
            500,
            {
                success = false,
                status = "error",
                message = "youtubeApiKey nao configurada em config/business.local.cfm"
            }
        ) />
    </cfif>
    <cfheader statuscode="500" statustext="Internal Server Error" />
    <cfoutput><p>RUNNERHUB_YOUTUBE_API_KEY nao configurada.</p></cfoutput>
    <cfabort />
</cfif>
<cfif NOT looksLikeGoogleApiKey(VARIABLES.youtubeApiKey)>
    <cfset jsonAbort(
        500,
        {
            success = false,
            status = "configuration_error",
            message = "youtubeApiKey invalida: informe uma Google API key iniciada por AIza, com 39 caracteres. Nao use o segredo business_youtube.",
            api_key_source = VARIABLES.apiKeySource,
            api_key_length = len(VARIABLES.youtubeApiKey),
            api_key_fingerprint = left(lCase(hash(VARIABLES.youtubeApiKey, "SHA-256")), 12)
        }
    ) />
</cfif>

<cfquery name="qYoutubeSchemaCheck">
    SELECT
        to_regclass('public.tb_youtube_canais') IS NOT NULL AS has_channels,
        to_regclass('public.tb_media') IS NOT NULL AS has_media,
        to_regclass('public.tb_paginas_feed') IS NOT NULL AS has_feed,
        (
            SELECT count(*)
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'tb_media'
              AND column_name IN ('youtube_duration_iso', 'youtube_duration_seconds', 'pub_status')
        ) AS media_columns
</cfquery>
<cfif NOT asBoolean(qYoutubeSchemaCheck.has_channels)
    OR NOT asBoolean(qYoutubeSchemaCheck.has_media)
    OR NOT asBoolean(qYoutubeSchemaCheck.has_feed)
    OR val(qYoutubeSchemaCheck.media_columns) NEQ 3>
    <cfset jsonAbort(500, {
        success=false,
        status="schema_required",
        message="A estrutura da importacao YouTube esta incompleta. Verifique api/youtube/jobs/schema.sql."
    }) />
</cfif>

<cfquery name="qYoutubeChannels">
    SELECT
        id_youtube_canal,
        code,
        name,
        COALESCE(source_type, 'channel') AS source_type,
        COALESCE(channel_id, '') AS channel_id,
        COALESCE(channel_handle, '') AS channel_handle,
        COALESCE(playlist_id, '') AS playlist_id,
        id_pagina,
        id_usuario,
        COALESCE(max_results, 3) AS max_results,
        min_duration_seconds,
        max_duration_seconds,
        COALESCE(enabled, false) AS enabled,
        COALESCE(sort_order, 0) AS sort_order
    FROM tb_youtube_canais
    ORDER BY sort_order ASC, id_youtube_canal ASC
</cfquery>

<cfset VARIABLES.channels = [] />

<cfloop query="qYoutubeChannels">
    <cfset arrayAppend(
        VARIABLES.channels,
        {
            idYoutubeCanal = qYoutubeChannels.id_youtube_canal,
            code = trim(qYoutubeChannels.code),
            name = trim(qYoutubeChannels.name),
            sourceType = len(trim(qYoutubeChannels.source_type)) ? lCase(trim(qYoutubeChannels.source_type)) : "channel",
            channelId = trim(qYoutubeChannels.channel_id),
            channelHandle = trim(qYoutubeChannels.channel_handle),
            playlistId = trim(qYoutubeChannels.playlist_id),
            idPagina = isNull(qYoutubeChannels.id_pagina) ? "" : qYoutubeChannels.id_pagina,
            idUsuario = isNull(qYoutubeChannels.id_usuario) ? "" : qYoutubeChannels.id_usuario,
            maxResults = val(qYoutubeChannels.max_results) GT 0 ? val(qYoutubeChannels.max_results) : 3,
            minDurationSeconds = isNull(qYoutubeChannels.min_duration_seconds) ? "" : val(qYoutubeChannels.min_duration_seconds),
            maxDurationSeconds = isNull(qYoutubeChannels.max_duration_seconds) ? "" : val(qYoutubeChannels.max_duration_seconds),
            enabled = javacast("boolean", qYoutubeChannels.enabled),
            sortOrder = val(qYoutubeChannels.sort_order)
        }
    ) />
</cfloop>

<cffunction name="normalizeMaxResults" access="private" returntype="numeric" output="false">
    <cfargument name="requestedValue" type="string" required="true" />
    <cfargument name="fallbackValue" type="numeric" required="true" />

    <cfset var normalizedValue = arguments.fallbackValue />

    <cfif len(trim(arguments.requestedValue)) AND isNumeric(arguments.requestedValue)>
        <cfset normalizedValue = int(arguments.requestedValue) />
        <cfif normalizedValue LT 1>
            <cfset normalizedValue = 1 />
        <cfelseif normalizedValue GT 50>
            <cfset normalizedValue = 50 />
        </cfif>
    </cfif>

    <cfreturn normalizedValue />
</cffunction>

<cffunction name="isDuplicateInsertError" access="private" returntype="boolean" output="false">
    <cfargument name="cfcatch" type="any" required="true" />

    <cfset var combinedMessage = "" />

    <cfif isStruct(arguments.cfcatch)>
        <cfif structKeyExists(arguments.cfcatch, "message")>
            <cfset combinedMessage = combinedMessage & " " & arguments.cfcatch.message />
        </cfif>
        <cfif structKeyExists(arguments.cfcatch, "detail")>
            <cfset combinedMessage = combinedMessage & " " & arguments.cfcatch.detail />
        </cfif>
    <cfelseif NOT isNull(arguments.cfcatch)>
        <cfset combinedMessage = toString(arguments.cfcatch) />
    </cfif>

    <cfreturn reFindNoCase("duplicate|unique|already exists|violates unique|duplicate key", combinedMessage) GT 0 />
</cffunction>

<cffunction name="isoDurationToSeconds" access="private" returntype="numeric" output="false">
    <cfargument name="isoDuration" type="string" required="true" />

    <cfset var normalizedDuration = trim(arguments.isoDuration) />
    <cfset var javaDuration = "" />

    <cfif NOT len(normalizedDuration)>
        <cfreturn 0 />
    </cfif>

    <cftry>
        <cfset javaDuration = createObject("java", "java.time.Duration").parse(normalizedDuration) />
        <cfreturn javaDuration.getSeconds() />
    <cfcatch type="any">
        <cfreturn 0 />
    </cfcatch>
    </cftry>
</cffunction>

<cffunction name="fetchChannelFeed" access="private" returntype="struct" output="false">
    <cfargument name="channel" type="struct" required="true" />
    <cfargument name="maxResults" type="numeric" required="true" />
    <cfargument name="pageToken" type="string" required="true" />

    <cfset var httpResult = {} />
    <cfset var payload = {} />
    <cfset var result = {
        success = false,
        statusCode = "",
        payload = {},
        errorMessage = ""
    } />

    <cftry>
        <cfhttp method="get" result="httpResult" url="https://www.googleapis.com/youtube/v3/playlistItems" timeout="30">
            <cfhttpparam type="header" name="Referer" value="https://business.roadrunners.run/" />
            <cfhttpparam type="url" name="key" value="#VARIABLES.youtubeApiKey#" />
            <cfhttpparam type="url" name="playlistId" value="#arguments.channel.playlistId#" />
            <cfhttpparam type="url" name="part" value="snippet,contentDetails" />
            <cfhttpparam type="url" name="maxResults" value="#arguments.maxResults#" />
            <cfif len(trim(arguments.pageToken))>
                <cfhttpparam type="url" name="pageToken" value="#arguments.pageToken#" />
            </cfif>
        </cfhttp>

        <cfif structKeyExists(httpResult, "fileContent") AND len(trim(httpResult.fileContent))>
            <cfset payload = deserializeJSON(httpResult.fileContent) />
        </cfif>

        <cfset result.statusCode = structKeyExists(httpResult, "statusCode") ? httpResult.statusCode : "" />

        <cfif left(result.statusCode, 3) EQ "200">
            <cfset result.success = true />
            <cfset result.payload = payload />
        <cfelse>
            <cfset result.errorMessage = structKeyExists(payload, "error")
                AND structKeyExists(payload.error, "message")
                ? payload.error.message
                : "A API do YouTube respondeu com status inesperado." />
        </cfif>
    <cfcatch type="any">
        <cfset result.errorMessage = cfcatch.message />
        <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
            <cfset result.errorMessage &= " | " & cfcatch.detail />
        </cfif>
    </cfcatch>
    </cftry>

    <cfreturn result />
</cffunction>

<cffunction name="fetchVideoDetailsBatch" access="private" returntype="struct" output="false">
    <cfargument name="videoIds" type="array" required="true" />

    <cfset var httpResult = {} />
    <cfset var payload = {} />
    <cfset var item = {} />
    <cfset var durationIso = "" />
    <cfset var durationSeconds = 0 />
    <cfset var result = {
        success = false,
        details = {},
        errorMessage = ""
    } />

    <cfif NOT arrayLen(arguments.videoIds)>
        <cfset result.success = true />
        <cfreturn result />
    </cfif>

    <cftry>
        <cfhttp method="get" result="httpResult" url="https://www.googleapis.com/youtube/v3/videos" timeout="30">
            <cfhttpparam type="header" name="Referer" value="https://business.roadrunners.run/" />
            <cfhttpparam type="url" name="key" value="#VARIABLES.youtubeApiKey#" />
            <cfhttpparam type="url" name="part" value="contentDetails" />
            <cfhttpparam type="url" name="id" value="#arrayToList(arguments.videoIds)#" />
            <cfhttpparam type="url" name="maxResults" value="#arrayLen(arguments.videoIds)#" />
        </cfhttp>

        <cfif structKeyExists(httpResult, "fileContent") AND len(trim(httpResult.fileContent))>
            <cfset payload = deserializeJSON(httpResult.fileContent) />
        </cfif>

        <cfif structKeyExists(httpResult, "statusCode")
            AND left(httpResult.statusCode, 3) EQ "200"
            AND structKeyExists(payload, "items")
            AND isArray(payload.items)>
            <cfloop array="#payload.items#" item="item">
                <cfif structKeyExists(item, "id")
                    AND len(trim(item.id))
                    AND structKeyExists(item, "contentDetails")
                    AND isStruct(item.contentDetails)>
                    <cfset durationIso = structKeyExists(item.contentDetails, "duration") ? trim(item.contentDetails.duration) : "" />
                    <cfset durationSeconds = isoDurationToSeconds(durationIso) />
                    <cfset result.details[trim(item.id)] = {
                        durationIso = durationIso,
                        durationSeconds = durationSeconds
                    } />
                </cfif>
            </cfloop>

            <cfset result.success = true />
        <cfelse>
            <cfset result.errorMessage = structKeyExists(payload, "error")
                AND structKeyExists(payload.error, "message")
                ? payload.error.message
                : "Nao foi possivel buscar os detalhes de duracao dos videos no YouTube." />
        </cfif>
    <cfcatch type="any">
        <cfset result.errorMessage = cfcatch.message />
        <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
            <cfset result.errorMessage &= " | " & cfcatch.detail />
        </cfif>
    </cfcatch>
    </cftry>

    <cfreturn result />
</cffunction>

<cffunction name="resolveChannelUploadsPlaylist" access="private" returntype="struct" output="false">
    <cfargument name="channelId" type="string" required="true" />

    <cfset var httpResult = {} />
    <cfset var payload = {} />
    <cfset var result = {
        success = false,
        uploadsPlaylistId = "",
        channelTitle = "",
        errorMessage = ""
    } />

    <cftry>
        <cfhttp method="get" result="httpResult" url="https://www.googleapis.com/youtube/v3/channels" timeout="30">
            <cfhttpparam type="header" name="Referer" value="https://business.roadrunners.run/" />
            <cfhttpparam type="url" name="key" value="#VARIABLES.youtubeApiKey#" />
            <cfhttpparam type="url" name="part" value="contentDetails,snippet" />
            <cfhttpparam type="url" name="id" value="#arguments.channelId#" />
        </cfhttp>

        <cfif structKeyExists(httpResult, "fileContent") AND len(trim(httpResult.fileContent))>
            <cfset payload = deserializeJSON(httpResult.fileContent) />
        </cfif>

        <cfif structKeyExists(httpResult, "statusCode")
            AND left(httpResult.statusCode, 3) EQ "200"
            AND structKeyExists(payload, "items")
            AND isArray(payload.items)
            AND arrayLen(payload.items)
            AND structKeyExists(payload.items[1], "contentDetails")
            AND isStruct(payload.items[1].contentDetails)
            AND structKeyExists(payload.items[1].contentDetails, "relatedPlaylists")
            AND isStruct(payload.items[1].contentDetails.relatedPlaylists)
            AND structKeyExists(payload.items[1].contentDetails.relatedPlaylists, "uploads")
            AND len(trim(payload.items[1].contentDetails.relatedPlaylists.uploads))>
            <cfset result.success = true />
            <cfset result.uploadsPlaylistId = trim(payload.items[1].contentDetails.relatedPlaylists.uploads) />
            <cfset result.channelTitle = structKeyExists(payload.items[1], "snippet")
                AND isStruct(payload.items[1].snippet)
                AND structKeyExists(payload.items[1].snippet, "title")
                ? trim(payload.items[1].snippet.title)
                : "" />
        <cfelse>
            <cfset result.errorMessage = structKeyExists(payload, "error")
                AND structKeyExists(payload.error, "message")
                ? payload.error.message
                : "Nao foi possivel resolver a playlist de uploads do canal no YouTube." />
        </cfif>
    <cfcatch type="any">
        <cfset result.errorMessage = cfcatch.message />
        <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
            <cfset result.errorMessage &= " | " & cfcatch.detail />
        </cfif>
    </cfcatch>
    </cftry>

    <cfreturn result />
</cffunction>

<cffunction name="resolveChannelByHandle" access="private" returntype="struct" output="false">
    <cfargument name="channelHandle" type="string" required="true" />

    <cfset var httpResult = {} />
    <cfset var payload = {} />
    <cfset var result = {
        success = false,
        channelId = "",
        channelTitle = "",
        errorMessage = ""
    } />

    <cftry>
        <cfhttp method="get" result="httpResult" url="https://www.googleapis.com/youtube/v3/channels" timeout="30">
            <cfhttpparam type="header" name="Referer" value="https://business.roadrunners.run/" />
            <cfhttpparam type="url" name="key" value="#VARIABLES.youtubeApiKey#" />
            <cfhttpparam type="url" name="part" value="id,snippet" />
            <cfhttpparam type="url" name="forHandle" value="#arguments.channelHandle#" />
        </cfhttp>

        <cfif structKeyExists(httpResult, "fileContent") AND len(trim(httpResult.fileContent))>
            <cfset payload = deserializeJSON(httpResult.fileContent) />
        </cfif>

        <cfif structKeyExists(httpResult, "statusCode")
            AND left(httpResult.statusCode, 3) EQ "200"
            AND structKeyExists(payload, "items")
            AND isArray(payload.items)
            AND arrayLen(payload.items)
            AND structKeyExists(payload.items[1], "id")
            AND len(trim(payload.items[1].id))>
            <cfset result.success = true />
            <cfset result.channelId = trim(payload.items[1].id) />
            <cfset result.channelTitle = structKeyExists(payload.items[1], "snippet")
                AND isStruct(payload.items[1].snippet)
                AND structKeyExists(payload.items[1].snippet, "title")
                ? trim(payload.items[1].snippet.title)
                : "" />
        <cfelse>
            <cfset result.errorMessage = structKeyExists(payload, "error")
                AND structKeyExists(payload.error, "message")
                ? payload.error.message
                : "Nao foi possivel resolver o handle do canal no YouTube." />
        </cfif>
    <cfcatch type="any">
        <cfset result.errorMessage = cfcatch.message />
        <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
            <cfset result.errorMessage &= " | " & cfcatch.detail />
        </cfif>
    </cfcatch>
    </cftry>

    <cfreturn result />
</cffunction>

<cffunction name="getSourceIdentifier" access="private" returntype="string" output="false">
    <cfargument name="channel" type="struct" required="true" />

    <cfif structKeyExists(arguments.channel, "sourceType") AND arguments.channel.sourceType EQ "playlist">
        <cfreturn structKeyExists(arguments.channel, "playlistId") ? trim(arguments.channel.playlistId) : "" />
    </cfif>

    <cfif structKeyExists(arguments.channel, "channelId") AND len(trim(arguments.channel.channelId))>
        <cfreturn trim(arguments.channel.channelId) />
    </cfif>

    <cfif structKeyExists(arguments.channel, "channelHandle") AND len(trim(arguments.channel.channelHandle))>
        <cfreturn trim(arguments.channel.channelHandle) />
    </cfif>

    <cfreturn "" />
</cffunction>

<cffunction name="getSourceLabel" access="private" returntype="string" output="false">
    <cfargument name="channel" type="struct" required="true" />

    <cfif structKeyExists(arguments.channel, "sourceType") AND arguments.channel.sourceType EQ "playlist">
        <cfreturn "playlist" />
    </cfif>

    <cfreturn "channel" />
</cffunction>

<cffunction name="passesDurationFilter" access="private" returntype="boolean" output="false">
    <cfargument name="channel" type="struct" required="true" />
    <cfargument name="durationSeconds" type="numeric" required="true" />

    <cfif structKeyExists(arguments.channel, "minDurationSeconds")
        AND len(trim(arguments.channel.minDurationSeconds & ""))
        AND val(arguments.channel.minDurationSeconds) GT 0
        AND arguments.durationSeconds LT val(arguments.channel.minDurationSeconds)>
        <cfreturn false />
    </cfif>

    <cfif structKeyExists(arguments.channel, "maxDurationSeconds")
        AND len(trim(arguments.channel.maxDurationSeconds & ""))
        AND val(arguments.channel.maxDurationSeconds) GT 0
        AND arguments.durationSeconds GT val(arguments.channel.maxDurationSeconds)>
        <cfreturn false />
    </cfif>

    <cfreturn true />
</cffunction>

<cffunction name="shouldPublishYoutubeVideo" access="private" returntype="boolean" output="false">
    <cfargument name="durationSeconds" type="numeric" required="true" />

    <cfif arguments.durationSeconds GT 0 AND arguments.durationSeconds LT 210>
        <cfreturn false />
    </cfif>

    <cfreturn true />
</cffunction>

<cffunction name="getYoutubeVideoId" access="private" returntype="string" output="false">
    <cfargument name="channel" type="struct" required="true" />
    <cfargument name="item" type="struct" required="true" />

    <cfif structKeyExists(arguments.item, "contentDetails")
        AND isStruct(arguments.item.contentDetails)
        AND structKeyExists(arguments.item.contentDetails, "videoId")
        AND len(trim(arguments.item.contentDetails.videoId))>
        <cfreturn trim(arguments.item.contentDetails.videoId) />
    </cfif>

    <cfif structKeyExists(arguments.item, "snippet")
        AND isStruct(arguments.item.snippet)
        AND structKeyExists(arguments.item.snippet, "resourceId")
        AND isStruct(arguments.item.snippet.resourceId)
        AND structKeyExists(arguments.item.snippet.resourceId, "videoId")
        AND len(trim(arguments.item.snippet.resourceId.videoId))>
        <cfreturn trim(arguments.item.snippet.resourceId.videoId) />
    </cfif>

    <cfif structKeyExists(arguments.item, "id")
        AND isStruct(arguments.item.id)
        AND structKeyExists(arguments.item.id, "videoId")
        AND len(trim(arguments.item.id.videoId))>
        <cfreturn trim(arguments.item.id.videoId) />
    </cfif>

    <cfreturn "" />
</cffunction>

<cffunction name="processChannel" access="private" returntype="struct" output="false">
    <cfargument name="channel" type="struct" required="true" />
    <cfargument name="requestMaxResults" type="string" required="true" />
    <cfargument name="pageToken" type="string" required="true" />

    <cfset var fetchResult = {} />
    <cfset var item = {} />
    <cfset var videoId = "" />
    <cfset var title = "" />
    <cfset var description = "" />
    <cfset var publishedAt = "" />
    <cfset var channelName = "" />
    <cfset var channelSlug = arguments.channel.code />
    <cfset var insertResult = {} />
    <cfset var resolvedChannel = duplicate(arguments.channel) />
    <cfset var resolvedHandle = {} />
    <cfset var uploadsPlaylist = {} />
    <cfset var videoIds = [] />
    <cfset var videoDetailsResult = {} />
    <cfset var videoDetails = {} />
    <cfset var detailData = {} />
    <cfset var durationIso = "" />
    <cfset var durationSeconds = 0 />
    <cfset var publishStatus = true />
    <cfset var sourceIdentifier = getSourceIdentifier(arguments.channel) />
    <cfset var currentPageToken = trim(arguments.pageToken) />
    <cfset var importAllPages = structKeyExists(arguments.channel, "sourceType") AND arguments.channel.sourceType EQ "playlist" />
    <cfset var shouldContinue = true />
    <cfset var feedConfigured = structKeyExists(arguments.channel, "idPagina")
        AND structKeyExists(arguments.channel, "idUsuario")
        AND len(trim(arguments.channel.idPagina))
        AND len(trim(arguments.channel.idUsuario))
        AND isNumeric(arguments.channel.idPagina)
        AND isNumeric(arguments.channel.idUsuario) />
    <cfset var summary = {
        code = arguments.channel.code,
        name = arguments.channel.name,
        sourceType = getSourceLabel(arguments.channel),
        sourceIdentifier = sourceIdentifier,
        imported = 0,
        duplicates = 0,
        linked = 0,
        filteredByDuration = 0,
        skipped = 0,
        pagesProcessed = 0,
        feedConfigured = feedConfigured,
        errors = [],
        nextPageToken = "",
        effectiveMaxResults = normalizeMaxResults(arguments.requestMaxResults, arguments.channel.maxResults),
        minDurationSeconds = structKeyExists(arguments.channel, "minDurationSeconds") ? arguments.channel.minDurationSeconds : "",
        maxDurationSeconds = structKeyExists(arguments.channel, "maxDurationSeconds") ? arguments.channel.maxDurationSeconds : ""
    } />

    <cfif NOT structKeyExists(resolvedChannel, "channelId")
        OR NOT len(trim(resolvedChannel.channelId))>
        <cfif structKeyExists(resolvedChannel, "channelHandle") AND len(trim(resolvedChannel.channelHandle))>
            <cfset resolvedHandle = resolveChannelByHandle(resolvedChannel.channelHandle) />
            <cfif NOT resolvedHandle.success>
                <cfset arrayAppend(summary.errors, resolvedHandle.errorMessage) />
                <cfreturn summary />
            </cfif>
            <cfset resolvedChannel.channelId = resolvedHandle.channelId />
            <cfif len(trim(resolvedHandle.channelTitle))>
                <cfset resolvedChannel.name = resolvedHandle.channelTitle />
                <cfset summary.name = resolvedHandle.channelTitle />
            </cfif>
            <cfset summary.sourceIdentifier = resolvedHandle.channelId />
        </cfif>
    </cfif>

    <cfif resolvedChannel.sourceType EQ "channel">
        <cfset uploadsPlaylist = resolveChannelUploadsPlaylist(resolvedChannel.channelId) />
        <cfif NOT uploadsPlaylist.success>
            <cfset arrayAppend(summary.errors, uploadsPlaylist.errorMessage) />
            <cfreturn summary />
        </cfif>
        <cfset resolvedChannel.playlistId = uploadsPlaylist.uploadsPlaylistId />
        <cfif len(trim(uploadsPlaylist.channelTitle))>
            <cfset resolvedChannel.name = uploadsPlaylist.channelTitle />
            <cfset summary.name = uploadsPlaylist.channelTitle />
        </cfif>
    </cfif>

    <cfloop condition="shouldContinue">
        <cfset fetchResult = fetchChannelFeed(resolvedChannel, summary.effectiveMaxResults, currentPageToken) />

        <cfif NOT fetchResult.success>
            <cfset arrayAppend(summary.errors, fetchResult.errorMessage) />
            <cfreturn summary />
        </cfif>

        <cfset summary.pagesProcessed++ />
        <cfset summary.nextPageToken = structKeyExists(fetchResult.payload, "nextPageToken") ? trim(fetchResult.payload.nextPageToken) : "" />

        <cfif NOT structKeyExists(fetchResult.payload, "items") OR NOT isArray(fetchResult.payload.items)>
            <cfset arrayAppend(summary.errors, "Resposta do YouTube sem lista de itens.") />
            <cfreturn summary />
        </cfif>

        <cfset videoIds = [] />
        <cfloop array="#fetchResult.payload.items#" item="item">
            <cfset videoId = getYoutubeVideoId(arguments.channel, item) />
            <cfif len(trim(videoId)) AND NOT arrayFindNoCase(videoIds, trim(videoId))>
                <cfset arrayAppend(videoIds, trim(videoId)) />
            </cfif>
        </cfloop>

        <cfset videoDetailsResult = fetchVideoDetailsBatch(videoIds) />
        <cfif NOT videoDetailsResult.success>
            <cfset arrayAppend(summary.errors, videoDetailsResult.errorMessage) />
            <cfreturn summary />
        </cfif>
        <cfset videoDetails = videoDetailsResult.details />

        <cfloop array="#fetchResult.payload.items#" item="item">
            <cfif NOT structKeyExists(item, "snippet")
                OR NOT isStruct(item.snippet)>
                <cfset summary.skipped++ />
                <cfcontinue />
            </cfif>

            <cfset videoId = getYoutubeVideoId(arguments.channel, item) />
            <cfif NOT len(trim(videoId))>
                <cfset summary.skipped++ />
                <cfcontinue />
            </cfif>

            <cfset title = structKeyExists(item.snippet, "title") ? item.snippet.title : "" />
            <cfset description = structKeyExists(item.snippet, "description") ? item.snippet.description : "" />
            <cfset publishedAt = structKeyExists(item.snippet, "publishedAt") ? item.snippet.publishedAt : "" />
            <cfset channelName = structKeyExists(item.snippet, "channelTitle") AND len(trim(item.snippet.channelTitle))
                ? trim(item.snippet.channelTitle)
                : arguments.channel.name />
            <cfset detailData = structKeyExists(videoDetails, videoId) ? videoDetails[videoId] : {} />
            <cfset durationIso = structKeyExists(detailData, "durationIso") ? trim(detailData.durationIso) : "" />
            <cfset durationSeconds = structKeyExists(detailData, "durationSeconds") ? val(detailData.durationSeconds) : 0 />
            <cfset publishStatus = shouldPublishYoutubeVideo(durationSeconds) />

            <cfif NOT passesDurationFilter(resolvedChannel, durationSeconds)>
                <cfset summary.filteredByDuration++ />
                <cfcontinue />
            </cfif>

            <cfif VARIABLES.dryRun>
                <cfquery name="qYoutubeDryRunExisting">
                    SELECT id_media
                    FROM tb_media
                    WHERE media_url = <cfqueryparam cfsqltype="cf_sql_varchar" value="#videoId#" />
                    LIMIT 1
                </cfquery>
                <cfif qYoutubeDryRunExisting.recordcount>
                    <cfset summary.duplicates++ />
                <cfelse>
                    <cfset summary.imported++ />
                </cfif>
                <cfif feedConfigured>
                    <cfset summary.linked++ />
                </cfif>
                <cfcontinue />
            </cfif>

            <cftry>
                <cfquery>
                    UPDATE tb_media
                    SET
                        media_canal_nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#channelName#" />,
                        media_canal_slug = <cfqueryparam cfsqltype="cf_sql_varchar" value="#channelSlug#" />,
                        youtube_duration_iso = <cfqueryparam cfsqltype="cf_sql_varchar" value="#durationIso#" null="#NOT len(durationIso)#" />,
                        youtube_duration_seconds = <cfqueryparam cfsqltype="cf_sql_integer" value="#durationSeconds#" null="#durationSeconds LTE 0#" />,
                        pub_status = <cfqueryparam cfsqltype="cf_sql_bit" value="#publishStatus#" />
                    WHERE media_url = <cfqueryparam cfsqltype="cf_sql_varchar" value="#videoId#" />
                </cfquery>
            <cfcatch type="any">
                <cfset arrayAppend(summary.errors, "Falha ao atualizar canal em " & videoId & ": " & cfcatch.message) />
                <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
                    <cfset summary.errors[arrayLen(summary.errors)] &= " | " & cfcatch.detail />
                </cfif>
            </cfcatch>
            </cftry>

            <cftry>
                <cfquery result="insertResult">
                    INSERT INTO tb_media
                    (media_url, media_tipo, media_titulo, media_descricao, data_publicacao, media_canal_nome, media_canal_slug, youtube_duration_iso, youtube_duration_seconds, pub_status)
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#videoId#" />,
                        'codigo_youtube',
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#title#" />,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#description#" />,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#publishedAt#" />,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#channelName#" />,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#channelSlug#" />,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#durationIso#" null="#NOT len(durationIso)#" />,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#durationSeconds#" null="#durationSeconds LTE 0#" />,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="#publishStatus#" />
                    )
                    ON CONFLICT (media_url) DO NOTHING
                </cfquery>

                <cfif structKeyExists(insertResult, "recordCount") AND val(insertResult.recordCount) GT 0>
                    <cfset summary.imported++ />
                <cfelse>
                    <cfset summary.duplicates++ />
                </cfif>
            <cfcatch type="any">
                <cfif isDuplicateInsertError(cfcatch)>
                    <cfset summary.duplicates++ />
                <cfelse>
                    <cfset arrayAppend(summary.errors, "Falha ao inserir " & videoId & ": " & cfcatch.message) />
                    <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
                        <cfset summary.errors[arrayLen(summary.errors)] &= " | " & cfcatch.detail />
                    </cfif>
                    <cfcontinue />
                </cfif>
            </cfcatch>
            </cftry>

            <cfif feedConfigured>
                <cftry>
                    <cfquery>
                        INSERT INTO tb_paginas_feed (id_pagina, titulo, descricao, referencia, id_referencia, publico, data_atualizacao, id_usuario)
                        SELECT
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.channel.idPagina#" />,
                            'publicou um video no youtube',
                            '',
                            'video',
                            media.id_media,
                            true,
                            media.data_publicacao,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.channel.idUsuario#" />
                        FROM tb_media media
                        WHERE media_url = <cfqueryparam cfsqltype="cf_sql_varchar" value="#videoId#" />
                        ON CONFLICT (id_pagina, referencia, id_referencia)
                        DO NOTHING
                    </cfquery>
                    <cfset summary.linked++ />
                <cfcatch type="any">
                    <cfset arrayAppend(summary.errors, "Falha ao vincular " & videoId & " ao feed: " & cfcatch.message) />
                    <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
                        <cfset summary.errors[arrayLen(summary.errors)] &= " | " & cfcatch.detail />
                    </cfif>
                </cfcatch>
                </cftry>
            </cfif>
        </cfloop>

        <cfif importAllPages
            AND len(summary.nextPageToken)
            AND summary.pagesProcessed LT VARIABLES.maxPages>
            <cfset currentPageToken = summary.nextPageToken />
        <cfelse>
            <cfset shouldContinue = false />
        </cfif>
    </cfloop>

    <cfreturn summary />
</cffunction>

<cfset VARIABLES.enabledChannels = [] />
<cfset VARIABLES.disabledChannels = [] />
<cfset VARIABLES.summary = [] />

<cfloop array="#VARIABLES.channels#" item="channelConfig">
    <cfif channelConfig.enabled>
        <cfset arrayAppend(VARIABLES.enabledChannels, channelConfig) />
    <cfelse>
        <cfset arrayAppend(VARIABLES.disabledChannels, channelConfig) />
    </cfif>
</cfloop>

<cfif len(trim(URL.channel))>
    <cfset VARIABLES.filteredChannels = [] />
    <cfloop array="#VARIABLES.enabledChannels#" item="channelConfig">
        <cfif channelConfig.code EQ trim(URL.channel)
            OR getSourceIdentifier(channelConfig) EQ trim(URL.channel)>
            <cfset arrayAppend(VARIABLES.filteredChannels, channelConfig) />
        </cfif>
    </cfloop>
<cfelse>
    <cfset VARIABLES.filteredChannels = VARIABLES.enabledChannels />
</cfif>

<cfif NOT arrayLen(VARIABLES.filteredChannels)>
    <cfif VARIABLES.isTechnicalRun>
        <cfset jsonAbort(
            404,
            {
                success = false,
                status = "not_found",
                message = "Canal invalido ou desabilitado",
                canais_processados = 0,
                importados = 0,
                duplicados = 0,
                vinculados = 0,
                filtrados = 0,
                ignorados = 0,
                erros = ["Canal invalido ou desabilitado"]
            }
        ) />
    </cfif>
    <cfheader statuscode="404" statustext="Not Found" />
    <cfoutput><p>Canal invalido ou desabilitado.</p></cfoutput>
    <cfabort />
</cfif>

<cfquery name="qYoutubeJobLock">
    SELECT pg_try_advisory_lock(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.lockId#" />) AS locked
</cfquery>

<cfset VARIABLES.lockAcquired = qYoutubeJobLock.recordcount AND asBoolean(qYoutubeJobLock.locked) />
<cfset VARIABLES.totalChannelsProcessed = 0 />
<cfset VARIABLES.totalImported = 0 />
<cfset VARIABLES.totalDuplicates = 0 />
<cfset VARIABLES.totalLinked = 0 />
<cfset VARIABLES.totalFiltered = 0 />
<cfset VARIABLES.totalSkipped = 0 />
<cfset VARIABLES.allErrors = [] />
<cfset VARIABLES.skipMessage = "" />

<cfif NOT VARIABLES.lockAcquired>
    <cfif VARIABLES.isTechnicalRun>
        <cfset jsonAbort(
            200,
            {
                success = true,
                status = "skipped",
                message = "Job ja esta em execucao",
                canais_processados = 0,
                importados = 0,
                duplicados = 0,
                vinculados = 0,
                filtrados = 0,
                ignorados = 0,
                erros = []
            }
        ) />
    </cfif>
    <cfset VARIABLES.skipMessage = "Job ja esta em execucao." />
<cfelse>
    <cftry>
        <cfloop array="#VARIABLES.filteredChannels#" item="channelConfig">
            <cfset arrayAppend(
                VARIABLES.summary,
                processChannel(
                    channelConfig,
                    URL.maxResults,
                    channelConfig.code EQ trim(URL.channel) ? trim(URL.pageToken) : ""
                )
            ) />
        </cfloop>

        <cfset VARIABLES.totalChannelsProcessed = arrayLen(VARIABLES.summary) />

        <cfloop array="#VARIABLES.summary#" item="channelSummaryForTotals">
            <cfset VARIABLES.totalImported += val(channelSummaryForTotals.imported) />
            <cfset VARIABLES.totalDuplicates += val(channelSummaryForTotals.duplicates) />
            <cfset VARIABLES.totalLinked += val(channelSummaryForTotals.linked) />
            <cfset VARIABLES.totalFiltered += val(channelSummaryForTotals.filteredByDuration) />
            <cfset VARIABLES.totalSkipped += val(channelSummaryForTotals.skipped) />
            <cfif structKeyExists(channelSummaryForTotals, "errors") AND isArray(channelSummaryForTotals.errors) AND arrayLen(channelSummaryForTotals.errors)>
                <cfloop array="#channelSummaryForTotals.errors#" item="channelErrorText">
                    <cfset arrayAppend(VARIABLES.allErrors, channelSummaryForTotals.code & ": " & channelErrorText) />
                </cfloop>
            </cfif>
        </cfloop>
    <cfcatch type="any">
        <cfquery>
            SELECT pg_advisory_unlock(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.lockId#" />)
        </cfquery>
        <cfif VARIABLES.isTechnicalRun>
            <cfset jsonAbort(
                500,
                {
                    success = false,
                    status = "error",
                    message = cfcatch.message,
                    canais_processados = VARIABLES.totalChannelsProcessed,
                    importados = VARIABLES.totalImported,
                    duplicados = VARIABLES.totalDuplicates,
                    vinculados = VARIABLES.totalLinked,
                    filtrados = VARIABLES.totalFiltered,
                    ignorados = VARIABLES.totalSkipped,
                    erros = [cfcatch.message & (structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail)) ? " | " & cfcatch.detail : "")]
                }
            ) />
        </cfif>
        <cfrethrow />
    </cfcatch>
    </cftry>
    <cfquery>
        SELECT pg_advisory_unlock(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.lockId#" />)
    </cfquery>
</cfif>

<cfif VARIABLES.isTechnicalRun>
    <cfset jsonAbort(
        200,
        {
            success = true,
            status = VARIABLES.dryRun ? "dry_run" : "ok",
            message = VARIABLES.dryRun ? "Simulacao concluida sem gravacoes" : "Importacao concluida",
            dry_run = VARIABLES.dryRun,
            max_pages = VARIABLES.maxPages,
            api_key_source = VARIABLES.apiKeySource,
            api_key_fingerprint = left(lCase(hash(VARIABLES.youtubeApiKey, "SHA-256")), 12),
            canais_processados = VARIABLES.totalChannelsProcessed,
            importados = VARIABLES.totalImported,
            duplicados = VARIABLES.totalDuplicates,
            vinculados = VARIABLES.totalLinked,
            filtrados = VARIABLES.totalFiltered,
            ignorados = VARIABLES.totalSkipped,
            erros = VARIABLES.allErrors
        }
    ) />
</cfif>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8" />
    <title>Importador YouTube</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 24px; color: #111; }
        h1, h2, h3 { margin-bottom: 0.4rem; }
        p, li { line-height: 1.45; }
        table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
        th, td { border: 1px solid #d7d7d7; padding: 10px; text-align: left; vertical-align: top; }
        th { background: #f4f4f4; }
        .meta { color: #555; margin-bottom: 1rem; }
        .ok { color: #116b39; font-weight: 700; }
        .warn { color: #9a6700; font-weight: 700; }
        .err { color: #b42318; font-weight: 700; }
        .section { margin-top: 1.5rem; }
        .token-link { margin-top: 0.5rem; }
        code { background: #f6f8fa; padding: 2px 6px; border-radius: 6px; }
        .actions { margin-top: 0.75rem; display: flex; gap: 0.5rem; flex-wrap: wrap; }
        .btn { display: inline-flex; align-items: center; justify-content: center; padding: 0.55rem 0.8rem; border-radius: 8px; background: #111827; color: #fff; text-decoration: none; font-weight: 700; }
        .btn:hover { background: #1f2937; }
        .btn.secondary { background: #f3f4f6; color: #111; border: 1px solid #d1d5db; }
        .btn.secondary:hover { background: #e5e7eb; }
    </style>
</head>
<body>
    <h1>Importador YouTube</h1>
    <cfoutput>
        <p class="meta">
            Usuario autenticado: <code>#encodeForHtml(VARIABLES.requestUserId)#</code><br />
            Origem da chave: <code>#encodeForHtml(VARIABLES.apiKeySource)#</code><br />
            Execucao automatica por token:
            <code><cfif len(VARIABLES.jobToken)>configurada<cfelse>nao configurada</cfif></code><br />
            Backup do original: <code>/api/youtube/index.cfm.original-2026-04-24</code>
        </p>
    </cfoutput>

    <cfif len(trim(VARIABLES.skipMessage))>
        <p class="warn"><cfoutput>#encodeForHtml(VARIABLES.skipMessage)#</cfoutput></p>
    </cfif>

    <table>
        <thead>
            <tr>
                <th>Canal</th>
                <th>Configuracao</th>
                <th>Resultado</th>
                <th>Erros</th>
            </tr>
        </thead>
        <tbody>
            <cfoutput>
                <cfloop array="#VARIABLES.summary#" item="channelSummary">
                    <tr>
                        <td>
                            <strong>#encodeForHtml(channelSummary.name)#</strong><br />
                            <code>#encodeForHtml(channelSummary.sourceType)#:</code>
                            <code>#encodeForHtml(channelSummary.sourceIdentifier)#</code>
                            <div class="actions">
                                <a class="btn" href="./?channel=#encodeForURL(channelSummary.code)#">Reimportar canal</a>
                                <a class="btn secondary" href="./?channel=#encodeForURL(channelSummary.code)#&maxResults=#channelSummary.effectiveMaxResults#">Reimportar com limite atual</a>
                            </div>
                        </td>
                        <td>
                            slug: <code>#encodeForHtml(channelSummary.code)#</code><br />
                            maxResults: <code>#channelSummary.effectiveMaxResults#</code><br />
                            filtro duracao:
                            <code>
                                <cfif len(trim(channelSummary.minDurationSeconds & "")) OR len(trim(channelSummary.maxDurationSeconds & ""))>
                                    #len(trim(channelSummary.minDurationSeconds & "")) ? channelSummary.minDurationSeconds : "0"#s
                                    -
                                    <cfif len(trim(channelSummary.maxDurationSeconds & ""))>#channelSummary.maxDurationSeconds#s<cfelse>sem limite</cfif>
                                <cfelse>
                                    sem filtro
                                </cfif>
                            </code><br />
                            paginas processadas: <code>#channelSummary.pagesProcessed#</code><br />
                            feed:
                            <code><cfif channelSummary.feedConfigured>configurado<cfelse>nao configurado</cfif></code>
                        </td>
                        <td>
                            <span class="ok">importados: #channelSummary.imported#</span><br />
                            <span class="warn">duplicados: #channelSummary.duplicates#</span><br />
                            vinculados ao feed: #channelSummary.linked#<br />
                            filtrados por duracao: #channelSummary.filteredByDuration#<br />
                            ignorados: #channelSummary.skipped#

                            <cfif len(trim(channelSummary.nextPageToken))>
                                <p class="token-link">
                                    <a href="./?channel=#encodeForURL(channelSummary.code)#&maxResults=#channelSummary.effectiveMaxResults#&pageToken=#encodeForURL(channelSummary.nextPageToken)#">
                                        Proximos #channelSummary.effectiveMaxResults#
                                    </a>
                                </p>
                            </cfif>
                        </td>
                        <td>
                            <cfif arrayLen(channelSummary.errors)>
                                <ul>
                                    <cfloop array="#channelSummary.errors#" item="errorText">
                                        <li class="err">#encodeForHtml(errorText)#</li>
                                    </cfloop>
                                </ul>
                            <cfelse>
                                <span class="ok">Nenhum erro.</span>
                            </cfif>
                        </td>
                    </tr>
                </cfloop>
            </cfoutput>
        </tbody>
    </table>

    <div class="section">
        <h2>Canais ativos</h2>
        <ul>
            <cfoutput>
                <cfloop array="#VARIABLES.enabledChannels#" item="channelConfig">
                    <li>
                        <strong>#encodeForHtml(channelConfig.name)#</strong>
                        (<code>#encodeForHtml(channelConfig.code)#</code> - <code>#encodeForHtml(getSourceLabel(channelConfig))#</code>)
                    </li>
                </cfloop>
            </cfoutput>
        </ul>
    </div>

    <cfif arrayLen(VARIABLES.disabledChannels)>
        <div class="section">
            <h2>Canais desabilitados</h2>
            <ul>
                <cfoutput>
                    <cfloop array="#VARIABLES.disabledChannels#" item="channelConfig">
                        <li>
                            <strong>#encodeForHtml(channelConfig.name)#</strong>
                            (<code>#encodeForHtml(channelConfig.code)#</code> - <code>#encodeForHtml(getSourceLabel(channelConfig))#</code>)
                        </li>
                    </cfloop>
                </cfoutput>
            </ul>
        </div>
    </cfif>
</body>
</html>
