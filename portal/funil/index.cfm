<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/portal/funil/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../../includes/backend/require_real_platform_context.cfm"/>
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/portal/funil/assets/funil.css?v=20261006"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>
    <main style="margin-top:-55px"><div class="container-fluid px-4">
        <cfinclude template="home.cfm"/>
    </div></main>
    <cfinclude template="../../includes/estrutura/footer.cfm"/>
    <script src="/portal/funil/assets/funil.js?v=20261006" defer></script>
</body>
</html>
