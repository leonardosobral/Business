<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<!--- Compatibility only. The catalogue is now served exclusively by the public API. --->
<cfheader name="Access-Control-Allow-Origin" value="*"/>
<cfheader name="Access-Control-Allow-Methods" value="GET, HEAD, OPTIONS"/>
<cfif CGI.request_method EQ "OPTIONS">
    <cfheader statuscode="204"/>
    <cfcontent type="text/plain" reset="true"/><cfabort/>
</cfif>
<cfif NOT listFindNoCase("GET,HEAD",CGI.request_method)>
    <cfheader statuscode="405"/><cfheader name="Allow" value="GET, HEAD, OPTIONS"/>
    <cfcontent type="application/json" reset="true"/><cfoutput>{"success":false,"status":"method_not_allowed"}</cfoutput><cfabort/>
</cfif>
<cfset runnerAppsLine=lCase(trim(URL.linha ?: ""))/>
<cfif (len(runnerAppsLine) AND runnerAppsLine NEQ "principal") OR structKeyExists(URL,"incluir_ocultos")>
    <cfheader statuscode="400"/>
    <cfcontent type="application/json" reset="true"/><cfoutput>{"success":false,"status":"invalid_parameter"}</cfoutput><cfabort/>
</cfif>
<cfheader name="Cache-Control" value="public, max-age=300"/>
<cfheader statuscode="308" statustext="Permanent Redirect"/>
<cfheader name="Location" value="https://api.roadrunners.run/v1/discovery/runner-apps.cfm#len(runnerAppsLine) ? '?linha=principal' : ''#"/>
<cfcontent type="text/plain; charset=utf-8" reset="true"/><cfabort/>
