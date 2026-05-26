<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/suporte/"/>
<cfset VARIABLES.helpdeskMode = "support"/>

<cfinclude template="../helpdesk/includes/backend.cfm"/>
<cfinclude template="../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">

    <cfinclude template="../includes/estrutura/header.cfm"/>

    <main class="" style="margin-top: -55px;">
      <div class="container px-4">
        <cfinclude template="home.cfm"/>
      </div>
    </main>

    <cfinclude template="../includes/estrutura/footer.cfm"/>

</body>

</html>
