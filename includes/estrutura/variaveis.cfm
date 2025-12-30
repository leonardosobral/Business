<!--- VARIAVEIS DA APLICACAO --->

<cfset VARIABLES.queryString = ""/>
<cfset VARIABLES.queryString = replace(VARIABLES.queryString, "&", "?")/>
<cfset VARIABLES.pageSize = 50/>
<cfset VARIABLES.agrupamento = "default"/>
<cfset VARIABLES.devMode = false/>
<cfset VARIABLES.codPagina = ""/>
<cfset VARIABLES.loginAutoPrompt = "true"/>
<cfset VARIABLES.chave_pagarme = tobase64('sk_2501474de4d64171be553a65cec7372b:')/>
<cfset VARIABLES.cidade = ""/>
<cfset VARIABLES.estado = ""/>
<cfset VARIABLES.uf = ""/>
<cfset VARIABLES.pais = ""/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/"/>

<!--- URL PARAMS --->

<cfparam name="URL.distancia" default="1,42"/>
<cfparam name="URL.tempo" default="0,12"/>
<cfparam name="URL.filtro" default=""/>
<cfparam name="URL.badges" default=""/>
<cfparam name="URL.rua" default="true"/>
<cfparam name="URL.trail" default="true"/>
<cfparam name="URL.nacional" default="true"/>
<cfparam name="URL.internacional" default="false"/>
<cfparam name="URL.cupom" default="false"/>

<!--- DEV --->
<cfif CGI.HTTP_HOST CONTAINS 'dev.'>
    <cfset VARIABLES.devMode = true/>
</cfif>
