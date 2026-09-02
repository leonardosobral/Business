<cfscript>
function raceTagTrailingSlash(required string value) {
    var normalized = trim(arguments.value);
    return right(normalized, 1) EQ "/" ? normalized : normalized & "/";
}

function raceTagHostIsPublic(required string hostName) {
    var addresses = [];
    var address = "";
    var normalizedAddress = "";

    try {
        addresses = createObject("java", "java.net.InetAddress").getAllByName(arguments.hostName);
    } catch (any dnsError) {
        return false;
    }

    if (!arrayLen(addresses)) {
        return false;
    }

    for (address in addresses) {
        normalizedAddress = lCase(address.getHostAddress() & "");
        if (address.isAnyLocalAddress()
            OR address.isLoopbackAddress()
            OR address.isLinkLocalAddress()
            OR address.isSiteLocalAddress()
            OR address.isMulticastAddress()
            OR reFind("^(0|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])|169\.254)\.", normalizedAddress)
            OR reFind("^(fc|fd)[0-9a-f]{2}:", normalizedAddress)) {
            return false;
        }
    }

    return true;
}

function raceTagSourceInfo(required string sourceUrl, string externalEventId = "") {
    var source = trim(arguments.sourceUrl);
    var uri = "";
    var scheme = "";
    var host = "";
    var port = -1;
    var path = "";
    var fragment = "";
    var origin = "";
    var basePath = "";
    var directEventId = "";
    var result = {
        valid = false,
        baseUrl = "",
        eventUrl = "",
        eventId = trim(arguments.externalEventId),
        eventPath = "",
        error = ""
    };

    if (!len(source)) {
        result.error = "Informe a URL técnica ou pública do resultado.";
        return result;
    }

    if (len(source) GT 2048) {
        result.error = "A URL da fonte ultrapassa 2.048 caracteres.";
        return result;
    }

    try {
        uri = createObject("java", "java.net.URI").init(source);
        scheme = lCase(uri.getScheme() & "");
        host = lCase(uri.getHost() & "");
        port = uri.getPort();
        path = uri.getPath() & "";
        fragment = isNull(uri.getFragment()) ? "" : uri.getFragment() & "";
    } catch (any invalidUrl) {
        result.error = "A URL informada não é válida.";
        return result;
    }

    if (scheme NEQ "https" OR !len(host) OR !isNull(uri.getUserInfo())) {
        result.error = "A fonte precisa usar HTTPS e possuir um host válido.";
        return result;
    }

    if (host EQ "localhost"
        OR host EQ "0.0.0.0"
        OR host EQ "::1"
        OR reFind("^(127|10)\.", host)
        OR reFind("^192\.168\.", host)
        OR reFind("^172\.(1[6-9]|2[0-9]|3[0-1])\.", host)) {
        result.error = "Hosts locais ou privados não podem ser usados como fonte.";
        return result;
    }

    if (!raceTagHostIsPublic(host)) {
        result.error = "O host da fonte não possui um endereço público permitido.";
        return result;
    }

    origin = scheme & "://" & host & (port GT 0 ? ":" & port : "");

    if (reFindNoCase("/data/[^/]+/event\.json$", path)) {
        directEventId = reReplaceNoCase(path, "^.*/data/([^/]+)/event\.json$", "\1");
        basePath = reReplaceNoCase(path, "data/[^/]+/event\.json$", "");
        result.eventId = len(result.eventId) ? result.eventId : directEventId;
        result.eventUrl = origin & path & (isNull(uri.getQuery()) ? "" : "?" & uri.getQuery());
    } else {
        basePath = path;
        result.eventPath = reReplace(fragment, "^/|/$", "", "all");
    }

    result.baseUrl = raceTagTrailingSlash(origin & basePath);
    result.valid = true;
    return result;
}

function raceTagPublicUrlValid(string publicUrl = "") {
    var value = trim(arguments.publicUrl);
    var uri = "";

    if (!len(value)) {
        return true;
    }
    if (len(value) GT 2048) {
        return false;
    }

    try {
        uri = createObject("java", "java.net.URI").init(value);
        return compareNoCase(uri.getScheme() & "", "https") EQ 0
            AND len(uri.getHost() & "")
            AND isNull(uri.getUserInfo());
    } catch (any invalidPublicUrl) {
        return false;
    }
}

function raceTagHttpSucceeded(required struct response) {
    return structKeyExists(arguments.response, "statusCode")
        AND val(listFirst(arguments.response.statusCode & "", " ")) GTE 200
        AND val(listFirst(arguments.response.statusCode & "", " ")) LT 300;
}

function raceTagPlace(required string rawPlace) {
    var place = trim(arguments.rawPlace);
    var parsed = { city = place, state = "" };
    var match = reFindNoCase("^(.*?)[[:space:]]*(?:/|-)[[:space:]]*([A-Z]{2})$", place, 1, true);

    if (arrayLen(match.pos) GTE 3 AND match.pos[2] GT 0 AND match.pos[3] GT 0) {
        parsed.city = trim(mid(place, match.pos[2], match.len[2]));
        parsed.state = uCase(trim(mid(place, match.pos[3], match.len[3])));
    }

    return parsed;
}

