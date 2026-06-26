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

    cfquery(name = "qCronTables") {
        writeOutput("
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name IN ('tb_cron_jobs', 'tb_cron_job_runs')
        ");
    }

    return listFindNoCase(valueList(qCronTables.table_name), "tb_cron_jobs")
        AND listFindNoCase(valueList(qCronTables.table_name), "tb_cron_job_runs");
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

    if (!cronJobsTablesReady()) {
        result.message = "As tabelas de cron jobs ainda nao foram criadas.";
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
        authMode = lCase(trim(qCronJob.auth_mode));
        requestBody = isNull(qCronJob.request_body) ? "" : toString(qCronJob.request_body);
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
                responsePreview = cronJobsResponsePreview(structKeyExists(httpResult, "fileContent") ? httpResult.fileContent : "");

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
    }

    return result;
}
</cfscript>
