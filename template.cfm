<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMA --->

<cfset VARIABLES.theme = "dark"/>

<!--- TEMPLATE --->

<cfset VARIABLES.template = "/"/>

<!--- BACKEND --->

<cfinclude template="includes/backend/backend_login.cfm"/>

<!--- HEAD --->

<cfinclude template="includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">


    <!--- HEADER --->

    <cfinclude template="includes/estrutura/header.cfm"/>

    <!--- CONTEUDO --->

    <main id="" class="" style="margin-top: -55px;">

      <div class="container">

        <cfinclude template="home_logado.cfm">

      </div>

    </main>

    <!--- FOOTER --->

    <cfinclude template="includes/estrutura/footer.cfm"/>

</body>

</html>

