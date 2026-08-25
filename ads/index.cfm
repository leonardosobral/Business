<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMA --->

<cfset VARIABLES.theme = "dark"/>

<!--- TEMPLATE --->

<cfset VARIABLES.template = "/ads/"/>

<!--- BACKEND --->

<cfinclude template="../includes/backend/backend_login.cfm"/>

<cfinclude template="includes/backend.cfm"/>

<!--- HEAD --->

<cfinclude template="../includes/estrutura/head.cfm"/>

<!--- CONTEUDO --->

<body data-mdb-theme="dark" class="bg-dark-subtle">


    <!--- HEADER --->

    <cfinclude template="../includes/estrutura/header.cfm"/>

    <!--- CONTEUDO --->

    <main id="" class="" style="margin-top: -55px;">

      <div class="container-fluid px-4">

        <cfinclude template="../includes/estrutura/pending_workspace_return.cfm">

        <cfinclude template="home.cfm">

      </div>

    </main>

    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>

</body>

</html>
