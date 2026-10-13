<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfinclude template="/administracao/agenda/includes/service.cfm"/>
<cfscript>
// This diagnostic catches cached credentials being absent or unable to open the existing token.
// It never returns credentials, token envelopes or plaintext.
try {
    businessLocalConfig={};
    include "/config/business.local.cfm";
    environment=createObject("java","java.lang.System").getenv();
    saved={}; fields={};
    for (setting in ["CLIENT_ID","CLIENT_SECRET","TOKEN_KEY"]) {
        localName="googleCalendar" & replace(setting,"_","","all");
        saved[setting]=structKeyExists(environment,"RR_GOOGLE_CALENDAR_" & setting) ? trim(environment["RR_GOOGLE_CALENDAR_" & setting]) : (structKeyExists(businessLocalConfig,localName) ? trim(businessLocalConfig[localName] & "") : "");
        cached=structKeyExists(APPLICATION,"googleCalendar") && structKeyExists(APPLICATION.googleCalendar,setting) ? APPLICATION.googleCalendar[setting] : "";
        fields[setting]={savedConfigured=len(saved[setting])>0,cachedConfigured=len(cached)>0,matchesSaved=len(cached)>0 && compare(cached,saved[setting])==0};
    }
    keyValid=false;
    try { keyValid=len(binaryEncode(binaryDecode(saved.TOKEN_KEY,"base64"),"hex"))==64; } catch(any invalidKey) {}
    connection=agendaDb("SELECT refresh_token FROM public.tb_google_agenda_conexao WHERE id=1");
    savedTokenValid=false;
    if (keyValid && connection.recordCount==1) {
        parts=listToArray(connection.refresh_token,".");
        if (arrayLen(parts)==2) {
            signature=hmac(parts[1],saved.TOKEN_KEY & ":authentication","HmacSHA256");
            if (createObject("java","java.security.MessageDigest").isEqual(charsetDecode(signature,"utf-8"),charsetDecode(parts[2],"utf-8"))) {
                try {
                    savedTokenValid=len(decrypt(parts[1],toBase64(binaryDecode(hash(saved.TOKEN_KEY & ":encryption","SHA-256"),"hex")),"AES/CBC/PKCS5Padding","Base64"))>0;
                } catch(any invalidEnvelope) {}
            }
        }
    }
    runtimeConfigValid=false; runtimeTokenValid=false;
    try {
        agendaConfig(); runtimeConfigValid=true;
        if (connection.recordCount==1) runtimeTokenValid=len(agendaUnseal(connection.refresh_token))>0;
    } catch(any runtimeMissing) {}
    calendars=agendaDb("SELECT count(*) AS total FROM public.tb_google_agenda_calendarios WHERE ativo=true");
    result={fields=fields,savedKeyValid=keyValid,savedTokenValid=savedTokenValid,connected=connection.recordCount==1,activeCalendars=val(calendars.total),runtimeConfigValid=runtimeConfigValid,runtimeTokenValid=runtimeTokenValid};
    result.ok=result.runtimeConfigValid && result.runtimeTokenValid && result.savedTokenValid;
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON(result));
} catch(any diagnosticError) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({ok=false,diagnosticError=true}));
}
</cfscript>
