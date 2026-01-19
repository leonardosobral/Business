<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
  <cfset raw = toString(getHttpRequestData().content)>
  <cfif !len(trim(raw))><cfthrow message="Body vazio"></cfif>
  <cfset payload = deserializeJson(raw)>

  <cfset notebookId = val(payload.notebookId)>
  <cfset cellType   = trim(payload.type)>
  <cfset lang       = structKeyExists(payload,"lang") ? lcase(trim(payload.lang)) : "">
  <cfset content    = structKeyExists(payload,"content") ? payload.content : "">

  <cfif notebookId LTE 0><cfthrow message="notebookId inválido"></cfif>
  <cfif !len(cellType)><cfthrow message="type obrigatório"></cfif>
  <cfif cellType NEQ "markdown" AND cellType NEQ "code">
    <cfthrow message="type inválido">
  </cfif>

  <!--- TODO: Autorização do usuário aqui (session.userId etc.) --->

  <!--- pega próxima ordem --->
  <cfquery name="qMax" datasource="runner_dba">
    SELECT COALESCE(MAX(cell_order), 0) AS max_order
    FROM notebook_cells
    WHERE notebook_id = <cfqueryparam value="#notebookId#" cfsqltype="cf_sql_bigint">
  </cfquery>
  <cfset nextOrder = qMax.max_order + 1>

  <!--- ÚNICO INSERT (com RETURNING) --->
  <cfquery name="qRet" datasource="runner_dba">
    INSERT INTO notebook_cells (notebook_id, cell_order, cell_type, lang, content, updated_at)
    VALUES (
      <cfqueryparam value="#notebookId#" cfsqltype="cf_sql_bigint">,
      <cfqueryparam value="#nextOrder#" cfsqltype="cf_sql_integer">,
      <cfqueryparam value="#cellType#" cfsqltype="cf_sql_varchar">,
      <cfqueryparam value="#lang#" cfsqltype="cf_sql_varchar">,
      <cfqueryparam value="#content#" cfsqltype="cf_sql_longvarchar">,
      now()
    )
    RETURNING id, cell_order, cell_type, lang, content, updated_at
  </cfquery>

  <cfset cell = {
    "id" = qRet.id,
    "order" = qRet.cell_order,
    "cell_type" = qRet.cell_type,
    "lang" = qRet.lang,
    "content" = qRet.content,
    "updated_at" = dateTimeFormat(qRet.updated_at, "yyyy-mm-dd'T'HH:nn:ss")
  }>

  <cfoutput>#serializeJson({ "ok"=true, "cell"=cell })#</cfoutput>

  <cfcatch>
    <cfoutput>#serializeJson({ "ok"=false, "error"=cfcatch.message, "detail"=cfcatch.detail })#</cfoutput>
  </cfcatch>
</cftry>
