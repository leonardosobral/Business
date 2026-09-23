<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/administracao/ponto/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../../includes/backend/require_real_platform_context.cfm"/>
<cfinclude template="includes/backend.cfm"/>
<!doctype html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>
    <main style="margin-top: -55px;">
        <div class="container px-4 pb-5">
            <cfinclude template="home.cfm"/>
        </div>
    </main>
    <cfinclude template="../../includes/estrutura/footer.cfm"/>
    <script src="assets/ponto.js" defer></script>
</body>
</html>
