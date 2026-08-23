<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting requesttimeout="45" showdebugoutput="false"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>

<cfscript>
function adsPaymentWebhookWrite(required struct payload, numeric statusCode = 200, string statusText = "OK") output="true" {
    cfheader(statuscode = arguments.statusCode, statustext = arguments.statusText);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function adsPaymentWebhookText(required any source, required string key, numeric maxLength = 200) {
    if (!isStruct(arguments.source) OR !structKeyExists(arguments.source, arguments.key)) return "";
    return left(trim(arguments.source[arguments.key] & ""), arguments.maxLength);
}

function adsPaymentWebhookStruct(required any source, required string key) {
    if (!isStruct(arguments.source)
        OR !structKeyExists(arguments.source, arguments.key)
        OR !isStruct(arguments.source[arguments.key])) return {};
    return arguments.source[arguments.key];
}

function adsPaymentWebhookSafeReference(required any value, numeric maxLength = 200) {
    var normalized = trim(arguments.value & "");
    return len(normalized) LTE arguments.maxLength
        AND reFind("^[A-Za-z0-9_-]+$", normalized)
        ? normalized
        : "";
}

VARIABLES.adsPaymentWebhookRelevantEvents = "order.paid,order.payment_failed,order.canceled,charge.pending,charge.refunded,chargeback.received,charge.partial_canceled";

if (uCase(trim(CGI.request_method & "")) NEQ "POST") {
    cfheader(name = "Allow", value = "POST");
    adsPaymentWebhookWrite({ received = false, status = "method_not_allowed" }, 405, "Method Not Allowed");
}

VARIABLES.adsPaymentWebhookContentType = structKeyExists(CGI, "content_type")
    ? lCase(trim(CGI.content_type & ""))
    : "";
if (listFirst(VARIABLES.adsPaymentWebhookContentType, ";") NEQ "application/json") {
    adsPaymentWebhookWrite({ received = false, status = "unsupported_media_type" }, 415, "Unsupported Media Type");
}

VARIABLES.adsPaymentWebhookContentLength = structKeyExists(CGI, "content_length")
    AND isNumeric(CGI.content_length)
    ? val(CGI.content_length)
    : 0;
if (VARIABLES.adsPaymentWebhookContentLength GT 262144) {
    adsPaymentWebhookWrite({ received = false, status = "invalid_body_size" }, 413, "Payload Too Large");
}

VARIABLES.adsPaymentWebhookRequestData = getHTTPRequestData();
VARIABLES.adsPaymentWebhookBody = toString(VARIABLES.adsPaymentWebhookRequestData.content);
if (!len(VARIABLES.adsPaymentWebhookBody) OR len(VARIABLES.adsPaymentWebhookBody) GT 262144) {
    adsPaymentWebhookWrite({ received = false, status = "invalid_body_size" }, 413, "Payload Too Large");
}
if (!isJSON(VARIABLES.adsPaymentWebhookBody)) {
    adsPaymentWebhookWrite({ received = false, status = "invalid_json" }, 400, "Bad Request");
}

VARIABLES.adsPaymentWebhookPayload = deserializeJSON(VARIABLES.adsPaymentWebhookBody);
if (!isStruct(VARIABLES.adsPaymentWebhookPayload)) {
    adsPaymentWebhookWrite({ received = false, status = "invalid_payload" }, 400, "Bad Request");
}

VARIABLES.adsPaymentWebhookEventId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookPayload, "id", 200);
VARIABLES.adsPaymentWebhookEventType = lCase(adsPaymentWebhookText(VARIABLES.adsPaymentWebhookPayload, "type", 100));
VARIABLES.adsPaymentWebhookData = adsPaymentWebhookStruct(VARIABLES.adsPaymentWebhookPayload, "data");
VARIABLES.adsPaymentWebhookBodyHash = lCase(hash(VARIABLES.adsPaymentWebhookBody, "SHA-256"));

if (!reFind("^[A-Za-z0-9_-]{1,200}$", VARIABLES.adsPaymentWebhookEventId)
    OR !reFind("^[a-z0-9_.-]{1,100}$", VARIABLES.adsPaymentWebhookEventType)
    OR !structKeyExists(VARIABLES.adsPaymentWebhookPayload, "data")
    OR !isStruct(VARIABLES.adsPaymentWebhookPayload.data)) {
    adsPaymentWebhookWrite({ received = false, status = "invalid_event" }, 400, "Bad Request");
}

VARIABLES.adsPaymentWebhookOrder = adsPaymentWebhookStruct(VARIABLES.adsPaymentWebhookData, "order");
VARIABLES.adsPaymentWebhookCharge = adsPaymentWebhookStruct(VARIABLES.adsPaymentWebhookData, "charge");
VARIABLES.adsPaymentWebhookPaymentLink = adsPaymentWebhookStruct(VARIABLES.adsPaymentWebhookData, "payment_link");
VARIABLES.adsPaymentWebhookOrderId = "";
VARIABLES.adsPaymentWebhookOrderCode = "";
VARIABLES.adsPaymentWebhookChargeId = "";
VARIABLES.adsPaymentWebhookLinkId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookData, "payment_link_id", 200);