function raceTagOpenResultsPolicy(
    required struct eventPayload,
    boolean payloadEnabled = true,
    boolean hasPersistedPayload = false,
    boolean isInternalAdmin = false,
    boolean overrideRequested = false
) {
    var state = "missing";
    var serializedValue = "";
    var standardAllowed = true;
    var decisionSource = "legacy";
    var divergent = false;
    var overrideAvailable = false;
    var overrideAccepted = false;

    if (structKeyExists(arguments.eventPayload, "openResultsEnabled")
        AND NOT isNull(arguments.eventPayload.openResultsEnabled)) {
        try {
            serializedValue = lCase(trim(serializeJSON(arguments.eventPayload.openResultsEnabled)));
        } catch (any invalidOpenResultsValue) {
            serializedValue = "";
        }

        if (serializedValue EQ "true") {
            state = "enabled";
        } else if (serializedValue EQ "false") {
            state = "disabled";
        } else {
            state = "invalid";
        }
    }

    if (state EQ "enabled") {
        standardAllowed = true;
        decisionSource = "event_json";
    } else if (state EQ "disabled" OR state EQ "invalid") {
        standardAllowed = false;
        decisionSource = "event_json";
    } else if (arguments.hasPersistedPayload) {
        standardAllowed = arguments.payloadEnabled;
        decisionSource = "payload";
    }

    divergent = arguments.hasPersistedPayload
        AND listFindNoCase("enabled,disabled", state)
        AND ((state EQ "enabled") NEQ arguments.payloadEnabled);

    overrideAvailable = arguments.isInternalAdmin AND NOT standardAllowed;
    overrideAccepted = overrideAvailable AND arguments.overrideRequested;

    return {
        state = state,
        eventState = state,
        decisionSource = decisionSource,
        divergent = divergent,
        payloadEnabled = arguments.payloadEnabled,
        hasPersistedPayload = arguments.hasPersistedPayload,
        standardAllowed = standardAllowed,
        overrideAvailable = overrideAvailable,
        overrideAccepted = overrideAccepted,
        processingAllowed = standardAllowed OR overrideAccepted
    };
}

function raceTagResponseHeaderValue(required any rawValue) {
    if (isNull(arguments.rawValue)) {
        return "";
    }
    if (isArray(arguments.rawValue)) {
        return arrayToList(arguments.rawValue, ", ");
    }
    if (isSimpleValue(arguments.rawValue)) {
        return arguments.rawValue & "";
    }

    try {
        return serializeJSON(arguments.rawValue);
    } catch (any headerSerializationError) {
        return "[valor não exibível]";
    }
}
</cfscript>

<cfset VARIABLES.raceTagAnalyzed = false/>
<cfset VARIABLES.raceTagCanProcess = false/>
<cfset VARIABLES.raceTagProcessingAttempted = false/>
<cfset VARIABLES.raceTagProcessingSucceeded = false/>
<cfset VARIABLES.raceTagProcessingError = ""/>
<cfset VARIABLES.raceTagQueueClaimed = false/>
<cfset VARIABLES.raceTagSource = raceTagSourceInfo(FORM.url_resultado, FORM.external_event_id)/>
<cfset VARIABLES.raceTagExternalEvents = []/>
<cfset VARIABLES.evento = {}/>
<cfset eventoJSON = {}/>
<cfset VARIABLES.raceTagEventHttpStatus = ""/>
<cfset VARIABLES.raceTagEventResponseHeaders = {}/>
<cfset VARIABLES.raceTagEventRawBody = ""/>
<cfset VARIABLES.raceTagEventRawDisplayLimit = 262144/>
<cfset VARIABLES.raceTagEventJsonLoaded = false/>
<cfset VARIABLES.raceTagOpenResultsOverrideRequested = compareNoCase(trim(FORM.open_results_override & ""), "1") EQ 0/>
<cfset VARIABLES.raceTagOpenResultsDecision = raceTagOpenResultsPolicy(
    eventoJSON,
    VARIABLES.raceTagPayloadOpenResultsEnabled,
    VARIABLES.raceTagPayloadIntentAvailable,
    VARIABLES.raceTagUnscopedAccess,
    VARIABLES.raceTagOpenResultsOverrideRequested
)/>
<cfset VARIABLES.raceTagOverrideActorId = isDefined("qPerfil")
    AND qPerfil.recordcount
    AND listFindNoCase(qPerfil.columnList, "id")
    ? val(qPerfil.id)
    : 0/>
<cfset qRaceTagCandidates = queryNew("id_evento,nome_evento,tag,cidade,estado,data_inicial,data_final")/>
<cfset qRaceTagSelectedEvent = queryNew("id_evento,nome_evento,tag,cidade,estado,data_inicial,data_final")/>

