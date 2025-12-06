<!--- VARIAVEIS DA APLICACAO --->

<cfset VARIABLES.devMode = false/>

<!--- URL PARAMS --->

<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>

<cfparam name="URL.preset" default=""/>
<cfparam name="URL.periodo" default="2025"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.sessao" default="dados"/>

<cfparam name="URL.id_evento" default=""/>
<cfparam name="URL.agregador_tag" default=""/>
<cfparam name="URL.id_agrega_evento" default=""/>

<!--- DEV --->

<cfif CGI.HTTP_HOST CONTAINS 'dev.'>
    <cfset VARIABLES.devMode = true/>
</cfif>
