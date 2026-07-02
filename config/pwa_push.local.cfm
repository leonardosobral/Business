<cfscript>
// Legado: mantido apenas para compatibilidade de código antigo.
// O fluxo atual envia Push pela API central do Road Runners.
businessLocalConfig = {};
include "/config/business.local.cfm";

localPushConfig = {
    "publicKey" = structKeyExists(businessLocalConfig, "pushPublicKey") ? trim(businessLocalConfig.pushPublicKey) : "",
    "privateKey" = structKeyExists(businessLocalConfig, "pushPrivateKey") ? trim(businessLocalConfig.pushPrivateKey) : "",
    "subject" = structKeyExists(businessLocalConfig, "pushSubject") ? trim(businessLocalConfig.pushSubject) : "mailto:contato@runnerhub.run"
};
</cfscript>
