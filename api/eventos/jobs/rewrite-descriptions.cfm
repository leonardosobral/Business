<cfsetting showdebugoutput="false" requesttimeout="110" />
<cfscript>
function rewriteJsonResponse(required numeric statusCode, required struct payload) {
    var labels = {"200"="OK", "400"="Bad Request", "401"="Unauthorized", "405"="Method Not Allowed", "409"="Conflict", "422"="Unprocessable Entity", "502"="Bad Gateway", "503"="Service Unavailable"};
    cfheader(statuscode=arguments.statusCode, statustext=structKeyExists(labels, arguments.statusCode) ? labels[arguments.statusCode] : "Internal Server Error");
    cfcontent(type="application/json; charset=utf-8", reset=true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function rewriteRequestHeader(required struct requestData, required string headerName) {
    var cgiKey = "http_" & lCase(replace(arguments.headerName, "-", "_", "all"));
    if (structKeyExists(arguments.requestData, "headers") AND isStruct(arguments.requestData.headers)
        AND structKeyExists(arguments.requestData.headers, arguments.headerName)) {
        return trim(arguments.requestData.headers[arguments.headerName] & "");
    }
    return structKeyExists(CGI, cgiKey) ? trim(CGI[cgiKey] & "") : "";
}

function rewriteValidHmac(required string secret, required string body, required string timestamp, required string signature) {
    if (!len(arguments.secret) OR !len(arguments.timestamp) OR !reFindNoCase("^[0-9a-f]{64}$", arguments.signature)) return false;
    try {
        if (abs(dateDiff("s", parseDateTime(arguments.timestamp), now())) GT 300) return false;
    } catch (any invalidTimestamp) { return false; }
    var expected = lCase(hmac(arguments.timestamp & "." & arguments.body, arguments.secret, "HmacSHA256", "UTF-8"));
    return hash(expected, "SHA-256") EQ hash(lCase(arguments.signature), "SHA-256");
}

if (uCase(CGI.request_method & "") NEQ "POST") {
    cfheader(name="Allow", value="POST");
    rewriteJsonResponse(405, {success=false, status="method_not_allowed", message="Use POST com corpo JSON."});
}

// Read request-scoped configuration so secret/key rotations need no application restart.
VARIABLES.businessLocalConfig = {};
if (fileExists(expandPath("/config/business.local.cfm"))) include "../../../config/business.local.cfm";
VARIABLES.rewriteSecret = "";
if (structKeyExists(VARIABLES.businessLocalConfig, "cronSecrets") AND isStruct(VARIABLES.businessLocalConfig.cronSecrets)
    AND structKeyExists(VARIABLES.businessLocalConfig.cronSecrets, "business_internal")) {
    VARIABLES.rewriteSecret = trim(VARIABLES.businessLocalConfig.cronSecrets.business_internal & "");
}
if (!len(VARIABLES.rewriteSecret)) {
    rewriteJsonResponse(503, {success=false, status="configuration_error", message="Segredo interno do cron não configurado."});
}

VARIABLES.rewriteRequest = getHttpRequestData();
VARIABLES.rewriteBody = structKeyExists(VARIABLES.rewriteRequest, "content")
    ? (isBinary(VARIABLES.rewriteRequest.content) ? charsetEncode(VARIABLES.rewriteRequest.content, "UTF-8") : VARIABLES.rewriteRequest.content & "") : "";
if (!rewriteValidHmac(VARIABLES.rewriteSecret, VARIABLES.rewriteBody,
    rewriteRequestHeader(VARIABLES.rewriteRequest, "X-RR-Handoff-Timestamp"),
    rewriteRequestHeader(VARIABLES.rewriteRequest, "X-RR-Handoff-Signature"))) {
    rewriteJsonResponse(401, {success=false, status="unauthorized", message="Assinatura inválida ou ausente."});
}
if (!len(trim(VARIABLES.rewriteBody)) OR len(VARIABLES.rewriteBody) GT 4096) {
    rewriteJsonResponse(400, {success=false, status="invalid_json", message="Envie um objeto JSON de até 4096 caracteres."});
}
try { VARIABLES.rewritePayload = deserializeJSON(VARIABLES.rewriteBody); }
catch (any invalidJson) { rewriteJsonResponse(400, {success=false, status="invalid_json", message="O corpo não contém JSON válido."}); }
if (!isStruct(VARIABLES.rewritePayload)) {
    rewriteJsonResponse(400, {success=false, status="validation_error", message="O corpo JSON deve ser um objeto."});
}
for (VARIABLES.rewriteField in VARIABLES.rewritePayload) {
    if (isNull(VARIABLES.rewritePayload[VARIABLES.rewriteField])) {
        rewriteJsonResponse(400, {success=false, status="validation_error", message="Parâmetros não podem ser null."});
    }
    if (!listFindNoCase("limit,dryRun,eventId", VARIABLES.rewriteField)) {
        rewriteJsonResponse(400, {success=false, status="validation_error", message="Parâmetro não permitido. Use limit, dryRun e eventId."});
    }
}
VARIABLES.rewriteLimit = 1;
VARIABLES.rewriteDryRun = true;
VARIABLES.rewriteEventId = 0;
if (structKeyExists(VARIABLES.rewritePayload, "limit")) {
    if (!isSimpleValue(VARIABLES.rewritePayload.limit) OR !reFind("^1$", VARIABLES.rewritePayload.limit & "")) {
        rewriteJsonResponse(400, {success=false, status="validation_error", message="limit deve ser 1."});
    }
}
if (structKeyExists(VARIABLES.rewritePayload, "dryRun")) {
    if (!isSimpleValue(VARIABLES.rewritePayload.dryRun) OR !reFindNoCase("^(true|false)$", serializeJSON(VARIABLES.rewritePayload.dryRun))) {
        rewriteJsonResponse(400, {success=false, status="validation_error", message="dryRun deve ser true ou false."});
    }
    VARIABLES.rewriteDryRun = VARIABLES.rewritePayload.dryRun;
}
if (structKeyExists(VARIABLES.rewritePayload, "eventId")) {
    if (!isSimpleValue(VARIABLES.rewritePayload.eventId) OR !reFind("^[1-9][0-9]{0,9}$", VARIABLES.rewritePayload.eventId & "")
        OR val(VARIABLES.rewritePayload.eventId) GT 2147483647) {
        rewriteJsonResponse(400, {success=false, status="validation_error", message="eventId deve ser um inteiro positivo válido."});
    }
    VARIABLES.rewriteEventId = val(VARIABLES.rewritePayload.eventId);
}
VARIABLES.rewriteEnvironment = createObject("java", "java.lang.System").getenv();
VARIABLES.rewriteApiKey = VARIABLES.rewriteEnvironment.containsKey("OPENAI_API_KEY") ? trim(VARIABLES.rewriteEnvironment.get("OPENAI_API_KEY") & "") : "";
if (!len(VARIABLES.rewriteApiKey) AND structKeyExists(VARIABLES.businessLocalConfig, "openAiApiKey")) {
    VARIABLES.rewriteApiKey = trim(VARIABLES.businessLocalConfig.openAiApiKey & "");
}
VARIABLES.rewriteModel = structKeyExists(VARIABLES.businessLocalConfig, "eventDescriptionModel")
    ? trim(VARIABLES.businessLocalConfig.eventDescriptionModel & "") : "gpt-4.1-mini";
if (!len(VARIABLES.rewriteApiKey) OR !len(VARIABLES.rewriteModel) OR len(VARIABLES.rewriteModel) GT 80) {
    rewriteJsonResponse(503, {success=false, status="configuration_error", message="Chave ou modelo da IA não configurado."});
}

VARIABLES.rewriteDbOptions = {datasource="runner_dba"};
try {
    VARIABLES.rewriteSchema = queryExecute("SELECT to_regclass('public.tb_evento_descricao_rewrites') IS NOT NULL AS ready", [], VARIABLES.rewriteDbOptions);
} catch (any unavailableDatabase) {
    rewriteJsonResponse(503, {success=false, status="database_unavailable", message="Banco indisponível para a reescrita."});
}
if (!VARIABLES.rewriteSchema.ready[1]) {
    rewriteJsonResponse(503, {success=false, status="schema_required", message="Instale o schema de auditoria da reescrita antes de executar."});
}
VARIABLES.rewriteResponse = {success=true, status="completed", dryRun=VARIABLES.rewriteDryRun, selected=0, processed=0, updated=0, skipped=0, errors=0, results=[]};
VARIABLES.rewriteHttpStatus = 200;
VARIABLES.rewriteLocked = false;
try {
    transaction {
        // The transaction lock covers selection, provider calls and compare-and-set write.
        VARIABLES.rewriteLock = queryExecute("SELECT pg_try_advisory_xact_lock(1380472914, 1) AS acquired", [], VARIABLES.rewriteDbOptions);
        VARIABLES.rewriteLocked = !VARIABLES.rewriteLock.acquired[1];
        if (!VARIABLES.rewriteLocked) {
            VARIABLES.rewriteCandidates = queryExecute("
                SELECT evt.id_evento, evt.descricao_original AS source_text
                FROM public.tb_evento_corridas evt
                WHERE length(COALESCE(evt.descricao_original, '')) > 200
                  AND btrim(COALESCE(evt.descricao, '')) = ''
                  AND (:event_id = 0 OR evt.id_evento = :event_id)
                  AND NOT EXISTS (
                      SELECT 1 FROM public.tb_evento_descricao_rewrites audit
                      WHERE audit.id_evento = evt.id_evento AND audit.source_hash = md5(evt.descricao_original)
                  )
                ORDER BY CASE WHEN COALESCE(evt.data_final, evt.data_inicial) >= CURRENT_DATE THEN 0 ELSE 1 END, evt.id_evento
                LIMIT 1", {event_id={value=VARIABLES.rewriteEventId, cfsqltype="cf_sql_integer"}}, VARIABLES.rewriteDbOptions);
            VARIABLES.rewriteResponse.selected = VARIABLES.rewriteCandidates.recordCount;
            for (VARIABLES.rewriteRow in VARIABLES.rewriteCandidates) {
                VARIABLES.rewriteSource = VARIABLES.rewriteRow.source_text & "";
                VARIABLES.rewriteSourceHash = lCase(hash(VARIABLES.rewriteSource, "MD5", "UTF-8"));
                VARIABLES.rewriteAuditId = 0;
                VARIABLES.rewriteResult = {id=VARIABLES.rewriteRow.id_evento, status="error"};
                if (!VARIABLES.rewriteDryRun) {
                    VARIABLES.rewriteAudit = queryExecute("
                        INSERT INTO public.tb_evento_descricao_rewrites
                            (id_evento, source_hash, source_text, status, description_before, model)
                        SELECT evt.id_evento, :source_hash, evt.descricao_original, 'running', evt.descricao, :model
                        FROM public.tb_evento_corridas evt
                        WHERE evt.id_evento = :event_id AND evt.descricao_original = :source_text
                          AND btrim(COALESCE(evt.descricao, '')) = ''
                        RETURNING id", {
                        event_id={value=VARIABLES.rewriteRow.id_evento, cfsqltype="cf_sql_integer"},
                        source_hash={value=VARIABLES.rewriteSourceHash, cfsqltype="cf_sql_varchar"},
                        source_text={value=VARIABLES.rewriteSource, cfsqltype="cf_sql_longvarchar"},
                        model={value=VARIABLES.rewriteModel, cfsqltype="cf_sql_varchar"}
                    }, VARIABLES.rewriteDbOptions);
                    if (!VARIABLES.rewriteAudit.recordCount) {
                        VARIABLES.rewriteResult.status = "source_changed";
                        VARIABLES.rewriteResponse.skipped++;
                        arrayAppend(VARIABLES.rewriteResponse.results, VARIABLES.rewriteResult);
                        continue;
                    }
                    VARIABLES.rewriteAuditId = VARIABLES.rewriteAudit.id[1];
                }
                VARIABLES.rewriteErrorCode = "";
                VARIABLES.rewriteOutput = {};
                try {
                    VARIABLES.rewriteResponse.processed++;
                    VARIABLES.rewriteOutput = new services.EventDescriptionRewriteService().rewrite(VARIABLES.rewriteSource, VARIABLES.rewriteApiKey, VARIABLES.rewriteModel);
                    if (VARIABLES.rewriteDryRun) {
                        VARIABLES.rewriteResult.status = "preview";
                        VARIABLES.rewriteResult.text = VARIABLES.rewriteOutput.text;
                    } else {
                        // Never overwrite a description/source edited while the provider was running.
                        VARIABLES.rewriteUpdated = queryExecute("
                            UPDATE public.tb_evento_corridas SET descricao = :description
                            WHERE id_evento = :event_id AND btrim(COALESCE(descricao, '')) = ''
                              AND descricao_original = :source_text
                            RETURNING id_evento", {
                            description={value=VARIABLES.rewriteOutput.html, cfsqltype="cf_sql_longvarchar"},
                            event_id={value=VARIABLES.rewriteRow.id_evento, cfsqltype="cf_sql_integer"},
                            source_text={value=VARIABLES.rewriteSource, cfsqltype="cf_sql_longvarchar"}
                        }, VARIABLES.rewriteDbOptions);
                        if (VARIABLES.rewriteUpdated.recordCount) {
                            VARIABLES.rewriteResult.status = "updated";
                            VARIABLES.rewriteResponse.updated++;
                        } else {
                            VARIABLES.rewriteResult.status = "source_changed";
                            VARIABLES.rewriteResponse.skipped++;
                        }
                    }
                } catch (EventDescriptionRewrite.Validation rejectedDescription) {
                    VARIABLES.rewriteResult.status = "rejected";
                    VARIABLES.rewriteErrorCode = "validation_rejected";
                    VARIABLES.rewriteHttpStatus = 422;
                    VARIABLES.rewriteResponse.errors++;
                } catch (EventDescriptionRewrite.Provider providerFailure) {
                    VARIABLES.rewriteErrorCode = "provider_error";
                    VARIABLES.rewriteHttpStatus = 502;
                    VARIABLES.rewriteResponse.errors++;
                }
                if (!VARIABLES.rewriteDryRun) {
                    queryExecute("
                        UPDATE public.tb_evento_descricao_rewrites
                        SET status = :status, description_after = :description_after, error_code = :error_code, finished_at = now()
                        WHERE id = :audit_id", {
                        status={value=VARIABLES.rewriteResult.status, cfsqltype="cf_sql_varchar"},
                        description_after={value=structKeyExists(VARIABLES.rewriteOutput, "html") ? VARIABLES.rewriteOutput.html : "", null=!structKeyExists(VARIABLES.rewriteOutput, "html"), cfsqltype="cf_sql_longvarchar"},
                        error_code={value=VARIABLES.rewriteErrorCode, null=!len(VARIABLES.rewriteErrorCode), cfsqltype="cf_sql_varchar"},
                        audit_id={value=VARIABLES.rewriteAuditId, cfsqltype="cf_sql_bigint"}
                    }, VARIABLES.rewriteDbOptions);
                }
                if (len(VARIABLES.rewriteErrorCode)) VARIABLES.rewriteResult.errorCode = VARIABLES.rewriteErrorCode;
                arrayAppend(VARIABLES.rewriteResponse.results, VARIABLES.rewriteResult);
            }
        }
    }
} catch (any executionFailure) {
    // The surrounding transaction rolls back all writes; exception details may contain SQL/source data.
    rewriteJsonResponse(503, {success=false, status="execution_error", message="A reescrita não foi concluída. Nenhuma alteração desta execução foi confirmada."});
}
if (VARIABLES.rewriteLocked) {
    rewriteJsonResponse(409, {success=false, status="locked", message="Já existe uma reescrita em execução."});
}
if (VARIABLES.rewriteResponse.errors) {
    VARIABLES.rewriteResponse.success = false;
    VARIABLES.rewriteResponse.status = "failed";
}
rewriteJsonResponse(VARIABLES.rewriteHttpStatus, VARIABLES.rewriteResponse);
</cfscript>
