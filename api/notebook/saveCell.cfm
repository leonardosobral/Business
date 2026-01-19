<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
  <cfset raw = toString(getHttpRequestData().content)>
  <cfif !len(trim(raw))><cfthrow message="Body vazio"></cfif>
  <cfset payload = deserializeJson(raw)>

  <cfset notebookId = val(payload.notebookId)>
  <cfset cellId     = val(payload.cellId)>
  <cfset cellType   = trim(payload.type)>
  <cfset lang       = structKeyExists(payload,"lang") ? lcase(trim(payload.lang)) : "">
  <cfset content    = structKeyExists(payload,"content") ? payload.content : "">

  <cfif notebookId LTE 0><cfthrow message="notebookId inválido"></cfif>
  <cfif cellId LTE 0><cfthrow message="cellId inválido"></cfif>
  <cfif !len(cellType)><cfthrow message="type obrigatório"></cfif>

  <!--- TODO: Autorização do usuário aqui --->

  <!--- Garante que a célula pertence ao notebook --->
  <cfquery name="qUpd" datasource="runner_dba">
    UPDATE notebook_cells
    SET
      cell_type = <cfqueryparam value="#cellType#" cfsqltype="cf_sql_varchar">,
      lang      = <cfqueryparam value="#lang#" cfsqltype="cf_sql_varchar">,
      content   = <cfqueryparam value="#content#" cfsqltype="cf_sql_longvarchar">,
      updated_at = now()
    WHERE
      id = <cfqueryparam value="#cellId#" cfsqltype="cf_sql_bigint">
      AND notebook_id = <cfqueryparam value="#notebookId#" cfsqltype="cf_sql_bigint">
  </cfquery>

  <cfoutput>#serializeJson({ "ok"=true })#</cfoutput>

  <cfcatch>
    <cfoutput>#serializeJson({ "ok"=false, "error"=cfcatch.message, "detail"=cfcatch.detail })#</cfoutput>
  </cfcatch>
</cftry>
