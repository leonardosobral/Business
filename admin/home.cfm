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

    <cfinclude template="listagem_eventos.cfm"/>

    <cfinclude template="form_edicao.cfm"/>

</div>
