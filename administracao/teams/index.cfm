<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false">
<cfinclude template="includes/backend.cfm">
<cfset VARIABLES.theme="dark"><cfset VARIABLES.template="/administracao/teams/">
<cfinclude template="../../includes/backend/backend_login.cfm">
<!DOCTYPE html><html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm">
<body data-mdb-theme="dark" class="bg-dark-subtle">
<link rel="stylesheet" href="/administracao/teams/assets/manager.css?v=1">
<script src="/teams/assets/teams.js?v=1" defer></script>
<cfinclude template="../../includes/estrutura/header.cfm">
<main style="margin-top:-55px"><div class="container px-4"><cfinclude template="home.cfm"></div></main>
<cfinclude template="../../includes/estrutura/footer.cfm">
</body></html>
