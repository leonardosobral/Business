<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST" OR NOT structKeyExists(FORM,"refresh_existing_configuration") OR FORM.refresh_existing_configuration NEQ "chat-signature-20261010"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="60"/>
<cfscript>
try {
    // Refresh only this integration's cache, using the corrected production loader.
    source=fileRead(expandPath("/Application.cfc"),"utf-8");
    start=find('<cfset var businessLocalConfig = {}/>',source);
    finish=find('<cfset var accountDelegationSetting',source,start);
    if (!start || !finish) throw(message="Bloco de configuração não encontrado.");
    loader=mid(source,start,finish-start);
    loader=reReplace(loader,'<cfset var businessLocalConfigPath = [^\r\n]+','<cfset var businessLocalConfigPath = expandPath("/config/business.local.cfm")/>');
    loader=replace(loader,'template="config/business.local.cfm"','template="/config/business.local.cfm"');
    fileWrite("/var/www/business.roadrunners.run/__chat_signature_stage/production-loader.cfm",'<cffunction name="loadCurrentBusinessConfig" output="false" returntype="struct">' & loader & '<cfreturn duplicate(businessLocalConfig)/></cffunction>',"utf-8");
    include "/__chat_signature_stage/production-loader.cfm";
    cfg=loadCurrentBusinessConfig();
    env=createObject("java","java.lang.System").getenv();
    secret=structKeyExists(env,"RR_CHAT_SPECIAL_GROUPS_SECRET") ? trim(env["RR_CHAT_SPECIAL_GROUPS_SECRET"]) : (structKeyExists(cfg,"specialGroupsSecret") ? trim(cfg.specialGroupsSecret) : "");
    if (!len(secret)) {
        secret=structKeyExists(env,"RR_HANDOFF_SECRET") ? trim(env["RR_HANDOFF_SECRET"]) : (structKeyExists(cfg,"notificationDispatchSecret") ? trim(cfg.notificationDispatchSecret) : "");
        if (!len(secret) && structKeyExists(cfg,"cronSecrets") && structKeyExists(cfg.cronSecrets,"road_runners_handoff")) secret=trim(cfg.cronSecrets.road_runners_handoff);
    }
    endpoint=structKeyExists(env,"RR_CHAT_SPECIAL_GROUPS_URL") ? trim(env["RR_CHAT_SPECIAL_GROUPS_URL"]) : (structKeyExists(cfg,"specialGroupsUrl") ? trim(cfg.specialGroupsUrl) : "");
    if (!len(endpoint)) {
        pushEndpoint=structKeyExists(env,"RR_PUSH_DISPATCH_URL") ? trim(env["RR_PUSH_DISPATCH_URL"]) : (structKeyExists(cfg,"notificationDispatchUrl") ? trim(cfg.notificationDispatchUrl) : "https://roadrunners.run/api/notifications/integrations/dispatch.cfm");
        notificationEndpoint=structKeyExists(env,"RR_NOTIFICATION_DISPATCH_URL") ? trim(env["RR_NOTIFICATION_DISPATCH_URL"]) : (structKeyExists(cfg,"notificationDispatchUrl") ? trim(cfg.notificationDispatchUrl) : "");
        if (!len(notificationEndpoint)) notificationEndpoint=pushEndpoint;
        endpoint=reReplace(notificationEndpoint,"/api/.*$","/api/chat/admin/special-groups.cfm","one");
    }
    seconds=structKeyExists(env,"RR_CHAT_SPECIAL_GROUPS_TIMEOUT_SECONDS") ? val(env["RR_CHAT_SPECIAL_GROUPS_TIMEOUT_SECONDS"]) : (structKeyExists(cfg,"specialGroupsTimeoutSeconds") ? val(cfg.specialGroupsTimeoutSeconds) : 180);
    if (!len(secret) || endpoint NEQ "https://roadrunners.run/api/chat/admin/special-groups.cfm") throw(message="Configuração da integração fora do escopo esperado.");
    original=duplicate(APPLICATION.specialGroups);
    lock name="business-chat-config-refresh" type="exclusive" timeout="5" {
        APPLICATION.specialGroups={url=endpoint,secret=secret,timeoutSeconds=seconds GT 0 ? seconds : 180,configured=true};
    }
    qPerfil=queryExecute("SELECT id FROM tb_usuarios WHERE id=142 AND is_admin=true",{},{datasource="runner_dba",timeout=5});
    if (!qPerfil.recordCount) throw(message="Administrador de validação indisponível.");
    include "/administracao/chat/grupos-especiais/includes/backend.cfm";
    if (!VARIABLES.specialGroupsReady) {
        APPLICATION.specialGroups=original;
        throw(message="A consulta assinada falhou; cache anterior restaurado.");
    }
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=true,groups=arrayLen(VARIABLES.specialGroups),onlyIntegrationCacheRefreshed=true}));
} catch(any e) {
    if (structKeyExists(VARIABLES,"original")) APPLICATION.specialGroups=original;
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=false,message=e.message,line=e.tagContext[1].line,configKeys=structKeyExists(VARIABLES,"cfg") ? structKeyArray(cfg) : [],secretConfigured=structKeyExists(VARIABLES,"secret") && len(secret)>0,endpoint=structKeyExists(VARIABLES,"endpoint") ? endpoint : ""}));
}
</cfscript>
