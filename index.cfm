<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cflocation addtoken="false" url="/logout.cfm"/>
</cfif>

<cfinclude template="includes/backend/backend_login.cfm"/>

<cfset VARIABLES.researchLoginReturn = isDefined("URL.redirect") ? trim(URL.redirect & "") : ""/>
<cfset VARIABLES.validResearchLoginReturn = len(VARIABLES.researchLoginReturn)
    AND left(VARIABLES.researchLoginReturn, 10) EQ "/pesquisa/"
    AND left(VARIABLES.researchLoginReturn, 2) NEQ "//"
    AND NOT find("\", VARIABLES.researchLoginReturn)
    AND NOT find(chr(10), VARIABLES.researchLoginReturn)
    AND NOT find(chr(13), VARIABLES.researchLoginReturn)/>
<cfif VARIABLES.validResearchLoginReturn AND isDefined("qPerfil") AND qPerfil.recordcount>
    <cflocation addtoken="false" url="#VARIABLES.researchLoginReturn#"/>
</cfif>

<cfif isDefined("URL.logout") AND URL.logout EQ "1">

    <cfinclude template="home.cfm"/>

<cfelseif isDefined("VARIABLES.businessAccountPendingAccess") AND VARIABLES.businessAccountPendingAccess>

    <cfinclude template="cadastro/status.cfm"/>

<cfelseif isDefined("qPerfil") AND qPerfil.recordcount>

    <cfinclude template="template.cfm"/>

<cfelse>

    <cfinclude template="home.cfm"/>

</cfif>
