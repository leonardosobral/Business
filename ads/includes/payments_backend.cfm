<cfparam name="URL.payment" default=""/>
<cfparam name="FORM.ads_payment_csrf" default=""/>
<cfparam name="FORM.ads_payment_amount" default=""/>
<cfparam name="FORM.ads_payment_idempotency_key" default=""/>

<cfset VARIABLES.adsPaymentActionHandled = false/>
<cfset VARIABLES.adsPaymentApiReady = false/>
<cfset VARIABLES.adsPaymentDataReady = false/>
<cfset VARIABLES.adsPaymentError = ""/>
<cfset VARIABLES.adsPaymentCsrf = ""/>
<cfset VARIABLES.adsPaymentIdempotencyKey = ""/>
<cfset VARIABLES.adsPaymentAmountRaw = "100.00"/>
<cfset VARIABLES.adsPaymentSelectedId = ""/>
<cfset VARIABLES.adsPaymentValidatedCheckoutUrl = ""/>
<cfset VARIABLES.adsPaymentCurrent = {}/>
<cfset VARIABLES.adsPaymentProviderStatus = {
    configured = false,
    enabled = false,
    ready = false,
    mode = "test",
    errorCode = "not_configured"
}/>
<cfset qAdsPayments = queryNew("payment_intent_id,amount_cents,currency,status,order_code,payment_method,expires_at,paid_at,created_at,updated_at,ledger_entry_id,support_reference")/>

<cfif NOT structKeyExists(SESSION, "adsV1PaymentCsrf")
    OR NOT len(trim(SESSION.adsV1PaymentCsrf & ""))>
    <cfset SESSION.adsV1PaymentCsrf = lCase(hash(createUUID() & now() & getTickCount() & "payments", "SHA-256"))/>
</cfif>
<cfset VARIABLES.adsPaymentCsrf = SESSION.adsV1PaymentCsrf/>

<cftry>
    <cfset VARIABLES.adsPaymentClient = createObject("component", "ads.components.PagarMeClient").init()/>
    <cfset VARIABLES.adsPaymentService = createObject("component", "ads.components.AdsPaymentService").init(
        datasource = "runnerhub",
        pagarMeClient = VARIABLES.adsPaymentClient
    )/>
    <cfset VARIABLES.adsPaymentProviderStatus = VARIABLES.adsPaymentService.getProviderStatus()/>
    <cfcatch type="any">
        <cflog file="business_ads_payments" type="error" text="stage=client_init account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# type=#cfcatch.type# message=#left(cfcatch.message & '', 500)#"/>
    </cfcatch>
</cftry>

