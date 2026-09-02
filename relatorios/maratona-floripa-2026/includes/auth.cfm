<cfsetting showdebugoutput="false"/>

<cfset VARIABLES.template = "/relatorios/maratona-floripa-2026/"/>
<cfinclude template="../../../includes/backend/backend_login.cfm"/>

<cfset VARIABLES.mifReportDefaultReturnPath = "/relatorios/maratona-floripa-2026/"/>
<cfset VARIABLES.mifReportReturnPath = structKeyExists(VARIABLES, "mifReportRequestedReturnPath")
    ? trim(VARIABLES.mifReportRequestedReturnPath & "")
    : (structKeyExists(CGI, "SCRIPT_NAME")
        ? trim(CGI.SCRIPT_NAME & "")
        : VARIABLES.mifReportDefaultReturnPath)/>

<cfif NOT (
    len(VARIABLES.mifReportReturnPath)
    AND left(VARIABLES.mifReportReturnPath, 1) EQ "/"
    AND left(VARIABLES.mifReportReturnPath, 2) NEQ "//"
    AND NOT find(chr(10), VARIABLES.mifReportReturnPath)
    AND NOT find(chr(13), VARIABLES.mifReportReturnPath)
    AND NOT find("\", VARIABLES.mifReportReturnPath)
)>
    <cfset VARIABLES.mifReportReturnPath = VARIABLES.mifReportDefaultReturnPath/>
</cfif>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount>
    <cfset VARIABLES.mifReportLoginUrl = "/?login=1&redirect="
        & urlEncodedFormat(VARIABLES.mifReportReturnPath)/>
    <cflocation addtoken="false" url="#VARIABLES.mifReportLoginUrl#"/>
    <cfabort/>
</cfif>

<cfset REQUEST.mifReportAuthorized = true/>
