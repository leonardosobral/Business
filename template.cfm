<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- BACKEND --->

<cfinclude template="includes/backend/backend_login.cfm"/>

<!--- BACKEND --->

<cfinclude template="includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">


    <!--- HEADER --->

    <cfinclude template="includes/estrutura/header.cfm"/>

    <!--- CONTEUDO --->

    <main id="content" class="" style="margin-top: -55px;">

      <div class="container">

        <cfinclude template="home_logado.cfm">

      </div>

    </main>

    <!--- FOOTER --->

    <cfinclude template="includes/estrutura/footer.cfm"/>

</body>

</html>

