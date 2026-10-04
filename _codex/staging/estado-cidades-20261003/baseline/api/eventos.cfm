<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<cfif len(trim(URL.tag))>
    <cfset VARIABLES.template = "/estado/"/>
</cfif>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfif NOT len(trim(URL.tag))
    AND NOT (structKeyExists(URL, "context_uf") AND len(trim(URL.context_uf)))
    AND NOT (structKeyExists(URL, "cidade") AND len(trim(URL.cidade)))>
    <cfinclude template="../includes/location.cfm"/>
</cfif>
<cfinclude template="../includes/backend/backend.cfm"/>

<cfset VARIABLES.qEventosAba = qEventos/>

<cfinclude template="../includes/lista_de_eventos_simple.cfm"/>
