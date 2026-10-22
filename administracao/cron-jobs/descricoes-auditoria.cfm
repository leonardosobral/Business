<cfprocessingdirective pageencoding="utf-8">
<cfsetting showdebugoutput="false">
<cfset VARIABLES.theme="dark">
<cfset VARIABLES.template="/administracao/cron-jobs/">
<cfinclude template="../../includes/backend/backend_login.cfm">
<cfinclude template="includes/description_audit_backend.cfm">
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm">
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm">
<main style="margin-top:-55px;"><div class="container-fluid px-4 py-4">
<cfinclude template="includes/description_audit_view.cfm">
</div></main>
<cfinclude template="../../includes/estrutura/footer.cfm">
</body></html>
