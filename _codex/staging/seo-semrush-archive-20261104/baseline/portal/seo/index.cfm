<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/portal/seo/"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>
    <main style="margin-top:-55px"><div class="container-fluid px-4">
        <cfinclude template="../conteudo/seo.cfm"/>
    </div></main>
    <cfinclude template="../../includes/estrutura/footer.cfm"/>
</body>
</html>
