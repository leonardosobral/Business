<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/estado/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<cfif NOT listFindNoCase("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO",URL.tag)>
    <cfheader statuscode="404" statustext="Not Found"/><cfcontent type="text/plain; charset=utf-8" reset="true"/>Estado não encontrado.<cfabort/>
</cfif>

<!--- BACKEND --->
<cfinclude template="../includes/variaveis.cfm"/>
<cfinclude template="../includes/backend.cfm"/>
<cfinclude template="../includes/backend_estado_cidades.cfm"/>

<cfset qEventosAba = qEventos/>
<cfset VARIABLES.qEventosAba = qEventosAba/>
<cfset VARIABLES.eventMonthDividerFormat = "mmmm yyyy"/>
<cfset VARIABLES.eventCardColumnClass = "col-12 mb-1"/>
<cfset VARIABLES.eventListRenderItemsOnly = true/>

<script>totalEventos = <cfoutput>#qEventos.recordcount#</cfoutput>;</script>
<cfinclude template="../includes/lista_de_eventos_simple.cfm"/>
