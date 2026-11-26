<cfset REQUEST.businessAuthenticatedActor=duplicate(REQUEST.businessIdentity)/>
<cfif CGI.script_name EQ "/logout.cfm" AND structKeyExists(SESSION,"businessSupportSession")>
    <cftry>
        <cflock scope="session" type="exclusive" timeout="10"><cfset new services.BusinessSupportSession().logout(SESSION,{reason="logout",method=CGI.request_method,path=CGI.script_name,ip=CGI.remote_addr,agent=CGI.http_user_agent})/></cflock>
        <cfcatch type="any"><cflog file="business_auth" type="warning" text="Business support logout audit unavailable; logout continues"/></cfcatch>
    </cftry>
</cfif>
<cfif structKeyExists(SESSION,"businessSupportSession")>
    <cftry>
        <cfset REQUEST.businessSupportService=new services.BusinessSupportSession()/>
        <cfset REQUEST.businessSupportMeta={method=CGI.request_method,path=CGI.script_name,ip=CGI.remote_addr,agent=CGI.http_user_agent}/>
        <cflock scope="session" type="exclusive" timeout="10">
            <cfset REQUEST.businessSupportContext=REQUEST.businessSupportService.current(SESSION,REQUEST.businessAuthenticatedActor,REQUEST.businessSupportMeta)/>
            <cfif NOT structIsEmpty(REQUEST.businessSupportContext) AND NOT REQUEST.businessSupportContext.ended>
                <cfset REQUEST.businessIdentity=duplicate(REQUEST.businessSupportContext.identity)/>
                <cfset REQUEST.businessSupportService.recordRequest(SESSION,REQUEST.businessSupportMeta)/>
            </cfif>
        </cflock>
        <cfheader name="Cache-Control" value="private, no-store"/>
        <cfif NOT structIsEmpty(REQUEST.businessSupportContext) AND REQUEST.businessSupportContext.ended>
            <cfset sessionRotate()/>
            <!--- Never replay an expired support POST with the operator's privileges. --->
            <cfheader statuscode="409"/><cfcontent type="text/html; charset=utf-8" reset="true"/>
            <cfoutput><p>A sessão de suporte terminou. Nenhuma ação desta solicitação foi executada. <a href="/suporte/acesso/">Continuar</a></p></cfoutput><cfabort/>
        </cfif>
        <cfcatch type="any">
            <cflog file="business_auth" type="error" text="Business support request rejected: #cfcatch.type#"/>
            <cfheader statuscode="403"/><cfcontent type="text/html; charset=utf-8" reset="true"/>
            <cfoutput><p>Não foi possível validar a sessão de suporte. <a href="/logout.cfm">Sair</a></p></cfoutput><cfabort/>
        </cfcatch>
    </cftry>
</cfif>
