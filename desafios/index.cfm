<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- BACKEND --->

<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- HEAD --->

<cfinclude template="../includes/estrutura/head.cfm"/>

<!--- CONTEUDO --->

<body data-mdb-theme="dark" class="bg-dark-subtle">


    <!--- HEADER --->

    <cfinclude template="../includes/estrutura/header.cfm"/>

    <!--- CONTEUDO --->

    <main class="" style="margin-top: -55px;">

      <div class="container px-4">

        <cfinclude template="home.cfm">

      </div>

    </main>

    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>

</body>

</html>

