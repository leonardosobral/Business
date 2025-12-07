<!--- TEMPLATE --->
<cfset VARIABLES.template = "/admin/"/>

<!--- VARIAVEIS --->
<cfinclude template="includes/variaveis.cfm"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>
<cfinclude template="includes/backend/backend_evento_edicao.cfm"/>
<cfinclude template="includes/backend/backend.cfm"/>

<!--- FILTROS --->

<cfinclude template="filtro_resultados.cfm"/>


<!--- CONTEUDO --->

<div class="row">

    <cfif isDefined("URL.id_evento") and URL.id_evento NEQ 0>
        <cfinclude template="listagem_eventos.cfm"/>
    </cfif>

    <cfinclude template="form_edicao.cfm"/>

</div>
