<cfprocessingdirective pageencoding="utf-8">
<cfset VARIABLES.theme="dark"><cfset VARIABLES.template="/administracao/comparador/">
<cfinclude template="../../includes/backend/backend_login.cfm">
<cfinclude template="../../includes/backend/require_admin.cfm">
<cfset REQUEST.comparadorAdminPage=true>
<cfinclude template="includes/backend.cfm">
<!doctype html><html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm">
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm">
<main style="margin-top: -55px;"><div class="container-fluid px-3 px-md-4 comparador-admin"><cfinclude template="home.cfm"></div></main>
<cfinclude template="../../includes/estrutura/footer.cfm">
</body></html>
