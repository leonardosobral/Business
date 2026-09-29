<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.rrMissingLanguage=listFirst(CGI.REQUEST_URI ?: "", "/")/>
<cfif listFind("en,es",URL.i18n_lang ?: "")><cfset VARIABLES.rrMissingLanguage=URL.i18n_lang/></cfif>
<cfset VARIABLES.rrMissingSuffix=listFind("en,es",VARIABLES.rrMissingLanguage) ? "-" & VARIABLES.rrMissingLanguage : ""/>
<cftry>
  <cfif NOT structKeyExists(REQUEST,"rrNotFoundLogged")>
    <cfset REQUEST.rrNotFoundLogged=true/>
    <cfset VARIABLES.rrMissingPath=CGI.REDIRECT_URL ?: ""/>
    <cfif NOT len(trim(VARIABLES.rrMissingPath))><cfset VARIABLES.rrMissingPath=URL.tag ?: (CGI.REQUEST_URI ?: "/404/")/></cfif>
    <cfset VARIABLES.rrMissingPath=left(listFirst(VARIABLES.rrMissingPath,"?"),1000)/>
    <cftry>
      <cfquery datasource="runnerhub" timeout="2">INSERT INTO tb_log(log_item,log_item_id,log_user,site) VALUES ('404',<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.rrMissingPath#"/>,'not-found','RR')</cfquery>
      <cfcatch type="any"><cftry><cflog file="roadrunners-errors" type="warning" text="not_found_log_unavailable"/><cfcatch type="any"></cfcatch></cftry></cfcatch>
    </cftry>
  </cfif>
  <cfcatch type="any"></cfcatch>
</cftry>
<cfheader statuscode="404" statustext="Not Found"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfcontent type="text/html; charset=utf-8" reset="true"/>
<cftry><cfoutput>#fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../../errors/404" & VARIABLES.rrMissingSuffix & ".html","utf-8")#</cfoutput><cfcatch type="any"><cfoutput><!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Road Runners</title><h1>Esse caminho não foi encontrado</h1><a href="/">Ir para o início</a></html></cfoutput></cfcatch></cftry>
