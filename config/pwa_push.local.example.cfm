<cfscript>
// Legado: o envio atual de Push deve ser feito pela API central do Road Runners.
// Use config/business.local.cfm com notificationDispatchUrl/notificationDispatchSecret.
localPushConfig = {
    "publicKey" = "COLOQUE_AQUI_A_CHAVE_PUBLICA_VAPID",
    "privateKey" = "COLOQUE_AQUI_A_CHAVE_PRIVADA_VAPID",
    "subject" = "mailto:contato@runnerhub.run"
};
</cfscript>
