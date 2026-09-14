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

function rewriteTranslation(required struct row, required boolean dryRun, required string apiKey, required string model) {
    var dbOptions = {datasource="runner_dba"};
    var source = arguments.row.source_text & "";
    var language = arguments.row.language & "";
    // The column name comes only from the server's two-language queue, never SQL input.
    var targetColumn = language EQ "en" ? "descricao_en" : "descricao_es";
    var outcome = {httpStatus=200, processed=0, updated=0, skipped=0, errors=0,
        result={id=arguments.row.id_evento, language=language, status="error", reused=arguments.row.cached_id GT 0}};
    var params = {
        event_id={value=arguments.row.id_evento, cfsqltype="cf_sql_integer"},
        language={value=language, cfsqltype="cf_sql_varchar"},
        source_text={value=source, cfsqltype="cf_sql_longvarchar"},
        source_hash={value=lCase(hash(source, "MD5", "UTF-8")), cfsqltype="cf_sql_varchar"},
        target_before={value=arguments.row.target_text, null=arguments.row.target_is_null, cfsqltype="cf_sql_longvarchar"},
        model={value=arguments.row.cached_id GT 0 ? arguments.row.cached_model : arguments.model, cfsqltype="cf_sql_varchar"},
        attempt_count={value=arguments.row.cached_id GT 0 ? 1 : arguments.row.attempt_count + 1, cfsqltype="cf_sql_integer"},
        reused_from_id={value=arguments.row.cached_id, null=arguments.row.cached_id EQ 0, cfsqltype="cf_sql_bigint"}
    };
    var auditId = 0;
    var audit = queryNew("");
    var output = {};
    var errorCode = "";
    var updated = queryNew("");
    var service = new services.EventDescriptionRewriteService();
    if (!arguments.dryRun) {
        audit = queryExecute("
            INSERT INTO public.tb_evento_descricao_translations
                (id_evento, language, source_hash, source_text, status, description_before,
                 metadata_before, model, attempt_count, reused_from_id)
            SELECT evt.id_evento, :language, :source_hash, evt.descricao, 'running', evt." & targetColumn & ",
                evt.descricao_traducoes_meta -> CAST(:language AS text), :model, :attempt_count, :reused_from_id
            FROM public.tb_evento_corridas evt
            WHERE evt.id_evento = :event_id AND evt.descricao = :source_text
              AND evt." & targetColumn & " IS NOT DISTINCT FROM :target_before
            RETURNING id", params, dbOptions);
        if (!audit.recordCount) {
            outcome.result.status = "source_changed";
            outcome.skipped = 1;
            return outcome;
        }
        auditId = audit.id[1];
    }
    try {
        outcome.processed = 1;
        if (arguments.row.cached_id GT 0) {
            output = {html=arguments.row.cached_html,
                text=arguments.dryRun ? decodeForHTML(reReplace(arguments.row.cached_html, "(?i)<br\s*/?>", chr(10), "all")) : "",
                model=arguments.row.cached_model};
        } else {
            output = service.translate(source, language, arguments.apiKey, arguments.model);
        }
        if (arguments.dryRun) {
            outcome.result.status = "preview";
            outcome.result.text = output.text;
        } else {
            var writeParams = {
                event_id=params.event_id, language=params.language, source_text=params.source_text,
                source_hash=params.source_hash, target_before=params.target_before,
                description={value=output.html, cfsqltype="cf_sql_longvarchar"}
            };
            updated = queryExecute("UPDATE public.tb_evento_corridas SET " & targetColumn & " = :description,
                    descricao_traducoes_meta = jsonb_set(COALESCE(descricao_traducoes_meta,CAST('{}' AS jsonb)),
                        ARRAY[CAST(:language AS text)], jsonb_build_object('source_hash',CAST(:source_hash AS text),
                        'description_hash',md5(CAST(:description AS text))),true)
                WHERE id_evento = :event_id AND descricao = :source_text
                  AND " & targetColumn & " IS NOT DISTINCT FROM :target_before
                RETURNING id_evento", writeParams, dbOptions);
            if (updated.recordCount) {
                outcome.result.status = "updated";
                outcome.updated = 1;
            } else {
                outcome.result.status = "source_changed";
                outcome.skipped = 1;
            }
        }
    } catch (EventDescriptionRewrite.Validation rejectedTranslation) {
        outcome.result.status = "rejected";
        errorCode = "validation_rejected";
        outcome.httpStatus = 422;
        outcome.errors = 1;
    } catch (EventDescriptionRewrite.Provider providerFailure) {
        errorCode = "provider_error";
        outcome.httpStatus = 502;
        outcome.errors = 1;
    }
    if (!arguments.dryRun) {
        queryExecute("
            UPDATE public.tb_evento_descricao_translations
            SET status = :status, description_after = :description_after, error_code = :error_code,
                finished_at = clock_timestamp(), next_retry_at = CASE
                    WHEN :status = 'error' AND attempt_count = 1 THEN clock_timestamp() + interval '5 minutes'
                    WHEN :status = 'error' AND attempt_count = 2 THEN clock_timestamp() + interval '30 minutes'
                    ELSE NULL END
            WHERE id = :audit_id", {
            status={value=outcome.result.status, cfsqltype="cf_sql_varchar"},
            description_after={value=structKeyExists(output, "html") ? output.html : "", null=!structKeyExists(output, "html"), cfsqltype="cf_sql_longvarchar"},
            error_code={value=errorCode, null=!len(errorCode), cfsqltype="cf_sql_varchar"},
            audit_id={value=auditId, cfsqltype="cf_sql_bigint"}
        }, dbOptions);
    }
    if (len(errorCode)) outcome.result.errorCode = errorCode;
    return outcome;
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
    if (!listFindNoCase("limit,dryRun,eventId,language", VARIABLES.rewriteField)) {
        rewriteJsonResponse(400, {success=false, status="validation_error", message="Parâmetro não permitido. Use limit, dryRun, eventId e language."});
    }
}
VARIABLES.rewriteLimit = 1;
VARIABLES.rewriteDryRun = true;
VARIABLES.rewriteEventId = 0;
VARIABLES.rewriteLanguage = "auto";
if (structKeyExists(VARIABLES.rewritePayload, "language")) {
    if (!isSimpleValue(VARIABLES.rewritePayload.language) OR !listFind("auto,pt-BR,en,es", VARIABLES.rewritePayload.language & "")) {
        rewriteJsonResponse(400, {success=false, status="validation_error", message="language deve ser auto, pt-BR, en ou es."});
    }
    VARIABLES.rewriteLanguage = VARIABLES.rewritePayload.language & "";
}
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
    VARIABLES.rewriteSchema = queryExecute("SELECT
        to_regclass('public.tb_evento_descricao_rewrites') IS NOT NULL
        AND to_regclass('public.tb_evento_descricao_translations') IS NOT NULL
        AND (SELECT count(*) FROM information_schema.columns WHERE table_schema='public'
            AND table_name='tb_evento_corridas' AND ((column_name IN ('descricao_en','descricao_es') AND data_type='text')
                OR (column_name='descricao_traducoes_meta' AND data_type='jsonb'))) = 3 AS ready", [], VARIABLES.rewriteDbOptions);
} catch (any unavailableDatabase) {
    rewriteJsonResponse(503, {success=false, status="database_unavailable", message="Banco indisponível para a reescrita."});
}
if (!VARIABLES.rewriteSchema.ready[1]) {
    rewriteJsonResponse(503, {success=false, status="schema_required", message="Instale o schema de auditoria da reescrita antes de executar."});
}
VARIABLES.rewriteResponse = {success=true, status="completed", language=VARIABLES.rewriteLanguage, dryRun=VARIABLES.rewriteDryRun, selected=0, processed=0, updated=0, skipped=0, errors=0, results=[]};
VARIABLES.rewriteHttpStatus = 200;
VARIABLES.rewriteLocked = false;
try {
    transaction {
        // The transaction lock covers selection, provider calls and compare-and-set write.
        VARIABLES.rewriteLock = queryExecute("SELECT pg_try_advisory_xact_lock(1380472914, 1) AS acquired", [], VARIABLES.rewriteDbOptions);
        VARIABLES.rewriteLocked = !VARIABLES.rewriteLock.acquired[1];
        if (!VARIABLES.rewriteLocked) {
            include "queue.cfm";
            VARIABLES.rewriteCandidates = queryExecute(eventDescriptionQueueSql() &
                "SELECT * FROM work WHERE queue_status='ready' ORDER BY date_rank,id_evento,language_rank LIMIT 1", {
                    event_id={value=VARIABLES.rewriteEventId, cfsqltype="cf_sql_integer"},
                    language={value=VARIABLES.rewriteLanguage, cfsqltype="cf_sql_varchar"}
                }, VARIABLES.rewriteDbOptions);
            VARIABLES.rewriteResponse.selected = VARIABLES.rewriteCandidates.recordCount;
            for (VARIABLES.rewriteRow in VARIABLES.rewriteCandidates) {
                if (VARIABLES.rewriteRow.language NEQ "pt-BR") {
                    VARIABLES.translationOutcome = rewriteTranslation(VARIABLES.rewriteRow, VARIABLES.rewriteDryRun, VARIABLES.rewriteApiKey, VARIABLES.rewriteModel);
                    VARIABLES.rewriteResponse.processed += VARIABLES.translationOutcome.processed;
                    VARIABLES.rewriteResponse.updated += VARIABLES.translationOutcome.updated;
                    VARIABLES.rewriteResponse.skipped += VARIABLES.translationOutcome.skipped;
                    VARIABLES.rewriteResponse.errors += VARIABLES.translationOutcome.errors;
                    VARIABLES.rewriteHttpStatus = VARIABLES.translationOutcome.httpStatus;
                    arrayAppend(VARIABLES.rewriteResponse.results, VARIABLES.translationOutcome.result);
                    continue;
                }
                VARIABLES.rewriteSource = VARIABLES.rewriteRow.source_text & "";
                VARIABLES.rewriteSourceHash = lCase(hash(VARIABLES.rewriteSource, "MD5", "UTF-8"));
                VARIABLES.rewriteAuditId = 0;
                VARIABLES.rewriteResult = {id=VARIABLES.rewriteRow.id_evento, language="pt-BR", status="error"};
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
