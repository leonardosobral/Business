<!DOCTYPE html>
<html lang="pt-br">
<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/selecionar-conta/"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount>
  <cflocation addtoken="false" url="/"/>
</cfif>
<cfif NOT isDefined("VARIABLES.businessAccountSelectionRequired") OR NOT VARIABLES.businessAccountSelectionRequired>
  <cflocation addtoken="false" url="/"/>
</cfif>

<cfinclude template="../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
  <main class="min-vh-100"></main>
  <cfset VARIABLES.businessAccountModalRequired = true/>
  <cfinclude template="../includes/estrutura/account_context_modal.cfm"/>
  <cfinclude template="../includes/estrutura/footer.cfm"/>
</body>
</html>
