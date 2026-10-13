<cfcomponent output="false">
    <cfset THIS.name="BusinessChatConfigLoaderTest"/>
    <cffunction name="onRequestStart" returntype="boolean" output="false">
        <cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
        <cfreturn true/>
    </cffunction>
</cfcomponent>