<cfif len(trim(FORM.url_resultado)) AND VARIABLES.raceTagSource.valid>
    <cftry>
        <cfhttp result="httpEventos"
                url="#VARIABLES.raceTagSource.baseUrl#data/events.json"
                method="get"
                timeout="30"
                redirect="false"
                throwonerror="false">
            <cfhttpparam type="header" name="Accept" value="application/json"/>
            <cfhttpparam type="header" name="User-Agent" value="RunnerHubBusiness-RaceTagImporter/1.0"/>
        </cfhttp>

        <cfif raceTagHttpSucceeded(httpEventos)
            AND len(httpEventos.fileContent & "") LTE (8 * 1024 * 1024)
            AND isJSON(httpEventos.fileContent)>
            <cfset VARIABLES.raceTagExternalEvents = deserializeJSON(httpEventos.fileContent)/>
            <cfif NOT isArray(VARIABLES.raceTagExternalEvents) OR arrayLen(VARIABLES.raceTagExternalEvents) GT 10000>
                <cfset VARIABLES.raceTagExternalEvents = []/>
            </cfif>
        </cfif>

        <cfif arrayLen(VARIABLES.raceTagExternalEvents)>
            <cfloop array="#VARIABLES.raceTagExternalEvents#" item="raceTagExternalEvent">
                <cfif (len(trim(VARIABLES.raceTagSource.eventId))
                        AND trim(raceTagExternalEvent.id & "") EQ trim(VARIABLES.raceTagSource.eventId))
                    OR (!len(trim(VARIABLES.raceTagSource.eventId))
                        AND len(trim(VARIABLES.raceTagSource.eventPath))
                        AND compareNoCase(trim(raceTagExternalEvent.link & ""), trim(VARIABLES.raceTagSource.eventPath)) EQ 0)>
                    <cfset VARIABLES.evento = duplicate(raceTagExternalEvent)/>
                    <cfbreak/>
                </cfif>
            </cfloop>
        </cfif>

        <cfif len(trim(FORM.cod_evento))>
            <cfloop array="#VARIABLES.raceTagExternalEvents#" item="raceTagExternalEvent">
                <cfif trim(raceTagExternalEvent.id & "") EQ trim(FORM.cod_evento)>
                    <cfset VARIABLES.evento = duplicate(raceTagExternalEvent)/>
                    <cfbreak/>
                </cfif>
            </cfloop>
        </cfif>

        <cfif NOT structKeyExists(VARIABLES.evento, "id") AND len(trim(VARIABLES.raceTagSource.eventId))>
            <cfset VARIABLES.evento = { id = VARIABLES.raceTagSource.eventId }/>
        </cfif>

        <cfif structKeyExists(VARIABLES.evento, "id") AND len(trim(VARIABLES.evento.id & ""))>
            <cfset FORM.cod_evento = VARIABLES.evento.id/>
            <cfset FORM.external_event_id = VARIABLES.evento.id/>
            <cfset FORM.url_racetag = VARIABLES.raceTagSource.baseUrl/>
            <cfset VARIABLES.raceTagSource.eventUrl = VARIABLES.raceTagSource.baseUrl & "data/" & encodeForURL(VARIABLES.evento.id & "") & "/event.json"/>

            <cfhttp result="httpEvento"
                    url="#VARIABLES.raceTagSource.eventUrl#"
                    method="get"
                    timeout="30"
                    redirect="false"
                    throwonerror="false">
                <cfhttpparam type="header" name="Accept" value="application/json"/>
                <cfhttpparam type="header" name="User-Agent" value="RunnerHubBusiness-RaceTagImporter/1.0"/>
            </cfhttp>

            <cfset VARIABLES.raceTagEventHttpStatus = structKeyExists(httpEvento, "statusCode") ? httpEvento.statusCode & "" : ""/>
            <cfset VARIABLES.raceTagEventResponseHeaders = structKeyExists(httpEvento, "responseHeader") AND isStruct(httpEvento.responseHeader)
                ? duplicate(httpEvento.responseHeader)
                : {}/>
            <cfset VARIABLES.raceTagEventRawBody = structKeyExists(httpEvento, "fileContent") ? httpEvento.fileContent & "" : ""/>

            <cfif raceTagHttpSucceeded(httpEvento)
                AND len(httpEvento.fileContent & "") LTE (8 * 1024 * 1024)
                AND isJSON(httpEvento.fileContent)>
                <cfset eventoJSON = deserializeJSON(httpEvento.fileContent)/>
                <cfif isStruct(eventoJSON)>
                    <cfset VARIABLES.raceTagEventJsonLoaded = true/>
                    <cfset VARIABLES.raceTagOpenResultsDecision = raceTagOpenResultsPolicy(
                        eventoJSON,
                        VARIABLES.raceTagPayloadOpenResultsEnabled,
                        VARIABLES.raceTagPayloadIntentAvailable,
                        VARIABLES.raceTagUnscopedAccess,
                        VARIABLES.raceTagOpenResultsOverrideRequested
                    )/>
                </cfif>
                <cfif isStruct(eventoJSON)
                    AND structKeyExists(eventoJSON, "routes")
                    AND isArray(eventoJSON.routes)
                    AND arrayLen(eventoJSON.routes)>
                    <cfset VARIABLES.raceTagAnalyzed = true/>
                <cfelse>
                    <cfset VARIABLES.raceTagError = "O event.json foi lido, mas não possui percursos RaceTag Pro válidos."/>
                </cfif>
            <cfelse>
                <cfset VARIABLES.raceTagError = "Não foi possível carregar um event.json válido para o evento externo selecionado."/>
            </cfif>
        <cfelseif len(trim(FORM.url_resultado))>
            <cfset VARIABLES.raceTagError = "Não foi possível identificar o evento na fonte. Selecione um evento externo ou informe seu ID."/>
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.raceTagError = "Falha ao ler a fonte RaceTag Pro: " & cfcatch.message/>
        </cfcatch>
    </cftry>
<cfelseif len(trim(FORM.url_resultado)) AND NOT VARIABLES.raceTagSource.valid>
    <cfset VARIABLES.raceTagError = VARIABLES.raceTagSource.error/>
</cfif>

