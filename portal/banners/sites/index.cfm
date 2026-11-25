<cfprocessingdirective pageencoding="utf-8"/>
<cfsilent>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/portal/banners/sites/"/>
<cfinclude template="../../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../../ads/includes/access.cfm"/>
<cfinclude template="backend.cfm"/>
</cfsilent>
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../../../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../../includes/estrutura/header.cfm"/>

    <main class="" style="margin-top: -55px;">
      <div class="container-fluid px-4">
        <cfinclude template="home.cfm">
      </div>
    </main>

    <cfinclude template="../../../includes/estrutura/footer.cfm"/>
</body>

</html>
