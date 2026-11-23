<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMA --->

<cfset VARIABLES.theme = "dark"/>

<!--- TEMPLATE --->

<cfset VARIABLES.template = "/eventos/"/>

<!--- BACKEND --->

<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- Processar ações antes de enviar o HTML: o cabeçalho pode esgotar o buffer e impedir os redirecionamentos. --->
<cfinclude template="includes/variaveis.cfm"/>
<cftry>
<cfinclude template="includes/backend/backend_evento_edicao.cfm"/>
<cfinclude template="includes/backend/backend_evento_solicitacoes.cfm"/>
<cfinclude template="includes/backend/backend.cfm"/>
    <cfcatch type="BusinessDelegation">
        <cfset VARIABLES.eventDelegationStatus=403/>
        <cfif cfcatch.type EQ "BusinessDelegation.NotFound"><cfset VARIABLES.eventDelegationStatus=404/></cfif>
        <cfif cfcatch.type EQ "BusinessDelegation.Conflict"><cfset VARIABLES.eventDelegationStatus=409/></cfif>
        <cfif cfcatch.type EQ "BusinessDelegation.Validation"><cfset VARIABLES.eventDelegationStatus=400/></cfif>
        <cfif cfcatch.type EQ "BusinessDelegation.Unavailable"><cfset VARIABLES.eventDelegationStatus=503/></cfif>
        <cfheader statuscode="#VARIABLES.eventDelegationStatus#"/>
        <cfheader name="Cache-Control" value="no-store"/>
        <cfif cfcatch.type EQ "BusinessDelegation.Validation" AND structKeyExists(cfcatch,"errorCode") AND cfcatch.errorCode EQ "event_location">
            <cfset VARIABLES.eventLocationErrorMessage=cfcatch.message><cfset VARIABLES.eventLocationErrorEventId=structKeyExists(FORM,"id_evento") AND isSimpleValue(FORM.id_evento) ? FORM.id_evento : "">
            <cfinclude template="includes/event_location_error.cfm">
        <cfelse><cfoutput>#encodeForHTML("Não foi possível realizar esta operação. Reabra o evento e confira seu acesso.")#</cfoutput></cfif>
        <cfabort/>
    </cfcatch>
</cftry>

<!DOCTYPE html>
<html lang="pt-br">

<!--- HEAD --->

<cfinclude template="../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">

    <link rel="stylesheet" href="/eventos/assets/events-workspace.css?v=20261117-1"/>

    <!--- HEADER --->

    <cfinclude template="../includes/estrutura/header.cfm"/>

    <!--- CONTEUDO --->

    <main class="events-page" style="margin-top: -55px;">

      <div class="container-fluid px-4">

        <cfinclude template="../includes/estrutura/pending_workspace_return.cfm">

        <cfinclude template="home.cfm">

      </div>

    </main>

    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>

</body>

</html>
