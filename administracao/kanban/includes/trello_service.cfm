<cfscript>
function kanbanBoolean(any value = false) {
    if (isBoolean(arguments.value)) {
        return arguments.value;
    }
    return listFindNoCase("1,true,yes,on,sim", trim(arguments.value & "")) GT 0;
}

function kanbanTrelloId(required string value) {
    var normalized = trim(arguments.value & "");
    if (!reFindNoCase("^[0-9a-f]{24}$", normalized)) {
        throw(type = "TrelloKanban.Validation", message = "Identificador do Trello inválido.");
    }
    return lCase(normalized);
}

function kanbanTrelloConfigured() {
    return structKeyExists(APPLICATION, "trello")
        AND isStruct(APPLICATION.trello)
        AND structKeyExists(APPLICATION.trello, "enabled")
        AND kanbanBoolean(APPLICATION.trello.enabled)
        AND structKeyExists(APPLICATION.trello, "apiKey")
        AND len(trim(APPLICATION.trello.apiKey & ""))
        AND structKeyExists(APPLICATION.trello, "apiToken")
        AND len(trim(APPLICATION.trello.apiToken & ""));
}

function kanbanHttpStatus(required struct httpResult) {
    var rawStatus = structKeyExists(arguments.httpResult, "statusCode")
        ? trim(arguments.httpResult.statusCode & "")
        : "";
    var numericStatus = val(left(rawStatus, 3));
    return numericStatus GT 0 ? numericStatus : 502;
}

function kanbanRemoteError(required string rawBody, numeric httpStatus = 502) {
    var message = "O Trello não respondeu como esperado.";
    var payload = {};

    if (len(trim(arguments.rawBody)) AND isJSON(arguments.rawBody)) {
        try {
            payload = deserializeJSON(arguments.rawBody);
            if (isStruct(payload) AND structKeyExists(payload, "message") AND len(trim(payload.message & ""))) {
                message = trim(payload.message & "");
            } else if (isStruct(payload) AND structKeyExists(payload, "error") AND len(trim(payload.error & ""))) {
                message = trim(payload.error & "");
            }
        } catch (any ignoredJsonError) {}
    }

    if (arguments.httpStatus EQ 401 OR arguments.httpStatus EQ 403) {
        return "A credencial do Trello não possui acesso a esta operação.";
    }
    if (arguments.httpStatus EQ 404) {
        return "O quadro, lista ou cartão não foi encontrado no Trello.";
    }
    if (arguments.httpStatus EQ 429) {
        return "O limite temporário da API do Trello foi atingido. Aguarde alguns segundos.";
    }
    return left(message, 500);
}

function kanbanLogRemoteFailure(
    required string method,
    required string path,
    numeric httpStatus = 0,
    string message = "",
    string detail = ""
) {
    var safeMethod = reReplace(uCase(arguments.method), "[^A-Z]", "", "all");
    var safePath = left(reReplace(arguments.path, "[\r\n]+", " ", "all"), 300);
    var safeMessage = left(reReplace(arguments.message, "[\r\n]+", " ", "all"), 700);
    var safeDetail = left(reReplace(arguments.detail, "[\r\n]+", " ", "all"), 1200);

    cflog(
        file = "trello_kanban",
        type = "error",
        text = "method=#safeMethod# path=#safePath# status=#val(arguments.httpStatus)# message=#safeMessage# detail=#safeDetail#"
    );
}

function kanbanTrelloParamName(required string rawName) {
    var canonicalNames = {
        "duecomplete" = "dueComplete",
        "idboard" = "idBoard",
        "idlist" = "idList",
        "idmembers" = "idMembers",
        "membercreator" = "memberCreator",
        "membercreator_fields" = "memberCreator_fields"
    };
    var lookupName = lCase(trim(arguments.rawName));

    return structKeyExists(canonicalNames, lookupName)
        ? canonicalNames[lookupName]
        : lookupName;
}

