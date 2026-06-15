<cfscript>
businessLocalConfig = {};
include "/config/business.local.cfm";

localPushConfig = {
    "publicKey" = businessLocalConfig.pushPublicKey,
    "privateKey" = businessLocalConfig.pushPrivateKey,
    "subject" = businessLocalConfig.pushSubject
};
</cfscript>