<cfif VARIABLES.adsAccessCanViewPayments AND VARIABLES.adsV1HasAccount>
    <cftry>
        <cfquery name="qAdsPaymentReadiness" datasource="runnerhub">
            WITH expected_functions(signature) AS (
                VALUES
                    ('ads.create_payment_intent(bigint,integer,bigint,character,text,timestamp with time zone)'),
                    ('ads.attach_payment_checkout(uuid,text,text,text)')
            ),
            resolved_functions AS (
                SELECT signature,
                       to_regprocedure(signature) AS procedure_oid
                FROM expected_functions
            )
            SELECT count(*)::integer AS expected_count,
                   count(procedure_oid)::integer AS resolved_count,
                   bool_and(
                       procedure_oid IS NOT NULL
                       AND has_function_privilege(current_user, procedure_oid, 'EXECUTE')
                   ) AS functions_ready,
                   to_regclass('ads.payment_intents') IS NOT NULL AS table_exists,
                   CASE
                       WHEN to_regclass('ads.payment_intents') IS NULL THEN false
                       ELSE has_table_privilege(current_user, 'ads.payment_intents', 'SELECT')
                   END AS table_ready
            FROM resolved_functions
        </cfquery>
        <cfset VARIABLES.adsPaymentApiReady = qAdsPaymentReadiness.recordcount
            AND val(qAdsPaymentReadiness.expected_count) EQ 2
            AND val(qAdsPaymentReadiness.resolved_count) EQ 2
            AND listFindNoCase("1,true,t,yes,on", trim(qAdsPaymentReadiness.functions_ready & "")) GT 0
            AND listFindNoCase("1,true,t,yes,on", trim(qAdsPaymentReadiness.table_exists & "")) GT 0
            AND listFindNoCase("1,true,t,yes,on", trim(qAdsPaymentReadiness.table_ready & "")) GT 0/>
        <cfcatch type="any">
            <cfset VARIABLES.adsPaymentApiReady = false/>
            <cflog file="business_ads_payments" type="error" text="stage=readiness account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# type=#cfcatch.type# message=#left(cfcatch.message & '', 500)#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfif lCase(trim(FORM.ads_v1_action & "")) EQ "create_payment_checkout">
    <cfset VARIABLES.adsPaymentActionHandled = true/>
    <cfset VARIABLES.adsPaymentAmountRaw = trim(FORM.ads_payment_amount & "")/>
    <cfset VARIABLES.adsPaymentIdempotencyKey = lCase(trim(FORM.ads_payment_idempotency_key & ""))/>
    <cftry>
        <cfif NOT VARIABLES.adsV1CanMutate OR NOT VARIABLES.adsPaymentApiReady>
            <cfthrow type="AdsPayment.Validation" message="A compra de credito ainda nao esta disponivel."/>
        </cfif>
        <cfif NOT VARIABLES.adsAccessCanPurchaseCredit>
            <cfheader statuscode="403" statustext="Forbidden"/>
            <cfthrow type="AdsPayment.Forbidden" message="Seu papel nesta conta nao permite comprar credito."/>
        </cfif>
        <cfif compare(trim(FORM.ads_payment_csrf & ""), VARIABLES.adsPaymentCsrf) NEQ 0>
            <cfthrow type="AdsPayment.Validation" message="A sessao do pagamento expirou. Recarregue a pagina."/>
        </cfif>

        <cfset VARIABLES.adsPaymentAmount = adsV1MoneyValue(VARIABLES.adsPaymentAmountRaw)/>
        <cfset VARIABLES.adsPaymentAmountCents = round(VARIABLES.adsPaymentAmount * 100)/>
        <cfif NOT reFind("^[0-9]+([.,][0-9]{1,2})?$", VARIABLES.adsPaymentAmountRaw)
            OR VARIABLES.adsPaymentAmountCents LT 5000
            OR VARIABLES.adsPaymentAmountCents GT 2147483647>
            <cfthrow type="AdsPayment.Validation" message="Informe um valor entre R$ 50,00 e o limite aceito pelo provedor."/>
        </cfif>

        <cfset VARIABLES.adsPaymentKeyPrefix = "business:payment:" & VARIABLES.adsV1AccountId & ":"/>
        <cfset VARIABLES.adsPaymentKeySuffix = left(VARIABLES.adsPaymentIdempotencyKey, len(VARIABLES.adsPaymentKeyPrefix)) EQ VARIABLES.adsPaymentKeyPrefix
            ? mid(VARIABLES.adsPaymentIdempotencyKey, len(VARIABLES.adsPaymentKeyPrefix) + 1, 32)
            : ""/>
        <cfif len(VARIABLES.adsPaymentIdempotencyKey) NEQ len(VARIABLES.adsPaymentKeyPrefix) + 32
            OR NOT adsV1IsIdempotencyToken(VARIABLES.adsPaymentKeySuffix)>
            <cfthrow type="AdsPayment.Validation" message="A chave desta tentativa e invalida. Recarregue a pagina."/>
        </cfif>

        <cfset VARIABLES.adsPaymentCheckoutResult = VARIABLES.adsPaymentService.createCheckout(
            accountId = VARIABLES.adsV1AccountId,
            createdBy = VARIABLES.adsV1ActorId,
            amountCents = VARIABLES.adsPaymentAmountCents,
            idempotencyKey = VARIABLES.adsPaymentIdempotencyKey
        )/>
        <cfif NOT VARIABLES.adsPaymentCheckoutResult.success>
            <cfthrow type="AdsPayment.Validation" message="#VARIABLES.adsPaymentCheckoutResult.message#"/>
        </cfif>
        <cflocation addtoken="false" url="./?payment=#urlEncodedFormat(VARIABLES.adsPaymentCheckoutResult.paymentIntentId)###payment-credit"/>

        <cfcatch type="any">
            <cflog file="business_ads_payments" type="error" text="stage=create_checkout account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# type=#cfcatch.type# message=#left(cfcatch.message & '', 500)#"/>
            <cfif cfcatch.type EQ "AdsPayment.Validation" OR cfcatch.type EQ "AdsPayment.Forbidden">
                <cfset VARIABLES.adsPaymentError = cfcatch.message/>
            <cfelse>
                <cfset VARIABLES.adsPaymentError = "Nao foi possivel iniciar o pagamento. Tente novamente."/>
            </cfif>
        </cfcatch>
    </cftry>