function kanbanFormBody(struct params = {}) {
    var pairs = [];
    var paramName = "";
    var outboundName = "";
    var paramValue = "";

    for (paramName in arguments.params) {
        if (isNull(arguments.params[paramName])) {
            continue;
        }
        outboundName = kanbanTrelloParamName(paramName);
        paramValue = arguments.params[paramName] & "";
        arrayAppend(
            pairs,
            urlEncodedFormat(outboundName, "UTF-8") & "=" & urlEncodedFormat(paramValue, "UTF-8")
        );
    }

    return arrayToList(pairs, "&");
}

function kanbanTrelloRequest(
    required string path,
    string method = "GET",
    struct params = {},
    numeric timeoutSeconds = 0
) {
    var result = {
        success = false,
        status = 502,
        data = {},
        raw = "",
        message = ""
    };
    var requestMethod = uCase(trim(arguments.method));
    var requestTimeout = arguments.timeoutSeconds GT 0
        ? min(45, max(5, int(arguments.timeoutSeconds)))
        : 20;
    var baseUrl = "https://api.trello.com/1";
    var requestUrl = "";
    var authorization = "";
    var paramName = "";
    var outboundParamName = "";
    var requestBody = "";
    var httpResult = {};

    if (!kanbanTrelloConfigured()) {
        throw(type = "TrelloKanban.Configuration", message = "Configure RR_TRELLO_API_KEY e RR_TRELLO_API_TOKEN no servidor.");
    }

    if (!listFindNoCase("GET,POST,PUT,DELETE", requestMethod)) {
        throw(type = "TrelloKanban.Validation", message = "Método HTTP não permitido para o Trello.");
    }
    if (!reFind("^/[A-Za-z0-9_/?=&,.-]+$", arguments.path)) {
        throw(type = "TrelloKanban.Validation", message = "Caminho da API do Trello inválido.");
    }

    if (structKeyExists(APPLICATION.trello, "baseUrl") AND len(trim(APPLICATION.trello.baseUrl & ""))) {
        baseUrl = reReplace(trim(APPLICATION.trello.baseUrl & ""), "/+$", "", "all");
    }
    if (structKeyExists(APPLICATION.trello, "timeoutSeconds") AND val(APPLICATION.trello.timeoutSeconds) GT 0) {
        requestTimeout = min(45, max(5, int(APPLICATION.trello.timeoutSeconds)));
    }

    if (!reFindNoCase("^https://api\.trello\.com/1$", baseUrl)) {
        throw(type = "TrelloKanban.Configuration", message = "A URL base do Trello não é permitida.");
    }
    if (reFind('[\r\n"]', APPLICATION.trello.apiKey & "") OR reFind('[\r\n"]', APPLICATION.trello.apiToken & "")) {
        throw(type = "TrelloKanban.Configuration", message = "A credencial do Trello contém caracteres inválidos.");
    }

    requestUrl = baseUrl & arguments.path;
    authorization = 'OAuth oauth_consumer_key="' & trim(APPLICATION.trello.apiKey & "")
        & '", oauth_token="' & trim(APPLICATION.trello.apiToken & "") & '"';
    if (requestMethod EQ "POST" OR requestMethod EQ "PUT") {
        requestBody = kanbanFormBody(arguments.params);
    }

    try {
        cfhttp(
            url = requestUrl,
            method = requestMethod,
            result = "httpResult",
            timeout = requestTimeout,
            throwOnError = false
        ) {
            cfhttpparam(type = "header", name = "Accept", value = "application/json");
            cfhttpparam(type = "header", name = "Authorization", value = authorization);
            cfhttpparam(type = "header", name = "User-Agent", value = "RunnerHub-Business-Kanban/1.0");
            if (requestMethod EQ "GET" OR requestMethod EQ "DELETE") {
                for (paramName in arguments.params) {
                    if (isNull(arguments.params[paramName])) {
                        continue;
                    }
                    outboundParamName = kanbanTrelloParamName(paramName);
                    cfhttpparam(type = "url", name = outboundParamName, value = arguments.params[paramName] & "");
                }
            } else {
                cfhttpparam(type = "header", name = "Content-Type", value = "application/x-www-form-urlencoded; charset=UTF-8");
                cfhttpparam(type = "body", value = requestBody);
            }
        }

        result.status = kanbanHttpStatus(httpResult);
        result.raw = structKeyExists(httpResult, "fileContent") ? (httpResult.fileContent & "") : "";
        result.success = result.status GTE 200 AND result.status LT 300;

        if (len(trim(result.raw)) AND isJSON(result.raw)) {
            result.data = deserializeJSON(result.raw);
        } else if (result.success) {
            result.data = {};
        }

        if (!result.success) {
            result.message = kanbanRemoteError(result.raw, result.status);
            kanbanLogRemoteFailure(requestMethod, arguments.path, result.status, result.message);
        }
    } catch (any requestError) {
        result.success = false;
        result.status = 502;
        result.message = "Não foi possível comunicar com o Trello.";
        kanbanLogRemoteFailure(
            requestMethod,
            arguments.path,
            result.status,
            requestError.message & "",
            structKeyExists(requestError, "detail") ? requestError.detail & "" : ""
        );
    }

    return result;
}

