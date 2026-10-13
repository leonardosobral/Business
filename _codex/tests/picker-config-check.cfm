<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfinclude template="/administracao/agenda/includes/service.cfm"/>
<cfinclude template="/administracao/drive/includes/service.cfm"/>
<cfscript>
// Regression: saved Picker settings must enable the real Drive service without widening scopes.
// No key, OAuth client ID, token, folder ID or document data is returned.
try {
    businessLocalConfig={};
    include "/config/business.local.cfm";
    environment=createObject("java","java.lang.System").getenv();
    saved={}; fields={};
    for (entry in [{name="pickerApiKey",env="RR_GOOGLE_DRIVE_PICKER_API_KEY",localName="googleDrivePickerApiKey"},{name="appId",env="RR_GOOGLE_DRIVE_APP_ID",localName="googleDriveAppId"}]) {
        saved[entry.name]=structKeyExists(environment,entry.env) ? trim(environment[entry.env]) : (structKeyExists(businessLocalConfig,entry.localName) ? trim(businessLocalConfig[entry.localName] & "") : "");
        cached=structKeyExists(APPLICATION,"googleDrive") && structKeyExists(APPLICATION.googleDrive,entry.name) ? APPLICATION.googleDrive[entry.name] & "" : "";
        fields[entry.name]={savedConfigured=len(saved[entry.name])>0,cachedConfigured=len(cached)>0,matchesSaved=len(cached)>0 && compare(cached,saved[entry.name])==0};
    }
    pickerClientId=agendaConfig().CLIENT_ID;
    connection=driveDb("SELECT scopes FROM public.tb_google_agenda_conexao WHERE id=1");
    root=driveRoot();
    result={fields=fields,savedAppIdValid=reFind("^[0-9]{6,32}$",saved.appId)>0,savedAppIdMatchesOAuthProject=compare(listFirst(pickerClientId,"-"),saved.appId)==0,existingDriveFileScope=connection.recordCount==1 && listFind(connection.scopes[1] & "","https://www.googleapis.com/auth/drive.file"," ")>0,rootConfigured=root.configured,runtimePickerConfigured=drivePickerConfigured() ? true : false};
    result.ok=result.runtimePickerConfigured && result.existingDriveFileScope && result.rootConfigured && fields.pickerApiKey.matchesSaved && fields.appId.matchesSaved;
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON(result));
} catch(any diagnosticError) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({ok=false,diagnosticError=true,type=diagnosticError.type,line=diagnosticError.tagContext[1].line}));
}
</cfscript>
