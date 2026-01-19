<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
  <cfset raw = toString(getHttpRequestData().content)>
  <cfif !len(trim(raw))><cfthrow message="Body vazio"></cfif>
  <cfset payload = deserializeJson(raw)>

  <cfset notebookId = val(payload.notebookId)>
  <cfset cellId     = val(payload.cellId)>

  <cfif notebookId LTE 0><cfthrow message="notebookId inválido"></cfif>
  <cfif cellId LTE 0><cfthrow message="cellId inválido"></cfif>

  <!--- TODO: Autorização do usuário aqui --->

  <cfquery name="qDel" datasource="runner_dba">
    DELETE FROM notebook_cells
    WHERE
      id = <cfqueryparam value="#cellId#" cfsqltype="cf_sql_bigint">
      AND notebook_id = <cfqueryparam value="#notebookId#" cfsqltype="cf_sql_bigint">
  </cfquery>

  <cfoutput>#serializeJson({ "ok"=true })#</cfoutput>

  <cfcatch>
    <cfoutput>#serializeJson({ "ok"=false, "error"=cfcatch.message, "detail"=cfcatch.detail })#</cfoutput>
  </cfcatch>
</cftry>
