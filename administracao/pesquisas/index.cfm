<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/administracao/pesquisas/"/>

<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>

    <main style="margin-top: -55px;">
        <div class="container-fluid px-3 px-lg-4">
            <cfinclude template="home.cfm"/>
        </div>
    </main>

    <cfinclude template="../../includes/estrutura/footer.cfm"/>
    <script src="/administracao/pesquisas/assets/pesquisas.js?v=20260819-5"></script>
</body>
</html>
