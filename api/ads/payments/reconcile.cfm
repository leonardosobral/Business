<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting requesttimeout="120" showdebugoutput="false"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>

<cfscript>
function adsPaymentReconcileWrite(
    required struct payload,
    numeric statusCode = 200,
    string statusText = "OK"
) output="true" {
    cfheader(statuscode = arguments.statusCode, statustext = arguments.statusText);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function adsPaymentReconcilePayload(required boolean success, required string status) {
    return {
        success = arguments.success,
        status = arguments.status,
        examined = VARIABLES.adsPaymentReconcileExamined,
        credited = VARIABLES.adsPaymentReconcileCredited,
        alreadyProcessed = VARIABLES.adsPaymentReconcileAlreadyProcessed,
        pending = VARIABLES.adsPaymentReconcilePending,
        failed = VARIABLES.adsPaymentReconcileFailed,
        expired = VARIABLES.adsPaymentReconcileExpired,
        review = VARIABLES.adsPaymentReconcileReview,
        durationMs = getTickCount() - VARIABLES.adsPaymentReconcileStartedAt,
        lastProviderTimestamp = VARIABLES.adsPaymentReconcileLastProviderTimestamp
    };
}

VARIABLES.adsPaymentReconcileStartedAt = getTickCount();
VARIABLES.adsPaymentReconcileHeaders = getHTTPRequestData().headers;
VARIABLES.adsPaymentReconcileAuthorization = structKeyExists(VARIABLES.adsPaymentReconcileHeaders, "Authorization")
    ? trim(VARIABLES.adsPaymentReconcileHeaders.Authorization & "")
    : "";
VARIABLES.adsPaymentReconcileSecret = "";
VARIABLES.adsPaymentReconcileCfLockAcquired = false;
VARIABLES.adsPaymentReconcileDbLockAcquired = false;
VARIABLES.adsPaymentReconcileProviderReady = false;
VARIABLES.adsPaymentReconcileExamined = 0;
VARIABLES.adsPaymentReconcileCredited = 0;
VARIABLES.adsPaymentReconcileAlreadyProcessed = 0;
VARIABLES.adsPaymentReconcilePending = 0;
VARIABLES.adsPaymentReconcileFailed = 0;
VARIABLES.adsPaymentReconcileExpired = 0;
VARIABLES.adsPaymentReconcileReview = 0;
VARIABLES.adsPaymentReconcileTemporaryFailures = 0;
VARIABLES.adsPaymentReconcileLastProviderTimestamp = "";
VARIABLES.adsPaymentReconcileCandidates = [];

if (uCase(trim(CGI.request_method & "")) NEQ "POST") {
    cfheader(name = "Allow", value = "POST");
    adsPaymentReconcileWrite(
        adsPaymentReconcilePayload(false, "method_not_allowed"),
        405,
        "Method Not Allowed"
    );
}

if (structKeyExists(APPLICATION, "cronJobs")
    AND isStruct(APPLICATION.cronJobs)
    AND structKeyExists(APPLICATION.cronJobs, "secrets")
    AND isStruct(APPLICATION.cronJobs.secrets)
    AND structKeyExists(APPLICATION.cronJobs.secrets, "business_internal")) {
    VARIABLES.adsPaymentReconcileSecret = trim(APPLICATION.cronJobs.secrets.business_internal & "");
}

if (!len(VARIABLES.adsPaymentReconcileSecret)) {
    adsPaymentReconcileWrite(
        adsPaymentReconcilePayload(false, "not_configured"),
        503,
        "Service Unavailable"
    );
}

if (!len(VARIABLES.adsPaymentReconcileAuthorization)
    OR hash(VARIABLES.adsPaymentReconcileAuthorization, "SHA-256")
        NEQ hash("Bearer " & VARIABLES.adsPaymentReconcileSecret, "SHA-256")) {
    adsPaymentReconcileWrite(
        adsPaymentReconcilePayload(false, "unauthorized"),
        401,
        "Unauthorized"
    );
}
</cfscript>

<cftry>
    <cflock
        name="business-ads-payment-reconciliation"
        type="exclusive"
        timeout="1"
        throwontimeout="false">
        <cfset VARIABLES.adsPaymentReconcileCfLockAcquired = true/>
        <cfset VARIABLES.adsPaymentReconcileClient = createObject(
            "component",
            "ads.components.PagarMeClient"
        ).init()/>
        <cfset VARIABLES.adsPaymentReconcileProviderStatus = VARIABLES.adsPaymentReconcileClient.getStatus()/>
        <cfset VARIABLES.adsPaymentReconcileProviderReady = VARIABLES.adsPaymentReconcileProviderStatus.ready/>

        <cfif VARIABLES.adsPaymentReconcileProviderReady>
            <cfset VARIABLES.adsPaymentReconcileService = createObject(
                "component",
                "ads.components.AdsPaymentService"
            ).init(
                datasource = "runnerhub",
                pagarMeClient = VARIABLES.adsPaymentReconcileClient
            )/>
            <cfset VARIABLES.adsPaymentReconcileBatchSize = VARIABLES.adsPaymentReconcileClient.getReconcileBatchSize()/>

            <cftransaction>
                <cfquery name="qAdsPaymentReconcileLock" datasource="runnerhub">
                    SELECT pg_try_advisory_xact_lock(940000011::bigint) AS locked
                </cfquery>
                <cfset VARIABLES.adsPaymentReconcileDbLockAcquired = qAdsPaymentReconcileLock.recordCount
                    AND qAdsPaymentReconcileLock.locked/>
                <cfif VARIABLES.adsPaymentReconcileDbLockAcquired>
                    <cfset VARIABLES.adsPaymentReconcileCandidates = VARIABLES.adsPaymentReconcileService.listReconciliationCandidates(
                        batchSize = VARIABLES.adsPaymentReconcileBatchSize,
                        updatedBefore = dateAdd("n", -1, now())
                    )/>
                </cfif>
            </cftransaction>

            <cfif VARIABLES.adsPaymentReconcileDbLockAcquired>
                <cfloop array="#VARIABLES.adsPaymentReconcileCandidates#" index="adsPaymentReconcileCandidate">
                    <cfif getTickCount() - VARIABLES.adsPaymentReconcileStartedAt GTE 90000>
                        <cfbreak/>
                    </cfif>
                    <cfset VARIABLES.adsPaymentReconcileExamined++/>
                    <cfset VARIABLES.adsPaymentReconcileResult = VARIABLES.adsPaymentReconcileService.reconcileIntent(
                        paymentIntentId = adsPaymentReconcileCandidate.paymentIntentId,
                        forceProviderCheck = false
                    )/>
                    <cfset VARIABLES.adsPaymentReconcileResultStatus = structKeyExists(VARIABLES.adsPaymentReconcileResult, "resultStatus")
                        ? lCase(trim(VARIABLES.adsPaymentReconcileResult.resultStatus & ""))
                        : ""/>
                    <cfset VARIABLES.adsPaymentReconcileIntentStatus = structKeyExists(VARIABLES.adsPaymentReconcileResult, "status")
                        ? lCase(trim(VARIABLES.adsPaymentReconcileResult.status & ""))
                        : ""/>

                    <cfif structKeyExists(VARIABLES.adsPaymentReconcileResult, "providerUpdatedAt")
                        AND len(trim(VARIABLES.adsPaymentReconcileResult.providerUpdatedAt & ""))>
                        <cfset VARIABLES.adsPaymentReconcileProviderTimestamp = left(
                            trim(VARIABLES.adsPaymentReconcileResult.providerUpdatedAt & ""),
                            80
                        )/>
                        <cfif NOT len(VARIABLES.adsPaymentReconcileLastProviderTimestamp)
                            OR (isDate(VARIABLES.adsPaymentReconcileProviderTimestamp)
                                AND isDate(VARIABLES.adsPaymentReconcileLastProviderTimestamp)
                                AND dateCompare(
                                    VARIABLES.adsPaymentReconcileProviderTimestamp,
                                    VARIABLES.adsPaymentReconcileLastProviderTimestamp
                                ) GT 0)>
                            <cfset VARIABLES.adsPaymentReconcileLastProviderTimestamp = VARIABLES.adsPaymentReconcileProviderTimestamp/>
                        </cfif>
                    </cfif>

                    <cfif NOT VARIABLES.adsPaymentReconcileResult.success>
                        <cfif structKeyExists(VARIABLES.adsPaymentReconcileResult, "review")
                            AND VARIABLES.adsPaymentReconcileResult.review>
                            <cfset VARIABLES.adsPaymentReconcileReview++/>
                        <cfelse>
                            <cfset VARIABLES.adsPaymentReconcileFailed++/>
                            <cfset VARIABLES.adsPaymentReconcileTemporaryFailures++/>
                        </cfif>
                    <cfelseif VARIABLES.adsPaymentReconcileResultStatus EQ "credited">
                        <cfset VARIABLES.adsPaymentReconcileCredited++/>
                    <cfelseif VARIABLES.adsPaymentReconcileIntentStatus EQ "paid">
                        <cfset VARIABLES.adsPaymentReconcileAlreadyProcessed++/>
                    <cfelseif listFindNoCase("created,checkout_ready,pending", VARIABLES.adsPaymentReconcileIntentStatus)>
                        <cfset VARIABLES.adsPaymentReconcilePending++/>
                    <cfelseif VARIABLES.adsPaymentReconcileIntentStatus EQ "expired">
                        <cfset VARIABLES.adsPaymentReconcileExpired++/>
                    <cfelseif listFindNoCase("failed,canceled", VARIABLES.adsPaymentReconcileIntentStatus)>
                        <cfset VARIABLES.adsPaymentReconcileFailed++/>
                    <cfelseif VARIABLES.adsPaymentReconcileIntentStatus EQ "review">
                        <cfset VARIABLES.adsPaymentReconcileReview++/>
                    <cfelse>
                        <cfset VARIABLES.adsPaymentReconcileAlreadyProcessed++/>
                    </cfif>
                </cfloop>
            </cfif>
        </cfif>
    </cflock>

    <cfcatch type="any">
        <cflog
            file="business_ads_payments"
            type="error"
            text="stage=reconcile type=#left(cfcatch.type & '', 100)# message=#left(cfcatch.message & '', 500)#"/>
        <cfset adsPaymentReconcileWrite(
            adsPaymentReconcilePayload(false, "reconcile_failed"),
            500,
            "Internal Server Error"
        )/>
    </cfcatch>
</cftry>

<cfif NOT VARIABLES.adsPaymentReconcileCfLockAcquired
    OR (VARIABLES.adsPaymentReconcileProviderReady
        AND NOT VARIABLES.adsPaymentReconcileDbLockAcquired)>
    <cfset adsPaymentReconcileWrite(
        adsPaymentReconcilePayload(false, "already_running"),
        409,
        "Conflict"
    )/>
</cfif>

<cfif NOT VARIABLES.adsPaymentReconcileProviderReady>
    <cfset adsPaymentReconcileWrite(
        adsPaymentReconcilePayload(false, "provider_not_configured"),
        503,
        "Service Unavailable"
    )/>
</cfif>

<cfif VARIABLES.adsPaymentReconcileTemporaryFailures GT 0>
    <cfset adsPaymentReconcileWrite(
        adsPaymentReconcilePayload(false, "partial_failure"),
        503,
        "Service Unavailable"
    )/>
</cfif>

<cfset adsPaymentReconcileWrite(
    adsPaymentReconcilePayload(true, "reconciled")
)/>
