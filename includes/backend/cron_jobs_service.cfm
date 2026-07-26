<cffunction name="cronJobsGetDiskSecret" access="private" returntype="string" output="false">
    <cfargument name="secretRef" type="string" required="true"/>

    <cfset var businessLocalConfig = {}/>
    <cfset var localConfigPath = expandPath("/config/business.local.cfm")/>
    <cfset var normalizedSecretRef = trim(arguments.secretRef)/>

    <cfif NOT len(normalizedSecretRef) OR NOT fileExists(localConfigPath)>
        <cfreturn ""/>
    </cfif>

    <cfinclude template="../../config/business.local.cfm"/>

    <cfif structKeyExists(businessLocalConfig, "cronSecrets")
        AND isStruct(businessLocalConfig.cronSecrets)
        AND structKeyExists(businessLocalConfig.cronSecrets, normalizedSecretRef)>
        <cfreturn trim(businessLocalConfig.cronSecrets[normalizedSecretRef])/>
    </cfif>

    <cfreturn ""/>
</cffunction>

<cfscript>
function cronJobsTablesReady() {
    var qCronTables = "";
    var qCronColumns = "";

    cfquery(name = "qCronTables") {
        writeOutput("
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name IN ('tb_cron_jobs', 'tb_cron_job_runs', 'tb_cron_job_notification_recipients')
        ");
    }

    if (!(listFindNoCase(valueList(qCronTables.table_name), "tb_cron_jobs")
        AND listFindNoCase(valueList(qCronTables.table_name), "tb_cron_job_runs")
        AND listFindNoCase(valueList(qCronTables.table_name), "tb_cron_job_notification_recipients"))) {
        return false;
    }

    cfquery(name = "qCronColumns") {
        writeOutput("
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'tb_cron_jobs'
              AND column_name = 'notificacao_novos_itens_destino'
        ");
    }

    return qCronColumns.recordcount GT 0;
}

function cronJobsParseAdminIds(any rawIds = "") {
    var normalized = reReplace(trim(arguments.rawIds & ""), "[^0-9]+", ",", "all");
    var parsedIds = [];
    var seenIds = {};
    var rawId = "";
    var numericId = 0;

    for (rawId in listToArray(normalized)) {
        numericId = val(rawId);
        if (numericId GT 0 AND !structKeyExists(seenIds, numericId & "")) {
            seenIds[numericId & ""] = true;
            arrayAppend(parsedIds, numericId);
        }
    }

    return parsedIds;
}

function cronJobsReplaceNotificationRecipients(
    required numeric jobId,
    array errorAdminIds = [],
    array newItemsAdminIds = []
) {
    var recipients = {};
    var adminId = 0;
    var recipientKey = "";

    for (adminId in arguments.errorAdminIds) {
        recipientKey = val(adminId) & "";
        recipients[recipientKey] = {
            id = val(adminId),
            notifyError = true,
            notifyNewItems = false
        };
    }

    for (adminId in arguments.newItemsAdminIds) {
        recipientKey = val(adminId) & "";
        if (!structKeyExists(recipients, recipientKey)) {
            recipients[recipientKey] = {
                id = val(adminId),
                notifyError = false,
                notifyNewItems = true
            };
        } else {
            recipients[recipientKey].notifyNewItems = true;
        }
    }

    queryExecute(
        "DELETE FROM tb_cron_job_notification_recipients WHERE id_cron_job = :jobId",
        { jobId = { value = arguments.jobId, cfsqltype = "cf_sql_bigint" } },
        { datasource = "runner_dba" }
    );

    for (recipientKey in recipients) {
        queryExecute(
            "INSERT INTO tb_cron_job_notification_recipients
                (id_cron_job, id_usuario, notificar_erro, notificar_novos_itens)
             VALUES
                (:jobId, :userId, :notifyError, :notifyNewItems)",
            {
                jobId = { value = arguments.jobId, cfsqltype = "cf_sql_bigint" },
                userId = { value = recipients[recipientKey].id, cfsqltype = "cf_sql_bigint" },
                notifyError = { value = recipients[recipientKey].notifyError, cfsqltype = "cf_sql_bit" },
                notifyNewItems = { value = recipients[recipientKey].notifyNewItems, cfsqltype = "cf_sql_bit" }
            },
            { datasource = "runner_dba" }
        );
    }
}

function cronJobsExtractNewItemCount(any rawResponse = "") {
    var payload = {};
    var metricGroups = [
        ["new_items", "novos_itens"],
        ["created", "criados", "inserted", "inseridos"],
        ["imported", "importados"]
    ];
    var metricGroup = [];
    var keyName = "";
    var groupHasMetric = false;
    var groupValue = 0;
    var metricValue = 0;

    if (!len(trim(arguments.rawResponse & "")) OR !isJSON(arguments.rawResponse & "")) {
        return 0;
    }

    try {
        payload = deserializeJSON(arguments.rawResponse & "");
        if (!isStruct(payload)) {
            return 0;
        }

        /*
         * Os grupos sao alternativas em ordem de confiabilidade, nao valores
         * cumulativos. Alguns importadores retornam importados = created +
         * updated; somar ambos gera duplicidade e falso positivo. Vinculados
         * tambem nao significa item novo e, por isso, nao participa da regra.
         */
        for (metricGroup in metricGroups) {
            groupHasMetric = false;
            groupValue = 0;

            for (keyName in metricGroup) {
                if (structKeyExists(payload, keyName)
                    AND !isNull(payload[keyName])
                    AND isSimpleValue(payload[keyName])
                    AND isNumeric(payload[keyName])) {
                    groupHasMetric = true;
                    metricValue = max(0, val(payload[keyName]));
                    groupValue = max(groupValue, metricValue);
                }
            }

            if (groupHasMetric) {
                return int(groupValue);
            }
        }
    } catch (any parseError) {
        return 0;
    }

    return 0;
}

function cronJobsNormalizeNewsImporterRequestBody(
    required string endpointUrl,
    string contentType = "application/json",
    any requestBody = ""
) {
    var normalizedEndpoint = lCase(listFirst(trim(arguments.endpointUrl), "?"));
    var normalizedContentType = lCase(trim(arguments.contentType));
    var rawBody = trim(arguments.requestBody & "");
    var payload = {};
    var importerEndpointPattern = "/api/admin/importers/(contrarelogio|corridanoar|cbat|cbat-corrida-de-rua)\.cfm$";

    if (!reFindNoCase(importerEndpointPattern, normalizedEndpoint)
        OR left(normalizedContentType, 16) NEQ "application/json") {
        return arguments.requestBody & "";
    }

    if (len(rawBody)) {
        if (!isJSON(rawBody)) {
            return arguments.requestBody & "";
        }

        try {
            payload = deserializeJSON(rawBody);
        } catch (any parseError) {
            return arguments.requestBody & "";
        }

        if (!isStruct(payload)) {
            return arguments.requestBody & "";
        }
    }

    /*
     * Jobs de importacao de noticias nunca devem publicar diretamente.
     * A API tambem usa review como padrao, mas a normalizacao protege jobs
     * antigos cujo payload ainda contenha import_status = published.
     */
    payload.import_status = "review";
    return serializeJSON(payload);
}

function cronJobsResolveNotificationDispatchUrl(any configuredUrl = "") {
    var resolvedUrl = trim(arguments.configuredUrl & "");

    if (!len(resolvedUrl)) {
        return "https://roadrunners.run/api/notifications/integrations/dispatch.cfm";
    }
    if (findNoCase("/api/notifications/integrations/dispatch.cfm", resolvedUrl)) {
        return resolvedUrl;
    }
    if (findNoCase("/api/push/send.cfm", resolvedUrl)) {
        return replaceNoCase(resolvedUrl, "/api/push/send.cfm", "/api/notifications/integrations/dispatch.cfm", "one");
    }
    if (findNoCase("/api/push/send-notifications.cfm", resolvedUrl)) {
        return replaceNoCase(resolvedUrl, "/api/push/send-notifications.cfm", "/api/notifications/integrations/dispatch.cfm", "one");
    }
    return resolvedUrl;
}

function cronJobsDispatchNotification(required struct payload) {
    var dispatchUrl = "https://roadrunners.run/api/notifications/integrations/dispatch.cfm";
    var dispatchSecret = hash("RoadRunners::handoff::roadrunners.run::v1", "SHA-256");
    var dispatchTimeoutSeconds = 20;
    var rawBody = "";
    var timestampHeader = "";
    var signatureHeader = "";
    var dispatchResult = {};
    var responsePayload = {};

    if (structKeyExists(APPLICATION, "notificationDispatch") AND isStruct(APPLICATION.notificationDispatch)) {
        if (structKeyExists(APPLICATION.notificationDispatch, "url")) {
            dispatchUrl = cronJobsResolveNotificationDispatchUrl(APPLICATION.notificationDispatch.url);
        }
        if (structKeyExists(APPLICATION.notificationDispatch, "secret") AND len(trim(APPLICATION.notificationDispatch.secret & ""))) {
            dispatchSecret = trim(APPLICATION.notificationDispatch.secret & "");
        }
        if (structKeyExists(APPLICATION.notificationDispatch, "timeoutSeconds") AND val(APPLICATION.notificationDispatch.timeoutSeconds) GT 0) {
            dispatchTimeoutSeconds = int(APPLICATION.notificationDispatch.timeoutSeconds);
        }
    }

    rawBody = serializeJSON(arguments.payload);
    timestampHeader = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
    signatureHeader = lCase(hmac(timestampHeader & "." & rawBody, dispatchSecret, "HmacSHA256"));

    try {
        cfhttp(
            url = dispatchUrl,
            method = "post",
            result = "dispatchResult",
            timeout = dispatchTimeoutSeconds,
            throwOnError = false
        ) {
            cfhttpparam(type = "header", name = "Content-Type", value = "application/json; charset=utf-8");
            cfhttpparam(type = "header", name = "X-RR-Handoff-Timestamp", value = timestampHeader);
            cfhttpparam(type = "header", name = "X-RR-Handoff-Signature", value = signatureHeader);
            cfhttpparam(type = "body", value = rawBody);
        }

        if (structKeyExists(dispatchResult, "fileContent")
            AND len(trim(dispatchResult.fileContent & ""))
            AND isJSON(dispatchResult.fileContent & "")) {
            responsePayload = deserializeJSON(dispatchResult.fileContent & "");
        }

        return structKeyExists(responsePayload, "success")
            AND responsePayload.success
            AND structKeyExists(responsePayload, "status")
            AND trim(responsePayload.status & "") EQ "dispatched";
    } catch (any dispatchError) {
        return false;
    }
}

function cronJobsNotifyRecipients(
    required numeric jobId,
    required string eventType,
    required string jobName,
    numeric runId = 0,
    numeric newItemsCount = 0,
    string detail = "",
    string newItemsDestination = ""
) {
    var qRecipients = "";
    var recipientIds = [];
    var notificationText = "";
    var notificationPayload = {};
    var preferenceColumn = arguments.eventType EQ "error" ? "notificar_erro" : "notificar_novos_itens";
    var notificationLink = "https://business.roadrunners.run/administracao/cron-jobs/";

    qRecipients = queryExecute(
        "SELECT id_usuario
         FROM tb_cron_job_notification_recipients
         WHERE id_cron_job = :jobId
           AND " & preferenceColumn & " = true
         ORDER BY id_usuario",
        { jobId = { value = arguments.jobId, cfsqltype = "cf_sql_bigint" } },
        { datasource = "runner_dba" }
    );

    if (!qRecipients.recordcount) {
        return false;
    }

    recipientIds = listToArray(valueList(qRecipients.id_usuario));
    if (arguments.eventType EQ "error") {
        notificationText = "Erro no Cron Job " & arguments.jobName;
        if (len(trim(arguments.detail))) {
            notificationText &= ": " & left(trim(arguments.detail), 170);
        }
    } else {
        notificationText = arguments.newItemsCount & " novo(s) item(ns) no Cron Job " & arguments.jobName & ".";
        if (len(trim(arguments.newItemsDestination))) {
            notificationLink = "https://business.roadrunners.run/" & reReplace(trim(arguments.newItemsDestination), "^/+", "", "all");
        }
    }

    notificationPayload = {
        origin = "business",
        category = "cron_jobs",
        conteudo_notifica = left(notificationText, 240),
        icone = "fa-solid fa-clock-rotate-left",
        link = notificationLink,
        data_publicacao = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
        data_expiracao = dateTimeFormat(dateAdd("d", 30, now()), "yyyy-mm-dd HH:nn:ss"),
        userIds = recipientIds,
        options = {
            sendPush = true,
            pushCategory = "sistema",
            pushUrgency = arguments.eventType EQ "error" ? "high" : "normal",
            pushTtlSeconds = 300
        }
    };

    return cronJobsDispatchNotification(notificationPayload);
}

function cronJobsReconcileStaleRuns() {
    var staleRuns = "";

    if (!cronJobsTablesReady()) {
        return 0;
    }

    staleRuns = queryExecute(
        "UPDATE tb_cron_job_runs run
         SET finished_at = now(),
             duration_ms = LEAST(2147483647, GREATEST(0, (extract(epoch FROM (now() - run.started_at)) * 1000)::bigint))::integer,
             status = 'timeout',
             error_message = coalesce(run.error_message, 'Execucao encerrada por exceder o tempo maximo configurado.')
         FROM tb_cron_jobs job
         WHERE job.id_cron_job = run.id_cron_job
           AND run.status = 'running'
           AND run.finished_at IS NULL
           AND run.started_at < now() - (interval '1 second' * GREATEST(30, job.max_runtime_seconds))
         RETURNING run.id_cron_job_run",
        {},
        { datasource = "runner_dba" }
    );

    return staleRuns.recordcount;
}

function cronJobsGetSecret(required string secretRef) {
    var diskSecret = "";

    if (!len(trim(arguments.secretRef))) {
        return "";
    }

    diskSecret = cronJobsGetDiskSecret(arguments.secretRef);
    if (len(diskSecret)) {
        return diskSecret;
    }

    if (structKeyExists(APPLICATION, "cronJobs")
        AND structKeyExists(APPLICATION.cronJobs, "secrets")
        AND isStruct(APPLICATION.cronJobs.secrets)
        AND structKeyExists(APPLICATION.cronJobs.secrets, arguments.secretRef)) {
        return trim(APPLICATION.cronJobs.secrets[arguments.secretRef]);
    }

    return "";
}

function cronJobsSafeJsonStruct(required string rawJson) {
    if (!len(trim(arguments.rawJson))) {
        return {};
    }

    try {
        var parsed = deserializeJSON(arguments.rawJson);
        if (isStruct(parsed)) {
            return parsed;
        }
    } catch (any error) {
    }

    return {};
}

function cronJobsResponsePreview(required any value) {
    var preview = "";
    var parsedPayload = {};
    var compactPayload = {};
    var previewKey = "";
    var summaryKeys = listToArray("success,status,message,importados,created,updated,duplicados,skipped,vinculados,filtrados,ignorados,canais_processados,selected,processed,linked,review,high_confidence_matches,not_found,conflicts,errors,pages,executed,erros,fatal_error");

    if (isNull(arguments.value)) {
        return "";
    }

    preview = toString(arguments.value);
    preview = reReplace(preview, "[\r\n\t]+", " ", "all");

    if (len(preview) GT 4000) {
        try {
            if (isJSON(preview)) {
                parsedPayload = deserializeJSON(preview);
                if (isStruct(parsedPayload)) {
                    for (previewKey in summaryKeys) {
                        if (structKeyExists(parsedPayload, previewKey) AND !isNull(parsedPayload[previewKey])) {
                            if (previewKey EQ "erros" AND isArray(parsedPayload[previewKey])) {
                                compactPayload[previewKey] = arrayLen(parsedPayload[previewKey]);
                            } else if (isSimpleValue(parsedPayload[previewKey])) {
                                compactPayload[previewKey] = parsedPayload[previewKey];
                            }
                        }
                    }
                    compactPayload.response_compacted = true;
                    preview = serializeJSON(compactPayload);
                }
            }
        } catch (any compactError) {
        }

        if (len(preview) GT 4000) {
            preview = left(preview, 4000);
        }
    }

    return preview;
}

function cronJobsRunJob(required numeric jobId, string triggerType = "manual", numeric createdBy = 0) {
    var result = {
        success = false,
        status = "error",
        message = "",
        httpStatus = "",
        runId = 0,
        durationMs = 0,
        attempt = 1
    };
    var qCronJob = "";
    var qCronRun = "";
    var qCronLock = "";
    var qCronRunUpdate = "";
    var qCronJobUpdate = "";
    var qCronUnlock = "";
    var headers = {};
    var headerName = "";
    var requestBody = "";
    var httpMethod = "GET";
    var contentType = "application/json";
    var timeoutSeconds = 30;
    var startedTick = getTickCount();
    var responsePreview = "";
    var errorMessage = "";
    var runStatus = "running";
    var httpResult = {};
    var timestampHeader = "";
    var signatureHeader = "";
    var secretValue = "";
    var endpointUrl = "";
    var maxAttempts = 1;
    var currentAttempt = 1;
    var attemptError = "";
    var authMode = "none";
    var rawResponse = "";
    var newItemsCount = 0;
    var requestTimeoutSeconds = 60;

    if (!cronJobsTablesReady()) {
        result.message = "O schema de cron jobs esta incompleto.";
        return result;
    }

    cronJobsReconcileStaleRuns();

    cfquery(name = "qCronLock") {
        writeOutput("SELECT pg_try_advisory_lock(");
        cfqueryparam(cfsqltype = "cf_sql_bigint", value = 930000000 + val(arguments.jobId));
        writeOutput(") AS locked");
    }

    if (!qCronLock.recordcount OR !qCronLock.locked) {
        result.status = "skipped";
        result.message = "Job ja esta em execucao.";
        return result;
    }

    try {
        cfquery(name = "qCronJob") {
            writeOutput("
                SELECT *
                FROM tb_cron_jobs
                WHERE id_cron_job = ");
            cfqueryparam(cfsqltype = "cf_sql_bigint", value = arguments.jobId);
            writeOutput("
                LIMIT 1
            ");
        }

        if (!qCronJob.recordcount) {
            result.message = "Job nao encontrado.";
            return result;
        }

        endpointUrl = trim(qCronJob.endpoint_url);
        httpMethod = uCase(trim(qCronJob.http_method));
        contentType = len(trim(qCronJob.content_type)) ? trim(qCronJob.content_type) : "application/json";
        timeoutSeconds = val(qCronJob.timeout_seconds) GT 0 ? val(qCronJob.timeout_seconds) : 30;
        maxAttempts = min(4, max(1, val(qCronJob.retry_limit) + 1));
        /*
         * Application.cfc limita requisicoes comuns a 20 segundos, mas um job
         * pode aguardar timeoutSeconds em cada tentativa. Reserva tambem tempo
         * para persistir o resultado, liberar o lock e enviar notificacoes.
         */
        requestTimeoutSeconds = max(60, (timeoutSeconds * maxAttempts) + 60);
        setting requesttimeout = requestTimeoutSeconds;
        authMode = lCase(trim(qCronJob.auth_mode));
        requestBody = isNull(qCronJob.request_body) ? "" : toString(qCronJob.request_body);
        requestBody = cronJobsNormalizeNewsImporterRequestBody(
            endpointUrl = endpointUrl,
            contentType = contentType,
            requestBody = requestBody
        );
        if (!isNull(qCronJob.headers_json) AND isStruct(qCronJob.headers_json)) {
            headers = duplicate(qCronJob.headers_json);
        } else {
            headers = cronJobsSafeJsonStruct(isNull(qCronJob.headers_json) ? "" : toString(qCronJob.headers_json));
        }

        cfquery(name = "qCronRun") {
            writeOutput("
                INSERT INTO tb_cron_job_runs
                    (id_cron_job, trigger_type, started_at, status, endpoint_url, request_body_preview, created_by)
                VALUES
                    (
            ");
            cfqueryparam(cfsqltype = "cf_sql_bigint", value = arguments.jobId);
            writeOutput(", ");
            cfqueryparam(cfsqltype = "cf_sql_varchar", value = arguments.triggerType);
            writeOutput(", now(), 'running', ");
            cfqueryparam(cfsqltype = "cf_sql_longvarchar", value = endpointUrl);
            writeOutput(", ");
            cfqueryparam(cfsqltype = "cf_sql_longvarchar", value = cronJobsResponsePreview(requestBody), null = !len(trim(requestBody)));
            writeOutput(", ");
            cfqueryparam(cfsqltype = "cf_sql_bigint", value = arguments.createdBy, null = arguments.createdBy LTE 0);
            writeOutput(")
                RETURNING id_cron_job_run
            ");
        }

        result.runId = qCronRun.id_cron_job_run;

        if (!len(endpointUrl) OR !reFindNoCase("^https?://", endpointUrl)) {
            throw(message = "Endpoint invalido. Use uma URL absoluta http/https.");
        }

        if (!listFindNoCase("GET,POST,PUT,PATCH,DELETE", httpMethod)) {
            throw(message = "Metodo HTTP invalido.");
        }

        if (authMode EQ "bearer") {
            secretValue = cronJobsGetSecret(qCronJob.secret_ref);
            if (!len(secretValue)) {
                throw(message = "Secret ref sem valor configurado: " & qCronJob.secret_ref);
            }
            headers["Authorization"] = "Bearer " & secretValue;
        } else if (authMode EQ "api_key_header") {
            secretValue = cronJobsGetSecret(qCronJob.secret_ref);
            if (!len(secretValue)) {
                throw(message = "Secret ref sem valor configurado: " & qCronJob.secret_ref);
            }
            headers["X-API-Key"] = secretValue;
        } else if (authMode EQ "api_key_query") {
            secretValue = cronJobsGetSecret(qCronJob.secret_ref);
            if (!len(secretValue)) {
                throw(message = "Secret ref sem valor configurado: " & qCronJob.secret_ref);
            }
            endpointUrl &= (find("?", endpointUrl) ? "&" : "?") & "api_key=" & urlEncodedFormat(secretValue);
        } else if (authMode EQ "hmac_sha256") {
            secretValue = cronJobsGetSecret(qCronJob.secret_ref);
            if (!len(secretValue)) {
                throw(message = "Secret ref sem valor configurado: " & qCronJob.secret_ref);
            }
            timestampHeader = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
            signatureHeader = lCase(hmac(timestampHeader & "." & requestBody, secretValue, "HmacSHA256"));
            headers["X-RR-Handoff-Timestamp"] = timestampHeader;
            headers["X-RR-Handoff-Signature"] = signatureHeader;
        }

        for (currentAttempt = 1; currentAttempt <= maxAttempts; currentAttempt++) {
            result.attempt = currentAttempt;
            attemptError = "";

            try {
                cfhttp(url = endpointUrl, method = httpMethod, result = "httpResult", timeout = timeoutSeconds, throwOnError = false) {
                    cfhttpparam(type = "header", name = "User-Agent", value = "RoadRunners-Business-Cron/1.0");
                    if (len(contentType) AND listFindNoCase("POST,PUT,PATCH", httpMethod)) {
                        cfhttpparam(type = "header", name = "Content-Type", value = contentType);
                    }
                    for (headerName in headers) {
                        if (len(trim(headerName)) AND !isNull(headers[headerName])) {
                            cfhttpparam(type = "header", name = headerName, value = toString(headers[headerName]));
                        }
                    }
                    if (listFindNoCase("POST,PUT,PATCH", httpMethod) AND len(requestBody)) {
                        cfhttpparam(type = "body", value = requestBody);
                    }
                }

                result.httpStatus = structKeyExists(httpResult, "statusCode") ? trim(httpResult.statusCode) : "";
                rawResponse = structKeyExists(httpResult, "fileContent") ? (httpResult.fileContent & "") : "";
                responsePreview = cronJobsResponsePreview(rawResponse);

                if (len(result.httpStatus) AND left(result.httpStatus, 1) EQ "2") {
                    break;
                }
            } catch (any httpError) {
                attemptError = httpError.message;
                if (currentAttempt GTE maxAttempts) {
                    throw(message = attemptError);
                }
            }

            if (currentAttempt LT maxAttempts) {
                sleep(500);
            }
        }

        result.durationMs = getTickCount() - startedTick;

        if (len(result.httpStatus) AND left(result.httpStatus, 1) EQ "2") {
            runStatus = "success";
            result.success = true;
            result.status = runStatus;
            result.message = "Job executado com sucesso.";
        } else {
            runStatus = "http_error";
            result.status = runStatus;
            result.message = "Job retornou HTTP " & result.httpStatus & " apos " & result.attempt & " tentativa(s).";
        }
    } catch (any error) {
        result.durationMs = getTickCount() - startedTick;
        runStatus = "error";
        errorMessage = len(attemptError) ? attemptError : error.message;
        result.status = runStatus;
        result.message = errorMessage;
    } finally {
        if (result.runId GT 0) {
            cfquery(name = "qCronRunUpdate") {
                writeOutput("
                    UPDATE tb_cron_job_runs
                    SET finished_at = now(),
                        attempt = ");
                cfqueryparam(cfsqltype = "cf_sql_integer", value = result.attempt);
                writeOutput(",
                        duration_ms = ");
                cfqueryparam(cfsqltype = "cf_sql_integer", value = result.durationMs);
                writeOutput(",
                        status = ");
                cfqueryparam(cfsqltype = "cf_sql_varchar", value = runStatus);
                writeOutput(",
                        http_status = ");
                cfqueryparam(cfsqltype = "cf_sql_varchar", value = result.httpStatus, null = !len(result.httpStatus));
                writeOutput(",
                        response_preview = ");
                cfqueryparam(cfsqltype = "cf_sql_longvarchar", value = responsePreview, null = !len(responsePreview));
                writeOutput(",
                        error_message = ");
                cfqueryparam(cfsqltype = "cf_sql_longvarchar", value = errorMessage, null = !len(errorMessage));
                writeOutput("
                    WHERE id_cron_job_run = ");
                cfqueryparam(cfsqltype = "cf_sql_bigint", value = result.runId);
            }
        }

        if (qCronJob.recordcount) {
            cfquery(name = "qCronJobUpdate") {
                writeOutput("
                    UPDATE tb_cron_jobs
                    SET last_run_at = now(),
                        next_run_at = now() + (interval '1 minute' * interval_minutes),
                        last_status = ");
                cfqueryparam(cfsqltype = "cf_sql_varchar", value = runStatus);
                writeOutput(",
                        last_http_status = ");
                cfqueryparam(cfsqltype = "cf_sql_varchar", value = result.httpStatus, null = !len(result.httpStatus));
                writeOutput(",
                        last_duration_ms = ");
                cfqueryparam(cfsqltype = "cf_sql_integer", value = result.durationMs, null = result.durationMs LTE 0);
                writeOutput(",
                        last_error = ");
                cfqueryparam(cfsqltype = "cf_sql_longvarchar", value = len(errorMessage) ? errorMessage : responsePreview, null = !(len(errorMessage) OR len(responsePreview)));
                writeOutput(",
                        data_atualizacao = now()
                    WHERE id_cron_job = ");
                cfqueryparam(cfsqltype = "cf_sql_bigint", value = arguments.jobId);
            }
        }

        cfquery(name = "qCronUnlock") {
            writeOutput("SELECT pg_advisory_unlock(");
            cfqueryparam(cfsqltype = "cf_sql_bigint", value = 930000000 + val(arguments.jobId));
            writeOutput(")");
        }

        if (qCronJob.recordcount AND result.runId GT 0) {
            try {
                if (listFindNoCase("error,http_error,failed,timeout", runStatus)) {
                    cronJobsNotifyRecipients(
                        arguments.jobId,
                        "error",
                        qCronJob.nome,
                        result.runId,
                        0,
                        len(errorMessage) ? errorMessage : result.message
                    );
                } else if (runStatus EQ "success") {
                    newItemsCount = cronJobsExtractNewItemCount(rawResponse);
                    if (newItemsCount GT 0) {
                        cronJobsNotifyRecipients(
                            arguments.jobId,
                            "new_items",
                            qCronJob.nome,
                            result.runId,
                            newItemsCount,
                            "",
                            isNull(qCronJob.notificacao_novos_itens_destino)
                                ? ""
                                : qCronJob.notificacao_novos_itens_destino
                        );
                    }
                }
            } catch (any notificationError) {
                // Notificacoes sao acessorias e nunca devem alterar o resultado do job.
            }
        }
    }

    return result;
}
</cfscript>
