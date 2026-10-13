<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST" OR NOT structKeyExists(FORM,"refresh_existing_summary_config") OR FORM.refresh_existing_summary_config NEQ "summary-config-20261010"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
try {
    businessLocalConfig={};
    include "/config/business.local.cfm";
    savedSecret=structKeyExists(businessLocalConfig,"cronSecrets") && structKeyExists(businessLocalConfig.cronSecrets,"conteudo_internal") ? trim(businessLocalConfig.cronSecrets.conteudo_internal & "") : "";
    proof=deserializeJSON(fileRead("/tmp/business-summary-config-20261010-CH6OhC/news-proof.json","utf-8"));
    if (!len(savedSecret) || compare(lCase(hmac("summary-config-check-20261010",savedSecret,"HmacSHA256")),proof.check)) throw(message="Configuração salva não corresponde ao processador News.");
    if (!structKeyExists(APPLICATION,"cronJobs") || !isStruct(APPLICATION.cronJobs) || !structKeyExists(APPLICATION.cronJobs,"secrets") || !isStruct(APPLICATION.cronJobs.secrets)) throw(message="Estrutura da configuração de jobs indisponível.");
    previous={present=structKeyExists(APPLICATION.cronJobs.secrets,"conteudo_internal"),value=structKeyExists(APPLICATION.cronJobs.secrets,"conteudo_internal") ? APPLICATION.cronJobs.secrets.conteudo_internal : ""};
    cffile(action="write",file="/tmp/business-summary-config-20261010-CH6OhC/cache-before.json",output=serializeJSON(previous),charset="utf-8",mode="600");
    lock name="business-summary-config-refresh" type="exclusive" timeout="5" {
        APPLICATION.cronJobs.secrets.conteudo_internal=savedSecret;
    }
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=true,onlySummaryCredentialCacheRefreshed=true}));
} catch(any e) {
    cfheader(statuscode=500);
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON({success=false,message=e.message,line=e.tagContext[1].line}));
}
</cfscript>
