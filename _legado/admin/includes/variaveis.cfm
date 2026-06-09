<!--- VARIAVEIS DA APLICACAO --->

<cfset VARIABLES.devMode = false/>
<cfset VARIABLES.adminIsAdmin = false/>

<cfif isDefined("VARIABLES.businessEffectiveIsAdmin")>
    <cfset VARIABLES.adminIsAdmin = VARIABLES.businessEffectiveIsAdmin/>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin") AND qPerfil.is_admin>
    <cfset VARIABLES.adminIsAdmin = true/>
</cfif>

<!--- URL PARAMS --->

<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>

<cfparam name="URL.preset" default=""/>
<cfif NOT structKeyExists(URL, "periodo")>
    <cfif VARIABLES.adminIsAdmin>
        <cfset URL.periodo = "2026"/>
    <cfelse>
        <cfset URL.periodo = ""/>
    </cfif>
</cfif>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.sessao" default="dados"/>

<cfif NOT VARIABLES.adminIsAdmin AND listFindNoCase("configuracoes,or", URL.sessao)>
    <cfset URL.sessao = "dados"/>
</cfif>

<cfparam name="URL.id_evento" default=""/>
<cfparam name="URL.agregador_tag" default=""/>
<cfparam name="URL.id_agrega_evento" default=""/>

<!--- DEV --->

<cfif CGI.HTTP_HOST CONTAINS 'dev.'>
    <cfset VARIABLES.devMode = true/>
</cfif>
