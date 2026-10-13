<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
cfg=createObject("component","inc.article_summary_config").load();
proof={check=lCase(hmac("summary-config-check-20261010",cfg.workerSecret,"HmacSHA256")),enabled=cfg.enabled,providerConfigured=len(trim(cfg.apiKey))>0};
fileWrite("/tmp/business-summary-config-20261010-CH6OhC/news-proof.json",serializeJSON(proof),"utf-8");
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({configured=len(trim(cfg.workerSecret))>0,enabled=proof.enabled,providerConfigured=proof.providerConfigured}));
</cfscript>
