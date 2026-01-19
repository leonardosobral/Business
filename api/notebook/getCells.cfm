<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
  <cfset notebookId = val(url.notebookId)>
  <cfif notebookId LTE 0>
    <cfthrow message="notebookId inválido">
  </cfif>

  <!--- TODO: Autorização do usuário aqui --->
  <!--- ex: if (!session.userId) throw --->

  <cfquery name="q" datasource="runner_dba">
    SELECT id, cell_order, cell_type, lang, content, updated_at
    FROM notebook_cells
    WHERE notebook_id = <cfqueryparam value="#notebookId#" cfsqltype="cf_sql_bigint">
    ORDER BY cell_order ASC, id ASC
  </cfquery>

  <cfset cells = []>
  <cfloop query="q">
    <cfset arrayAppend(cells, {
      "id" = q.id,
      "order" = q.cell_order,
      "cell_type" = q.cell_type,
      "lang" = q.lang,
      "content" = q.content,
      "updated_at" = dateTimeFormat(q.updated_at, "yyyy-mm-dd'T'HH:nn:ss")
    })>
  </cfloop>

  <cfoutput>#serializeJson({ "ok"=true, "notebookId"=notebookId, "cells"=cells })#</cfoutput>

  <cfcatch>
    <cfoutput>#serializeJson({ "ok"=false, "error"=cfcatch.message, "detail"=cfcatch.detail })#</cfoutput>
  </cfcatch>
</cftry>
