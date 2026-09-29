<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.template="/portal/erros/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfif CGI.request_method NEQ "POST" OR NOT structKeyExists(SESSION,"errorTriageCsrf") OR NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.errorTriageCsrf) NEQ 0><cfcontent reset="true"/><cfheader statuscode="403"/><cfoutput>Sessão expirada. Recarregue a página.</cfoutput><cfabort/></cfif>
<cftry>
  <cfset service=new portal.erros.includes.ErrorTriage().init()/>
  <cfif NOT service.ready()><cfthrow type="Triage.Validation" message="Acompanhamento indisponível."/></cfif>
  <cfset packet=service.exportProblems(listToArray(FORM.ids ?: ""))/>
  <cfheader name="Content-Disposition" value='attachment; filename="problemas-para-codex.json"'/>
  <cfcontent type="application/json; charset=utf-8" reset="true"/><cfoutput>#serializeJSON(packet)#</cfoutput>
  <cfcatch type="Triage.Validation"><cfheader statuscode="400"/><cfcontent type="text/plain; charset=utf-8" reset="true"/><cfoutput>#cfcatch.message#</cfoutput></cfcatch>
  <cfcatch type="any"><cfheader statuscode="503"/><cfcontent type="text/plain; charset=utf-8" reset="true"/><cfoutput>Não foi possível gerar o pacote. Tente novamente.</cfoutput></cfcatch>
</cftry>
