<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="300"/>
<cfcontent type="application/json; charset=utf-8"/>
<cfinclude template="../includes/backend/cron_jobs_service.cfm"/>

<cfscript>
function cronRunnerWrite(required struct payload, numeric statusCode = 200, string statusText = "OK") {
    cfheader(statuscode = arguments.statusCode, statustext = arguments.statusText);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

runnerHeaders = getHTTPRequestData().headers;
runnerToken = "";
if (structKeyExists(runnerHeaders, "X-Business-Cron-Token")) {
    runnerToken = trim(runnerHeaders["X-Business-Cron-Token"]);
} else if (structKeyExists(runnerHeaders, "x-business-cron-token")) {
    runnerToken = trim(runnerHeaders["x-business-cron-token"]);
} else if (isDefined("URL.token")) {
    runnerToken = trim(URL.token);
}

if (!structKeyExists(APPLICATION, "cronJobs")
    OR !structKeyExists(APPLICATION.cronJobs, "enabled")
    OR !APPLICATION.cronJobs.enabled
    OR !structKeyExists(APPLICATION.cronJobs, "runnerToken")
    OR !len(trim(APPLICATION.cronJobs.runnerToken))) {
    cronRunnerWrite({
        success = false,
        status = "not_configured",
        message = "Runner token nao configurado no Business."
    }, 503, "Service Unavailable");
}

if (!len(runnerToken) OR runnerToken NEQ APPLICATION.cronJobs.runnerToken) {
    cronRunnerWrite({
        success = false,
        status = "unauthorized",
        message = "Token invalido."
    }, 401, "Unauthorized");
}

if (!cronJobsTablesReady()) {
    cronRunnerWrite({
        success = false,
        status = "tables_missing",
        message = "Tabelas de cron jobs nao encontradas."
    }, 503, "Service Unavailable");
}

runnerLimit = isDefined("URL.limit") AND isNumeric(URL.limit) ? min(20, max(1, val(URL.limit))) : 5;
runnerJobId = isDefined("URL.job_id") AND isNumeric(URL.job_id) ? val(URL.job_id) : 0;
runnerResults = [];
</cfscript>

<cfif runnerJobId GT 0>
    <cfset arrayAppend(runnerResults, cronJobsRunJob(runnerJobId, "runner_manual", 0))/>
<cfelse>
    <cfquery name="qCronRunnerDueJobs">
        SELECT id_cron_job
        FROM tb_cron_jobs
        WHERE ativo = true
          AND next_run_at <= now()
        ORDER BY next_run_at ASC, id_cron_job ASC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#runnerLimit#"/>
    </cfquery>

    <cfloop query="qCronRunnerDueJobs">
        <cfset arrayAppend(runnerResults, cronJobsRunJob(qCronRunnerDueJobs.id_cron_job, "scheduled", 0))/>
    </cfloop>
</cfif>

<cfset cronRunnerWrite({
    success = true,
    status = "ok",
    executed = arrayLen(runnerResults),
    results = runnerResults,
    generatedAt = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
})/>
