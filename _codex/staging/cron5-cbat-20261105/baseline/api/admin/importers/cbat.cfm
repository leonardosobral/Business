<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false" requesttimeout="900">
<cfscript>
function sendJson(required numeric statusCode, required struct payload) {
    cfheader(
        statuscode=arguments.statusCode);
    writeOutput(serializeJSON(arguments.payload, "struct", false));
}

function textOrEmpty(value) {
    if (isNull(arguments.value)) {
        return "";
    }

    return trim(arguments.value & "");
}

function parseHandoffTimestamp(required string rawValue) {
    var normalized = trim(arguments.rawValue);

    if (!len(normalized)) {
        return "";
    }

    if (isNumeric(normalized)) {
        return dateAdd("s", val(normalized), createDateTime(1970, 1, 1, 0, 0, 0));
    }

    normalized = replace(normalized, "T", " ", "all");
    normalized = replace(normalized, "Z", "", "all");

    if (isDate(normalized)) {
        return parseDateTime(normalized);
    }

    return "";
}

function buildHmacSignature(required string message, required string secret) {
    return lCase(hmac(arguments.message, arguments.secret, "HmacSHA256", "UTF-8"));
}

function isTruthy(value) {
    var normalized = lCase(textOrEmpty(arguments.value));

    if (isBoolean(arguments.value)) {
        return arguments.value;
    }

    return listFindNoCase("1,true,yes,on", normalized) GT 0;
}

db = createObject("component", "inc.db");
requestData = getHttpRequestData();
rawBody = "";
rawTimestamp = textOrEmpty(cgi.http_x_rr_handoff_timestamp ?: "");
providedSignature = lCase(textOrEmpty(cgi.http_x_rr_handoff_signature ?: ""));
configuredSecret = textOrEmpty(application.importerHandoffSecret ?: "");
parsedTimestamp = "";
payloadData = {};
importResponse = {};
lockAcquired = false;
lockKey = 910003;
timestampDriftSeconds = 300;

if (structKeyExists(requestData, "content")) {
    rawBody = requestData.content & "";
}

if (cgi.request_method NEQ "POST") {
    sendJson(405, {
        success = false,
        status = "method_not_allowed",
        importados = 0,
        duplicados = 0,
        erros = 1,
        message = "Use POST neste endpoint."
    });
    abort;
}

if (!len(configuredSecret)) {
    sendJson(500, {
        success = false,
        status = "misconfigured",
        importados = 0,
        duplicados = 0,
        erros = 1,
        message = "IMPORTER_HANDOFF_SECRET não configurado."
    });
    abort;
}

if (!len(rawTimestamp) OR !len(providedSignature)) {
    sendJson(401, {
        success = false,
        status = "unauthorized",
        importados = 0,
        duplicados = 0,
        erros = 1,
        message = "Cabeçalhos de autenticação ausentes."
    });
    abort;
}

parsedTimestamp = parseHandoffTimestamp(rawTimestamp);
if (!isDate(parsedTimestamp)) {
    sendJson(401, {
        success = false,
        status = "unauthorized",
        importados = 0,
        duplicados = 0,
        erros = 1,
        message = "Timestamp inválido."
    });
    abort;
}

if (abs(dateDiff("s", parsedTimestamp, now())) GT timestampDriftSeconds) {
    sendJson(401, {
        success = false,
        status = "unauthorized",
        importados = 0,
        duplicados = 0,
        erros = 1,
        message = "Timestamp fora da janela permitida."
    });
    abort;
}

if (providedSignature NEQ buildHmacSignature(rawTimestamp & "." & rawBody, configuredSecret)) {
    sendJson(401, {
        success = false,
        status = "unauthorized",
        importados = 0,
        duplicados = 0,
        erros = 1,
        message = "Assinatura inválida."
    });
    abort;
}

if (len(trim(rawBody))) {
    if (!isJSON(rawBody)) {
        sendJson(400, {
            success = false,
            status = "invalid_body",
            importados = 0,
            duplicados = 0,
            erros = 1,
            message = "O corpo da requisição precisa ser JSON válido."
        });
        abort;
    }

    payloadData = deserializeJSON(rawBody);
    if (!isStruct(payloadData)) {
        sendJson(400, {
            success = false,
            status = "invalid_body",
            importados = 0,
            duplicados = 0,
            erros = 1,
            message = "O corpo JSON precisa ser um objeto."
        });
        abort;
    }
}

try {
    lockResult = db.q("
      SELECT pg_try_advisory_lock(:lock_key) AS acquired
    ", {
      lock_key: {value=lockKey, cfsqltype="cf_sql_bigint"}
    });

    lockAcquired = (
        lockResult.recordCount
        AND (
            (isBoolean(lockResult.acquired[1]) AND lockResult.acquired[1])
            OR textOrEmpty(lockResult.acquired[1]) EQ "t"
            OR textOrEmpty(lockResult.acquired[1]) EQ "true"
            OR val(lockResult.acquired[1]) EQ 1
        )
    );

    if (!lockAcquired) {
        sendJson(409, {
            success = false,
            status = "locked",
            importados = 0,
            duplicados = 0,
            erros = 1,
            message = "O importador CBAt já está em execução."
        });
        abort;
    }

    request.cbatImporterExecutionMode = "api";
    form.import_mode = textOrEmpty(payloadData.import_mode ?: "latest");
    form.import_status = textOrEmpty(payloadData.import_status ?: "review");
    form.max_pages = textOrEmpty(payloadData.max_pages ?: "0");
    form.reimport_content_id = textOrEmpty(payloadData.content_id ?: payloadData.reimport_content_id ?: "0");

    if (structKeyExists(payloadData, "download_featured_media")) {
        form.download_featured_media = isTruthy(payloadData.download_featured_media) ? "1" : "0";
    } else {
        form.download_featured_media = "1";
    }

    include "/admin/importer_cbat_corridaderua.cfm";

    if (!structKeyExists(request, "cbatImporterResponse") OR !isStruct(request.cbatImporterResponse)) {
        sendJson(500, {
            success = false,
            status = "failed",
            importados = 0,
            duplicados = 0,
            erros = 1,
            message = "O importador não retornou resposta técnica."
        });
        abort;
    }

    importResponse = request.cbatImporterResponse;
    sendJson(importResponse.success ? 200 : 500, importResponse);
} catch (any e) {
    sendJson(500, {
        success = false,
        status = "failed",
        importados = 0,
        duplicados = 0,
        erros = 1,
        message = textOrEmpty(e.message ?: "Falha inesperada ao executar o importador.")
    });
} finally {
    if (lockAcquired) {
        try {
            db.q("
              SELECT pg_advisory_unlock(:lock_key)
            ", {
              lock_key: {value=lockKey, cfsqltype="cf_sql_bigint"}
            });
        } catch (any unlockError) {}
    }

    if (structKeyExists(request, "cbatImporterExecutionMode")) {
        structDelete(request, "cbatImporterExecutionMode");
    }
    if (structKeyExists(request, "cbatImporterResponse")) {
        structDelete(request, "cbatImporterResponse");
    }
}
</cfscript>