if (left(VARIABLES.adsPaymentWebhookEventType, 6) EQ "order.") {
    VARIABLES.adsPaymentWebhookOrderId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookData, "id", 186);
    VARIABLES.adsPaymentWebhookOrderCode = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookData, "code", 100);
    if (structKeyExists(VARIABLES.adsPaymentWebhookData, "charges")
        AND isArray(VARIABLES.adsPaymentWebhookData.charges)
        AND arrayLen(VARIABLES.adsPaymentWebhookData.charges)
        AND isStruct(VARIABLES.adsPaymentWebhookData.charges[1])) {
        VARIABLES.adsPaymentWebhookChargeId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookData.charges[1], "id", 200);
    }
} else if (left(VARIABLES.adsPaymentWebhookEventType, 7) EQ "charge.") {
    VARIABLES.adsPaymentWebhookChargeId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookData, "id", 200);
    VARIABLES.adsPaymentWebhookOrderId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookOrder, "id", 186);
    VARIABLES.adsPaymentWebhookOrderCode = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookOrder, "code", 100);
} else if (VARIABLES.adsPaymentWebhookEventType EQ "chargeback.received") {
    if (!structCount(VARIABLES.adsPaymentWebhookCharge)) {
        VARIABLES.adsPaymentWebhookCharge = adsPaymentWebhookStruct(VARIABLES.adsPaymentWebhookData, "last_transaction");
    }
    VARIABLES.adsPaymentWebhookChargeId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookData, "charge_id", 200);
    if (!len(VARIABLES.adsPaymentWebhookChargeId)) {
        VARIABLES.adsPaymentWebhookChargeId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookCharge, "id", 200);
    }
    VARIABLES.adsPaymentWebhookOrder = adsPaymentWebhookStruct(VARIABLES.adsPaymentWebhookCharge, "order");
    VARIABLES.adsPaymentWebhookOrderId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookOrder, "id", 186);
    VARIABLES.adsPaymentWebhookOrderCode = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookOrder, "code", 100);
}
if (!len(VARIABLES.adsPaymentWebhookLinkId)) {
    VARIABLES.adsPaymentWebhookLinkId = adsPaymentWebhookText(VARIABLES.adsPaymentWebhookPaymentLink, "id", 200);
}
VARIABLES.adsPaymentWebhookLinkId = adsPaymentWebhookSafeReference(VARIABLES.adsPaymentWebhookLinkId, 200);
VARIABLES.adsPaymentWebhookOrderId = adsPaymentWebhookSafeReference(VARIABLES.adsPaymentWebhookOrderId, 186);
VARIABLES.adsPaymentWebhookChargeId = adsPaymentWebhookSafeReference(VARIABLES.adsPaymentWebhookChargeId, 200);
if (!reFind("^RHADS-[0-9a-f]{32}$", VARIABLES.adsPaymentWebhookOrderCode)) {
    VARIABLES.adsPaymentWebhookOrderCode = "";
}
</cfscript>

