<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
  <cfset raw = toString(getHttpRequestData().content)>
  <cfif !len(trim(raw))><cfthrow message="Body vazio"></cfif>
  <cfset payload = deserializeJson(raw)>

  <cfset notebookId = val(payload.notebookId)>
  <cfif notebookId LTE 0><cfthrow message="notebookId inválido"></cfif>

  <cfif !structKeyExists(payload,"orderedCellIds") OR !isArray(payload.orderedCellIds)>
    <cfthrow message="orderedCellIds inválido">
  </cfif>

  <!--- TODO: Autorização do usuário aqui --->

  <!--- Transação para consistência --->
  <cftransaction>
    <cfloop from="1" to="#arrayLen(payload.orderedCellIds)#" index="i">
      <cfset cellId = val(payload.orderedCellIds[i])>
      <cfif cellId LTE 0><cfthrow message="cellId inválido na lista"></cfif>

      <cfquery name="qUpdOrder" datasource="runner_dba">
        UPDATE notebook_cells
        SET cell_order = <cfqueryparam value="#i#" cfsqltype="cf_sql_integer">
        WHERE
          id = <cfqueryparam value="#cellId#" cfsqltype="cf_sql_bigint">
          AND notebook_id = <cfqueryparam value="#notebookId#" cfsqltype="cf_sql_bigint">
      </cfquery>
    </cfloop>
  </cftransaction>

  <cfoutput>#serializeJson({ "ok"=true })#</cfoutput>

  <cfcatch>
    <cfoutput>#serializeJson({ "ok"=false, "error"=cfcatch.message, "detail"=cfcatch.detail })#</cfoutput>
  </cfcatch>
</cftry>
