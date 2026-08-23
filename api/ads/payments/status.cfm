<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting requesttimeout="30" showdebugoutput="false"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfheader name="Cache-Control" value="no-store, private, max-age=0"/>
<cfheader name="Pragma" value="no-cache"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>

<cfscript>
function adsPaymentStatusWrite(required struct payload, numeric statusCode = 200, string statusText = "OK") output="true" {
    cfheader(statuscode = arguments.statusCode, statustext = arguments.statusText);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function adsPaymentStatusIsUuid(required any value) {
    return reFindNoCase(
        "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
        trim(arguments.value & "")
    ) EQ 1;
}

if (uCase(trim(CGI.request_method & "")) NEQ "GET") {
    cfheader(name = "Allow", value = "GET");
    adsPaymentStatusWrite({
        success = false,
        status = "method_not_allowed"
    }, 405, "Method Not Allowed");
}
</cfscript>

<cfinclude template="../../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../../ads/includes/access.cfm"/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount>
    <cfset adsPaymentStatusWrite({
        success = false,
        status = "unauthorized"
    }, 401, "Unauthorized")/>
</cfif>

<cfif NOT VARIABLES.adsAccessCanViewPayments>
    <cfset adsPaymentStatusWrite({
        success = false,
        status = "forbidden"
    }, 403, "Forbidden")/>
</cfif>

<cfset VARIABLES.adsPaymentStatusId = structKeyExists(URL, "payment") ? trim(URL.payment & "") : ""/>
<cfif NOT adsPaymentStatusIsUuid(VARIABLES.adsPaymentStatusId)>
    <cfset adsPaymentStatusWrite({
        success = false,
        status = "invalid_payment"
    }, 400, "Bad Request")/>
</cfif>

<cftry>
    <cfset VARIABLES.adsPaymentStatusService = createObject("component", "ads.components.AdsPaymentService").init(
        datasource = "runnerhub"
    )/>
    <cfset VARIABLES.adsPaymentStatusResult = VARIABLES.adsPaymentStatusService.getIntentStatus(
        accountId = VARIABLES.adsAccessAccountId,
        paymentIntentId = VARIABLES.adsPaymentStatusId
    )/>
    <cfif NOT VARIABLES.adsPaymentStatusResult.success>
        <cfif VARIABLES.adsPaymentStatusResult.errorCode EQ "not_found">
            <cfset adsPaymentStatusWrite({ success = false, status = "not_found" }, 404, "Not Found")/>
        </cfif>
        <cfset adsPaymentStatusWrite({ success = false, status = "unavailable" }, 503, "Service Unavailable")/>
    </cfif>

    <cfquery name="qAdsPaymentStatusBalance" datasource="runnerhub">
        SELECT coalesce(balance.available_balance, 0)::numeric(14, 2) AS available_balance,
               coalesce(balance.currency, 'BRL')::character(3) AS currency
        FROM public.tb_contas account
        LEFT JOIN ads.account_balances balance
          ON balance.account_id = account.id_conta
        WHERE account.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsAccessAccountId#"/>
          AND account.status::text = 'ATIVA'
        LIMIT 1
    </cfquery>

    <cfif NOT qAdsPaymentStatusBalance.recordcount>
        <cfset adsPaymentStatusWrite({ success = false, status = "not_found" }, 404, "Not Found")/>
    </cfif>

    <cfset adsPaymentStatusWrite({
        success = true,
        status = VARIABLES.adsPaymentStatusResult.status,
        reference = VARIABLES.adsPaymentStatusResult.reference,
        amountCents = VARIABLES.adsPaymentStatusResult.amountCents,
        currency = VARIABLES.adsPaymentStatusResult.currency,
        expiresAt = isDate(VARIABLES.adsPaymentStatusResult.expiresAt)
            ? dateTimeFormat(VARIABLES.adsPaymentStatusResult.expiresAt, "yyyy-mm-dd'T'HH:nn:ssXXX")
            : "",
        paidAt = isDate(VARIABLES.adsPaymentStatusResult.paidAt)
            ? dateTimeFormat(VARIABLES.adsPaymentStatusResult.paidAt, "yyyy-mm-dd'T'HH:nn:ssXXX")
            : "",
        paymentMethod = VARIABLES.adsPaymentStatusResult.paymentMethod,
        credited = VARIABLES.adsPaymentStatusResult.credited,
        availableBalance = val(qAdsPaymentStatusBalance.available_balance),
        balanceCurrency = trim(qAdsPaymentStatusBalance.currency & "")
    })/>

    <cfcatch type="any">
        <cflog file="business_ads_payments" type="error" text="stage=status account=#VARIABLES.adsAccessAccountId# actor=#VARIABLES.adsAccessActorId# type=#cfcatch.type# message=#left(cfcatch.message & '', 500)#"/>
        <cfset adsPaymentStatusWrite({
            success = false,
            status = "unavailable"
        }, 503, "Service Unavailable")/>
    </cfcatch>
</cftry>
