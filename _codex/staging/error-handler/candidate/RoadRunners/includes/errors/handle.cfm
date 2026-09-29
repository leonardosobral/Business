<cfif NOT isDefined("ARGUMENTS.exception")><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false"/>
<cfset LOCAL.rrId=""/>
<cfset LOCAL.rrLanguage=listFirst(CGI.REQUEST_URI ?: "", "/")/>
<cfif listFind("en,es",URL.i18n_lang ?: "")><cfset LOCAL.rrLanguage=URL.i18n_lang/></cfif>
<cfset LOCAL.rrLanguageSuffix=listFind("en,es",LOCAL.rrLanguage) ? "-" & LOCAL.rrLanguage : ""/>
<cfset LOCAL.rrJson=false/>
<cftry>
  <cfset LOCAL.rrJson=reFindNoCase("^/(api|public-api)(/|$)",CGI.script_name) GT 0 OR findNoCase("application/json",CGI.http_accept ?: "") GT 0/>
  <cfset LOCAL.rrId=lCase(createUUID())/>
  <cfif NOT structKeyExists(REQUEST,"rrHandlingError")>
    <cfset REQUEST.rrHandlingError=true/>
    <cfset LOCAL.rrReporter=new services.ErrorReporter()/>
    <cfset LOCAL.rrEvent=LOCAL.rrReporter.describe(ARGUMENTS.exception,ARGUMENTS.eventname,CGI.server_name,CGI.script_name,LOCAL.rrId,LOCAL.rrSite)/>
    <cfset LOCAL.rrEvent.notify=LOCAL.rrEvent.notify AND LOCAL.rrAllowAlert/>
    <cfset LOCAL.rrEvent.alert={allowed=false,reason="limiter_unavailable",occurrences=1}/>
    <cftry><cfset LOCAL.rrEvent.alert=LOCAL.rrReporter.reserveAlert(LOCAL.rrEvent)/><cfcatch type="any"></cfcatch></cftry>
    <cfset LOCAL.rrLogId=0/>
    <cftry>
      <cfset LOCAL.rrLogId=LOCAL.rrReporter.writeDatabase(LOCAL.rrEvent)/>
      <cfcatch type="any"><cftry><cfset LOCAL.rrReporter.writeLocal(LOCAL.rrEvent)/><cfcatch type="any"></cfcatch></cftry></cfcatch>
    </cftry>
    <cfif LOCAL.rrEvent.alert.allowed>
      <cftry><cfinclude template="notify.cfm"/><cfcatch type="any"><cftry><cfset LOCAL.rrReporter.writeLocal(LOCAL.rrEvent,"notification_enqueue_failed")/><cfcatch type="any"></cfcatch></cftry></cfcatch></cftry>
    </cfif>
  </cfif>
  <cfcatch type="any"><!--- Reporting is best effort; response below is independent. ---></cfcatch>
</cftry>
<cfheader statuscode="500" statustext="Internal Server Error"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfif len(LOCAL.rrId)><cfheader name="X-Request-ID" value="#LOCAL.rrId#"/></cfif>
<cfif LOCAL.rrJson>
  <cfcontent type="application/json; charset=utf-8" reset="true"/><cfoutput>#serializeJSON({success=false,error="internal_error",message="Não foi possível concluir a solicitação. Tente novamente em instantes.",request_id=LOCAL.rrId})#</cfoutput>
<cfelse>
  <cfcontent type="text/html; charset=utf-8" reset="true"/>
  <cftry>
    <cfset LOCAL.rrPage=fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../../errors/500" & LOCAL.rrLanguageSuffix & ".html","utf-8")/>
    <cfoutput>#replace(LOCAL.rrPage,"<!--REFERENCE-->",'<p class="reference">Referência: ' & encodeForHTML(LOCAL.rrId) & '</p>')#</cfoutput>
    <cfcatch type="any"><cfoutput><!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Road Runners</title><h1>Uma pausa no percurso</h1><p>Tente novamente em instantes.</p><a href="/">Ir para o início</a></html></cfoutput></cfcatch>
  </cftry>
</cfif>
