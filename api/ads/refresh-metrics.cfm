<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting requesttimeout="120" showdebugoutput="false"/>
<cfcontent type="application/json; charset=utf-8"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>

<cfscript>
function adsMetricsWrite(required struct payload, numeric statusCode = 200, string statusText = "OK") output="true" {
    cfheader(statuscode = arguments.statusCode, statustext = arguments.statusText);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

VARIABLES.adsMetricsStartedAt = getTickCount();
VARIABLES.adsMetricsHeaders = getHTTPRequestData().headers;
VARIABLES.adsMetricsAuthorization = structKeyExists(VARIABLES.adsMetricsHeaders, "Authorization")
    ? trim(VARIABLES.adsMetricsHeaders.Authorization & "")
    : "";
VARIABLES.adsMetricsSecret = "";

if (uCase(trim(CGI.request_method & "")) NEQ "POST") {
    cfheader(name = "Allow", value = "POST");
    adsMetricsWrite({
        success = false,
        status = "method_not_allowed",
        message = "Use POST para atualizar as metricas."
    }, 405, "Method Not Allowed");
}

if (structKeyExists(APPLICATION, "cronJobs")
    AND isStruct(APPLICATION.cronJobs)
    AND structKeyExists(APPLICATION.cronJobs, "secrets")
    AND isStruct(APPLICATION.cronJobs.secrets)
    AND structKeyExists(APPLICATION.cronJobs.secrets, "business_internal")) {
    VARIABLES.adsMetricsSecret = trim(APPLICATION.cronJobs.secrets.business_internal & "");
}

if (!len(VARIABLES.adsMetricsSecret)) {
    adsMetricsWrite({
        success = false,
        status = "not_configured",
        message = "Credencial interna do Business nao configurada."
    }, 503, "Service Unavailable");
}

if (!len(VARIABLES.adsMetricsAuthorization)
    OR hash(VARIABLES.adsMetricsAuthorization, "SHA-256")
        NEQ hash("Bearer " & VARIABLES.adsMetricsSecret, "SHA-256")) {
    adsMetricsWrite({
        success = false,
        status = "unauthorized",
        message = "Credencial invalida."
    }, 401, "Unauthorized");
}

VARIABLES.adsMetricsRequestBody = trim(toString(getHTTPRequestData().content));
VARIABLES.adsMetricsRequest = {};
VARIABLES.adsMetricsLookbackDays = 2;

if (len(VARIABLES.adsMetricsRequestBody)) {
    if (!isJSON(VARIABLES.adsMetricsRequestBody)) {
        adsMetricsWrite({
            success = false,
            status = "invalid_json",
            message = "Body JSON invalido."
        }, 400, "Bad Request");
    }

    VARIABLES.adsMetricsRequest = deserializeJSON(VARIABLES.adsMetricsRequestBody);
    if (!isStruct(VARIABLES.adsMetricsRequest)) {
        adsMetricsWrite({
            success = false,
            status = "invalid_payload",
            message = "O body deve ser um objeto JSON."
        }, 400, "Bad Request");
    }

    if (structKeyExists(VARIABLES.adsMetricsRequest, "lookbackDays")
        AND isNumeric(VARIABLES.adsMetricsRequest.lookbackDays)) {
        VARIABLES.adsMetricsLookbackDays = min(7, max(0, int(VARIABLES.adsMetricsRequest.lookbackDays)));
    }
}

VARIABLES.adsMetricsLockAcquired = false;
</cfscript>

<cftry>
    <cftransaction>
        <cfquery name="qAdsMetricsRefreshLock">
            SELECT pg_try_advisory_xact_lock(940000001::bigint) AS locked
        </cfquery>

        <cfset VARIABLES.adsMetricsLockAcquired = qAdsMetricsRefreshLock.recordcount
            AND qAdsMetricsRefreshLock.locked/>

        <cfif VARIABLES.adsMetricsLockAcquired>
            <cfquery name="qAdsMetricsRefresh">
                SELECT ads.refresh_tb_ad_evento_metricas_dia(
                    current_date - <cfqueryparam
                        cfsqltype="cf_sql_integer"
                        value="#VARIABLES.adsMetricsLookbackDays#"/>,
                    current_date
                )
            </cfquery>

            <cfquery name="qAdsMetricsRefreshSummary">
                SELECT current_date - <cfqueryparam
                           cfsqltype="cf_sql_integer"
                           value="#VARIABLES.adsMetricsLookbackDays#"/> AS data_inicio,
                       current_date AS data_fim,
                       count(*)::integer AS linhas_agregadas,
                       coalesce(sum(metricas.views), 0)::bigint AS views,
                       coalesce(sum(metricas.clicks), 0)::bigint AS clicks,
                       coalesce(sum(metricas.custo), 0)::numeric(14, 2) AS custo,
                       (
                           SELECT max(log.data_insercao)
                           FROM ads.tb_ad_log log
                       ) AS fonte_ultima_ocorrencia,
                       (
                           SELECT max(todas_metricas.data_metrica)
                           FROM ads.tb_ad_evento_metricas_dia todas_metricas
                       ) AS agregado_ultima_data,
                       (
                           SELECT max(todas_metricas.updated_at)
                           FROM ads.tb_ad_evento_metricas_dia todas_metricas
                       ) AS agregado_atualizado_em
                FROM ads.tb_ad_evento_metricas_dia metricas
                WHERE metricas.data_metrica BETWEEN
                      current_date - <cfqueryparam
                          cfsqltype="cf_sql_integer"
                          value="#VARIABLES.adsMetricsLookbackDays#"/>
                      AND current_date
            </cfquery>
        </cfif>
    </cftransaction>

    <cfcatch>
        <cflog
            file="application"
            type="error"
            text="Falha ao atualizar ads.tb_ad_evento_metricas_dia: #left(cfcatch.message, 500)#"/>
        <cfset adsMetricsWrite({
            success = false,
            status = "refresh_failed",
            message = "Nao foi possivel atualizar as metricas de publicidade."
        }, 500, "Internal Server Error")/>
    </cfcatch>
</cftry>

<cfif NOT VARIABLES.adsMetricsLockAcquired>
    <cfset adsMetricsWrite({
        success = false,
        status = "already_running",
        message = "Outra atualizacao das metricas ja esta em andamento."
    }, 409, "Conflict")/>
</cfif>

<cfset VARIABLES.adsMetricsSourceLastAt = isNull(qAdsMetricsRefreshSummary.fonte_ultima_ocorrencia)
    ? ""
    : dateTimeFormat(qAdsMetricsRefreshSummary.fonte_ultima_ocorrencia, "yyyy-mm-dd HH:nn:ss")/>
<cfset VARIABLES.adsMetricsAggregateLastDate = isNull(qAdsMetricsRefreshSummary.agregado_ultima_data)
    ? ""
    : dateFormat(qAdsMetricsRefreshSummary.agregado_ultima_data, "yyyy-mm-dd")/>
<cfset VARIABLES.adsMetricsAggregateUpdatedAt = isNull(qAdsMetricsRefreshSummary.agregado_atualizado_em)
    ? ""
    : dateTimeFormat(qAdsMetricsRefreshSummary.agregado_atualizado_em, "yyyy-mm-dd HH:nn:ss")/>

<cfset adsMetricsWrite({
    success = true,
    status = "refreshed",
    message = "Metricas de publicidade atualizadas.",
    dataInicio = dateFormat(qAdsMetricsRefreshSummary.data_inicio, "yyyy-mm-dd"),
    dataFim = dateFormat(qAdsMetricsRefreshSummary.data_fim, "yyyy-mm-dd"),
    linhasAgregadas = val(qAdsMetricsRefreshSummary.linhas_agregadas),
    views = val(qAdsMetricsRefreshSummary.views),
    clicks = val(qAdsMetricsRefreshSummary.clicks),
    custo = val(qAdsMetricsRefreshSummary.custo),
    fonteUltimaOcorrencia = VARIABLES.adsMetricsSourceLastAt,
    agregadoUltimaData = VARIABLES.adsMetricsAggregateLastDate,
    agregadoAtualizadoEm = VARIABLES.adsMetricsAggregateUpdatedAt,
    durationMs = getTickCount() - VARIABLES.adsMetricsStartedAt
})/>
