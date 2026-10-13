<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
try {
    cachedSecret=structKeyExists(APPLICATION,"cronJobs") && isStruct(APPLICATION.cronJobs) && structKeyExists(APPLICATION.cronJobs,"secrets") && isStruct(APPLICATION.cronJobs.secrets) && structKeyExists(APPLICATION.cronJobs.secrets,"conteudo_internal") ? trim(APPLICATION.cronJobs.secrets.conteudo_internal & "") : "";
    businessLocalConfig={};
    include "/config/business.local.cfm";
    savedSecret=structKeyExists(businessLocalConfig,"cronSecrets") && structKeyExists(businessLocalConfig.cronSecrets,"conteudo_internal") ? trim(businessLocalConfig.cronSecrets.conteudo_internal & "") : "";
    newsProof=deserializeJSON(fileRead("/tmp/business-summary-config-20261010-CH6OhC/news-proof.json","utf-8"));
    matchesNews=len(savedSecret)>0 && compare(lCase(hmac("summary-config-check-20261010",savedSecret,"HmacSHA256")),newsProof.check) EQ 0;
    result={cachedConfigured=len(cachedSecret)>0,savedConfigured=len(savedSecret)>0,savedMatchesNews=matchesNews,cachedMatchesSaved=len(cachedSecret)>0 && compare(cachedSecret,savedSecret) EQ 0,newsEnabled=newsProof.enabled,newsProviderConfigured=newsProof.providerConfigured};
    result.ok=result.cachedConfigured && result.savedConfigured && result.savedMatchesNews && result.cachedMatchesSaved;
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON(result));
} catch(any e) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({ok=false,message=e.message,line=e.tagContext[1].line}));
}
</cfscript>