<cfif VARIABLES.raceTagAnalyzed>
    <cfset VARIABLES.raceTagEventPlace = raceTagPlace(structKeyExists(VARIABLES.evento, "place") ? VARIABLES.evento.place & "" : "")/>
    <cfset VARIABLES.raceTagEventStart = structKeyExists(VARIABLES.evento, "startDate") AND isDate(VARIABLES.evento.startDate) ? VARIABLES.evento.startDate : ""/>
    <cfset VARIABLES.raceTagEventEnd = structKeyExists(VARIABLES.evento, "endDate") AND isDate(VARIABLES.evento.endDate) ? VARIABLES.evento.endDate : VARIABLES.raceTagEventStart/>

    <cfif isDate(VARIABLES.raceTagEventStart) OR val(FORM.id_evento) GT 0>
        <cfquery name="qRaceTagCandidates">
            SELECT id_evento, nome_evento, tag, cidade, estado, data_inicial, data_final
            FROM tb_evento_corridas
            WHERE ativo = true
              AND (
                <cfif val(FORM.id_evento) GT 0>
                    id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(FORM.id_evento)#"/>
                    <cfif isDate(VARIABLES.raceTagEventStart)> OR </cfif>
                </cfif>
                <cfif isDate(VARIABLES.raceTagEventStart)>
                    (
                        data_inicial <= <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.raceTagEventEnd#"/>
                        AND data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.raceTagEventStart#"/>
                        <cfif len(VARIABLES.raceTagEventPlace.state)>
                            AND upper(trim(estado)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.raceTagEventPlace.state#"/>
                        </cfif>
                    )
                </cfif>
              )
            ORDER BY
                CASE WHEN id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#max(0, val(FORM.id_evento))#"/> THEN 0 ELSE 1 END,
                <cfif len(VARIABLES.raceTagEventPlace.city)>
                    CASE WHEN lower(unaccent(trim(cidade))) = lower(unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.raceTagEventPlace.city#"/>)) THEN 0 ELSE 1 END,
                </cfif>
                data_inicial DESC,
                nome_evento
            LIMIT 100
        </cfquery>
    </cfif>

    <cfif val(FORM.id_evento) GT 0>
        <cfquery name="qRaceTagSelectedEvent">
            SELECT id_evento, nome_evento, tag, cidade, estado, data_inicial, data_final
            FROM tb_evento_corridas
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(FORM.id_evento)#"/>
              AND ativo = true
            LIMIT 1
        </cfquery>
    </cfif>

    <cfset VARIABLES.raceTagCanProcess = qRaceTagSelectedEvent.recordcount GT 0/>
</cfif>

<cfif NOT VARIABLES.raceTagStandaloneAllowed AND NOT VARIABLES.raceTagSubmissionReady>
    <div class="alert alert-warning">
        <strong>Selecione uma submissão da sua conta.</strong>
        O processamento externo começa pela fila para preservar o escopo da integração.
        <a class="alert-link" href="/administracao/importacoes-resultados/">Abrir fila de resultados</a>.
    </div>
<cfelse>
<form id="formRaceTag" action="./" method="post">
    <input type="hidden" name="submission_id" value="<cfoutput>#htmlEditFormat(VARIABLES.raceTagSubmissionId)#</cfoutput>"/>
    <input type="hidden" name="external_event_id" value="<cfoutput>#htmlEditFormat(FORM.external_event_id)#</cfoutput>"/>
    <input type="hidden" name="result_import_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.raceTagCsrf)#</cfoutput>"/>

    <div class="mb-3">
        <label for="inputRaceTagUrl" class="form-label">URL técnica ou pública do resultado</label>
        <input type="url"
               class="form-control"
               id="inputRaceTagUrl"
               name="url_resultado"
               required
               <cfif NOT VARIABLES.raceTagUnscopedAccess>readonly</cfif>
               value="<cfoutput>#htmlEditFormat(FORM.url_resultado)#</cfoutput>"
               placeholder="https://.../data/ID/event.json ou https://.../#/evento"/>
        <div class="form-text">Aceita o <code>event.json</code> direto ou a página pública RaceTag Pro.</div>
    </div>

    <div class="mb-3">
        <label for="inputRaceTagPublicUrl" class="form-label">URL pública para os corredores <span class="text-muted">(opcional)</span></label>
        <input type="url"
               class="form-control"
               id="inputRaceTagPublicUrl"
               name="url_resultado_publica"
               <cfif NOT VARIABLES.raceTagUnscopedAccess>readonly</cfif>
               value="<cfoutput>#htmlEditFormat(FORM.url_resultado_publica)#</cfoutput>"
               placeholder="https://.../#/evento"/>
        <div class="form-text">Quando a submissão vem da fila, este campo já utiliza <code>url_resultado_publica</code>.</div>
    </div>

    <cfif len(FORM.url_resultado) AND VARIABLES.raceTagSource.valid>
        <div class="alert alert-secondary py-2 small">
            <strong>Base detectada:</strong> <cfoutput>#htmlEditFormat(VARIABLES.raceTagSource.baseUrl)#</cfoutput>
            <cfif len(VARIABLES.raceTagSource.eventUrl)>
                <br/><strong>event.json:</strong> <cfoutput>#htmlEditFormat(VARIABLES.raceTagSource.eventUrl)#</cfoutput>
            </cfif>
        </div>
    </cfif>

    <cfif arrayLen(VARIABLES.raceTagExternalEvents)>
        <div class="mb-3">
            <label for="inputRaceTagExternalEvent" class="form-label">Evento RaceTag Pro</label>
            <select class="form-select" id="inputRaceTagExternalEvent" name="cod_evento">
                <cfset VARIABLES.raceTagExternalOptionLimit = min(arrayLen(VARIABLES.raceTagExternalEvents), 300)/>
                <cfset VARIABLES.raceTagSelectedExternalInWindow = false/>
                <cfloop from="1" to="#VARIABLES.raceTagExternalOptionLimit#" index="raceTagExternalIndex">
                    <cfif trim(VARIABLES.raceTagExternalEvents[raceTagExternalIndex].id & "") EQ trim(FORM.cod_evento)>
                        <cfset VARIABLES.raceTagSelectedExternalInWindow = true/>
                        <cfbreak/>
                    </cfif>
                </cfloop>
                <cfif NOT VARIABLES.raceTagSelectedExternalInWindow AND structKeyExists(VARIABLES.evento, "id")>
                    <cfoutput>
                        <option value="#htmlEditFormat(VARIABLES.evento.id & '')#" selected>
                            #htmlEditFormat(structKeyExists(VARIABLES.evento, "startDate") ? VARIABLES.evento.startDate & " · " : "")##htmlEditFormat(structKeyExists(VARIABLES.evento, "name") ? VARIABLES.evento.name & "" : "Evento " & VARIABLES.evento.id)#<cfif structKeyExists(VARIABLES.evento, "place") AND len(trim(VARIABLES.evento.place & ""))> · #htmlEditFormat(VARIABLES.evento.place & "")#</cfif>
                        </option>
                    </cfoutput>
                </cfif>
                <cfloop from="1" to="#VARIABLES.raceTagExternalOptionLimit#" index="raceTagExternalIndex">
                    <cfset raceTagExternalOption = VARIABLES.raceTagExternalEvents[raceTagExternalIndex]/>
                    <cfoutput>
                        <option value="#htmlEditFormat(raceTagExternalOption.id & '')#" <cfif trim(FORM.cod_evento) EQ trim(raceTagExternalOption.id & "")>selected</cfif>>
                            #htmlEditFormat(structKeyExists(raceTagExternalOption, "startDate") ? raceTagExternalOption.startDate & " · " : "")##htmlEditFormat(raceTagExternalOption.name & "")#<cfif structKeyExists(raceTagExternalOption, "place") AND len(trim(raceTagExternalOption.place & ""))> · #htmlEditFormat(raceTagExternalOption.place & "")#</cfif>
                        </option>
                    </cfoutput>
                </cfloop>
            </select>
            <div class="form-text">A lista vem de <code>data/events.json</code> e exibe até os 300 eventos mais recentes da fonte.</div>
        </div>
    </cfif>

    <button class="btn btn-outline-warning mb-3" type="submit" name="action" value="analisar">
        <i class="fa-solid fa-magnifying-glass me-1"></i>Ler e conferir evento
    </button>

    <cfif len(VARIABLES.raceTagError)>
        <div class="alert alert-danger"><cfoutput>#htmlEditFormat(VARIABLES.raceTagError)#</cfoutput></div>
    </cfif>

    <cfif VARIABLES.raceTagPayloadIntentAvailable>
        <div class="alert alert-<cfif VARIABLES.raceTagPayloadOpenResultsEnabled>success<cfelse>danger</cfif> border mb-3">
            <div class="fw-bold">Intenção recebida pela API</div>
            <code>open_results_enabled: <cfoutput>#VARIABLES.raceTagPayloadOpenResultsEnabled ? "true" : "false"#</cfoutput></code>
            <div class="small mt-1">Valor persistido junto com a submissão. Se o <code>event.json</code> trouxer a flag, o valor atual dele prevalece.</div>
        </div>
    </cfif>

    <cfif len(VARIABLES.raceTagEventHttpStatus)>
        <cfif VARIABLES.raceTagEventJsonLoaded>
            <cfif VARIABLES.raceTagOpenResultsDecision.state EQ "enabled">
                <div class="alert alert-success border border-success">
                    <div class="fw-bold"><i class="fa-solid fa-circle-check me-1"></i>Envio autorizado pelo provedor</div>
                    <code>openResultsEnabled: true</code>
                </div>
            <cfelseif VARIABLES.raceTagOpenResultsDecision.state EQ "disabled">
                <div class="alert alert-danger border border-danger">
                    <div class="fw-bold"><i class="fa-solid fa-circle-xmark me-1"></i>Processamento não autorizado pelo provedor</div>
                    <code>openResultsEnabled: false</code>
                    <div class="small mt-1">A importação normal está bloqueada. Somente um administrador interno pode executar uma exceção manual.</div>
                </div>
            <cfelseif VARIABLES.raceTagOpenResultsDecision.state EQ "invalid">
                <div class="alert alert-danger border border-danger">
                    <div class="fw-bold"><i class="fa-solid fa-triangle-exclamation me-1"></i>Flag de autorização inválida</div>
                    <code>openResultsEnabled</code> precisa ser um booleano JSON. O processamento normal está bloqueado.
                </div>
            <cfelse>
                <div class="alert alert-<cfif VARIABLES.raceTagOpenResultsDecision.standardAllowed>secondary<cfelse>danger</cfif> border">
                    <div class="fw-bold"><i class="fa-solid fa-circle-question me-1"></i>Autorização não informada</div>
                    <code>openResultsEnabled</code> não existe neste <code>event.json</code>.
                    <cfif VARIABLES.raceTagOpenResultsDecision.decisionSource EQ "payload">
                        A decisão usa a intenção persistida da API e
                        <strong><cfif VARIABLES.raceTagOpenResultsDecision.standardAllowed>autoriza<cfelse>bloqueia</cfif></strong> o processamento normal.
                    <cfelse>
                        A fonte será tratada como formato legado e autoriza o processamento normal.
                    </cfif>
                </div>
            </cfif>

            <cfif VARIABLES.raceTagOpenResultsDecision.divergent>
                <div class="alert alert-warning border border-warning">
                    <div class="fw-bold"><i class="fa-solid fa-code-compare me-1"></i>Intenções divergentes</div>
                    O valor atual do <code>event.json</code> difere do valor recebido pela API. A decisão efetiva usa o <code>event.json</code>.
                </div>
            </cfif>
        </cfif>

        <details class="card bg-body-tertiary shadow-0 mb-3">
            <summary class="card-header fw-bold" role="button">
                Ver resposta atual do event.json
            </summary>
            <div class="card-body">
                <div class="small mb-3">
                    <strong>Status HTTP:</strong>
                    <code><cfoutput>#htmlEditFormat(VARIABLES.raceTagEventHttpStatus)#</cfoutput></code>
                </div>

                <cfif structCount(VARIABLES.raceTagEventResponseHeaders)>
                    <div class="small fw-bold mb-1">Headers retornados pela fonte</div>
                    <div class="table-responsive mb-3">
                        <table class="table table-sm mb-0">
                            <tbody>
                                <cfloop collection="#VARIABLES.raceTagEventResponseHeaders#" item="raceTagResponseHeaderName">
                                    <tr>
                                        <th scope="row"><code><cfoutput>#htmlEditFormat(raceTagResponseHeaderName)#</cfoutput></code></th>
                                        <td class="text-break"><cfoutput>#htmlEditFormat(raceTagResponseHeaderValue(VARIABLES.raceTagEventResponseHeaders[raceTagResponseHeaderName]))#</cfoutput></td>
                                    </tr>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                </cfif>

                <div class="small fw-bold mb-1">Conteúdo bruto atual</div>
                <pre class="bg-dark text-light rounded p-3 mb-1" style="max-height: 28rem; overflow: auto; white-space: pre-wrap;"><cfoutput>#htmlEditFormat(left(VARIABLES.raceTagEventRawBody, min(len(VARIABLES.raceTagEventRawBody), VARIABLES.raceTagEventRawDisplayLimit)))#</cfoutput></pre>
                <cfif len(VARIABLES.raceTagEventRawBody) GT VARIABLES.raceTagEventRawDisplayLimit>
                    <div class="text-warning small">Exibição limitada aos primeiros 256 KB. O arquivo completo continua sendo validado pelo processador.</div>
                </cfif>
                <div class="text-muted small mt-2">Esta é uma consulta atual à URL externa, não uma fotografia do momento em que o webhook foi recebido.</div>
            </div>
        </details>
    </cfif>

    <cfif VARIABLES.raceTagAnalyzed>
        <div class="card bg-body-tertiary shadow-0 mb-3">
            <div class="card-body">
                <div class="d-flex flex-wrap align-items-center gap-2 mb-2">
                    <i class="fa-solid fa-circle-check text-success"></i>
                    <strong>event.json válido</strong>
                    <span class="badge badge-info"><cfoutput>#arrayLen(eventoJSON.routes)#</cfoutput> percurso(s)</span>
                    <cfif structKeyExists(eventoJSON, "extraoficialResults")>
                        <span class="badge badge-<cfif eventoJSON.extraoficialResults>warning<cfelse>success</cfif>">
                            <cfif eventoJSON.extraoficialResults>Extraoficial<cfelse>Final</cfif>
                        </span>
                    </cfif>
                </div>
                <cfoutput>
                    <div><strong>ID externo:</strong> #htmlEditFormat(VARIABLES.evento.id & "")#</div>
                    <cfif structKeyExists(VARIABLES.evento, "name")><div><strong>Evento:</strong> #htmlEditFormat(VARIABLES.evento.name & "")#</div></cfif>
                    <cfif structKeyExists(VARIABLES.evento, "startDate")><div><strong>Data:</strong> #htmlEditFormat(VARIABLES.evento.startDate & "")#<cfif structKeyExists(VARIABLES.evento, "endDate") AND VARIABLES.evento.endDate NEQ VARIABLES.evento.startDate> a #htmlEditFormat(VARIABLES.evento.endDate & "")#</cfif></div></cfif>
                    <cfif structKeyExists(VARIABLES.evento, "place")><div><strong>Local:</strong> #htmlEditFormat(VARIABLES.evento.place & "")#</div></cfif>
                    <cfif structKeyExists(VARIABLES.evento, "organizer") AND len(trim(VARIABLES.evento.organizer & ""))><div><strong>Organizador:</strong> #htmlEditFormat(VARIABLES.evento.organizer & "")#</div></cfif>
                </cfoutput>
            </div>
        </div>

        <div class="mb-3">
            <label for="inputRoadRunnersEvent" class="form-label">Vincular ao evento Road Runners</label>
            <select class="form-select" id="inputRoadRunnersEvent" name="id_evento" required>
                <option value="">Selecione o evento correto</option>
                <cfoutput query="qRaceTagCandidates">
                    <option value="#id_evento#" <cfif val(FORM.id_evento) EQ id_evento>selected</cfif>>
                        #lsDateFormat(data_inicial, "dd/mm/yyyy")# · #htmlEditFormat(nome_evento)# · #htmlEditFormat(cidade)#/#htmlEditFormat(estado)# · ID #id_evento#
                    </option>
                </cfoutput>
            </select>
            <div class="form-text">
                As sugestões combinam data, cidade e UF. Se não houver candidato, cadastre ou localize o evento antes de processar.
            </div>
        </div>

        <cfif VARIABLES.raceTagCanProcess
            AND VARIABLES.raceTagSubmissionCanProcess
            AND VARIABLES.raceTagOpenResultsDecision.standardAllowed>
            <div class="alert alert-warning">
                <strong>Confirme antes de publicar:</strong>
                <cfoutput>#htmlEditFormat(qRaceTagSelectedEvent.nome_evento)# · ID #qRaceTagSelectedEvent.id_evento#</cfoutput>.
                A importação atualizará as tabelas de resultados desse evento.
            </div>
            <button class="btn btn-warning" type="submit" name="action" value="processar">
                <i class="fa-solid fa-gears me-1"></i>Processar resultado agora
            </button>
        <cfelseif VARIABLES.raceTagCanProcess
            AND VARIABLES.raceTagSubmissionCanProcess
            AND VARIABLES.raceTagOpenResultsDecision.overrideAvailable>
            <div class="alert alert-danger">
                <strong>Exceção administrativa:</strong>
                o provedor não autorizou o processamento normal deste evento.
                Marque a confirmação somente se houver uma decisão operacional para importar manualmente.
            </div>
            <div class="form-check mb-3">
                <input class="form-check-input"
                       type="checkbox"
                       id="inputOpenResultsOverride"
                       name="open_results_override"
                       value="1"
                       data-racetag-open-results-override
                       <cfif VARIABLES.raceTagOpenResultsOverrideRequested>checked</cfif>/>
                <label class="form-check-label" for="inputOpenResultsOverride">
                    Estou ciente de que <code>openResultsEnabled</code> está bloqueando este evento e quero processá-lo manualmente.
                </label>
            </div>
            <button class="btn btn-danger"
                    type="submit"
                    name="action"
                    value="processar"
                    data-racetag-open-results-force-button
                    <cfif NOT VARIABLES.raceTagOpenResultsOverrideRequested>disabled</cfif>>
                <i class="fa-solid fa-triangle-exclamation me-1"></i>Processar manualmente mesmo assim
            </button>
        <cfelseif VARIABLES.raceTagCanProcess
            AND VARIABLES.raceTagSubmissionCanProcess
            AND NOT VARIABLES.raceTagOpenResultsDecision.standardAllowed>
            <div class="alert alert-danger mb-0">
                Esta submissão não pode ser processada porque o provedor não autorizou o envio.
            </div>
        <cfelseif NOT VARIABLES.raceTagCanProcess>
            <button class="btn btn-warning" type="submit" name="action" value="analisar">
                Confirmar vínculo
            </button>
        <cfelse>
            <div class="alert alert-secondary mb-0">
                Esta submissão já está <strong><cfoutput>#htmlEditFormat(qRaceTagSubmission.status_processamento)#</cfoutput></strong> e não pode ser reservada novamente por esta tela.
            </div>
        </cfif>
    </cfif>

    <cfif compareNoCase(FORM.action, "processar") EQ 0
        AND VARIABLES.raceTagAnalyzed
        AND VARIABLES.raceTagCanProcess
        AND VARIABLES.raceTagSubmissionCanProcess
        AND NOT VARIABLES.raceTagOpenResultsDecision.processingAllowed>
        <div class="alert alert-danger mt-3">
            <strong>Processamento bloqueado.</strong>
            A fonte externa não autorizou a importação e nenhuma exceção administrativa válida foi confirmada.
        </div>
    </cfif>

    <cfif compareNoCase(FORM.action, "processar") EQ 0
        AND VARIABLES.raceTagAnalyzed
        AND VARIABLES.raceTagCanProcess
        AND VARIABLES.raceTagSubmissionCanProcess
        AND VARIABLES.raceTagOpenResultsDecision.processingAllowed>
        <cfset VARIABLES.raceTagProcessingAttempted = true/>

        <cfif compare(FORM.result_import_csrf, VARIABLES.raceTagCsrf) NEQ 0>
            <div class="alert alert-danger mt-3">A sessão de segurança expirou. Recarregue a página e tente novamente.</div>
        <cfelse>
            <cfif VARIABLES.raceTagOpenResultsDecision.overrideAccepted>
                <cfset VARIABLES.raceTagOverrideExternalEventLog = left(
                    reReplace(trim(FORM.external_event_id & ""), "[^A-Za-z0-9._:-]", "-", "all"),
                    128
                )/>
                <cflog file="business_result_imports"
                       type="warning"
                       text="action=open_results_manual_override actor_id=#VARIABLES.raceTagOverrideActorId# submission_id=#VARIABLES.raceTagSubmissionId# external_event_id=#VARIABLES.raceTagOverrideExternalEventLog# road_event_id=#val(FORM.id_evento)# state=#VARIABLES.raceTagOpenResultsDecision.state#"/>
            </cfif>
            <cftry>
                <cfif NOT raceTagPublicUrlValid(FORM.url_resultado_publica)>
                    <cfthrow type="RaceTag.InvalidPublicUrl" message="A URL pública precisa ser uma URL HTTPS válida com até 2.048 caracteres."/>
                </cfif>

                <!--- Valida a fonte de resultados antes de reservar a submissão. --->
                <cfhttp result="raceTagResultsPreflight"
                        url="#FORM.url_racetag#data/#encodeForURL(VARIABLES.evento.id & '')#/results.json"
                        method="get"
                        timeout="60"
                        redirect="false"
                        throwonerror="false">
                    <cfhttpparam type="header" name="Accept" value="application/json"/>
                    <cfhttpparam type="header" name="User-Agent" value="RunnerHubBusiness-RaceTagImporter/1.0"/>
                </cfhttp>

                <cfif NOT raceTagHttpSucceeded(raceTagResultsPreflight)
                    OR len(raceTagResultsPreflight.fileContent & "") GT (64 * 1024 * 1024)
                    OR NOT isJSON(raceTagResultsPreflight.fileContent)>
                    <cfthrow type="RaceTag.ResultsUnavailable" message="O results.json não está disponível ou não contém JSON válido."/>
                </cfif>

                <cfif VARIABLES.raceTagSubmissionReady>
                    <cfquery name="qRaceTagClaim">
                        UPDATE public.tb_resultados_importacoes
                        SET id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qRaceTagSelectedEvent.id_evento#"/>,
                            external_event_id = coalesce(
                                external_event_id,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.evento.id#"/>
                            ),
                            status_processamento = 'processando',
                            tentativas = tentativas + 1,
                            data_inicio = now(),
                            data_processamento = NULL,
                            data_atualizacao = now(),
                            erro_codigo = NULL,
                            erro_detalhe = NULL
                        WHERE public_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.raceTagSubmissionId#"/> AS uuid)
                          AND lower(trim(cod_timer)) = 'racezone'
                          AND status_processamento IN ('pendente', 'falhou')
                        <cfif NOT VARIABLES.raceTagUnscopedAccess>
                          AND EXISTS (
                              SELECT 1
                              FROM public.tb_conta_integracoes_resultados account_integration
                              WHERE account_integration.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.raceTagScopeAccountId#"/>
                                AND account_integration.ativo = true
                                AND lower(trim(account_integration.client_id)) = lower(trim(tb_resultados_importacoes.client_id))
                                AND lower(trim(account_integration.cod_timer)) = lower(trim(tb_resultados_importacoes.cod_timer))
                                AND (
                                  account_integration.abrange_contas_externas = true
                                  OR nullif(trim(account_integration.external_account_id), '')
                                      IS NOT DISTINCT FROM nullif(trim(tb_resultados_importacoes.external_account_id), '')
                                )
                          )
                        </cfif>
                        RETURNING id_resultado_importacao
                    </cfquery>

                    <cfif NOT qRaceTagClaim.recordcount>
                        <cfthrow type="RaceTag.QueueConflict" message="A submissão não está pendente nem com falha; atualize a fila antes de tentar novamente."/>
                    </cfif>
                    <cfset VARIABLES.raceTagQueueClaimed = true/>
                </cfif>

                <cfset VARIABLES.raceTagProcessStartedAt = now()/>

                <cftransaction>
                    <cfquery name="qRaceTagEventLock">
                        SELECT pg_advisory_xact_lock(
                            20260806,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qRaceTagSelectedEvent.id_evento#"/>
                        )
                    </cfquery>

                    <div class="mt-4">
                        <cfinclude template="parse.cfm"/>
                    </div>

                    <cfquery name="qRaceTagCurrentProcessing">
                        SELECT chave_processamento, chave_verificacao, erro_execucao,
                               data_processamento_inicial, data_processamento_final
                        FROM tb_resultados_processa
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qRaceTagSelectedEvent.id_evento#"/>
                          AND data_processamento_inicial >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#dateAdd('s', -5, VARIABLES.raceTagProcessStartedAt)#"/>
                        ORDER BY data_processamento_inicial DESC
                        LIMIT 1
                    </cfquery>

                    <cfif NOT qRaceTagCurrentProcessing.recordcount>
                        <cfthrow type="RaceTag.NoProcessingLog" message="A procedure não registrou uma nova execução para esta submissão."/>
                    </cfif>

                    <cfif NOT isDefined("qPanorama") OR NOT qPanorama.recordcount>
                        <cfthrow type="RaceTag.EmptyProduction" message="O processamento terminou sem resultados na grade de produção."/>
                    </cfif>

                    <cfquery>
                        UPDATE tb_evento_corridas
                        SET url_wiclax = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.raceTagSource.eventUrl#"/>,
                            url_resultado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#len(trim(FORM.url_resultado_publica)) ? FORM.url_resultado_publica : FORM.url_resultado#"/>
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qRaceTagSelectedEvent.id_evento#"/>
                    </cfquery>

                    <cfif VARIABLES.raceTagSubmissionReady>
                        <cfquery>
                            UPDATE public.tb_resultados_importacoes
                            SET status_processamento = 'processado',
                                total_resultados = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(qCountTemp.total)#"/>,
                                data_processamento = now(),
                                data_atualizacao = now(),
                                erro_codigo = <cfqueryparam cfsqltype="cf_sql_varchar" value="procedure_warning" null="#NOT qRaceTagCurrentProcessing.erro_execucao#"/>,
                                erro_detalhe = <cfqueryparam cfsqltype="cf_sql_varchar" value="A procedure concluiu com avisos; consulte o log detalhado." null="#NOT qRaceTagCurrentProcessing.erro_execucao#"/>
                            WHERE public_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.raceTagSubmissionId#"/> AS uuid)
                        </cfquery>
                    </cfif>
                </cftransaction>

                <cfset VARIABLES.raceTagProcessingSucceeded = true/>
                <div class="alert alert-success mt-3">
                    <strong>Resultado processado.</strong>
                    <cfif VARIABLES.raceTagSubmissionReady>
                        A fila e as URLs do evento foram atualizadas.
                    <cfelse>
                        As URLs do evento foram atualizadas.
                    </cfif>
                    <cfif qRaceTagCurrentProcessing.erro_execucao>
                        <span class="d-block mt-1 text-warning">A procedure registrou avisos; revise o log exibido acima.</span>
                    </cfif>
                </div>

                <cfcatch type="any">
                    <cfset VARIABLES.raceTagProcessingError = cfcatch.message/>
                    <cfif VARIABLES.raceTagSubmissionReady AND VARIABLES.raceTagQueueClaimed>
                        <cfquery>
                            UPDATE public.tb_resultados_importacoes
                            SET status_processamento = 'falhou',
                                data_processamento = now(),
                                data_atualizacao = now(),
                                erro_codigo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(listLast(cfcatch.type, '.'), 64)#"/>,
                                erro_detalhe = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(cfcatch.message & (len(trim(cfcatch.detail & '')) ? ' ' & cfcatch.detail : ''), 1024)#"/>
                            WHERE public_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.raceTagSubmissionId#"/> AS uuid)
                        </cfquery>
                    </cfif>
                    <div class="alert alert-danger mt-3">
                        <strong>Falha no processamento.</strong>
                        <cfoutput>#htmlEditFormat(cfcatch.message)#</cfoutput>
                    </div>
                </cfcatch>
            </cftry>
        </cfif>
    </cfif>
</form>
<script src="/assets/js/racetag-open-results.js"></script>
<script>
    if (window.RaceTagOpenResults) {
        window.RaceTagOpenResults.initialize(document);
    }
</script>
</cfif>
