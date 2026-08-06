<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting requesttimeout="600"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/racetag/"/>

<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/require_admin.cfm"/>
<cfinclude template="includes/backend.cfm"/>
<cfinclude template="../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../includes/estrutura/header.cfm"/>

    <main style="margin-top: -55px;">
        <div class="container px-4 py-5">
            <cfinclude template="home.cfm"/>
        </div>
    </main>

    <cfinclude template="../includes/estrutura/footer.cfm"/>
</body>
</html>
