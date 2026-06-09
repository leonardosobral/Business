<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cflocation addtoken="false" url="/logout.cfm"/>
</cfif>

<cfinclude template="includes/backend/backend_login.cfm"/>

<cfif isDefined("URL.logout") AND URL.logout EQ "1">

    <cfinclude template="home.cfm"/>

<cfelseif isDefined("VARIABLES.businessAccountPendingAccess") AND VARIABLES.businessAccountPendingAccess>

    <cfinclude template="cadastro/status.cfm"/>

<cfelseif isDefined("qPerfil") AND qPerfil.recordcount>

    <cfinclude template="template.cfm"/>

<cfelse>

    <cfinclude template="home.cfm"/>

</cfif>
