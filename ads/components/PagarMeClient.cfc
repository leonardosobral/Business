component output="false" hint="Cliente minimo e sanitizado para o checkout hospedado Pagar.me." {

    variables.config = {};

    public any function init() output="false" {
        variables.config = loadConfig();
        return this;
    }

    public struct function getStatus() output="false" {
        return {
            configured = variables.config.configured,
            enabled = variables.config.enabled,
            ready = variables.config.ready,
            mode = variables.config.mode,
            errorCode = variables.config.errorCode,
            endpointAllowed = variables.config.endpointAllowed,
            webhookRegistered = variables.config.webhookRegistered,
            checkoutEnabled = variables.config.ready AND variables.config.enabled
        };
    }

    public numeric function getMinimumAmountCents() output="false" {
        return variables.config.minimumAmountCents;
    }

    public numeric function getPaymentLinkExpiresMinutes() output="false" {
        return variables.config.paymentLinkExpiresMinutes;
    }

    public numeric function getReconcileBatchSize() output="false" {
        return min(30, max(1, int(variables.config.reconcileBatchSize)));
    }

    public string function validateCheckoutUrl(required string checkoutUrl) output="false" {
        var uri = createObject("java", "java.net.URI").init(trim(arguments.checkoutUrl));
        var path = isNull(uri.getPath()) ? "" : (uri.getPath() & "");

        if (isNull(uri.getScheme())
            OR compareNoCase(uri.getScheme() & "", "https") NEQ 0
            OR isNull(uri.getHost())
            OR !isCheckoutHostAllowed(lCase(uri.getHost() & ""))
            OR uri.getPort() NEQ -1
            OR NOT isNull(uri.getUserInfo())
            OR NOT isNull(uri.getFragment())
            OR left(path, 1) NEQ "/"
            OR len(path) LTE 1) {
            throw(
                type = "PagarMeClient.InvalidCheckoutUrl",
                message = "URL de checkout invalida."
            );
        }
        return uri.normalize().toString();
    }

    public boolean function isCheckoutUrlAllowed(required string checkoutUrl) output="false" {
        try {
            validateCheckoutUrl(arguments.checkoutUrl);
            return true;
        } catch (any ignoredUrlError) {
            return false;
        }
    }

    public struct function createPaymentLink(
        required string orderCode,
        required numeric amountCents,
        string itemName = "Credito de publicidade RunnerHub"
    ) output="false" {
        var normalizedCode = trim(arguments.orderCode);
        var normalizedAmount = round(val(arguments.amountCents));
        var normalizedName = left(trim(arguments.itemName), 64);
        var installment_count = 1;
        var payload = {};
        var response = {};

        if (!variables.config.ready OR !variables.config.enabled) {
            return unavailableResult();
        }
        if (!reFind("^RHADS-[0-9a-f]{32}$", normalizedCode)) {
            return failureResult("invalid_order_code", "A referencia do pagamento e invalida.");
        }
        if (normalizedAmount LT variables.config.minimumAmountCents
            OR normalizedAmount GT 2147483647) {
            return failureResult("invalid_amount", "O valor do pagamento e invalido.");
        }
        if (!len(normalizedName)) {
            normalizedName = "Credito de publicidade RunnerHub";
        }

        payload = {
            "is_building" = false,
            "name" = left("RunnerHub Ads " & right(normalizedCode, 12), 64),
            "order_code" = normalizedCode,
            "type" = "order",
            "expires_in" = variables.config.paymentLinkExpiresMinutes,
            "max_sessions" = 1,
            "max_paid_sessions" = 1,
            "payment_settings" = {
                "accepted_payment_methods" = ["credit_card", "pix"],
                "statement_descriptor" = "RUNNERHUBADS",
                "credit_card_settings" = {
                    "operation_type" = "auth_and_capture",
                    "installments" = [
                        {
                            "number" = installment_count,
                            "total" = normalizedAmount
                        }
                    ]
                },
                "pix_settings" = {
                    "expires_in" = variables.config.paymentLinkExpiresMinutes * 60
                }
            },
            "cart_settings" = {
                "items" = [
                    {
                        "amount" = normalizedAmount,
                        "name" = normalizedName,
                        "default_quantity" = 1
                    }
                ]
            }
        };

        response = sendRequest("POST", "/paymentlinks", {}, payload);
        if (!response.success) {
            return response;
        }
        return normalizePaymentLink(response.data, normalizedCode, response.statusCode);
    }

    public struct function getOrder(required string orderId) output="false" {
        var normalizedId = trim(arguments.orderId);
        var response = {};

        if (!variables.config.ready) {
            return unavailableResult();
        }
        if (!isSafeProviderId(normalizedId)) {
            return failureResult("invalid_order_id", "A referencia do pedido e invalida.");
        }

        response = sendRequest("GET", "/orders/" & normalizedId);
        if (!response.success) {
            return response;
        }
        return normalizeOrder(response.data, response.statusCode);
    }

    public struct function listOrdersByCode(required string orderCode) output="false" {
        var normalizedCode = trim(arguments.orderCode);
        var response = {};
        var normalized = {};
        var item = {};
        var orders = [];

        if (!variables.config.ready) {
            return unavailableResult();
        }
        if (!reFind("^RHADS-[0-9a-f]{32}$", normalizedCode)) {
            return failureResult("invalid_order_code", "A referencia do pagamento e invalida.");
        }

        response = sendRequest("GET", "/orders", {
            "code" = normalizedCode,
            "page" = 1,
            "size" = 10
        });
        if (!response.success) {
            return response;
        }
        if (!isStruct(response.data)
            OR !structKeyExists(response.data, "data")
            OR !isArray(response.data.data)) {
            return failureResult("invalid_response", "O provedor retornou uma resposta invalida.", response.statusCode);
        }

        for (item in response.data.data) {
            normalized = normalizeOrder(item, response.statusCode);
            if (normalized.success AND normalized.order.code EQ normalizedCode) {
                arrayAppend(orders, normalized.order);
            }
        }

        return {
            success = true,
            status = "ok",
            statusCode = response.statusCode,
            orders = orders
        };
    }

    private struct function loadConfig() output="false" {
        var pagarMeLocalConfig = {};
        var raw = {};
        var config = {
            enabled = false,
            mode = "test",
            secretKey = "",
            baseUrl = "https://sdx-api.pagar.me/core/v5",
            checkoutHost = "payment-link.pagar.me",
            connectTimeoutSeconds = 5,
            requestTimeoutSeconds = 15,
            paymentLinkExpiresMinutes = 60,
            reconcileBatchSize = 25,
            minimumAmountCents = 5000,
            webhookRegistered = false,
            endpointAllowed = false,
            configured = false,
            ready = false,
            errorCode = "not_configured"
        };

        if (fileExists(expandPath("/config/pagarme.local.cfm"))) {
            include "/config/pagarme.local.cfm";
            config.configured = true;
        }
        if (isStruct(pagarMeLocalConfig)) {
            raw = pagarMeLocalConfig;
        }

        if (structKeyExists(raw, "enabled")) {
            config.enabled = booleanValue(raw.enabled);
        }
        if (structKeyExists(raw, "mode")) {
            config.mode = lCase(trim(raw.mode & ""));
        }
        if (structKeyExists(raw, "secretKey")) {
            config.secretKey = trim(raw.secretKey & "");
        }
        if (structKeyExists(raw, "baseUrl")) {
            config.baseUrl = removeTrailingSlash(trim(raw.baseUrl & ""));
        }
        if (structKeyExists(raw, "checkoutHost")) {
            config.checkoutHost = lCase(trim(raw.checkoutHost & ""));
        }
        if (structKeyExists(raw, "connectTimeoutSeconds") AND isNumeric(raw.connectTimeoutSeconds)) {
            config.connectTimeoutSeconds = min(30, max(1, int(raw.connectTimeoutSeconds)));
        }
        if (structKeyExists(raw, "requestTimeoutSeconds") AND isNumeric(raw.requestTimeoutSeconds)) {
            config.requestTimeoutSeconds = min(60, max(2, int(raw.requestTimeoutSeconds)));
        }
        if (structKeyExists(raw, "paymentLinkExpiresMinutes") AND isNumeric(raw.paymentLinkExpiresMinutes)) {
            config.paymentLinkExpiresMinutes = min(1440, max(5, int(raw.paymentLinkExpiresMinutes)));
        }
        if (structKeyExists(raw, "reconcileBatchSize") AND isNumeric(raw.reconcileBatchSize)) {
            config.reconcileBatchSize = min(30, max(1, int(raw.reconcileBatchSize)));
        }
        if (structKeyExists(raw, "minimumAmountCents") AND isNumeric(raw.minimumAmountCents)) {
            config.minimumAmountCents = max(5000, round(val(raw.minimumAmountCents)));
        }
        if (structKeyExists(raw, "webhookRegistered")) {
            config.webhookRegistered = booleanValue(raw.webhookRegistered);
        }

        if (!config.configured) {
            return config;
        }
        if (!listFindNoCase("test,production", config.mode)) {
            config.errorCode = "invalid_mode";
            return config;
        }
        if (!isApiBaseUrlAllowed(config.baseUrl, config.mode)) {
            config.errorCode = "invalid_api_url";
            return config;
        }
        if (!listFindNoCase(
            "payment-link.pagar.me,payment-link-v3-sdx.pagar.me",
            config.checkoutHost
        )) {
            config.errorCode = "invalid_checkout_host";
            return config;
        }
        config.checkoutHost = config.mode EQ "production"
            ? "payment-link.pagar.me"
            : "payment-link-v3-sdx.pagar.me";
        config.endpointAllowed = true;
        if (len(config.secretKey)
            AND (!reFind("^sk_[A-Za-z0-9_-]+$", config.secretKey)
                OR len(config.secretKey) GT 255)) {
            config.errorCode = "invalid_secret";
            return config;
        }
        if (config.enabled AND !len(config.secretKey)) {
            config.errorCode = "invalid_secret";
            return config;
        }

        config.errorCode = config.enabled ? "" : "disabled";
        config.ready = len(config.secretKey) GT 0;
        return config;
    }

    private boolean function isApiBaseUrlAllowed(required string baseUrl, required string mode) output="false" {
        var uri = "";
        var expectedHost = arguments.mode EQ "production"
            ? "api.pagar.me"
            : "sdx-api.pagar.me";

        try {
            uri = createObject("java", "java.net.URI").init(arguments.baseUrl);
            return !isNull(uri.getScheme())
                AND compareNoCase(uri.getScheme() & "", "https") EQ 0
                AND !isNull(uri.getHost())
                AND lCase(uri.getHost() & "") EQ expectedHost
                AND uri.getPort() EQ -1
                AND isNull(uri.getUserInfo())
                AND isNull(uri.getQuery())
                AND isNull(uri.getFragment())
                AND (uri.getPath() & "") EQ "/core/v5";
        } catch (any ignoredApiUrlError) {
            return false;
        }
    }

    private string function serializeProviderJson(required any value) output="false" {
        var keys = [];
        var parts = [];
        var key = "";
        var position = 0;
        var scalarJson = "";

        if (isStruct(arguments.value)) {
            keys = structKeyArray(arguments.value);
            arraySort(keys, "textnocase");
            for (key in keys) {
                arrayAppend(
                    parts,
                    serializeJSON(lCase(key)) & ":" & serializeProviderJson(arguments.value[key])
                );
            }
            return "{" & arrayToList(parts, ",") & "}";
        }
        if (isArray(arguments.value)) {
            for (position = 1; position LTE arrayLen(arguments.value); position++) {
                arrayAppend(parts, serializeProviderJson(arguments.value[position]));
            }
            return "[" & arrayToList(parts, ",") & "]";
        }
        scalarJson = serializeJSON(arguments.value);
        if (reFind("^-?[0-9]+[.]0+$", scalarJson)) {
            return reReplace(scalarJson, "[.]0+$", "");
        }
        return scalarJson;
    }

    private struct function sendRequest(
        required string method,
        required string path,
        struct query = {},
        struct body = {}
    ) output="false" {
        var endpoint = buildEndpoint(arguments.path, arguments.query);
        var httpResult = {};
        var responseBody = "";
        var responseData = {};
        var statusCode = 0;
        var serializedBody = "";

        if (!variables.config.ready) {
            return unavailableResult();
        }

        try {
            if (uCase(arguments.method) EQ "POST") {
                serializedBody = serializeProviderJson(arguments.body);
            }

            cfhttp(
                url = endpoint,
                result = "httpResult",
                method = uCase(arguments.method),
                timeout = variables.config.requestTimeoutSeconds
            ) {
                if (uCase(arguments.method) EQ "POST") {
                    cfhttpparam(type = "Header", name = "Content-Type", value = "application/json");
                }
                cfhttpparam(
                    type = "Header",
                    name = "User-Agent",
                    value = "RunnerHub-Business-Ads/1.0"
                );
                cfhttpparam(
                    type = "Header",
                    name = "Authorization",
                    value = "Basic " & toBase64(variables.config.secretKey & ":")
                );
                if (uCase(arguments.method) EQ "POST") {
                    cfhttpparam(type = "body", value = serializedBody);
                }
            }

            statusCode = structKeyExists(httpResult, "statusCode")
                ? val(httpResult.statusCode & "")
                : 0;
            if (structKeyExists(httpResult, "fileContent") AND !isNull(httpResult.fileContent)) {
                responseBody = isBinary(httpResult.fileContent)
                    ? charsetEncode(httpResult.fileContent, "utf-8")
                    : (httpResult.fileContent & "");
            }

            if (statusCode LT 200 OR statusCode GTE 300) {
                logProviderRejection(statusCode, responseBody);
                return failureResult(
                    statusCode GTE 500 ? "provider_unavailable" : "provider_rejected",
                    statusCode GTE 500
                        ? "O provedor de pagamento esta indisponivel. Tente novamente."
                        : "O provedor recusou a solicitacao de pagamento.",
                    statusCode
                );
            }
            if (!len(trim(responseBody))) {
                return failureResult("invalid_response", "O provedor retornou uma resposta vazia.", statusCode);
            }

            try {
                responseData = deserializeJSON(responseBody);
            } catch (any ignoredJsonError) {
                return failureResult("invalid_response", "O provedor retornou uma resposta invalida.", statusCode);
            }
            if (!isStruct(responseData)) {
                return failureResult("invalid_response", "O provedor retornou uma resposta invalida.", statusCode);
            }

            return {
                success = true,
                status = "ok",
                statusCode = statusCode,
                data = responseData
            };
        } catch (any providerNetworkError) {
            logProviderNetworkError(providerNetworkError);
            return failureResult(
                "provider_unavailable",
                "Nao foi possivel conectar ao provedor de pagamento. Tente novamente."
            );
        }
    }

    private string function summarizeProviderError(required string responseBody) output="false" {
        var decoded = {};
        var parts = [];
        var errors = {};
        var errorKeys = [];
        var errorKey = "";
        var errorValue = "";
        var position = 0;
        var item = {};

        if (!len(trim(arguments.responseBody))) {
            return "empty_response";
        }
        try {
            decoded = deserializeJSON(left(arguments.responseBody, 50000));
        } catch (any ignoredProviderErrorJson) {
            return "invalid_json_response";
        }
        if (!isStruct(decoded)) {
            return "non_object_response";
        }
        if (structKeyExists(decoded, "message") AND isSimpleValue(decoded.message)) {
            arrayAppend(parts, decoded.message & "");
        }
        if (structKeyExists(decoded, "errors")) {
            errors = decoded.errors;
            if (isStruct(errors)) {
                errorKeys = structKeyArray(errors);
                arraySort(errorKeys, "textnocase");
                for (errorKey in errorKeys) {
                    errorValue = errors[errorKey];
                    if (isArray(errorValue)
                        AND arrayLen(errorValue)
                        AND isSimpleValue(errorValue[1])) {
                        arrayAppend(parts, errorKey & ": " & (errorValue[1] & ""));
                    } else if (isSimpleValue(errorValue)) {
                        arrayAppend(parts, errorKey & ": " & (errorValue & ""));
                    } else if (isStruct(errorValue)
                        AND structKeyExists(errorValue, "message")
                        AND isSimpleValue(errorValue.message)) {
                        arrayAppend(parts, errorKey & ": " & (errorValue.message & ""));
                    }
                }
            } else if (isArray(errors)) {
                for (position = 1; position LTE min(5, arrayLen(errors)); position++) {
                    item = errors[position];
                    if (isSimpleValue(item)) {
                        arrayAppend(parts, item & "");
                    } else if (isStruct(item)
                        AND structKeyExists(item, "message")
                        AND isSimpleValue(item.message)) {
                        arrayAppend(parts, item.message & "");
                    }
                }
            }
        }
        return arrayLen(parts)
            ? sanitizeProviderLogValue(arrayToList(parts, " | "), 900)
            : "provider_error_without_message";
    }

    private void function logProviderRejection(
        required numeric statusCode,
        required string responseBody
    ) output="false" {
        var summary = summarizeProviderError(arguments.responseBody);

        writeLog(
            file = "business_ads_payments",
            type = "warning",
            text = "stage=provider_rejected status=#int(arguments.statusCode)# summary=#summary#"
        );
    }

    private void function logProviderNetworkError(required any providerNetworkError) output="false" {
        var exceptionType = structKeyExists(arguments.providerNetworkError, "type")
            ? sanitizeProviderLogValue(arguments.providerNetworkError.type, 120)
            : "unknown";
        var exceptionMessage = structKeyExists(arguments.providerNetworkError, "message")
            ? sanitizeProviderLogValue(arguments.providerNetworkError.message, 500)
            : "Sem mensagem de excecao.";

        writeLog(
            file = "business_ads_payments",
            type = "error",
            text = "stage=provider_http type=#exceptionType# message=#exceptionMessage#"
        );
    }

    private string function sanitizeProviderLogValue(required any value, numeric maxLength = 500) output="false" {
        var sanitized = arguments.value & "";
        var safeMaximum = min(1000, max(1, int(arguments.maxLength)));

        if (len(variables.config.secretKey)) {
            sanitized = replace(sanitized, variables.config.secretKey, "[redacted]", "all");
        }
        sanitized = reReplace(sanitized, "[\\r\\n\\t]+", " ", "all");
        return left(trim(sanitized), safeMaximum);
    }

    private string function buildEndpoint(required string path, struct query = {}) output="false" {
        var endpoint = "";
        var pairs = [];
        var key = "";

        if (!reFind("^/[A-Za-z0-9_/?=&.-]+$", arguments.path)
            OR find("://", arguments.path)) {
            throw(type="PagarMeClient.InvalidPath", message="Caminho do provedor invalido.");
        }
        endpoint = variables.config.baseUrl & arguments.path;
        for (key in arguments.query) {
            arrayAppend(
                pairs,
                urlEncodedFormat(lCase(key)) & "=" & urlEncodedFormat(arguments.query[key] & "")
            );
        }
        if (arrayLen(pairs)) {
            endpoint &= "?" & arrayToList(pairs, "&");
        }
        return endpoint;
    }

    private struct function normalizePaymentLink(
        required any providerData,
        required string orderCode,
        numeric statusCode = 200
    ) output="false" {
        var id = "";
        var url = "";
        var status = "";

        if (!isStruct(arguments.providerData)) {
            return failureResult("invalid_response", "O checkout retornado e invalido.", arguments.statusCode);
        }
        id = structText(arguments.providerData, "id", 200);
        url = structText(arguments.providerData, "url", 2000);
        status = lCase(structText(arguments.providerData, "status", 40));
        if (!isSafeProviderId(id) OR !isCheckoutUrlAllowed(url)) {
            return failureResult("invalid_response", "O checkout retornado e invalido.", arguments.statusCode);
        }

        return {
            success = true,
            status = "checkout_ready",
            statusCode = arguments.statusCode,
            paymentLink = {
                id = id,
                url = url,
                status = status,
                orderCode = arguments.orderCode
            }
        };
    }

    private struct function normalizeOrder(required any providerData, numeric statusCode = 200) output="false" {
        var order = {};
        var charges = [];
        var charge = {};
        var candidateCharge = {};
        var amountCents = 0;
        var currency = "";

        if (!isStruct(arguments.providerData)) {
            return failureResult("invalid_response", "O pedido retornado e invalido.", arguments.statusCode);
        }
        if (structKeyExists(arguments.providerData, "charges")
            AND isArray(arguments.providerData.charges)) {
            charges = arguments.providerData.charges;
        }
        for (candidateCharge in charges) {
            if (!isStruct(candidateCharge)) {
                continue;
            }
            if (!structCount(charge)) {
                charge = candidateCharge;
            }
            if (listFindNoCase(
                "paid,refunded,chargedback",
                structText(candidateCharge, "status", 40)
            )) {
                charge = candidateCharge;
                break;
            }
        }

        amountCents = structNumber(arguments.providerData, "amount", 0);
        if (amountCents LTE 0) {
            amountCents = structNumber(charge, "amount", 0);
        }
        currency = uCase(structText(arguments.providerData, "currency", 3));
        if (!len(currency)) {
            currency = uCase(structText(charge, "currency", 3));
        }

        order = {
            id = structText(arguments.providerData, "id", 200),
            code = structText(arguments.providerData, "code", 100),
            status = lCase(structText(arguments.providerData, "status", 40)),
            amountCents = amountCents,
            currency = currency,
            chargeId = structText(charge, "id", 200),
            chargeStatus = lCase(structText(charge, "status", 40)),
            paymentMethod = lCase(structText(charge, "payment_method", 40)),
            paidAt = structText(charge, "paid_at", 80),
            providerUpdatedAt = len(structText(arguments.providerData, "updated_at", 80))
                ? structText(arguments.providerData, "updated_at", 80)
                : structText(charge, "updated_at", 80)
        };

        if (!isSafeProviderId(order.id)
            OR !len(order.code)
            OR !len(order.status)
            OR order.amountCents LTE 0
            OR !len(order.currency)) {
            return failureResult("invalid_response", "O pedido retornado e invalido.", arguments.statusCode);
        }

        return {
            success = true,
            status = "ok",
            statusCode = arguments.statusCode,
            order = order
        };
    }

    private boolean function isSafeProviderId(required string value) output="false" {
        return reFind("^[A-Za-z0-9_-]{1,200}$", trim(arguments.value)) EQ 1;
    }

    private boolean function isCheckoutHostAllowed(required string host) output="false" {
        var allowedHosts = variables.config.mode EQ "production"
            ? "payment-link.pagar.me,checkout.pagar.me,payment-link-v3.pagar.me"
            : "payment-link-v3-sdx.pagar.me";

        return listFindNoCase(allowedHosts, trim(arguments.host)) GT 0;
    }

    private string function structText(required any source, required string key, numeric maxLength = 500) output="false" {
        if (!isStruct(arguments.source) OR !structKeyExists(arguments.source, arguments.key)) {
            return "";
        }
        return left(trim(arguments.source[arguments.key] & ""), arguments.maxLength);
    }

    private numeric function structNumber(required any source, required string key, numeric fallback = 0) output="false" {
        if (!isStruct(arguments.source)
            OR !structKeyExists(arguments.source, arguments.key)
            OR !isNumeric(arguments.source[arguments.key])) {
            return arguments.fallback;
        }
        return round(val(arguments.source[arguments.key]));
    }

    private boolean function booleanValue(required any value) output="false" {
        if (isBoolean(arguments.value)) {
            return arguments.value;
        }
        return listFindNoCase("1,true,t,yes,on,sim", trim(arguments.value & "")) GT 0;
    }

    private string function removeTrailingSlash(required string value) output="false" {
        var normalized = trim(arguments.value);
        while (len(normalized) GT 8 AND right(normalized, 1) EQ "/") {
            normalized = left(normalized, len(normalized) - 1);
        }
        return normalized;
    }

    private struct function unavailableResult() output="false" {
        return failureResult(
            variables.config.configured ? variables.config.errorCode : "not_configured",
            variables.config.enabled
                ? "A integracao de pagamento nao esta configurada corretamente."
                : "Novas compras de credito estao temporariamente desabilitadas."
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
}
