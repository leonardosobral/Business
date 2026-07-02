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

<cfset VARIABLES.eventosShowRequestPanel = true/>
<cfset VARIABLES.eventosRequestPanelCollapsed = false/>
<cfif NOT VARIABLES.eventosShowOnboarding
    AND VARIABLES.eventoSolicitacaoCanReview
    AND NOT VARIABLES.eventoSolicitacaoCanRequest
    AND VARIABLES.eventoSolicitacaoTablesReady
    AND qEventoSolicitacoesPendentes.recordcount EQ 0
    AND NOT len(trim(VARIABLES.eventoSolicitacaoNoticeMessage))
    AND NOT len(trim(VARIABLES.eventoSolicitacaoErrorMessage))>
    <cfset VARIABLES.eventosShowRequestPanel = false/>
</cfif>
<cfif VARIABLES.eventosShowOnboarding
    AND NOT len(trim(VARIABLES.eventoSolicitacaoReferencia))
    AND NOT len(trim(VARIABLES.eventoSolicitacaoNoticeMessage))
    AND NOT len(trim(VARIABLES.eventoSolicitacaoErrorMessage))
    AND NOT (VARIABLES.eventoSolicitacaoCanReview AND qEventoSolicitacoesPendentes.recordcount GT 0)
    AND qEventoMinhasSolicitacoes.recordcount EQ 0>
    <cfset VARIABLES.eventosShowRequestPanel = false/>
</cfif>
<cfif VARIABLES.eventosShowRequestPanel
    AND NOT VARIABLES.eventosShowOnboarding
    AND VARIABLES.eventoSolicitacaoCanRequest
    AND qEventos.recordcount GT 0
    AND NOT len(trim(VARIABLES.eventoSolicitacaoReferencia))
    AND NOT len(trim(VARIABLES.eventoSolicitacaoNoticeMessage))
    AND NOT len(trim(VARIABLES.eventoSolicitacaoErrorMessage))
    AND VARIABLES.eventoMinhasSolicitacoesPendentes EQ 0>
    <cfset VARIABLES.eventosRequestPanelCollapsed = true/>
</cfif>

<cfif VARIABLES.eventosShowOnboarding>
    <cfinclude template="onboarding_eventos.cfm"/>
</cfif>

<cfif VARIABLES.eventosShowRequestPanel>
    <cfinclude template="solicitacoes_eventos.cfm"/>
</cfif>
<cfinclude template="guia_cliente_eventos.cfm"/>

<cfif NOT VARIABLES.eventosShowOnboarding>
    <cfinclude template="filtro_resultados.cfm"/>
</cfif>


<!--- CONTEUDO --->

<cfif NOT VARIABLES.eventosShowOnboarding>
<div class="row">

    <cfif NOT (Len(trim(URL.id_evento)) AND isNumeric(URL.id_evento) AND val(URL.id_evento) EQ 0)>
        <cfinclude template="listagem_eventos.cfm"/>
    </cfif>

    <cfinclude template="form_edicao.cfm"/>

</div>
</cfif>
