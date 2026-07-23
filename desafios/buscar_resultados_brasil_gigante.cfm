<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>

<!--- Endpoint fisico para evitar que a rota amigavel do desafio intercepte a resposta JSON. --->
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/require_brasil_gigante_challenge_access.cfm"/>

<cfset URL.desafio = "circuitobrasilgigante"/>
<cfset URL.tela = "validacoes"/>
<cfset URL.cbg_result_search = "1"/>
<cfset VARIABLES.desafiosQueryDebugEnabled = false/>

<cfinclude template="includes/backend.cfm"/>

<!--- A busca sempre encerra dentro do backend; esta resposta cobre apenas falhas de fluxo. --->
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfheader statuscode="500" statustext="Internal Server Error"/>
<cfoutput>#serializeJSON({success=false, results=[], message="A busca nao foi inicializada."})#</cfoutput>
