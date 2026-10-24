<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/portal/audiencia/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<!--- Several bounded reports share this admin request; the global 20s budget is too short. --->
<cfsetting requesttimeout="60"/>
<cfinclude template="../includes/audience_backend.cfm"/>
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>
    <main style="margin-top:-55px"><div class="container-fluid px-4">
        <cfinclude template="home.cfm"/>
    </div></main>
    <cfinclude template="../../includes/estrutura/footer.cfm"/>
</body>
</html>
