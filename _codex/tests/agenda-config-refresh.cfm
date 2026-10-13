<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST" OR NOT structKeyExists(FORM,"refresh_existing_agenda_config") OR FORM.refresh_existing_agenda_config NEQ "agenda-config-20261010"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfinclude template="/administracao/agenda/includes/service.cfm"/>
<cfscript>
try {
    businessLocalConfig={};
    include "/config/business.local.cfm";
    environment=createObject("java","java.lang.System").getenv();
    saved={};
    for (setting in ["CLIENT_ID","CLIENT_SECRET","TOKEN_KEY"]) {
        localName="googleCalendar" & replace(setting,"_","","all");
        saved[setting]=structKeyExists(environment,"RR_GOOGLE_CALENDAR_" & setting) ? trim(environment["RR_GOOGLE_CALENDAR_" & setting]) : (structKeyExists(businessLocalConfig,localName) ? trim(businessLocalConfig[localName] & "") : "");
        if (!len(saved[setting])) throw(type="Agenda.RefreshValidation");
    }
    if (len(binaryEncode(binaryDecode(saved.TOKEN_KEY,"base64"),"hex"))!=64) throw(type="Agenda.RefreshValidation");
    connection=agendaDb("SELECT refresh_token FROM public.tb_google_agenda_conexao WHERE id=1");
    if (connection.recordCount!=1) throw(type="Agenda.RefreshValidation");
    parts=listToArray(connection.refresh_token,".");
    if (arrayLen(parts)!=2) throw(type="Agenda.RefreshValidation");
    signature=hmac(parts[1],saved.TOKEN_KEY & ":authentication","HmacSHA256");
    if (!createObject("java","java.security.MessageDigest").isEqual(charsetDecode(signature,"utf-8"),charsetDecode(parts[2],"utf-8"))) throw(type="Agenda.RefreshValidation");
    if (!len(decrypt(parts[1],toBase64(binaryDecode(hash(saved.TOKEN_KEY & ":encryption","SHA-256"),"hex")),"AES/CBC/PKCS5Padding","Base64"))) throw(type="Agenda.RefreshValidation");
    lock name="RunnerHubBusiness.GoogleAgenda" type="exclusive" timeout="5" {
        if (!structKeyExists(APPLICATION,"googleCalendar") || !isStruct(APPLICATION.googleCalendar)) throw(type="Agenda.RefreshValidation");
        previous=duplicate(APPLICATION.googleCalendar);
        candidate=duplicate(previous);
        for (setting in saved) {
            if (structKeyExists(previous,setting) && len(previous[setting]) && compare(previous[setting],saved[setting])!=0) throw(type="Agenda.RefreshConflict");
            candidate[setting]=saved[setting];
        }
        if (fileExists("/var/backups/business-agenda-config-20261010-K1knDJ/private/cache-before.json")) throw(type="Agenda.RefreshAlreadyRun");
        cffile(action="write",file="/var/backups/business-agenda-config-20261010-K1knDJ/private/cache-before.json",output=serializeJSON(previous),charset="utf-8",mode="600");
        APPLICATION.googleCalendar=candidate;
        try {
            agendaConfig();
            if (!len(agendaUnseal(connection.refresh_token))) throw(type="Agenda.RefreshValidation");
        } catch(any invalidRuntime) {
            APPLICATION.googleCalendar=previous;
            rethrow;
        }
    }
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=true,onlyAgendaCacheRefreshed=true,existingTokenVerified=true}));
} catch(any refreshError) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=false,validationOrConflict=true}));
}
</cfscript>
