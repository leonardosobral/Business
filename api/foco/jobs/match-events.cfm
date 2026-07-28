<cfsetting requesttimeout="120" showdebugoutput="false" enablecfoutputonly="true" />
<cfprocessingdirective pageencoding="utf-8" />

<cfscript>
function focoJsonAbort(required numeric statusCode, required struct payload) {
    var statusText = "OK";
    if (arguments.statusCode EQ 400) statusText = "Bad Request";
    else if (arguments.statusCode EQ 401) statusText = "Unauthorized";
    else if (arguments.statusCode EQ 405) statusText = "Method Not Allowed";
    else if (arguments.statusCode GTE 500) statusText = "Internal Server Error";

    cfheader(statuscode=arguments.statusCode, statustext=statusText);
    cfcontent(type="application/json; charset=utf-8", reset="true");
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function focoAuthorizationHeader() {
    var requestData = {};
    if (structKeyExists(CGI, "http_authorization") AND len(trim(CGI.http_authorization))) {
        return trim(CGI.http_authorization);
    }
    requestData = getHttpRequestData(false);
    if (structKeyExists(requestData, "headers") AND isStruct(requestData.headers)
        AND structKeyExists(requestData.headers, "Authorization")) {
        return trim(requestData.headers.Authorization & "");
    }
    return "";
}

function focoBearerToken(required string authorizationHeader) {
    if (reFindNoCase("^Bearer\s+.+$", trim(arguments.authorizationHeader))) {
        return trim(reReplaceNoCase(arguments.authorizationHeader, "^Bearer\s+", "", "one"));
    }
    return "";
}

function focoRequestPayload() {
    var requestData = getHttpRequestData();
    var rawBody = "";
    if (structKeyExists(requestData, "content") AND !isNull(requestData.content)) {
        rawBody = isBinary(requestData.content)
            ? charsetEncode(requestData.content, "utf-8")
            : requestData.content & "";
    }
    return len(trim(rawBody)) ? deserializeJSON(rawBody) : {};
}

function focoBoolean(required any value) {
    if (isBoolean(arguments.value)) return arguments.value;
    return listFindNoCase("true,t,1,yes,on", trim(arguments.value & "")) GT 0;
}

function focoInteger(required any value, numeric fallback=0) {
    var normalized = "";
    try {
        normalized = trim(toString(arguments.value));
    } catch (any conversionError) {
        return arguments.fallback;
    }
    if (!reFind("^[0-9]+([.]0+)?$", normalized)) return arguments.fallback;
    return javaCast("int", val(normalized));
}

function focoHttpCode(required any statusCode) {
    var match = reFind("^[0-9]{3}", trim(arguments.statusCode & ""), 1, true);
    return arrayLen(match.pos) AND match.pos[1] GT 0
        ? val(mid(arguments.statusCode & "", match.pos[1], match.len[1]))
        : 0;
}

function focoNormalize(required any value) {
    var textValue = isNull(arguments.value) ? "" : trim(arguments.value & "");
    var normalizer = createObject("java", "java.text.Normalizer");
    var normalizerForm = createObject("java", "java.text.Normalizer$Form");
    var normalized = normalizer.normalize(textValue, normalizerForm.NFD);
    normalized = reReplace(normalized, "\p{InCombiningDiacriticalMarks}+", "", "all");
    normalized = lCase(reReplace(normalized, "[^a-zA-Z0-9]+", " ", "all"));
    return trim(reReplace(normalized, "\s+", " ", "all"));
}

function focoTokenSimilarity(required string leftText, required string rightText) {
    var leftTokens = {};
    var rightTokens = {};
    var token = "";
    var intersection = 0;
    var unionCount = 0;

    for (token in listToArray(arguments.leftText, " ")) {
        if (len(token)) leftTokens[token] = true;
    }
    for (token in listToArray(arguments.rightText, " ")) {
        if (len(token)) rightTokens[token] = true;
    }
    for (token in leftTokens) {
        unionCount++;
        if (structKeyExists(rightTokens, token)) intersection++;
    }
    for (token in rightTokens) {
        if (!structKeyExists(leftTokens, token)) unionCount++;
    }
    return unionCount GT 0 ? intersection / unionCount : 0;
}

function focoStructValue(required struct source, required string key, any fallback="") {
    if (structKeyExists(arguments.source, arguments.key) AND !isNull(arguments.source[arguments.key])) {
        return arguments.source[arguments.key];
    }
    return arguments.fallback;
}
</cfscript>

<cffunction name="focoFetchCompetitions" access="private" returntype="array" output="false">
    <cfargument name="targetDate" type="string" required="true" />
    <cfargument name="targetUf" type="string" required="true" />
    <cfargument name="sport" type="string" required="true" />
    <cfargument name="authorization" type="string" required="true" />
    <cfargument name="pageSize" type="numeric" required="true" />

    <cfset var allCompetitions = [] />
    <cfset var currentPage = 1 />
    <cfset var totalPages = 1 />
    <cfset var httpResult = {} />
    <cfset var httpCode = 0 />
    <cfset var payload = {} />
    <cfset var competition = {} />

    <cfloop condition="currentPage LTE totalPages">
        <cfhttp url="https://www.focomarket.com.br/competition-api/competitions" result="httpResult" method="get" timeout="30" throwonerror="false">
            <cfhttpparam type="url" name="date" value="#arguments.targetDate#" />
            <cfhttpparam type="url" name="uf" value="#arguments.targetUf#" />
            <cfhttpparam type="url" name="place" value="" />
            <cfhttpparam type="url" name="name" value="" />
            <cfhttpparam type="url" name="sport" value="#arguments.sport#" />
            <cfhttpparam type="url" name="page" value="#currentPage#" />
            <cfhttpparam type="url" name="pageSize" value="#arguments.pageSize#" />
            <cfhttpparam type="header" name="Authorization" value="Bearer #arguments.authorization#" />
            <cfhttpparam type="header" name="Accept" value="application/json" />
        </cfhttp>

        <cfset httpCode = focoHttpCode(httpResult.statusCode) />
        <cfif httpCode LT 200 OR httpCode GTE 300>
            <cfthrow type="Foco.Upstream" message="A API da Foco retornou HTTP #httpCode#." errorcode="#httpCode#" />
        </cfif>

        <cfset payload = deserializeJSON(httpResult.fileContent) />
        <cfif !isStruct(payload) OR !structKeyExists(payload, "competitions") OR !isArray(payload.competitions)>
            <cfthrow type="Foco.Upstream" message="A API da Foco retornou uma estrutura inesperada." />
        </cfif>

        <cfloop array="#payload.competitions#" index="competition">
            <cfset arrayAppend(allCompetitions, competition) />
        </cfloop>

        <cfif structKeyExists(payload, "pagination") AND isStruct(payload.pagination)
            AND structKeyExists(payload.pagination, "totalPages")>
            <cfset totalPages = max(1, focoInteger(payload.pagination.totalPages, 1)) />
            <cfif totalPages GT 20>
                <cfthrow type="Foco.Upstream" message="A API da Foco retornou mais de 20 paginas para uma unica data e UF; refine o lote antes de continuar." />
            </cfif>
        <cfelse>
            <cfset totalPages = currentPage />
        </cfif>
        <cfset currentPage++ />
    </cfloop>

    <cfreturn allCompetitions />
</cffunction>

<cfset focoJobLocalConfig = {} />
<cfset VARIABLES.focoBusinessLocalConfig = {} />
<cfset VARIABLES.businessLocalConfigPath = expandPath("/config/business.local.cfm") />
<cfif fileExists(VARIABLES.businessLocalConfigPath)>
    <cfinclude template="../../../config/business.local.cfm" />
</cfif>
<cfif isDefined("businessLocalConfig") AND isStruct(businessLocalConfig)>
    <cfset VARIABLES.focoBusinessLocalConfig = businessLocalConfig />
<cfelseif structKeyExists(VARIABLES, "businessLocalConfig") AND isStruct(VARIABLES.businessLocalConfig)>
    <cfset VARIABLES.focoBusinessLocalConfig = VARIABLES.businessLocalConfig />
</cfif>
<cfif isStruct(VARIABLES.focoBusinessLocalConfig)>
    <cfset focoJobLocalConfig.apiToken = structKeyExists(VARIABLES.focoBusinessLocalConfig, "focoApiToken")
        ? trim(VARIABLES.focoBusinessLocalConfig.focoApiToken & "")
        : "" />
    <cfset focoJobLocalConfig.jobToken = (
        structKeyExists(VARIABLES.focoBusinessLocalConfig, "cronSecrets")
        AND isStruct(VARIABLES.focoBusinessLocalConfig.cronSecrets)
        AND structKeyExists(VARIABLES.focoBusinessLocalConfig.cronSecrets, "business_foco_eventos")
    ) ? trim(VARIABLES.focoBusinessLocalConfig.cronSecrets.business_foco_eventos & "") : "" />
    <cfif !len(focoJobLocalConfig.jobToken)
        AND structKeyExists(VARIABLES.focoBusinessLocalConfig, "cronSecrets")
        AND isStruct(VARIABLES.focoBusinessLocalConfig.cronSecrets)
        AND structKeyExists(VARIABLES.focoBusinessLocalConfig.cronSecrets, "runnerhub_foco_eventos")>
        <cfset focoJobLocalConfig.jobToken = trim(VARIABLES.focoBusinessLocalConfig.cronSecrets.runnerhub_foco_eventos & "") />
    </cfif>
</cfif>

<cfif uCase(trim(CGI.request_method & "")) NEQ "POST">
    <cfheader name="Allow" value="POST" />
    <cfset focoJsonAbort(405, {success=false, status="method_not_allowed", message="Use POST com corpo JSON."}) />
</cfif>

<cfif !isStruct(focoJobLocalConfig)
    OR !structKeyExists(focoJobLocalConfig, "jobToken")
    OR !structKeyExists(focoJobLocalConfig, "apiToken")
    OR !len(trim(focoJobLocalConfig.jobToken & ""))
    OR !len(trim(focoJobLocalConfig.apiToken & ""))>
    <cfset VARIABLES.focoMissingConfig = [] />
    <cfif !structKeyExists(focoJobLocalConfig, "apiToken") OR !len(trim(focoJobLocalConfig.apiToken & ""))>
        <cfset arrayAppend(VARIABLES.focoMissingConfig, "focoApiToken") />
    </cfif>
    <cfif !structKeyExists(focoJobLocalConfig, "jobToken") OR !len(trim(focoJobLocalConfig.jobToken & ""))>
        <cfset arrayAppend(VARIABLES.focoMissingConfig, "cronSecrets.business_foco_eventos") />
    </cfif>
    <cfset focoJsonAbort(500, {
        success=false,
        status="configuration_error",
        message="Configuracao ausente em config/business.local.cfm: " & arrayToList(VARIABLES.focoMissingConfig, ", ") & ".",
        config_file_found=fileExists(VARIABLES.businessLocalConfigPath)
    }) />
</cfif>

<cfset VARIABLES.receivedToken = focoBearerToken(focoAuthorizationHeader()) />
<cfif !len(VARIABLES.receivedToken)
    OR hash(VARIABLES.receivedToken, "SHA-256") NEQ hash(trim(focoJobLocalConfig.jobToken & ""), "SHA-256")>
    <cfset focoJsonAbort(401, {success=false, status="unauthorized", message="Token invalido ou ausente."}) />
</cfif>

<cftry>
    <cfset VARIABLES.payload = focoRequestPayload() />
    <cfcatch type="any">
        <cfset focoJsonAbort(400, {success=false, status="invalid_json", message="O corpo da requisicao nao contem JSON valido."}) />
    </cfcatch>
</cftry>

<cfif !isStruct(VARIABLES.payload)>
    <cfset focoJsonAbort(400, {success=false, status="validation_error", message="O corpo JSON deve ser um objeto."}) />
</cfif>

<cfset VARIABLES.limit = structKeyExists(VARIABLES.payload, "limit") ? focoInteger(VARIABLES.payload.limit, 5) : 5 />
<cfset VARIABLES.eventId = structKeyExists(VARIABLES.payload, "eventId") ? focoInteger(VARIABLES.payload.eventId, 0) : 0 />
<cfset VARIABLES.pageSize = structKeyExists(VARIABLES.payload, "pageSize") ? focoInteger(VARIABLES.payload.pageSize, 50) : 50 />
<cfset VARIABLES.dryRun = structKeyExists(VARIABLES.payload, "dryRun") ? focoBoolean(VARIABLES.payload.dryRun) : true />
<cfset VARIABLES.autoLink = structKeyExists(VARIABLES.payload, "autoLink") ? focoBoolean(VARIABLES.payload.autoLink) : true />
<cfset VARIABLES.fromDate = structKeyExists(VARIABLES.payload, "fromDate") ? trim(VARIABLES.payload.fromDate & "") : "2023-01-01" />
<cfset VARIABLES.minReviewScore = structKeyExists(VARIABLES.payload, "minReviewScore") ? focoInteger(VARIABLES.payload.minReviewScore, 60) : 60 />
<cfset VARIABLES.autoLinkScore = structKeyExists(VARIABLES.payload, "autoLinkScore") ? focoInteger(VARIABLES.payload.autoLinkScore, 85) : 85 />

<cfif VARIABLES.limit LT 1
    OR VARIABLES.limit GT 20
    OR VARIABLES.pageSize LT 1
    OR VARIABLES.pageSize GT 100
    OR VARIABLES.minReviewScore LT 1
    OR VARIABLES.minReviewScore GT 100
    OR VARIABLES.autoLinkScore LT VARIABLES.minReviewScore
    OR VARIABLES.autoLinkScore GT 100
    OR !isDate(VARIABLES.fromDate)>
    <cfset focoJsonAbort(400, {success=false, status="validation_error", message="limit deve estar entre 1 e 20, pageSize entre 1 e 100, minReviewScore entre 1 e 100, autoLinkScore entre minReviewScore e 100 e fromDate deve ser uma data valida."}) />
</cfif>

<cfquery name="qFocoTables">
    SELECT count(*) AS total
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('tb_foco_event_match_state', 'tb_foco_event_match_candidates', 'tb_evento_foco_vinculos')
</cfquery>
<cfif !qFocoTables.recordcount OR val(qFocoTables.total) NEQ 3>
    <cfset focoJsonAbort(500, {success=false, status="schema_required", message="Aplique foco_match_schema.sql antes de executar o vinculador."}) />
</cfif>
<cfquery name="qFocoCandidateColumns">
    SELECT count(*) AS total
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_foco_event_match_candidates'
      AND column_name IN ('status', 'reviewed_by', 'reviewed_at', 'review_note')
</cfquery>
<cfif !qFocoCandidateColumns.recordcount OR val(qFocoCandidateColumns.total) NEQ 4>
    <cfset focoJsonAbort(500, {success=false, status="schema_required", message="Reaplique foco_match_schema.sql para adicionar status e auditoria dos candidatos."}) />
</cfif>

<cfquery name="qFocoEvents">
    SELECT evt.id_evento, evt.nome_evento, evt.nome_simplificado,
           evt.cidade, evt.estado, evt.data_inicial, evt.data_final
    FROM tb_evento_corridas evt
    LEFT JOIN tb_foco_event_match_state mst ON mst.id_evento = evt.id_evento
    WHERE evt.pais = 'BR'
      AND evt.ativo = true
      AND evt.tipo_corrida = 'rua'
      AND length(trim(coalesce(evt.cidade, ''))) > 0
      AND length(trim(coalesce(evt.estado, ''))) > 0
    <cfif VARIABLES.eventId GT 0>
      AND evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventId#" />
    <cfelse>
      AND evt.data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.fromDate#" />
      AND (
          mst.id_evento IS NULL
          OR (
              mst.status IN ('pending', 'not_found', 'error')
              AND coalesce(mst.next_attempt_at, now()) <= now()
              AND coalesce(mst.processing_until, now() - interval '1 second') < now()
          )
      )
    </cfif>
    ORDER BY coalesce(mst.next_attempt_at, timestamp '0001-01-01'), evt.data_final DESC, evt.id_evento
    LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.limit#" />
</cfquery>

<cfset VARIABLES.response = {
    api_version = "2026-06-24.1",
    success = true,
    status = VARIABLES.dryRun ? "dry_run" : "ok",
    message = "Processamento concluido.",
    dry_run = VARIABLES.dryRun,
    selected = qFocoEvents.recordcount,
    min_review_score = VARIABLES.minReviewScore,
    auto_link_score = VARIABLES.autoLinkScore,
    processed = 0,
    linked = 0,
    review = 0,
    not_found = 0,
    conflicts = 0,
    skipped = 0,
    errors = 0,
    results = []
} />

<cfloop query="qFocoEvents">
    <cfset VARIABLES.eventResult = {
        event_id = qFocoEvents.id_evento,
        event_name = qFocoEvents.nome_evento,
        status = "pending",
        candidates = 0,
        exact_matches = 0,
        high_confidence_matches = 0,
        competition_id = "",
        competition_name = "",
        message = ""
    } />
    <cfset VARIABLES.claimed = VARIABLES.dryRun />

    <cfif !VARIABLES.dryRun>
        <cfquery name="qFocoClaim">
            INSERT INTO tb_foco_event_match_state
                (id_evento, status, attempts, processing_until, data_atualizacao)
            VALUES (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoEvents.id_evento#" />,
                'processing', 1, now() + interval '5 minutes', now()
            )
            ON CONFLICT (id_evento)
            DO UPDATE SET
                status = 'processing',
                attempts = tb_foco_event_match_state.attempts + 1,
                processing_until = now() + interval '5 minutes',
                last_error = NULL,
                data_atualizacao = now()
            WHERE coalesce(tb_foco_event_match_state.processing_until, now() - interval '1 second') < now()
            RETURNING id_evento
        </cfquery>
        <cfset VARIABLES.claimed = qFocoClaim.recordcount GT 0 />
    </cfif>

    <cfif !VARIABLES.claimed>
        <cfset VARIABLES.eventResult.status = "skipped" />
        <cfset VARIABLES.eventResult.message = "Evento ja esta sendo processado." />
        <cfset VARIABLES.response.skipped++ />
        <cfset arrayAppend(VARIABLES.response.results, VARIABLES.eventResult) />
        <cfcontinue />
    </cfif>

    <cftry>
        <cfset VARIABLES.eventNameNormalized = focoNormalize(qFocoEvents.nome_evento) />
        <cfset VARIABLES.simplifiedNameValue = isNull(qFocoEvents.nome_simplificado) ? "" : trim(qFocoEvents.nome_simplificado & "") />
        <cfset VARIABLES.simplifiedNameNormalized = len(VARIABLES.simplifiedNameValue) ? focoNormalize(VARIABLES.simplifiedNameValue) : "" />
        <cfset VARIABLES.eventPlaceNormalized = focoNormalize(qFocoEvents.cidade) />
        <cfset VARIABLES.eventUfNormalized = uCase(trim(qFocoEvents.estado & "")) />
        <cfset VARIABLES.searchDates = [] />
        <cfif dateCompare(qFocoEvents.data_inicial, qFocoEvents.data_final) NEQ 0>
            <cfset arrayAppend(VARIABLES.searchDates, dateFormat(qFocoEvents.data_inicial, "yyyy-mm-dd")) />
        </cfif>
        <cfset arrayAppend(VARIABLES.searchDates, dateFormat(qFocoEvents.data_final, "yyyy-mm-dd")) />
        <cfset VARIABLES.rawCandidates = [] />
        <cfset VARIABLES.seenCompetitionIds = {} />

        <cfloop array="#VARIABLES.searchDates#" index="VARIABLES.searchDate">
            <cfset VARIABLES.dateCandidates = focoFetchCompetitions(
                VARIABLES.searchDate,
                VARIABLES.eventUfNormalized,
                "Corrida de Rua",
                focoJobLocalConfig.apiToken,
                VARIABLES.pageSize
            ) />
            <cfloop array="#VARIABLES.dateCandidates#" index="VARIABLES.rawCandidate">
                <cfset VARIABLES.competitionId = trim(focoStructValue(VARIABLES.rawCandidate, "id", "") & "") />
                <cfif len(VARIABLES.competitionId) AND !structKeyExists(VARIABLES.seenCompetitionIds, VARIABLES.competitionId)>
                    <cfset VARIABLES.seenCompetitionIds[VARIABLES.competitionId] = true />
                    <cfset arrayAppend(VARIABLES.rawCandidates, VARIABLES.rawCandidate) />
                </cfif>
            </cfloop>
        </cfloop>

        <cfset VARIABLES.relevantCandidates = [] />
        <cfset VARIABLES.exactMatches = [] />
        <cfset VARIABLES.highConfidenceMatches = [] />

        <cfloop array="#VARIABLES.rawCandidates#" index="VARIABLES.candidate">
            <cfset VARIABLES.candidateName = trim(focoStructValue(VARIABLES.candidate, "competition_name", "") & "") />
            <cfset VARIABLES.candidatePlace = trim(focoStructValue(VARIABLES.candidate, "place", "") & "") />
            <cfset VARIABLES.candidateUf = uCase(trim(focoStructValue(VARIABLES.candidate, "UF", "") & "")) />
            <cfset VARIABLES.candidateDateRaw = trim(focoStructValue(VARIABLES.candidate, "date", "") & "") />
            <cfset VARIABLES.candidateNameNormalized = focoNormalize(VARIABLES.candidateName) />
            <cfset VARIABLES.candidatePlaceNormalized = focoNormalize(VARIABLES.candidatePlace) />
            <cfset VARIABLES.exactName = VARIABLES.candidateNameNormalized EQ VARIABLES.eventNameNormalized
                OR (len(VARIABLES.simplifiedNameNormalized) AND VARIABLES.candidateNameNormalized EQ VARIABLES.simplifiedNameNormalized) />
            <cfset VARIABLES.exactPlace = VARIABLES.candidatePlaceNormalized EQ VARIABLES.eventPlaceNormalized />
            <cfset VARIABLES.exactUf = VARIABLES.candidateUf EQ VARIABLES.eventUfNormalized />
            <cfset VARIABLES.exactDate = isDate(VARIABLES.candidateDateRaw)
                AND parseDateTime(VARIABLES.candidateDateRaw) GTE qFocoEvents.data_inicial
                AND parseDateTime(VARIABLES.candidateDateRaw) LTE qFocoEvents.data_final />
            <cfset VARIABLES.nameSimilarity = max(
                focoTokenSimilarity(VARIABLES.candidateNameNormalized, VARIABLES.eventNameNormalized),
                len(VARIABLES.simplifiedNameNormalized)
                    ? focoTokenSimilarity(VARIABLES.candidateNameNormalized, VARIABLES.simplifiedNameNormalized)
                    : 0
            ) />
            <cfset VARIABLES.score = (VARIABLES.exactDate ? 30 : 0)
                + (VARIABLES.exactUf ? 15 : 0)
                + (VARIABLES.exactPlace ? 20 : 0)
                + (VARIABLES.exactName ? 35 : VARIABLES.nameSimilarity * 35) />

            <cfif VARIABLES.exactPlace AND VARIABLES.score GTE VARIABLES.minReviewScore>
                <cfset VARIABLES.candidateEvaluation = {
                    data = VARIABLES.candidate,
                    competitionId = trim(focoStructValue(VARIABLES.candidate, "id", "") & ""),
                    competitionName = VARIABLES.candidateName,
                    competitionDate = VARIABLES.candidateDateRaw,
                    place = VARIABLES.candidatePlace,
                    uf = VARIABLES.candidateUf,
                    exactName = VARIABLES.exactName,
                    exactPlace = VARIABLES.exactPlace,
                    exactUf = VARIABLES.exactUf,
                    exactDate = VARIABLES.exactDate,
                    score = VARIABLES.score
                } />
                <cfset arrayAppend(VARIABLES.relevantCandidates, VARIABLES.candidateEvaluation) />
                <cfif VARIABLES.score GTE VARIABLES.autoLinkScore
                    AND VARIABLES.exactDate
                    AND VARIABLES.exactUf>
                    <cfset arrayAppend(VARIABLES.highConfidenceMatches, VARIABLES.candidateEvaluation) />
                </cfif>
                <cfif VARIABLES.exactName AND VARIABLES.exactPlace AND VARIABLES.exactUf AND VARIABLES.exactDate>
                    <cfset arrayAppend(VARIABLES.exactMatches, VARIABLES.candidateEvaluation) />
                </cfif>
            </cfif>
        </cfloop>

        <cfset VARIABLES.eventResult.candidates = arrayLen(VARIABLES.relevantCandidates) />
        <cfset VARIABLES.eventResult.exact_matches = arrayLen(VARIABLES.exactMatches) />
        <cfset VARIABLES.eventResult.high_confidence_matches = arrayLen(VARIABLES.highConfidenceMatches) />

        <cfif !VARIABLES.dryRun>
            <cftransaction>
                <cfquery>
                    DELETE FROM tb_foco_event_match_candidates
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoEvents.id_evento#" />
                      AND status = 'active'
                </cfquery>
                <cfloop array="#VARIABLES.relevantCandidates#" index="VARIABLES.evaluatedCandidate">
                    <cfquery>
                        INSERT INTO tb_foco_event_match_candidates
                            (id_evento, competition_id, competition_name, competition_date,
                             place, uf, score, exact_name, exact_date, exact_place,
                             exact_uf, status, payload, last_seen_at)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoEvents.id_evento#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.evaluatedCandidate.competitionId#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.evaluatedCandidate.competitionName#" null="#!len(VARIABLES.evaluatedCandidate.competitionName)#" />,
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.evaluatedCandidate.competitionDate#" null="#!isDate(VARIABLES.evaluatedCandidate.competitionDate)#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.evaluatedCandidate.place#" null="#!len(VARIABLES.evaluatedCandidate.place)#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.evaluatedCandidate.uf#" null="#!len(VARIABLES.evaluatedCandidate.uf)#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#VARIABLES.evaluatedCandidate.score#" />,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.evaluatedCandidate.exactName#" />,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.evaluatedCandidate.exactDate#" />,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.evaluatedCandidate.exactPlace#" />,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.evaluatedCandidate.exactUf#" />,
                            'active',
                            CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.evaluatedCandidate.data)#" /> AS jsonb),
                            now()
                        )
                        ON CONFLICT (id_evento, competition_id)
                        DO UPDATE SET
                            competition_name = excluded.competition_name,
                            competition_date = excluded.competition_date,
                            place = excluded.place,
                            uf = excluded.uf,
                            score = excluded.score,
                            exact_name = excluded.exact_name,
                            exact_date = excluded.exact_date,
                            exact_place = excluded.exact_place,
                            exact_uf = excluded.exact_uf,
                            payload = excluded.payload,
                            last_seen_at = now()
                        WHERE tb_foco_event_match_candidates.status <> 'ignored'
                    </cfquery>
                </cfloop>
            </cftransaction>
        </cfif>

        <cfset VARIABLES.finalStatus = "review" />
        <cfset VARIABLES.finalMessage = "Candidatos encontrados; revisao manual necessaria." />
        <cfset VARIABLES.matchMode = "candidate_review" />
        <cfset VARIABLES.selectedMatch = {} />
        <cfset VARIABLES.linkedMatches = [] />

        <cfif arrayLen(VARIABLES.highConfidenceMatches) GTE 1>
            <cfif VARIABLES.autoLink>
                <cfif !VARIABLES.dryRun>
                    <cftransaction>
                        <cfloop array="#VARIABLES.highConfidenceMatches#" index="VARIABLES.selectedMatch">
                            <cfset VARIABLES.identificationType = focoInteger(focoStructValue(VARIABLES.selectedMatch.data, "identification_by_face", 0), 0) EQ 1
                                ? trim(focoStructValue(VARIABLES.selectedMatch.data, "competition_path", "") & "")
                                : "numero" />
                            <cfif !len(VARIABLES.identificationType)>
                                <cfset VARIABLES.identificationType = "numero" />
                            </cfif>
                            <cfset VARIABLES.competitionPath = trim(focoStructValue(VARIABLES.selectedMatch.data, "competition_path", "") & "") />

                            <cfquery>
                                SELECT pg_advisory_xact_lock(
                                    hashtext(<cfqueryparam cfsqltype="cf_sql_varchar" value="foco:#VARIABLES.selectedMatch.competitionId#" />)
                                )
                            </cfquery>
                            <cfquery name="qFocoCompetitionConflictLocked">
                                SELECT id_evento
                                FROM tb_evento_foco_vinculos
                                WHERE status = 'active'
                                  AND trim(competition_id) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.selectedMatch.competitionId#" />
                                  AND id_evento <> <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoEvents.id_evento#" />
                                LIMIT 1
                            </cfquery>
                            <cfif qFocoCompetitionConflictLocked.recordcount>
                                <cfthrow type="Foco.Conflict" message="A competicao Foco foi vinculada a outro evento durante o processamento." />
                            </cfif>

                            <cfquery>
                                INSERT INTO tb_evento_foco_vinculos
                                    (id_evento, competition_id, competition_name, competition_date,
                                     place, uf, competition_path, identification_type, score,
                                     match_mode, status, payload, reviewed_at)
                                VALUES (
                                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoEvents.id_evento#" />,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.selectedMatch.competitionId#" />,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.selectedMatch.competitionName#" null="#!len(VARIABLES.selectedMatch.competitionName)#" />,
                                    <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.selectedMatch.competitionDate#" null="#!isDate(VARIABLES.selectedMatch.competitionDate)#" />,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.selectedMatch.place#" null="#!len(VARIABLES.selectedMatch.place)#" />,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.selectedMatch.uf#" null="#!len(VARIABLES.selectedMatch.uf)#" />,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.competitionPath#" null="#!len(VARIABLES.competitionPath)#" />,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.identificationType#" />,
                                    <cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#VARIABLES.selectedMatch.score#" />,
                                    'auto_high_score',
                                    'active',
                                    CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.selectedMatch.data)#" /> AS jsonb),
                                    now()
                                )
                                ON CONFLICT (id_evento, competition_id)
                                DO UPDATE SET
                                    competition_name = excluded.competition_name,
                                    competition_date = excluded.competition_date,
                                    place = excluded.place,
                                    uf = excluded.uf,
                                    competition_path = excluded.competition_path,
                                    identification_type = excluded.identification_type,
                                    score = excluded.score,
                                    match_mode = excluded.match_mode,
                                    status = 'active',
                                    payload = excluded.payload,
                                    reviewed_at = now(),
                                    data_atualizacao = now()
                            </cfquery>

                            <cfif arrayLen(VARIABLES.linkedMatches) EQ 0>
                                <cfquery>
                                    INSERT INTO tb_badges
                                        (id_evento, percurso, badge, valor_badge, complemento_badge, badge_raw)
                                    VALUES (
                                        <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoEvents.id_evento#" />,
                                        0, 'foco',
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.selectedMatch.competitionId#" />,
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.identificationType#" />,
                                        CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.selectedMatch.data)#" /> AS jsonb)
                                    )
                                    ON CONFLICT (id_evento, percurso, badge)
                                    DO UPDATE SET
                                        valor_badge = excluded.valor_badge,
                                        complemento_badge = excluded.complemento_badge,
                                        badge_raw = excluded.badge_raw
                                </cfquery>
                            </cfif>

                            <cfset arrayAppend(VARIABLES.linkedMatches, VARIABLES.selectedMatch) />
                        </cfloop>
                    </cftransaction>
                <cfelse>
                    <cfset VARIABLES.linkedMatches = VARIABLES.highConfidenceMatches />
                </cfif>

                <cfset VARIABLES.selectedMatch = VARIABLES.highConfidenceMatches[1] />
                <cfset VARIABLES.finalStatus = "linked" />
                <cfset VARIABLES.finalMessage = "#arrayLen(VARIABLES.highConfidenceMatches)# galeria(s) Foco vinculada(s) automaticamente por score alto, data e UF." />
                <cfset VARIABLES.matchMode = arrayLen(VARIABLES.highConfidenceMatches) GT 1 ? "multiple_high_score" : "high_score_unique" />
            <cfelse>
                <cfset VARIABLES.selectedMatch = VARIABLES.highConfidenceMatches[1] />
                <cfset VARIABLES.finalMessage = "Candidato de alta confianca encontrado, mas autoLink esta desativado." />
                <cfset VARIABLES.matchMode = "high_score_review" />
            </cfif>
        <cfelseif arrayLen(VARIABLES.relevantCandidates) EQ 0>
            <cfset VARIABLES.finalStatus = "not_found" />
            <cfset VARIABLES.finalMessage = "Nenhum candidato relevante encontrado na Foco." />
            <cfset VARIABLES.matchMode = "none" />
        </cfif>

        <cfset VARIABLES.eventResult.status = VARIABLES.finalStatus />
        <cfset VARIABLES.eventResult.message = VARIABLES.finalMessage />
        <cfif !structIsEmpty(VARIABLES.selectedMatch)>
            <cfset VARIABLES.eventResult.competition_id = VARIABLES.selectedMatch.competitionId />
            <cfset VARIABLES.eventResult.competition_name = VARIABLES.selectedMatch.competitionName />
        </cfif>

        <cfif !VARIABLES.dryRun>
            <cfquery>
                UPDATE tb_foco_event_match_state
                SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.finalStatus#" />,
                    candidate_count = <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayLen(VARIABLES.relevantCandidates)#" />,
                    matched_competition_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventResult.competition_id#" null="#!len(VARIABLES.eventResult.competition_id)#" />,
                    matched_competition_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventResult.competition_name#" null="#!len(VARIABLES.eventResult.competition_name)#" />,
                    match_mode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.matchMode#" />,
                    last_checked_at = now(),
                    next_attempt_at = <cfif VARIABLES.finalStatus EQ "not_found">now() + interval '24 hours'<cfelse>NULL</cfif>,
                    processing_until = NULL,
                    last_error = NULL,
                    data_atualizacao = now()
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoEvents.id_evento#" />
            </cfquery>
        </cfif>

        <cfif VARIABLES.finalStatus EQ "linked"><cfset VARIABLES.response.linked++ />
        <cfelseif VARIABLES.finalStatus EQ "review"><cfset VARIABLES.response.review++ />
        <cfelseif VARIABLES.finalStatus EQ "not_found"><cfset VARIABLES.response.not_found++ />
        <cfelseif VARIABLES.finalStatus EQ "conflict"><cfset VARIABLES.response.conflicts++ /></cfif>
        <cfset VARIABLES.response.processed++ />

        <cfcatch type="any">
            <cfset VARIABLES.eventResult.status = "error" />
            <cfset VARIABLES.eventResult.message = cfcatch.message />
            <cfset VARIABLES.response.errors++ />
            <cfset VARIABLES.response.status = "partial" />
            <cfif !VARIABLES.dryRun>
                <cfquery>
                    UPDATE tb_foco_event_match_state
                    SET status = 'error',
                        last_checked_at = now(),
                        next_attempt_at = now() + interval '30 minutes',
                        processing_until = NULL,
                        last_error = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#left(cfcatch.message, 2000)#" />,
                        data_atualizacao = now()
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoEvents.id_evento#" />
                </cfquery>
            </cfif>
        </cfcatch>
    </cftry>

    <cfset arrayAppend(VARIABLES.response.results, VARIABLES.eventResult) />
</cfloop>

<cfif qFocoEvents.recordcount EQ 0>
    <cfset VARIABLES.response.status = "idle" />
    <cfset VARIABLES.response.message = "Nenhum evento elegivel para processar." />
<cfelseif VARIABLES.response.errors GT 0>
    <cfset VARIABLES.response.message = "Processamento concluido com erros parciais." />
</cfif>

<cfcontent type="application/json; charset=utf-8" reset="true" />
<cfoutput>#serializeJSON(VARIABLES.response)#</cfoutput>
