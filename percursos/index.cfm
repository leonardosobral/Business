<!DOCTYPE html>
<html lang="pt-br">
<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/percursos/"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount>
    <cfcontent reset="true"/><cfheader statuscode="403" statustext="Forbidden"/><cfoutput>Acesso restrito a usuarios autenticados no Business.</cfoutput><cfabort/>
</cfif>
<cfinclude template="../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../includes/estrutura/header.cfm"/>
    <main style="margin-top: -55px;"><div class="container-fluid px-4"><cfinclude template="home.cfm"/></div></main>
    <cfinclude template="../includes/estrutura/footer.cfm"/>
</body>
</html>
