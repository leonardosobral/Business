<cfif NOT isDefined("COOKIE.id")>

    <cfinclude template="home.cfm"/>

<cfelse>

    <cfinclude template="home_logado.cfm"/>

</cfif>
