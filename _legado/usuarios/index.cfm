<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMA --->

<cfset VARIABLES.theme = "dark"/>

<!--- TEMPLATE --->

<cfset VARIABLES.template = "/usuarios/"/>

<!--- BACKEND --->

<cfinclude template="../includes/backend/backend_login.cfm"/>

<cfif (isDefined("VARIABLES.businessAccountSimulationActive") AND VARIABLES.businessAccountSimulationActive)
    OR (
        isDefined("VARIABLES.businessEffectiveAccountIds")
        AND len(trim(VARIABLES.businessEffectiveAccountIds))
        AND VARIABLES.businessEffectiveAccountIds NEQ "0"
        AND NOT (isDefined("VARIABLES.businessRealIsAdmin") AND VARIABLES.businessRealIsAdmin)
    )>
    <cflocation addtoken="false" url="/administracao/contas/"/>
</cfif>

<cfinclude template="../includes/backend/require_admin.cfm"/>

<!--- HEAD --->

<cfinclude template="../includes/estrutura/head.cfm"/>

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