function kanbanAudit(
    required string action,
    required boolean success,
    string boardId = "",
    string cardId = "",
    numeric mappedBoardId = 0,
    numeric httpStatus = 0,
    struct details = {},
    string errorMessage = ""
) {
    var actorId = isDefined("qPerfil") AND qPerfil.recordCount ? val(qPerfil.id) : 0;
    var sourceIp = structKeyExists(CGI, "remote_addr") ? left(CGI.remote_addr & "", 64) : "";
    var userAgent = structKeyExists(CGI, "http_user_agent") ? left(CGI.http_user_agent & "", 512) : "";
    var detailsJson = serializeJSON(arguments.details);

    try {
        queryExecute(
            "INSERT INTO public.tb_trello_auditoria
                (id_usuario, id_trello_quadro, trello_board_id, trello_card_id, acao,
                 sucesso, http_status, detalhes, mensagem_erro, endereco_ip, user_agent)
             VALUES
                (:actorId, :mappedBoardId, :boardId, :cardId, :action,
                 :success, :httpStatus, CAST(:details AS jsonb), :errorMessage, :sourceIp, :userAgent)",
            {
                actorId = {value = actorId, cfsqltype = "cf_sql_integer", null = actorId LTE 0},
                mappedBoardId = {value = arguments.mappedBoardId, cfsqltype = "cf_sql_bigint", null = arguments.mappedBoardId LTE 0},
                boardId = {value = left(arguments.boardId, 32), cfsqltype = "cf_sql_varchar", null = !len(arguments.boardId)},
                cardId = {value = left(arguments.cardId, 32), cfsqltype = "cf_sql_varchar", null = !len(arguments.cardId)},
                action = {value = left(arguments.action, 64), cfsqltype = "cf_sql_varchar"},
                success = {value = arguments.success, cfsqltype = "cf_sql_boolean"},
                httpStatus = {value = arguments.httpStatus, cfsqltype = "cf_sql_integer", null = arguments.httpStatus LTE 0},
                details = {value = detailsJson, cfsqltype = "cf_sql_longvarchar"},
                errorMessage = {value = left(arguments.errorMessage, 1000), cfsqltype = "cf_sql_varchar", null = !len(arguments.errorMessage)},
                sourceIp = {value = sourceIp, cfsqltype = "cf_sql_varchar", null = !len(sourceIp)},
                userAgent = {value = userAgent, cfsqltype = "cf_sql_varchar", null = !len(userAgent)}
            },
            {datasource = "runner_dba"}
        );
    } catch (any ignoredAuditError) {}
}
</cfscript>
