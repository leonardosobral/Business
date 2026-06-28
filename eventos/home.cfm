<!--- TEMPLATE --->
<cfset VARIABLES.template = "/eventos/"/>

<!--- VARIAVEIS --->
<cfinclude template="includes/variaveis.cfm"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_evento_edicao.cfm"/>
<cfinclude template="includes/backend/backend_evento_solicitacoes.cfm"/>
<cfinclude template="includes/backend/backend.cfm"/>

<!--- FILTROS --->

<cfset VARIABLES.eventosShowOnboarding = false/>
<cfif isDefined("VARIABLES.adminRestrictByConta")
    AND VARIABLES.adminRestrictByConta
    AND isDefined("VARIABLES.adminEventosContaIds")
    AND VARIABLES.adminEventosContaIds EQ "0"
    AND NOT Len(trim(URL.id_evento))>
    <cfset VARIABLES.eventosShowOnboarding = true/>
</cfif>

<cfif VARIABLES.eventosShowOnboarding>
    <cfinclude template="onboarding_eventos.cfm"/>
</cfif>

<cfinclude template="solicitacoes_eventos.cfm"/>

<cfif NOT VARIABLES.eventosShowOnboarding>
    <cfinclude template="filtro_resultados.cfm"/>
</cfif>


<!--- CONTEUDO --->

<cfif NOT VARIABLES.eventosShowOnboarding>
<div class="row">

    <cfif isDefined("URL.id_evento") and URL.id_evento NEQ 0>
        <cfinclude template="listagem_eventos.cfm"/>
    </cfif>

    <cfinclude template="form_edicao.cfm"/>

</div>
</cfif>
