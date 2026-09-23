<!DOCTYPE html>
<html lang="pt-br">
<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/saude-eventos/"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/saude-eventos/assets/saude-eventos.css?v=20260921"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../includes/estrutura/header.cfm"/>
    <main class="saude-eventos-main">
        <div class="container-fluid px-3 px-xl-4">
            <cfinclude template="home.cfm"/>
        </div>
    </main>
    <cfinclude template="../includes/estrutura/footer.cfm"/>
</body>
</html>
