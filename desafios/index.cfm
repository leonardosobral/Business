<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMA --->

<cfset VARIABLES.theme = "dark"/>

<!--- TEMPLATE --->

<cfset VARIABLES.template = "/desafios/"/>

<!--- BACKEND --->

<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfparam name="URL.desafio" default="todosantodia"/>
<cfset VARIABLES.challengeAccessTag = lcase(trim(replace(URL.desafio, "/", "")))/>
<cfif listFindNoCase("catarinensecorridaderua,catarinensetrailrun", VARIABLES.challengeAccessTag)>
    <cfinclude template="../includes/backend/require_catarinense_challenge_access.cfm"/>
<cfelse>
    <cfinclude template="../includes/backend/require_admin.cfm"/>
</cfif>

<!--- HEAD --->

<cfinclude template="../includes/estrutura/head.cfm"/>

<!--- CONTEUDO --->

<body data-mdb-theme="dark" class="bg-dark-subtle">


    <!--- HEADER --->

    <cfinclude template="../includes/estrutura/header.cfm"/>

    <!--- CONTEUDO --->

    <main class="" style="margin-top: -80px;">

      <div class="px-2">

        <cfinclude template="home.cfm">

      </div>

    </main>

    <cfinclude template="includes/query_debug_bar.cfm"/>

    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>

</body>

</html>
