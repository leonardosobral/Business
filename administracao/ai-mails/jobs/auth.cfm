<cfsetting showdebugoutput="false" requesttimeout="135"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
mailHeaders=getHTTPRequestData().headers;
mailCredential=structKeyExists(mailHeaders,"Authorization")?reReplaceNoCase(trim(mailHeaders.Authorization),"^Bearer\s+","", "one"):"";
mailExpected=structKeyExists(application,"cronJobs") && structKeyExists(application.cronJobs,"runnerToken")?application.cronJobs.runnerToken:"";
if(CGI.REQUEST_METHOD!="POST" || !len(mailExpected) || !len(mailCredential) || !createObject("java","java.security.MessageDigest").isEqual(charsetDecode(mailCredential,"utf-8"),charsetDecode(mailExpected,"utf-8"))) {
    cfheader(statuscode=403);writeOutput('{"success":false,"status":"unauthorized"}');abort;
}
</cfscript>
<cfinclude template="../../agenda/includes/service.cfm"/>
<cfinclude template="../includes/service.cfm"/>
<cfinclude template="../includes/sync.cfm"/>
