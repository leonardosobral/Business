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

<cfset VARIABLES.businessAccountModalForcedRedirect = "/"/>
<cfif isDefined("URL.redirect")>
  <cfset VARIABLES.businessAccountSelectionRequestedRedirect = trim(URL.redirect & "")/>
  <cfif len(VARIABLES.businessAccountSelectionRequestedRedirect)
      AND left(VARIABLES.businessAccountSelectionRequestedRedirect, 1) EQ "/"
      AND left(VARIABLES.businessAccountSelectionRequestedRedirect, 2) NEQ "//"
      AND NOT find("\", VARIABLES.businessAccountSelectionRequestedRedirect)
      AND NOT find(chr(10), VARIABLES.businessAccountSelectionRequestedRedirect)
      AND NOT find(chr(13), VARIABLES.businessAccountSelectionRequestedRedirect)
      AND NOT findNoCase("/selecionar-conta/", VARIABLES.businessAccountSelectionRequestedRedirect)>
    <cfset VARIABLES.businessAccountModalForcedRedirect = VARIABLES.businessAccountSelectionRequestedRedirect/>
  </cfif>
</cfif>

<cfinclude template="../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
  <main class="min-vh-100"></main>
  <cfset VARIABLES.businessAccountModalRequired = true/>
  <cfinclude template="../includes/estrutura/account_context_modal.cfm"/>
  <cfinclude template="../includes/estrutura/footer.cfm"/>
</body>
</html>
