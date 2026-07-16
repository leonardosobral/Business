<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/administracao/usuarios/"/>

<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin_dev.cfm"/>
<cfinclude template="includes/backend.cfm"/>
<cfinclude template="../../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>

    <main style="margin-top: -55px;">
        <div class="container px-4">
            <cfinclude template="home.cfm"/>
        </div>
    </main>

    <cfinclude template="../../includes/estrutura/footer.cfm"/>
</body>
</html>
