<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="45"/>
<cfinclude template="/administracao/kanban/includes/trello_service.cfm"/>
<cfscript>
// Regression: credentials saved on the server must reach the actual Kanban service.
// This private probe returns presence/equality, status codes and counts only.
try {
    businessLocalConfig={};
    include "/config/business.local.cfm";
    environment=createObject("java","java.lang.System").getenv();
    saved={}; fields={};
    for (entry in [{name="apiKey",env="RR_TRELLO_API_KEY",localName="trelloApiKey"},{name="apiToken",env="RR_TRELLO_API_TOKEN",localName="trelloApiToken"}]) {
        saved[entry.name]=structKeyExists(environment,entry.env) ? trim(environment[entry.env]) : (structKeyExists(businessLocalConfig,entry.localName) ? trim(businessLocalConfig[entry.localName] & "") : "");
        cached=structKeyExists(APPLICATION,"trello") && isStruct(APPLICATION.trello) && structKeyExists(APPLICATION.trello,entry.name) ? APPLICATION.trello[entry.name] & "" : "";
        fields[entry.name]={savedConfigured=len(saved[entry.name])>0,cachedConfigured=len(cached)>0,matchesSaved=len(cached)>0 && compare(cached,saved[entry.name])==0};
    }
    savedStatus=0;
    if (len(saved.apiKey) && len(saved.apiToken) && !reFind('[\r\n"]',saved.apiKey & saved.apiToken)) {
        httpResult={};
        cfhttp(url="https://api.trello.com/1/members/me",method="GET",result="httpResult",timeout=15,redirect=false,throwonerror=false) {
            cfhttpparam(type="header",name="Accept",value="application/json");
            cfhttpparam(type="header",name="Authorization",value='OAuth oauth_consumer_key="' & saved.apiKey & '", oauth_token="' & saved.apiToken & '"');
            cfhttpparam(type="url",name="fields",value="id");
        }
        savedStatus=kanbanHttpStatus(httpResult);
    }
    runtimeConfigured=kanbanTrelloConfigured();
    runtimeStatus=0;
    if (runtimeConfigured) {
        runtimeResponse=kanbanTrelloRequest("/members/me","GET",{fields="id"});
        runtimeStatus=runtimeResponse.status;
    }
    mapped=queryExecute("SELECT count(*) AS total FROM public.tb_trello_quadros WHERE ativo=true",{},{datasource="runner_dba"});
    result={fields=fields,savedApiStatus=savedStatus,savedCredentialsValid=savedStatus==200,runtimeConfigured=runtimeConfigured,runtimeApiStatus=runtimeStatus,activeMappedBoards=val(mapped.total)};
    result.ok=result.runtimeConfigured && result.runtimeApiStatus==200 && result.savedCredentialsValid && fields.apiKey.matchesSaved && fields.apiToken.matchesSaved;
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON(result));
} catch(any diagnosticError) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({ok=false,diagnosticError=true}));
}
</cfscript>
