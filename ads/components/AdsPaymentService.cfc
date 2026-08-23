component output="false" hint="Orquestra intencoes Ads sem DML financeiro direto." {

    variables.datasource = "runnerhub";
    variables.pagarMeClient = "";

    public any function init(string datasource = "runnerhub", any pagarMeClient = "") output="false" {
        variables.datasource = len(trim(arguments.datasource))
            ? trim(arguments.datasource)
            : "runnerhub";
        variables.pagarMeClient = isObject(arguments.pagarMeClient)
            ? arguments.pagarMeClient
            : createObject("component", "ads.components.PagarMeClient").init();
        return this;
    }

    public struct function getProviderStatus() output="false" {
        return variables.pagarMeClient.getStatus();
    }

    public array function listReconciliationCandidates(
        numeric batchSize = 25,
        any updatedBefore = ""
    ) output="false" {
        var normalizedBatchSize = min(30, max(1, int(arguments.batchSize)));
        var normalizedUpdatedBefore = isDate(arguments.updatedBefore)
            ? arguments.updatedBefore
            : dateAdd("n", -1, now());
        var candidatesQuery = queryNew("");
        var candidates = [];
        var rowIndex = 0;

        candidatesQuery = queryExecute(
            "
                SELECT candidate.*
                  FROM ads.list_payment_intents_for_reconciliation(
                      CAST(:batch_size AS integer),
                      CAST(:updated_before AS timestamp with time zone)
                  ) candidate
            ",
            {
                batch_size = { value = normalizedBatchSize, cfsqltype = "cf_sql_integer" },
                updated_before = { value = normalizedUpdatedBefore, cfsqltype = "cf_sql_timestamp" }
            },
            { datasource = variables.datasource }
        );

        for (rowIndex = 1; rowIndex LTE candidatesQuery.recordCount; rowIndex++) {
            arrayAppend(candidates, {
                paymentIntentId = queryString(candidatesQuery, rowIndex, "payment_intent_id"),
                status = lCase(queryString(candidatesQuery, rowIndex, "status")),
                expiresAt = queryValue(candidatesQuery, rowIndex, "expires_at", ""),
                updatedAt = queryValue(candidatesQuery, rowIndex, "updated_at", "")
            });
        }
        return candidates;
    }

    public struct function createCheckout(
        required numeric accountId,
        required numeric createdBy,
        required numeric amountCents,
        required string idempotencyKey
    ) output="false" {
        var normalizedAccountId = val(arguments.accountId);
        var normalizedCreatedBy = val(arguments.createdBy);
        var normalizedAmount = round(val(arguments.amountCents));
        var normalizedKey = lCase(trim(arguments.idempotencyKey));
        var providerStatus = variables.pagarMeClient.getStatus();
        var intentQuery = queryNew("");
        var intent = {};
        var expiresAt = "";
        var providerResult = {};
        var attachQuery = queryNew("");
        var attached = {};

        if (normalizedAccountId LTE 0 OR normalizedCreatedBy LTE 0) {
            return failureResult("invalid_context", "Conta e usuario sao obrigatorios.");
        }
        if (normalizedAmount LT variables.pagarMeClient.getMinimumAmountCents()
            OR normalizedAmount GT 2147483647) {
            return failureResult("invalid_amount", "O valor da compra e invalido.");
        }
        if (!reFind("^[a-z0-9][a-z0-9:_-]{15,199}$", normalizedKey)) {
            return failureResult("invalid_idempotency_key", "A chave desta tentativa e invalida.");
        }

        intentQuery = findIntentByIdempotency(normalizedAccountId, normalizedKey);
        if (intentQuery.recordCount) {
            intent = mapIntent(intentQuery, 1);
            if (intent.createdBy NEQ normalizedCreatedBy
                OR intent.amountCents NEQ normalizedAmount
                OR intent.currency NEQ "BRL") {
                return failureResult(
                    "idempotency_conflict",
                    "Esta tentativa ja foi usada com outros dados."
                );
            }
        } else {
            if (!providerStatus.ready OR !providerStatus.enabled) {
                return failureResult(
                    len(providerStatus.errorCode) ? providerStatus.errorCode : "pagarme_disabled",
                    "Novas compras de credito estao temporariamente desabilitadas."
                );
            }
            expiresAt = dateAdd(
                "n",
                variables.pagarMeClient.getPaymentLinkExpiresMinutes(),
                now()
            );
            try {
                intentQuery = queryExecute(
                    "
                        SELECT created.*
                          FROM ads.create_payment_intent(
                              CAST(:account_id AS bigint),
                              CAST(:created_by AS integer),
                              CAST(:amount_cents AS bigint),
                              CAST('BRL' AS character(3)),
                              CAST(:idempotency_key AS text),
                              CAST(:expires_at AS timestamp with time zone)
                          ) created
                    ",
                    {
                        account_id = { value = normalizedAccountId, cfsqltype = "cf_sql_bigint" },
                        created_by = { value = normalizedCreatedBy, cfsqltype = "cf_sql_integer" },
                        amount_cents = { value = normalizedAmount, cfsqltype = "cf_sql_bigint" },
                        idempotency_key = { value = normalizedKey, cfsqltype = "cf_sql_varchar" },
                        expires_at = { value = expiresAt, cfsqltype = "cf_sql_timestamp" }
                    },
                    { datasource = variables.datasource }
                );
                intent = mapIntentResult(intentQuery, normalizedAccountId, normalizedCreatedBy, normalizedKey);
                if (!structKeyExists(intent, "paymentIntentId")) {
                    return failureResult(
                        "intent_readback_failed",
                        "O pagamento foi iniciado, mas ainda nao pode ser exibido. Tente novamente."
                    );
                }
            } catch (any ignoredCreateRace) {
                intentQuery = findIntentByIdempotency(normalizedAccountId, normalizedKey);
                if (!intentQuery.recordCount) {
                    return failureResult("intent_create_failed", "Nao foi possivel iniciar o pagamento.");
                }
                intent = mapIntent(intentQuery, 1);
                if (intent.createdBy NEQ normalizedCreatedBy
                    OR intent.amountCents NEQ normalizedAmount
                    OR intent.currency NEQ "BRL") {
                    return failureResult(
                        "idempotency_conflict",
                        "Esta tentativa ja foi usada com outros dados."
                    );
                }
            }
        }

        if (len(intent.providerPaymentLinkId) OR len(intent.checkoutUrl)) {
            if (len(intent.providerPaymentLinkId)
                AND len(intent.checkoutUrl)
                AND variables.pagarMeClient.isCheckoutUrlAllowed(intent.checkoutUrl)) {
                return checkoutResult(intent, "already_recorded");
            }
            return failureResult(
                "invalid_attached_checkout",
                "O checkout salvo exige revisao antes de ser reutilizado."
            );
        }
        if (intent.status NEQ "CREATED") {
            return failureResult(
                "intent_not_checkoutable",
                "Esta tentativa nao permite criar um novo checkout."
            );
        }
        if (!providerStatus.ready OR !providerStatus.enabled) {
            return failureResult(
                len(providerStatus.errorCode) ? providerStatus.errorCode : "pagarme_disabled",
                "Novas compras de credito estao temporariamente desabilitadas."
            );
        }

        providerResult = variables.pagarMeClient.createPaymentLink(
            intent.orderCode,
            intent.amountCents
        );
        if (!providerResult.success) {
            return providerFailureResult(providerResult);
        }
        if (!variables.pagarMeClient.isCheckoutUrlAllowed(providerResult.paymentLink.url)) {
            return failureResult("invalid_checkout_url", "O checkout retornado pelo provedor e invalido.");
        }

        try {
            attachQuery = queryExecute(
                "
                    SELECT attached.*
                      FROM ads.attach_payment_checkout(
                          CAST(:payment_intent_id AS uuid),
                          CAST(:provider_payment_link_id AS text),
                          CAST(:checkout_url AS text),
                          CAST(:provider_order_id AS text)
                      ) attached
                ",
                {
                    payment_intent_id = { value = intent.paymentIntentId, cfsqltype = "cf_sql_varchar" },
                    provider_payment_link_id = { value = providerResult.paymentLink.id, cfsqltype = "cf_sql_varchar" },
                    checkout_url = { value = providerResult.paymentLink.url, cfsqltype = "cf_sql_varchar" },
                    provider_order_id = { value = "", null = true, cfsqltype = "cf_sql_varchar" }
                },
                { datasource = variables.datasource }
            );
            if (!attachQuery.recordCount) {
                return failureResult("checkout_attach_failed", "Nao foi possivel vincular o checkout.");
            }
            attached = duplicate(intent);
            attached.status = queryString(attachQuery, 1, "status");
            attached.providerPaymentLinkId = queryString(attachQuery, 1, "provider_payment_link_id");
            attached.providerOrderId = queryString(attachQuery, 1, "provider_order_id");
            attached.checkoutUrl = queryString(attachQuery, 1, "checkout_url");
            if (!variables.pagarMeClient.isCheckoutUrlAllowed(attached.checkoutUrl)) {
                return failureResult("checkout_attach_failed", "O checkout vinculado e invalido.");
            }
            return checkoutResult(attached, queryString(attachQuery, 1, "result_status"));
        } catch (any ignoredAttachError) {
            return failureResult(
                "checkout_attach_failed",
                "O checkout foi criado, mas ainda nao pode ser liberado. Tente novamente."
            );
        }
    }

    public struct function getIntentStatus(
        required numeric accountId,
        required string paymentIntentId
    ) output="false" {
        var intentQuery = queryNew("");
        var intent = {};
        var checkoutUrl = "";

        if (val(arguments.accountId) LTE 0 OR !isUuid(arguments.paymentIntentId)) {
            return failureResult("invalid_context", "A referencia do pagamento e invalida.");
        }
        intentQuery = findIntentById(arguments.paymentIntentId, val(arguments.accountId));
        if (!intentQuery.recordCount) {
            return failureResult("not_found", "Pagamento nao encontrado.");
        }
        intent = mapIntent(intentQuery, 1);
        if (len(intent.checkoutUrl)
            AND variables.pagarMeClient.isCheckoutUrlAllowed(intent.checkoutUrl)) {
            checkoutUrl = intent.checkoutUrl;
        }

        return {
            success = true,
            status = lCase(intent.status),
            paymentIntentId = intent.paymentIntentId,
            reference = shortReference(intent.orderCode),
            amountCents = intent.amountCents,
            currency = intent.currency,
            checkoutUrl = checkoutUrl,
            expiresAt = intent.expiresAt,
            paidAt = intent.paidAt,
            paymentMethod = intent.paymentMethod,
            credited = len(intent.ledgerEntryId) GT 0,
            updatedAt = intent.updatedAt
        };
    }

    public struct function correlatePaymentIntent(
        string providerPaymentLinkId = "",
        string providerOrderId = "",
        string providerChargeId = "",
        string orderCode = ""
    ) output="false" {
        var linkId = trim(arguments.providerPaymentLinkId);
        var orderId = trim(arguments.providerOrderId);
        var chargeId = trim(arguments.providerChargeId);
        var normalizedCode = trim(arguments.orderCode);
        var matches = queryNew("");

        if ((len(linkId) AND !isSafeProviderReference(linkId, 200))
            OR (len(orderId) AND !isSafeProviderReference(orderId, 186))
            OR (len(chargeId) AND !isSafeProviderReference(chargeId, 200))
            OR (len(normalizedCode) AND !reFind("^RHADS-[0-9a-f]{32}$", normalizedCode))) {
            return failureResult("invalid_provider_reference", "A referencia do provedor e invalida.");
        }
        if (!len(linkId) AND !len(orderId) AND !len(chargeId) AND !len(normalizedCode)) {
            return {
                success = true,
                status = "not_found",
                found = false,
                paymentIntentId = ""
            };
        }

        try {
            matches = queryExecute(
                "
                    WITH refs AS (
                        SELECT CAST(:provider_link_id AS text) AS provider_link_id,
                               CAST(:provider_order_id AS text) AS provider_order_id,
                               CAST(:provider_charge_id AS text) AS provider_charge_id,
                               CAST(:order_code AS text) AS order_code
                    )
                    SELECT intent.payment_intent_id,
                           intent.status
                      FROM ads.payment_intents intent
                      CROSS JOIN refs
                     WHERE (refs.provider_link_id <> '' AND intent.provider_payment_link_id = refs.provider_link_id)
                        OR (refs.provider_order_id <> '' AND intent.provider_order_id = refs.provider_order_id)
                        OR (refs.provider_charge_id <> '' AND intent.provider_charge_id = refs.provider_charge_id)
                        OR (refs.order_code <> '' AND intent.order_code = refs.order_code)
                     ORDER BY intent.created_at DESC
                     LIMIT 2
                ",
                {
                    provider_link_id = { value = linkId, cfsqltype = "cf_sql_varchar" },
                    provider_order_id = { value = orderId, cfsqltype = "cf_sql_varchar" },
                    provider_charge_id = { value = chargeId, cfsqltype = "cf_sql_varchar" },
                    order_code = { value = normalizedCode, cfsqltype = "cf_sql_varchar" }
                },
                { datasource = variables.datasource }
            );
        } catch (any ignoredCorrelationError) {
            return failureResult("correlation_failed", "Nao foi possivel correlacionar o pagamento.");
        }

        if (!matches.recordCount) {
            return {
                success = true,
                status = "not_found",
                found = false,
                paymentIntentId = ""
            };
        }
        if (matches.recordCount NEQ 1) {
            return failureResult("ambiguous_correlation", "As referencias do provedor sao divergentes.");
        }
        return {
            success = true,
            status = "found",
            found = true,
            paymentIntentId = queryString(matches, 1, "payment_intent_id"),
            intentStatus = lCase(queryString(matches, 1, "status"))
        };
    }

    public struct function recordPaymentEvent(
        required string providerEventId,
        required string eventType,
        string providerPaymentLinkId = "",
        string providerOrderId = "",
        string providerChargeId = "",
        string paymentIntentId = "",
        required string bodyHash
    ) output="false" {
        var eventQuery = queryNew("");

        if (!isSafeProviderReference(arguments.providerEventId, 200)
            OR len(trim(arguments.eventType)) GT 100
            OR !reFind("^[a-z0-9_.-]+$", lCase(trim(arguments.eventType)))
            OR !reFind("^[0-9a-f]{64}$", lCase(trim(arguments.bodyHash)))
            OR (len(trim(arguments.providerPaymentLinkId))
                AND !isSafeProviderReference(arguments.providerPaymentLinkId, 200))
            OR (len(trim(arguments.providerOrderId))
                AND !isSafeProviderReference(arguments.providerOrderId, 186))
            OR (len(trim(arguments.providerChargeId))
                AND !isSafeProviderReference(arguments.providerChargeId, 200))
            OR (len(trim(arguments.paymentIntentId)) AND !isUuid(arguments.paymentIntentId))) {
            return failureResult("invalid_event", "O recibo do evento e invalido.");
        }
        try {
            eventQuery = queryExecute(
                "
                    SELECT recorded.*
                      FROM ads.record_payment_event(
                          CAST(:provider_event_id AS text),
                          CAST(:event_type AS text),
                          CAST(:provider_payment_link_id AS text),
                          CAST(:provider_order_id AS text),
                          CAST(:provider_charge_id AS text),
                          CAST(:payment_intent_id AS uuid),
                          CAST(:body_hash AS text),
                          clock_timestamp()
                      ) recorded
                ",
                {
                    provider_event_id = { value = trim(arguments.providerEventId), cfsqltype = "cf_sql_varchar" },
                    event_type = { value = lCase(trim(arguments.eventType)), cfsqltype = "cf_sql_varchar" },
                    provider_payment_link_id = { value = trim(arguments.providerPaymentLinkId), null = !len(trim(arguments.providerPaymentLinkId)), cfsqltype = "cf_sql_varchar" },
                    provider_order_id = { value = trim(arguments.providerOrderId), null = !len(trim(arguments.providerOrderId)), cfsqltype = "cf_sql_varchar" },
                    provider_charge_id = { value = trim(arguments.providerChargeId), null = !len(trim(arguments.providerChargeId)), cfsqltype = "cf_sql_varchar" },
                    payment_intent_id = { value = trim(arguments.paymentIntentId), null = !len(trim(arguments.paymentIntentId)), cfsqltype = "cf_sql_varchar" },
                    body_hash = { value = lCase(trim(arguments.bodyHash)), cfsqltype = "cf_sql_varchar" }
                },
                { datasource = variables.datasource }
            );
            if (!eventQuery.recordCount) {
                return failureResult("event_record_failed", "Nao foi possivel registrar o recibo.");
            }
            return {
                success = true,
                status = lCase(queryString(eventQuery, 1, "processing_status")),
                resultStatus = queryString(eventQuery, 1, "result_status"),
                paymentEventId = queryString(eventQuery, 1, "payment_event_id"),
                paymentIntentId = queryString(eventQuery, 1, "payment_intent_id")
            };
        } catch (any ignoredEventError) {
            return failureResult("event_record_failed", "Nao foi possivel registrar o recibo.");
        }
    }

    public struct function completePaymentEvent(
        required string paymentEventId,
        required string processingStatus,
        string reason = ""
    ) output="false" {
        var completionQuery = queryNew("");
        var normalizedStatus = uCase(trim(arguments.processingStatus));

        if (!isUuid(arguments.paymentEventId)
            OR !listFind("PROCESSED,IGNORED,FAILED,REVIEW", normalizedStatus)) {
            return failureResult("invalid_event_completion", "A conclusao do recibo e invalida.");
        }
        try {
            completionQuery = queryExecute(
                "
                    SELECT completed.*
                      FROM ads.complete_payment_event(
                          CAST(:payment_event_id AS uuid),
                          CAST(:processing_status AS text),
                          CAST(:reason AS text)
                      ) completed
                ",
                {
                    payment_event_id = { value = trim(arguments.paymentEventId), cfsqltype = "cf_sql_varchar" },
                    processing_status = { value = normalizedStatus, cfsqltype = "cf_sql_varchar" },
                    reason = { value = left(trim(arguments.reason), 500), null = !len(trim(arguments.reason)), cfsqltype = "cf_sql_varchar" }
                },
                { datasource = variables.datasource }
            );
            if (!completionQuery.recordCount) {
                return failureResult("event_completion_failed", "Nao foi possivel concluir o recibo.");
            }
            return {
                success = true,
                status = lCase(queryString(completionQuery, 1, "processing_status")),
                resultStatus = queryString(completionQuery, 1, "result_status"),
                paymentEventId = queryString(completionQuery, 1, "payment_event_id"),
                paymentIntentId = queryString(completionQuery, 1, "payment_intent_id")
            };
        } catch (any ignoredCompletionError) {
            return failureResult("event_completion_failed", "Nao foi possivel concluir o recibo.");
        }
    }

    public struct function processWebhookEvent(
        required string paymentEventId,
        required string eventType,
        required string paymentIntentId
    ) output="false" {
        var normalizedType = lCase(trim(arguments.eventType));
        var intentQuery = queryNew("");
        var intent = {};
        var providerCheck = {};
        var reconciliation = {};
        var reversalType = "";
        var reversal = {};

        if (!isUuid(arguments.paymentEventId) OR !isUuid(arguments.paymentIntentId)) {
            return failureResult("invalid_event_context", "O contexto do evento e invalido.");
        }
        if (listFindNoCase(
            "order.paid,order.payment_failed,order.canceled,charge.pending",
            normalizedType
        )) {
            reconciliation = reconcileIntent(arguments.paymentIntentId, true);
            if (reconciliation.success
                AND structKeyExists(reconciliation, "resultStatus")
                AND reconciliation.resultStatus EQ "awaiting_order") {
                return {
                    success = false,
                    status = "pending",
                    resultStatus = "awaiting_order",
                    errorCode = "provider_order_pending",
                    temporary = true,
                    review = false,
                    message = "O pedido ainda nao foi localizado no provedor."
                };
            }
            if (!reconciliation.success
                AND structKeyExists(reconciliation, "errorCode")
                AND reconciliation.errorCode EQ "transition_failed") {
                return {
                    success = false,
                    status = "review",
                    resultStatus = "transition_review",
                    errorCode = reconciliation.errorCode,
                    temporary = false,
                    review = true,
                    message = "A transicao confirmada no provedor exige revisao."
                };
            }
            return reconciliation;
        }
        if (!listFindNoCase(
            "charge.refunded,chargeback.received,charge.partial_canceled",
            normalizedType
        )) {
            return {
                success = true,
                status = "ignored",
                resultStatus = "event_not_relevant"
            };
        }

        intentQuery = findIntentById(arguments.paymentIntentId);
        if (!intentQuery.recordCount) {
            return failureResult("not_found", "Pagamento nao encontrado.");
        }
        intent = mapIntent(intentQuery, 1);
        providerCheck = fetchAndValidateProviderOrder(intent);
        if (!providerCheck.success) {
            return providerCheck;
        }
        if (normalizedType EQ "charge.partial_canceled") {
            return {
                success = false,
                status = "review",
                resultStatus = "partial_canceled_review",
                review = true,
                temporary = false,
                message = "Cancelamento parcial exige revisao manual."
            };
        }

        reversalType = normalizedType EQ "charge.refunded" ? "REFUND" : "CHARGEBACK";
        if ((reversalType EQ "REFUND" AND providerCheck.order.chargeStatus NEQ "refunded")
            OR (reversalType EQ "CHARGEBACK" AND providerCheck.order.chargeStatus NEQ "chargedback")) {
            return {
                success = false,
                status = "review",
                resultStatus = "provider_status_divergence",
                review = true,
                temporary = false,
                message = "O estado reconsultado da cobranca exige revisao."
            };
        }

        reversal = reversePayment(
            intent.paymentIntentId,
            reversalType,
            "pagarme:event:" & lCase(arguments.paymentEventId) & ":" & lCase(reversalType),
            0,
            reversalType EQ "REFUND"
                ? "Estorno confirmado por reconsulta ao provedor"
                : "Chargeback confirmado por reconsulta ao provedor"
        );
        return reversal;
    }

    public struct function reconcileIntent(
        required string paymentIntentId,
        boolean forceProviderCheck = false
    ) output="false" {
        var intentQuery = queryNew("");
        var intent = {};
        var providerResult = {};
        var order = {};

        if (!isUuid(arguments.paymentIntentId)) {
            return failureResult("invalid_intent", "A referencia do pagamento e invalida.");
        }
        intentQuery = findIntentById(arguments.paymentIntentId);
        if (!intentQuery.recordCount) {
            return failureResult("not_found", "Pagamento nao encontrado.");
        }
        intent = mapIntent(intentQuery, 1);

        if (!arguments.forceProviderCheck
            AND listFindNoCase("PAID,FAILED,CANCELED,EXPIRED,REFUNDED,CHARGEBACK,REVIEW", intent.status)) {
            return reconciliationResult(intent, "already_terminal");
        }
        if (len(intent.providerOrderId)) {
            providerResult = variables.pagarMeClient.getOrder(intent.providerOrderId);
        } else {
            providerResult = variables.pagarMeClient.listOrdersByCode(intent.orderCode);
            if (providerResult.success AND arrayLen(providerResult.orders)) {
                order = providerResult.orders[1];
                providerResult = {
                    success = true,
                    status = "ok",
                    order = order
                };
            } else if (providerResult.success) {
                if (isDate(intent.expiresAt) AND dateCompare(intent.expiresAt, now()) LT 0) {
                    return transitionIntent(
                        intent.paymentIntentId,
                        "EXPIRED",
                        "Checkout expirado sem pedido correlacionado"
                    );
                }
                return reconciliationResult(intent, "awaiting_order");
            }
        }
        if (!providerResult.success) {
            return providerFailureResult(providerResult);
        }
        order = providerResult.order;

        if (order.code NEQ intent.orderCode
            OR order.amountCents NEQ intent.amountCents
            OR order.currency NEQ intent.currency
            OR (len(intent.providerOrderId) AND order.id NEQ intent.providerOrderId)) {
            return withProviderTimestamp(transitionIntent(
                intent.paymentIntentId,
                "REVIEW",
                "Divergencia entre a intencao local e o pedido do provedor",
                order.id,
                order.chargeId,
                order.paymentMethod
            ), order);
        }

        switch (order.status) {
            case "paid":
                if (!len(order.chargeId)
                    OR !listFindNoCase("pix,credit_card", order.paymentMethod)) {
                    return withProviderTimestamp(transitionIntent(
                        intent.paymentIntentId,
                        "REVIEW",
                        "Pedido pago sem cobranca ou metodo validos",
                        order.id,
                        order.chargeId,
                        order.paymentMethod
                    ), order);
                }
                return withProviderTimestamp(confirmPayment(intent, order), order);
            case "pending":
                return withProviderTimestamp(transitionIntent(
                    intent.paymentIntentId,
                    "PENDING",
                    "Pagamento pendente no provedor",
                    order.id,
                    order.chargeId,
                    order.paymentMethod
                ), order);
            case "failed":
                return withProviderTimestamp(transitionIntent(
                    intent.paymentIntentId,
                    "FAILED",
                    "Pagamento recusado pelo provedor",
                    order.id,
                    order.chargeId,
                    order.paymentMethod
                ), order);
            case "canceled":
                return withProviderTimestamp(transitionIntent(
                    intent.paymentIntentId,
                    "CANCELED",
                    "Pedido cancelado no provedor",
                    order.id,
                    order.chargeId,
                    order.paymentMethod
                ), order);
            default:
                return withProviderTimestamp(transitionIntent(
                    intent.paymentIntentId,
                    "REVIEW",
                    "Status de pedido nao reconhecido na reconciliacao",
                    order.id,
                    order.chargeId,
                    order.paymentMethod
                ), order);
        }
    }

    public struct function transitionIntent(
        required string paymentIntentId,
        required string targetStatus,
        required string reason,
        string providerOrderId = "",
        string providerChargeId = "",
        string paymentMethod = ""
    ) output="false" {
        var transitionQuery = queryNew("");

        if (!isUuid(arguments.paymentIntentId)) {
            return failureResult("invalid_intent", "A referencia do pagamento e invalida.");
        }
        try {
            transitionQuery = queryExecute(
                "
                    SELECT transitioned.*
                      FROM ads.transition_payment_intent(
                          CAST(:payment_intent_id AS uuid),
                          CAST(:target_status AS text),
                          CAST(:provider_order_id AS text),
                          CAST(:provider_charge_id AS text),
                          CAST(:payment_method AS text),
                          CAST(:reason AS text)
                      ) transitioned
                ",
                {
                    payment_intent_id = { value = arguments.paymentIntentId, cfsqltype = "cf_sql_varchar" },
                    target_status = { value = uCase(trim(arguments.targetStatus)), cfsqltype = "cf_sql_varchar" },
                    provider_order_id = { value = trim(arguments.providerOrderId), null = !len(trim(arguments.providerOrderId)), cfsqltype = "cf_sql_varchar" },
                    provider_charge_id = { value = trim(arguments.providerChargeId), null = !len(trim(arguments.providerChargeId)), cfsqltype = "cf_sql_varchar" },
                    payment_method = { value = lCase(trim(arguments.paymentMethod)), null = !len(trim(arguments.paymentMethod)), cfsqltype = "cf_sql_varchar" },
                    reason = { value = left(trim(arguments.reason), 500), cfsqltype = "cf_sql_varchar" }
                },
                { datasource = variables.datasource }
            );
            if (!transitionQuery.recordCount) {
                return failureResult("transition_failed", "Nao foi possivel atualizar o pagamento.");
            }
            return {
                success = queryString(transitionQuery, 1, "result_status") NEQ "review_required",
                status = lCase(queryString(transitionQuery, 1, "status")),
                resultStatus = queryString(transitionQuery, 1, "result_status"),
                paymentIntentId = queryString(transitionQuery, 1, "payment_intent_id")
            };
        } catch (any ignoredTransitionError) {
            return failureResult("transition_failed", "Nao foi possivel atualizar o pagamento.");
        }
    }

    public struct function reversePayment(
        required string paymentIntentId,
        required string reversalType,
        required string idempotencyKey,
        numeric createdBy = 0,
        string reason = "Reversao confirmada no provedor"
    ) output="false" {
        var reversalQuery = queryNew("");

        if (!isUuid(arguments.paymentIntentId)
            OR !listFindNoCase("REFUND,CHARGEBACK", trim(arguments.reversalType))
            OR !len(trim(arguments.idempotencyKey))) {
            return failureResult("invalid_reversal", "Os dados da reversao sao invalidos.");
        }
        try {
            reversalQuery = queryExecute(
                "
                    SELECT reversed.*
                      FROM ads.reverse_payment_credit(
                          CAST(:payment_intent_id AS uuid),
                          CAST(:reversal_type AS text),
                          CAST(:idempotency_key AS text),
                          CAST(:created_by AS integer),
                          CAST(:reason AS text)
                      ) reversed
                ",
                {
                    payment_intent_id = { value = arguments.paymentIntentId, cfsqltype = "cf_sql_varchar" },
                    reversal_type = { value = uCase(trim(arguments.reversalType)), cfsqltype = "cf_sql_varchar" },
                    idempotency_key = { value = left(trim(arguments.idempotencyKey), 183), cfsqltype = "cf_sql_varchar" },
                    created_by = { value = val(arguments.createdBy), null = val(arguments.createdBy) LTE 0, cfsqltype = "cf_sql_integer" },
                    reason = { value = left(trim(arguments.reason), 500), cfsqltype = "cf_sql_varchar" }
                },
                { datasource = variables.datasource }
            );
            if (!reversalQuery.recordCount) {
                return failureResult("reversal_failed", "Nao foi possivel registrar a reversao.");
            }
            return {
                success = true,
                status = lCase(queryString(reversalQuery, 1, "status")),
                resultStatus = queryString(reversalQuery, 1, "result_status"),
                paymentIntentId = queryString(reversalQuery, 1, "payment_intent_id"),
                recoveredAmountCents = queryNumber(reversalQuery, 1, "recovered_amount_cents"),
                pendingAmountCents = queryNumber(reversalQuery, 1, "pending_amount_cents"),
                holdOpened = len(queryString(reversalQuery, 1, "financial_hold_id")) GT 0
            };
        } catch (any ignoredReversalError) {
            return failureResult("reversal_failed", "Nao foi possivel registrar a reversao.");
        }
    }

    private struct function fetchAndValidateProviderOrder(required struct intent) output="false" {
        var providerResult = {};
        var order = {};
        var failure = {};

        if (len(arguments.intent.providerOrderId)) {
            providerResult = variables.pagarMeClient.getOrder(arguments.intent.providerOrderId);
        } else {
            providerResult = variables.pagarMeClient.listOrdersByCode(arguments.intent.orderCode);
            if (providerResult.success AND arrayLen(providerResult.orders)) {
                providerResult = {
                    success = true,
                    status = "ok",
                    order = providerResult.orders[1]
                };
            } else if (providerResult.success) {
                return {
                    success = false,
                    status = "pending",
                    errorCode = "provider_order_pending",
                    message = "O pedido ainda nao foi localizado no provedor.",
                    temporary = true,
                    review = false
                };
            }
        }

        if (!providerResult.success) {
            failure = providerFailureResult(providerResult);
            failure.temporary = structKeyExists(providerResult, "errorCode")
                AND providerResult.errorCode EQ "provider_unavailable";
            failure.review = false;
            return failure;
        }
        order = providerResult.order;
        if (order.code NEQ arguments.intent.orderCode
            OR order.amountCents NEQ arguments.intent.amountCents
            OR order.currency NEQ arguments.intent.currency
            OR (len(arguments.intent.providerOrderId)
                AND order.id NEQ arguments.intent.providerOrderId)
            OR (len(arguments.intent.providerChargeId)
                AND order.chargeId NEQ arguments.intent.providerChargeId)) {
            return {
                success = false,
                status = "review",
                errorCode = "provider_identity_divergence",
                message = "A identidade reconsultada do pedido exige revisao.",
                temporary = false,
                review = true
            };
        }
        return {
            success = true,
            status = "verified",
            temporary = false,
            review = false,
            order = order
        };
    }

    private struct function confirmPayment(required struct intent, required struct order) output="false" {
        var confirmationQuery = queryNew("");

        try {
            confirmationQuery = queryExecute(
                "
                    SELECT confirmed.*
                      FROM ads.confirm_payment_credit(
                          CAST(:payment_intent_id AS uuid),
                          CAST(:order_code AS text),
                          CAST(:provider_order_id AS text),
                          CAST(:provider_charge_id AS text),
                          CAST(:amount_cents AS bigint),
                          CAST(:currency AS character(3)),
                          CAST(:payment_method AS text)
                      ) confirmed
                ",
                {
                    payment_intent_id = { value = arguments.intent.paymentIntentId, cfsqltype = "cf_sql_varchar" },
                    order_code = { value = arguments.order.code, cfsqltype = "cf_sql_varchar" },
                    provider_order_id = { value = arguments.order.id, cfsqltype = "cf_sql_varchar" },
                    provider_charge_id = { value = arguments.order.chargeId, cfsqltype = "cf_sql_varchar" },
                    amount_cents = { value = arguments.order.amountCents, cfsqltype = "cf_sql_bigint" },
                    currency = { value = arguments.order.currency, cfsqltype = "cf_sql_char" },
                    payment_method = { value = arguments.order.paymentMethod, cfsqltype = "cf_sql_varchar" }
                },
                { datasource = variables.datasource }
            );
            if (!confirmationQuery.recordCount) {
                return failureResult("credit_confirmation_failed", "O pagamento ainda nao pode ser confirmado.");
            }
            return {
                success = queryString(confirmationQuery, 1, "result_status") NEQ "review_required",
                status = lCase(queryString(confirmationQuery, 1, "status")),
                resultStatus = queryString(confirmationQuery, 1, "result_status"),
                paymentIntentId = queryString(confirmationQuery, 1, "payment_intent_id"),
                credited = len(queryString(confirmationQuery, 1, "ledger_entry_id")) GT 0,
                balanceAfter = queryNumber(confirmationQuery, 1, "balance_after")
            };
        } catch (any ignoredConfirmationError) {
            return failureResult("credit_confirmation_failed", "O pagamento ainda nao pode ser confirmado.");
        }
    }

    private query function findIntentByIdempotency(
        required numeric accountId,
        required string idempotencyKey
    ) output="false" {
        return queryExecute(
            intentSelectSql() & "
                WHERE intent.account_id = :account_id
                  AND intent.idempotency_key = :idempotency_key
                LIMIT 1
            ",
            {
                account_id = { value = arguments.accountId, cfsqltype = "cf_sql_bigint" },
                idempotency_key = { value = arguments.idempotencyKey, cfsqltype = "cf_sql_varchar" }
            },
            { datasource = variables.datasource }
        );
    }

    private query function findIntentById(required string paymentIntentId, numeric accountId = 0) output="false" {
        var sql = intentSelectSql() & "
            WHERE intent.payment_intent_id = CAST(:payment_intent_id AS uuid)
        ";
        var params = {
            payment_intent_id = { value = arguments.paymentIntentId, cfsqltype = "cf_sql_varchar" }
        };

        if (val(arguments.accountId) GT 0) {
            sql &= " AND intent.account_id = :account_id";
            params.account_id = { value = val(arguments.accountId), cfsqltype = "cf_sql_bigint" };
        }
        sql &= " LIMIT 1";
        return queryExecute(sql, params, { datasource = variables.datasource });
    }

    private string function intentSelectSql() output="false" {
        return "
            SELECT intent.payment_intent_id,
                   intent.account_id,
                   intent.created_by,
                   intent.amount_cents,
                   intent.currency,
                   intent.status,
                   intent.version,
                   intent.idempotency_key,
                   intent.order_code,
                   intent.provider_payment_link_id,
                   intent.provider_order_id,
                   intent.provider_charge_id,
                   intent.checkout_url,
                   intent.payment_method,
                   intent.expires_at,
                   intent.paid_at,
                   intent.created_at,
                   intent.updated_at,
                   intent.ledger_entry_id,
                   intent.failure_reason,
                   intent.review_reason
              FROM ads.payment_intents intent
        ";
    }

    private struct function mapIntentResult(
        required query resultQuery,
        required numeric accountId,
        required numeric createdBy,
        required string idempotencyKey
    ) output="false" {
        var intentQuery = queryNew("");
        if (!arguments.resultQuery.recordCount) {
            return {};
        }
        intentQuery = findIntentById(
            queryString(arguments.resultQuery, 1, "payment_intent_id"),
            arguments.accountId
        );
        return intentQuery.recordCount ? mapIntent(intentQuery, 1) : {};
    }

    private struct function mapIntent(required query source, required numeric rowIndex) output="false" {
        return {
            paymentIntentId = queryString(arguments.source, arguments.rowIndex, "payment_intent_id"),
            accountId = queryNumber(arguments.source, arguments.rowIndex, "account_id"),
            createdBy = queryNumber(arguments.source, arguments.rowIndex, "created_by"),
            amountCents = queryNumber(arguments.source, arguments.rowIndex, "amount_cents"),
            currency = uCase(queryString(arguments.source, arguments.rowIndex, "currency")),
            status = uCase(queryString(arguments.source, arguments.rowIndex, "status")),
            version = queryNumber(arguments.source, arguments.rowIndex, "version"),
            idempotencyKey = queryString(arguments.source, arguments.rowIndex, "idempotency_key"),
            orderCode = queryString(arguments.source, arguments.rowIndex, "order_code"),
            providerPaymentLinkId = queryString(arguments.source, arguments.rowIndex, "provider_payment_link_id"),
            providerOrderId = queryString(arguments.source, arguments.rowIndex, "provider_order_id"),
            providerChargeId = queryString(arguments.source, arguments.rowIndex, "provider_charge_id"),
            checkoutUrl = queryString(arguments.source, arguments.rowIndex, "checkout_url"),
            paymentMethod = lCase(queryString(arguments.source, arguments.rowIndex, "payment_method")),
            expiresAt = queryValue(arguments.source, arguments.rowIndex, "expires_at", ""),
            paidAt = queryValue(arguments.source, arguments.rowIndex, "paid_at", ""),
            createdAt = queryValue(arguments.source, arguments.rowIndex, "created_at", ""),
            updatedAt = queryValue(arguments.source, arguments.rowIndex, "updated_at", ""),
            ledgerEntryId = queryString(arguments.source, arguments.rowIndex, "ledger_entry_id"),
            failureReason = queryString(arguments.source, arguments.rowIndex, "failure_reason"),
            reviewReason = queryString(arguments.source, arguments.rowIndex, "review_reason")
        };
    }

    private struct function checkoutResult(required struct intent, required string resultStatus) output="false" {
        if (!variables.pagarMeClient.isCheckoutUrlAllowed(arguments.intent.checkoutUrl)) {
            return failureResult("invalid_checkout_url", "O checkout salvo e invalido.");
        }
        return {
            success = true,
            status = "checkout_ready",
            resultStatus = arguments.resultStatus,
            paymentIntentId = arguments.intent.paymentIntentId,
            reference = shortReference(arguments.intent.orderCode),
            amountCents = arguments.intent.amountCents,
            currency = arguments.intent.currency,
            expiresAt = arguments.intent.expiresAt,
            checkoutUrl = arguments.intent.checkoutUrl
        };
    }

    private struct function reconciliationResult(required struct intent, required string resultStatus) output="false" {
        return {
            success = true,
            status = lCase(arguments.intent.status),
            resultStatus = arguments.resultStatus,
            paymentIntentId = arguments.intent.paymentIntentId,
            credited = len(arguments.intent.ledgerEntryId) GT 0
        };
    }

    private struct function withProviderTimestamp(
        required struct result,
        required struct order
    ) output="false" {
        var enriched = duplicate(arguments.result);
        enriched.providerUpdatedAt = structKeyExists(arguments.order, "providerUpdatedAt")
            ? left(trim(arguments.order.providerUpdatedAt & ""), 80)
            : "";
        return enriched;
    }

    private struct function providerFailureResult(required struct providerResult) output="false" {
        return failureResult(
            structKeyExists(arguments.providerResult, "errorCode")
                ? arguments.providerResult.errorCode
                : "provider_unavailable",
            structKeyExists(arguments.providerResult, "message")
                ? arguments.providerResult.message
                : "O provedor de pagamento esta indisponivel.",
            structKeyExists(arguments.providerResult, "statusCode")
                ? val(arguments.providerResult.statusCode)
                : 0
        );
    }

    private struct function failureResult(
        required string errorCode,
        required string message,
        numeric statusCode = 0
    ) output="false" {
        return {
            success = false,
            status = "error",
            statusCode = arguments.statusCode,
            errorCode = left(lCase(trim(arguments.errorCode)), 80),
            message = left(trim(arguments.message), 240)
        };
    }

    private boolean function isUuid(required string value) output="false" {
        return reFindNoCase(
            "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
            trim(arguments.value)
        ) EQ 1;
    }

    private boolean function isSafeProviderReference(
        required string value,
        numeric maxLength = 200
    ) output="false" {
        var normalized = trim(arguments.value);
        return len(normalized) GTE 1
            AND len(normalized) LTE arguments.maxLength
            AND reFind("^[A-Za-z0-9_-]+$", normalized) EQ 1;
    }

    private string function shortReference(required string orderCode) output="false" {
        var normalized = replace(trim(arguments.orderCode), "RHADS-", "", "one");
        return "ADS-" & uCase(right(normalized, 8));
    }

    private any function queryValue(
        required query source,
        required numeric rowIndex,
        required string columnName,
        any fallback = ""
    ) output="false" {
        if (!listFindNoCase(arguments.source.columnList, arguments.columnName)) {
            return arguments.fallback;
        }
        try {
            if (isNull(arguments.source[arguments.columnName][arguments.rowIndex])) {
                return arguments.fallback;
            }
            return arguments.source[arguments.columnName][arguments.rowIndex];
        } catch (any ignoredQueryValueError) {
            return arguments.fallback;
        }
    }

    private string function queryString(
        required query source,
        required numeric rowIndex,
        required string columnName
    ) output="false" {
        return trim(queryValue(arguments.source, arguments.rowIndex, arguments.columnName, "") & "");
    }

    private numeric function queryNumber(
        required query source,
        required numeric rowIndex,
        required string columnName
    ) output="false" {
        var value = queryValue(arguments.source, arguments.rowIndex, arguments.columnName, 0);
        return isNumeric(value) ? val(value) : 0;
    }
}
