<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cflocation addtoken="false" url="/logout.cfm"/>
</cfif>

<cfinclude template="includes/backend/backend_login.cfm"/>
<cfif structKeyExists(REQUEST,"businessAccessContext") AND REQUEST.businessAccessContext.accessMode EQ "DELEGATED">
    <cfinclude template="includes/estrutura/home_delegated_account.cfm"/>
    <cfexit method="exittemplate"/>
</cfif>


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

<cfelseif isDefined("VARIABLES.businessPendingAccountId") AND len(trim(VARIABLES.businessPendingAccountId & "")) AND (NOT isDefined("VARIABLES.businessEffectiveAccountIds") OR VARIABLES.businessEffectiveAccountIds EQ "0")>

    <cfinclude template="cadastro/status.cfm"/>

<cfelseif isDefined("VARIABLES.businessAccountPendingAccess") AND VARIABLES.businessAccountPendingAccess>

    <cfinclude template="cadastro/status.cfm"/>

<cfelseif isDefined("qPerfil") AND qPerfil.recordcount>

    <cfinclude template="template.cfm"/>

<cfelse>

    <cfinclude template="home.cfm"/>

</cfif>