</cfif>

<cfif VARIABLES.adsAccessCanViewPayments
    AND VARIABLES.adsV1HasAccount
    AND VARIABLES.adsPaymentApiReady>
    <cftry>
        <cfquery name="qAdsPayments" datasource="runnerhub">
            SELECT intent.payment_intent_id,
                   intent.amount_cents,
                   intent.currency,
                   intent.status,
                   intent.order_code,
                   intent.payment_method,
                   intent.expires_at,
                   intent.paid_at,
                   intent.created_at,
                   intent.updated_at,
                   intent.ledger_entry_id,
                   'ADS-' || upper(right(replace(intent.order_code, 'RHADS-', ''), 8)) AS support_reference
            FROM ads.payment_intents intent
            WHERE intent.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
            ORDER BY intent.created_at DESC,
                     intent.payment_intent_id DESC
            LIMIT 30
        </cfquery>

        <cfif adsV1IsUuid(URL.payment)>
            <cfset VARIABLES.adsPaymentSelectedId = lCase(trim(URL.payment & ""))/>
            <cfquery name="qAdsPaymentCurrent" datasource="runnerhub">
                SELECT intent.payment_intent_id,
                       intent.amount_cents,
                       intent.currency,
                       intent.status,
                       intent.order_code,
                       intent.checkout_url,
                       intent.payment_method,
                       intent.expires_at,
                       intent.paid_at,
                       intent.updated_at,
                       intent.ledger_entry_id,
                       'ADS-' || upper(right(replace(intent.order_code, 'RHADS-', ''), 8)) AS support_reference
                FROM ads.payment_intents intent
                WHERE intent.payment_intent_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsPaymentSelectedId#"/> AS uuid)
                  AND intent.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                LIMIT 1
            </cfquery>
            <cfif qAdsPaymentCurrent.recordcount>
                <cfset VARIABLES.adsPaymentCurrent = {
                    paymentIntentId = qAdsPaymentCurrent.payment_intent_id & "",
                    amountCents = val(qAdsPaymentCurrent.amount_cents),
                    currency = qAdsPaymentCurrent.currency & "",
                    status = uCase(qAdsPaymentCurrent.status & ""),
                    paymentMethod = lCase(qAdsPaymentCurrent.payment_method & ""),
                    expiresAt = qAdsPaymentCurrent.expires_at,
                    paidAt = qAdsPaymentCurrent.paid_at,
                    updatedAt = qAdsPaymentCurrent.updated_at,
                    credited = len(trim(qAdsPaymentCurrent.ledger_entry_id & "")) GT 0,
                    reference = qAdsPaymentCurrent.support_reference & ""
                }/>
                <cfif len(trim(qAdsPaymentCurrent.checkout_url & ""))>
                    <cftry>
                        <cfset VARIABLES.adsPaymentValidatedCheckoutUrl = VARIABLES.adsPaymentClient.validateCheckoutUrl(qAdsPaymentCurrent.checkout_url & "")/>
                        <cfcatch type="any">
                            <cfset VARIABLES.adsPaymentValidatedCheckoutUrl = ""/>
                            <cflog file="business_ads_payments" type="warning" text="stage=checkout_url account=#VARIABLES.adsV1AccountId# intent=#VARIABLES.adsPaymentSelectedId# message=invalid_checkout_url"/>
                        </cfcatch>
                    </cftry>
                </cfif>
            </cfif>
        </cfif>
        <cfset VARIABLES.adsPaymentDataReady = true/>
        <cfcatch type="any">
            <cfset VARIABLES.adsPaymentDataReady = false/>
            <cflog file="business_ads_payments" type="error" text="stage=read account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# type=#cfcatch.type# message=#left(cfcatch.message & '', 500)#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfif NOT len(VARIABLES.adsPaymentIdempotencyKey)>
    <cfset VARIABLES.adsPaymentIdempotencyKey = "business:payment:"
        & VARIABLES.adsV1AccountId & ":" & adsV1NewIdempotencyToken()/>
</cfif>