<cftry>
    <cfset VARIABLES.adsPaymentWebhookService = createObject("component", "ads.components.AdsPaymentService").init(
        datasource = "runnerhub"
    )/>
    <cfset VARIABLES.adsPaymentWebhookCorrelation = VARIABLES.adsPaymentWebhookService.correlatePaymentIntent(
        providerPaymentLinkId = VARIABLES.adsPaymentWebhookLinkId,
        providerOrderId = VARIABLES.adsPaymentWebhookOrderId,
        providerChargeId = VARIABLES.adsPaymentWebhookChargeId,
        orderCode = VARIABLES.adsPaymentWebhookOrderCode
    )/>
    <cfset VARIABLES.adsPaymentWebhookIntentId = VARIABLES.adsPaymentWebhookCorrelation.success
        AND VARIABLES.adsPaymentWebhookCorrelation.found
        ? VARIABLES.adsPaymentWebhookCorrelation.paymentIntentId
        : ""/>

    <cfset VARIABLES.adsPaymentWebhookReceipt = VARIABLES.adsPaymentWebhookService.recordPaymentEvent(
        providerEventId = VARIABLES.adsPaymentWebhookEventId,
        eventType = VARIABLES.adsPaymentWebhookEventType,
        providerPaymentLinkId = VARIABLES.adsPaymentWebhookLinkId,
        providerOrderId = VARIABLES.adsPaymentWebhookOrderId,
        providerChargeId = VARIABLES.adsPaymentWebhookChargeId,
        paymentIntentId = VARIABLES.adsPaymentWebhookIntentId,
        bodyHash = VARIABLES.adsPaymentWebhookBodyHash
    )/>
    <cfif NOT VARIABLES.adsPaymentWebhookReceipt.success>
        <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
    </cfif>

    <cfif listFindNoCase("PROCESSED,IGNORED,REVIEW", VARIABLES.adsPaymentWebhookReceipt.status)>
        <cfset adsPaymentWebhookWrite({ received = true, status = "already_recorded" })/>
    </cfif>

    <cfif NOT listFindNoCase(VARIABLES.adsPaymentWebhookRelevantEvents, VARIABLES.adsPaymentWebhookEventType)>
        <cfset VARIABLES.adsPaymentWebhookCompletion = VARIABLES.adsPaymentWebhookService.completePaymentEvent(
            VARIABLES.adsPaymentWebhookReceipt.paymentEventId,
            "IGNORED"
        )/>
        <cfif NOT VARIABLES.adsPaymentWebhookCompletion.success>
            <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
        </cfif>
        <cfset adsPaymentWebhookWrite({ received = true, status = "ignored" })/>
    </cfif>

    <cfif NOT VARIABLES.adsPaymentWebhookCorrelation.success>
        <cfset VARIABLES.adsPaymentWebhookCompletion = VARIABLES.adsPaymentWebhookService.completePaymentEvent(
            VARIABLES.adsPaymentWebhookReceipt.paymentEventId,
            listFindNoCase("ambiguous_correlation,invalid_provider_reference", VARIABLES.adsPaymentWebhookCorrelation.errorCode) ? "REVIEW" : "FAILED",
            listFindNoCase("ambiguous_correlation,invalid_provider_reference", VARIABLES.adsPaymentWebhookCorrelation.errorCode)
                ? "Referencias do provedor divergentes"
                : "Falha temporaria de correlacao"
        )/>
        <cfif NOT VARIABLES.adsPaymentWebhookCompletion.success>
            <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
        </cfif>
        <cfif listFindNoCase("ambiguous_correlation,invalid_provider_reference", VARIABLES.adsPaymentWebhookCorrelation.errorCode)>
            <cflog file="business_ads_payments" type="error" text="stage=webhook_review event=#VARIABLES.adsPaymentWebhookEventId# reason=ambiguous_correlation"/>
            <cfset adsPaymentWebhookWrite({ received = true, status = "review" })/>
        </cfif>
        <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
    </cfif>

    <cfif NOT VARIABLES.adsPaymentWebhookCorrelation.found>
        <cfset VARIABLES.adsPaymentWebhookCompletion = VARIABLES.adsPaymentWebhookService.completePaymentEvent(
            VARIABLES.adsPaymentWebhookReceipt.paymentEventId,
            "IGNORED"
        )/>
        <cfif NOT VARIABLES.adsPaymentWebhookCompletion.success>
            <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
        </cfif>
        <cfset adsPaymentWebhookWrite({ received = true, status = "ignored" })/>
    </cfif>

    <cfset VARIABLES.adsPaymentWebhookProcess = VARIABLES.adsPaymentWebhookService.processWebhookEvent(
        paymentEventId = VARIABLES.adsPaymentWebhookReceipt.paymentEventId,
        eventType = VARIABLES.adsPaymentWebhookEventType,
        paymentIntentId = VARIABLES.adsPaymentWebhookIntentId
    )/>

    <cfif VARIABLES.adsPaymentWebhookProcess.success>
        <cfset VARIABLES.adsPaymentWebhookCompletion = VARIABLES.adsPaymentWebhookService.completePaymentEvent(
            VARIABLES.adsPaymentWebhookReceipt.paymentEventId,
            "PROCESSED"
        )/>
        <cfif NOT VARIABLES.adsPaymentWebhookCompletion.success>
            <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
        </cfif>
        <cfset adsPaymentWebhookWrite({ received = true, status = "processed" })/>
    </cfif>

    <cfif structKeyExists(VARIABLES.adsPaymentWebhookProcess, "review")
        AND VARIABLES.adsPaymentWebhookProcess.review>
        <cfset VARIABLES.adsPaymentWebhookCompletion = VARIABLES.adsPaymentWebhookService.completePaymentEvent(
            VARIABLES.adsPaymentWebhookReceipt.paymentEventId,
            "REVIEW",
            left(VARIABLES.adsPaymentWebhookProcess.message & "", 500)
        )/>
        <cfif NOT VARIABLES.adsPaymentWebhookCompletion.success>
            <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
        </cfif>
        <cflog file="business_ads_payments" type="error" text="stage=webhook_review event=#VARIABLES.adsPaymentWebhookEventId# intent=#VARIABLES.adsPaymentWebhookIntentId# reason=#left(VARIABLES.adsPaymentWebhookProcess.resultStatus & '', 100)#"/>
        <cfset adsPaymentWebhookWrite({ received = true, status = "review" })/>
    </cfif>

    <cfset VARIABLES.adsPaymentWebhookCompletion = VARIABLES.adsPaymentWebhookService.completePaymentEvent(
        VARIABLES.adsPaymentWebhookReceipt.paymentEventId,
        "FAILED",
        "Falha temporaria ao reconsultar ou processar o provedor"
    )/>
    <cfif NOT VARIABLES.adsPaymentWebhookCompletion.success>
        <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
    </cfif>
    <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>

    <cfcatch type="any">
        <cflog file="business_ads_payments" type="error" text="stage=webhook event=#VARIABLES.adsPaymentWebhookEventId# type=#cfcatch.type# message=#left(cfcatch.message & '', 500)#"/>
        <cfset adsPaymentWebhookWrite({ received = false, status = "retry" }, 503, "Service Unavailable")/>
    </cfcatch>
</cftry>
