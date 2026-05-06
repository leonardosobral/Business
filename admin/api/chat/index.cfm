
<!--- Desliga debug na resposta --->
<cfsetting showdebugoutput="false">

<!--- Força retorno como JSON --->
<cfheader name="Content-Type" value="application/json; charset=utf-8">

<!--- Garante que a variável venha como numérica --->
<cfparam name="URL.id_usuario" type="numeric" default="0">

<!--- Busca o usuário --->
<cfquery name="qUsuario" cachedwithin="#CreateTimeSpan(0, 0, 1, 0)#">
    SELECT
    usr.name,
    usr.email,
    usr.ddd_usuario,
    usr.telefone_usuario
    FROM tb_usuarios usr
    WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_usuario#">
</cfquery>

<!--- Monta o struct de retorno --->
<cfset retorno = structNew()>

<cfif qUsuario.recordCount>
    <cfset retorno.id_found         = true>
    <cfset retorno.name             = qUsuario.name>
    <cfset retorno.email            = qUsuario.email>
    <cfset retorno.ddd_usuario      = qUsuario.ddd_usuario>
    <cfset retorno.telefone_usuario = qUsuario.telefone_usuario>
<cfelse>
    <cfset retorno.id_found         = false>
    <cfset retorno.name             = "">
    <cfset retorno.email            = "">
    <cfset retorno.ddd_usuario      = "">
    <cfset retorno.telefone_usuario = "">
</cfif>

<!--- Imprime o JSON --->
<cfoutput>#serializeJSON(retorno)#</cfoutput>
