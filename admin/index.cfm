<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.adminRedirectUrl = "/eventos/"/>
<cfif isDefined("CGI.QUERY_STRING") AND len(trim(CGI.QUERY_STRING))>
    <cfset VARIABLES.adminRedirectUrl = VARIABLES.adminRedirectUrl & "?" & CGI.QUERY_STRING/>
</cfif>

<cflocation addtoken="false" url="#VARIABLES.adminRedirectUrl#"/>
