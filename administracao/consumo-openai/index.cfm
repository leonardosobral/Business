<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false" requesttimeout="60">
<cfset VARIABLES.theme="dark"><cfset VARIABLES.template="/administracao/consumo-openai/">
<cfinclude template="../../includes/backend/backend_login.cfm">
<cfinclude template="includes/backend.cfm">
<!doctype html><html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm">
<link rel="stylesheet" href="./assets/usage.css?v=20261023-1">
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm">
<main style="margin-top:-55px"><div class="container-fluid px-4 py-4 ou-page"><cfinclude template="includes/view.cfm"></div></main>
<cfinclude template="../../includes/estrutura/footer.cfm">
<script src="./assets/usage.js?v=20261023-1"></script>
</body></html>
