<cfif NOT isDefined("qPerfil")
    OR NOT isDefined("qNotificacoes")
    OR NOT isDefined("qNotificacoesNaoLidas")
    OR NOT isDefined("VARIABLES.roadRunnersBaseUrl")>
    <cfinclude template="../backend/backend_login.cfm"/>
</cfif>

<link rel="stylesheet" href="/assets/css/business-shell.css?v=20261024-1"/>
<header class="business-shell-header">

      <!--- Sidenav --->
        <cfinclude template="sidenav.cfm">

      <!--- Navbar --->
        <cfinclude template="navbar.cfm">

    </header>
<script src="/assets/js/business-shell.js?v=20261024-1"></script>
