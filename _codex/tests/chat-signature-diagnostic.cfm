<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="60"/>
<cfscript>
try {
    function inspectStartupScope() {
        var businessLocalConfig={};
        include "/config/business.local.cfm";
        var inspection={localHasSpecial=structKeyExists(LOCAL.businessLocalConfig,"specialGroupsSecret"),variablesHasSpecial=structKeyExists(VARIABLES,"businessLocalConfig") && structKeyExists(VARIABLES.businessLocalConfig,"specialGroupsSecret"),localKeyCount=structCount(LOCAL.businessLocalConfig),variablesKeys=structKeyExists(VARIABLES,"businessLocalConfig") ? structKeyArray(VARIABLES.businessLocalConfig) : []};
        if (structKeyExists(VARIABLES,"businessLocalConfig") && isStruct(VARIABLES.businessLocalConfig)) businessLocalConfig=duplicate(VARIABLES.businessLocalConfig);
        inspection.resultHasSpecial=structKeyExists(businessLocalConfig,"specialGroupsSecret");
        return inspection;
    }
    config=APPLICATION.specialGroups;
    stamp=dateTimeFormat(now(),"yyyy-mm-dd HH:nn:ss");
    result={configured=config.configured,locale=getLocale(),timestamp=stamp,timestampValid=isDate(stamp),keyCheck=lCase(hmac("chat-signature-diagnostic-20261010",config.secret,"HmacSHA256")),applicationName=getApplicationMetadata().name};
    env=createObject("java","java.lang.System").getenv();
    result.environmentSpecialPresent=structKeyExists(env,"RR_CHAT_SPECIAL_GROUPS_SECRET");
    result.environmentHandoffPresent=structKeyExists(env,"RR_HANDOFF_SECRET");
    if (result.applicationName EQ "RunnerHubBusiness") {
        result.startupScope=inspectStartupScope();
        businessLocalConfig={};
        include "/config/business.local.cfm";
        expectedSpecial=result.environmentSpecialPresent ? trim(env["RR_CHAT_SPECIAL_GROUPS_SECRET"]) : (structKeyExists(businessLocalConfig,"specialGroupsSecret") ? trim(businessLocalConfig.specialGroupsSecret) : "");
        expectedHandoff=result.environmentHandoffPresent ? trim(env["RR_HANDOFF_SECRET"]) : (structKeyExists(businessLocalConfig,"notificationDispatchSecret") ? trim(businessLocalConfig.notificationDispatchSecret) : "");
        if (!len(expectedHandoff) && structKeyExists(businessLocalConfig,"cronSecrets") && structKeyExists(businessLocalConfig.cronSecrets,"road_runners_handoff")) expectedHandoff=trim(businessLocalConfig.cronSecrets.road_runners_handoff);
    } else {
        localStravaConfig={};
        include "/config/strava.local.cfm";
        expectedSpecial=result.environmentSpecialPresent ? trim(env["RR_CHAT_SPECIAL_GROUPS_SECRET"]) : "";
        expectedHandoff=result.environmentHandoffPresent ? trim(env["RR_HANDOFF_SECRET"]) : "";
        if (!len(expectedSpecial) && structKeyExists(localStravaConfig,"specialGroupsSecret")) expectedSpecial=trim(localStravaConfig.specialGroupsSecret);
        if (!len(expectedHandoff) && structKeyExists(localStravaConfig,"handoffSecret")) expectedHandoff=trim(localStravaConfig.handoffSecret);
    }
    result.source=len(expectedSpecial) ? "special" : "handoff";
    expected=len(expectedSpecial) ? expectedSpecial : expectedHandoff;
    result.matchesCurrentConfiguration=compare(config.secret,expected) EQ 0;
    result.expectedCheck=lCase(hmac("chat-signature-diagnostic-20261010",expected,"HmacSHA256"));
    result.specialConfigured=len(expectedSpecial)>0;
    result.handoffConfigured=len(expectedHandoff)>0;
    if (result.handoffConfigured) result.handoffCheck=lCase(hmac("chat-signature-diagnostic-20261010",expectedHandoff,"HmacSHA256"));
    if (structKeyExists(URL,"manager")) {
        qPerfil=queryExecute("SELECT id FROM tb_usuarios WHERE id=142 AND is_admin=true",{},{datasource="runner_dba",timeout=5});
        if (!qPerfil.recordCount) throw(message="Administrador de validação indisponível.");
        include "/administracao/chat/grupos-especiais/includes/backend.cfm";
        result.managerReady=VARIABLES.specialGroupsReady;
        result.groupCount=arrayLen(VARIABLES.specialGroups);
        if (!result.managerReady) result.message=VARIABLES.specialGroupsData.message;
        result.endpoint=config.url;
    }
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON(result));
} catch(any e) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=false,message=e.message,line=e.tagContext[1].line}));
}
</cfscript>
