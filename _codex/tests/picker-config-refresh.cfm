<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST" OR NOT structKeyExists(FORM,"refresh_existing_picker_config") OR FORM.refresh_existing_picker_config NEQ "picker-config-20261010"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfinclude template="/administracao/agenda/includes/service.cfm"/>
<cfinclude template="/administracao/drive/includes/service.cfm"/>
<cfscript>
try {
    businessLocalConfig={};
    include "/config/business.local.cfm";
    environment=createObject("java","java.lang.System").getenv();
    saved={};
    for (entry in [{name="pickerApiKey",env="RR_GOOGLE_DRIVE_PICKER_API_KEY",localName="googleDrivePickerApiKey"},{name="appId",env="RR_GOOGLE_DRIVE_APP_ID",localName="googleDriveAppId"}]) {
        saved[entry.name]=structKeyExists(environment,entry.env) ? trim(environment[entry.env]) : (structKeyExists(businessLocalConfig,entry.localName) ? trim(businessLocalConfig[entry.localName] & "") : "");
        if (!len(saved[entry.name])) throw(type="Picker.RefreshValidation");
    }
    if (!reFind("^[A-Za-z0-9_-]{20,255}$",saved.pickerApiKey) || !reFind("^[0-9]{6,32}$",saved.appId)) throw(type="Picker.RefreshValidation");
    if (compare(listFirst(agendaConfig().CLIENT_ID,"-"),saved.appId)!=0) throw(type="Picker.RefreshValidation");
    connection=driveDb("SELECT scopes FROM public.tb_google_agenda_conexao WHERE id=1");
    if (connection.recordCount!=1 || !listFind(connection.scopes[1] & "","https://www.googleapis.com/auth/drive.file"," ")) throw(type="Picker.RefreshValidation");
    if (!driveRoot().configured) throw(type="Picker.RefreshValidation");
    lock name="RunnerHubBusiness.GoogleDriveConfiguration" type="exclusive" timeout="5" {
        if (!structKeyExists(APPLICATION,"googleDrive") || !isStruct(APPLICATION.googleDrive)) throw(type="Picker.RefreshValidation");
        previous=duplicate(APPLICATION.googleDrive);
        candidate=duplicate(previous);
        for (setting in saved) {
            if (structKeyExists(previous,setting) && len(previous[setting]) && compare(previous[setting],saved[setting])!=0) throw(type="Picker.RefreshConflict");
            candidate[setting]=saved[setting];
        }
        candidate.pickerConfigured=true;
        if (fileExists("/var/backups/business-picker-config-20261010-tj7nBo/private/cache-before.json")) throw(type="Picker.RefreshAlreadyRun");
        cffile(action="write",file="/var/backups/business-picker-config-20261010-tj7nBo/private/cache-before.json",output=serializeJSON(previous),charset="utf-8",mode="600");
        APPLICATION.googleDrive=candidate;
        try {
            if (!drivePickerConfigured()) throw(type="Picker.RefreshValidation");
        } catch(any invalidRuntime) {
            APPLICATION.googleDrive=previous;
            rethrow;
        }
    }
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=true,onlyPickerCacheRefreshed=true,existingScopePreserved=true}));
} catch(any refreshError) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=false,validationOrConflict=true}));
}
</cfscript>
