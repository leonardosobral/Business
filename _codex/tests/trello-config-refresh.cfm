<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST" OR NOT structKeyExists(FORM,"refresh_existing_trello_config") OR FORM.refresh_existing_trello_config NEQ "trello-config-20261010"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="60"/>
<cfinclude template="/administracao/kanban/includes/trello_service.cfm"/>
<cfscript>
try {
    businessLocalConfig={};
    include "/config/business.local.cfm";
    environment=createObject("java","java.lang.System").getenv();
    saved={};
    for (entry in [{name="apiKey",env="RR_TRELLO_API_KEY",localName="trelloApiKey"},{name="apiToken",env="RR_TRELLO_API_TOKEN",localName="trelloApiToken"}]) {
        saved[entry.name]=structKeyExists(environment,entry.env) ? trim(environment[entry.env]) : (structKeyExists(businessLocalConfig,entry.localName) ? trim(businessLocalConfig[entry.localName] & "") : "");
        if (!len(saved[entry.name]) || reFind('[\r\n"]',saved[entry.name])) throw(type="Trello.RefreshValidation");
    }
    savedResponse={};
    cfhttp(url="https://api.trello.com/1/members/me",method="GET",result="savedResponse",timeout=15,redirect=false,throwonerror=false) {
        cfhttpparam(type="header",name="Accept",value="application/json");
        cfhttpparam(type="header",name="Authorization",value='OAuth oauth_consumer_key="' & saved.apiKey & '", oauth_token="' & saved.apiToken & '"');
        cfhttpparam(type="url",name="fields",value="id");
    }
    if (kanbanHttpStatus(savedResponse)!=200) throw(type="Trello.RefreshValidation");
    lock name="RunnerHubBusiness.TrelloConfiguration" type="exclusive" timeout="5" {
        if (!structKeyExists(APPLICATION,"trello") || !isStruct(APPLICATION.trello)) throw(type="Trello.RefreshValidation");
        previous=duplicate(APPLICATION.trello);
        candidate=duplicate(previous);
        if (!structKeyExists(candidate,"baseUrl") || candidate.baseUrl!="https://api.trello.com/1") throw(type="Trello.RefreshValidation");
        for (setting in saved) {
            if (structKeyExists(previous,setting) && len(previous[setting]) && compare(previous[setting],saved[setting])!=0) throw(type="Trello.RefreshConflict");
            candidate[setting]=saved[setting];
        }
        candidate.enabled=true;
        if (fileExists("/var/backups/business-trello-config-20261010-2K0MKY/private/cache-before.json")) throw(type="Trello.RefreshAlreadyRun");
        cffile(action="write",file="/var/backups/business-trello-config-20261010-2K0MKY/private/cache-before.json",output=serializeJSON(previous),charset="utf-8",mode="600");
        APPLICATION.trello=candidate;
        try {
            if (!kanbanTrelloConfigured()) throw(type="Trello.RefreshValidation");
            runtimeResponse=kanbanTrelloRequest("/members/me","GET",{fields="id"});
            if (!runtimeResponse.success || runtimeResponse.status!=200) throw(type="Trello.RefreshValidation");
        } catch(any invalidRuntime) {
            APPLICATION.trello=previous;
            rethrow;
        }
    }
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=true,onlyTrelloCacheRefreshed=true,existingCredentialsVerified=true}));
} catch(any refreshError) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=false,validationOrConflict=true}));
}
</cfscript>
