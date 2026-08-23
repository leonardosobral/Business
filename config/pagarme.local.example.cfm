<cfscript>
    pagarMeLocalConfig = {
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
        webhookRegistered = false
    };
</cfscript>
