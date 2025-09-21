<cfcomponent
        displayname="Application"
        output="true"
        hint="Handle the application.">


    <!--- Set up the application. --->
    <cfset THIS.Name = "RunnerHubBusiness" />
    <cfset THIS.ApplicationTimeout = CreateTimeSpan( 2, 0, 0, 0 ) />
    <cfset THIS.SessionManagement = true />
    <cfset THIS.SetClientCookies = true />
    <cfset THIS.SearchImplicitScopes = true />
    <cfset this.SessionTimeout = createTimeSpan( 0, 0, 50, 0 ) />
    <cfset THIS.datasource = "runner_dba"/>
    <cfset oldlocale = SetLocale("Portuguese (Brazilian)")>


    <!--- Define the page request properties. --->
    <cfsetting
            requesttimeout="20"
            showdebugoutput="false"
            enablecfoutputonly="false"
            />


    <cffunction
            name="OnApplicationStart"
            access="public"
            returntype="boolean"
            output="false"
            hint="Fires when the application is first created.">

        <!--- APPLICATION VARIABLES --->
        <cfset APPLICATION.codSite = "RH"/>
        <cfset APPLICATION.nomeSite = "Runner Hub"/>
        <cfset APPLICATION.dominio = "runnerhub.run"/>
        <cfset APPLICATION.baseCanonica = "https://runnerhub.run"/>
        <cfset APPLICATION.ga = ""/>

        <!--- Return out. --->
        <cfreturn true />
    </cffunction>


    <cffunction
            name="OnSessionStart"
            access="public"
            returntype="void"
            output="false"
            hint="Fires when the session is first created.">

<!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnRequestStart"
            access="public"
            returntype="boolean"
            output="false"
            hint="Fires at first part of page processing.">

        <!--- Define arguments. --->
        <cfargument
                name="TargetPage"
                type="string"
                required="true"
                />

        <cfif IsDefined("url.resetApp")>
          <cfset ApplicationStop()>
          <cfabort><!--- or, if you like, <cflocation url="index.cfm"> --->
        </cfif>

        <!---cftry>
            <cfquery>
                INSERT INTO webtumtum.logs
                (texto, tag, tipo, session_id, user_id)
                VALUES
                (<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.script_name#"/>,
                <cfif isDefined("URL.tag")>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#Replace(cgi.script_name, 'index.cfm', '')##URL.tag#"/>,
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#Replace(cgi.script_name, 'index.cfm', '')#"/>,
                </cfif>
                'acesso',
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#SESSION.SESSIONID#"/>,
                <cfif isDefined("COOKIE.id_usuario") and len(trim(COOKIE.id_usuario)) AND isDefined("COOKIE.is_admin") and len(trim(COOKIE.is_admin))>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id_usuario#"/>
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value=""/>
                </cfif>)
            </cfquery>
        <cfcatch type="any">
            <cfquery>
                INSERT INTO webtumtum.logs
                (texto, tipo)
                VALUES
                (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.TargetPage#"/>,
                'erro'
                )
            </cfquery>
        </cfcatch>
        </cftry--->

        <!--- Return out. --->
        <cfreturn true />
    </cffunction>


    <cffunction
            name="OnRequest"
            access="public"
            returntype="void"
            output="true"
            hint="Fires after pre page processing is complete.">

<!--- Define arguments. --->
        <cfargument
                name="TargetPage"
                type="string"
                required="true"
                />

<!--- Include the requested page. --->
        <cfinclude template="#ARGUMENTS.TargetPage#" />

<!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnRequestEnd"
            access="public"
            returntype="void"
            output="true"
            hint="Fires after the page processing is complete.">

<!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnSessionEnd"
            access="public"
            returntype="void"
            output="false"
            hint="Fires when the session is terminated.">

<!--- Define arguments. --->
        <cfargument
                name="SessionScope"
                type="struct"
                required="true"
                />

        <cfargument
                name="ApplicationScope"
                type="struct"
                required="false"
                default="#StructNew()#"
                />

<!--- Return out. --->
        <cfreturn />
    </cffunction>


    <cffunction
            name="OnApplicationEnd"
            access="public"
            returntype="void"
            output="false"
            hint="Fires when the application is terminated.">

<!--- Define arguments. --->
        <cfargument
                name="ApplicationScope"
                type="struct"
                required="false"
                default="#StructNew()#"
                />

<!--- Return out. --->
        <cfreturn />
    </cffunction>


    <!---cffunction
            name="OnError"
            access="public"
            returntype="void"
            output="true"
            hint="Fires when an exception occures that is not caught by a try/catch.">

        <!--- Define arguments. --->
        <cfargument name="exception" required="true">
        <cfargument name="eventname" type="string" required="true">
        <cfset var errortext = "">

        <cfif NOT isDefined("URL.debug")>

            <cfsavecontent variable="errortext">
                <cfoutput>
                    An error occurred: http://#cgi.server_name##cgi.script_name#?#cgi.query_string#<br />
                Time: #dateFormat(now(), "short")# #timeFormat(now(), "short")#<br />

                    <cfdump var="#arguments.exception#" label="Error">
                    <cfdump var="#form#" label="Form">
                    <cfdump var="#url#" label="URL">

                </cfoutput>
            </cfsavecontent>

            <cfmail from="Site Tum Tum <contato@projetocaua.org>" to="leonardo.sobral@gmail.com"
                    cc="pimenta.carlospimenta@gmail.com"
                    subject="Erro no site TumTum: #arguments.exception.message#" usetls="true"
                    server="smtp.gmail.com" username="contato@projetocaua.com" password="Mrmaio##996614Stairway"
                    charset="utf-8" type="html" port="587">
                #errortext#
            </cfmail>

            <cfquery>
                INSERT INTO webtumtum.logs
                (texto, tag, tipo, session_id, user_id)
                VALUES
                (<cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.EventName#|#ARGUMENTS.Exception#"/>,
                <cfif isDefined("URL.tag")>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#Replace(cgi.script_name, 'index.cfm', '')##URL.tag#"/>,
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#Replace(cgi.script_name, 'index.cfm', '')#"/>,
                </cfif>
                'erro',
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#SESSION.SESSIONID#"/>,
                <cfif isDefined("COOKIE.id_usuario") and len(trim(COOKIE.id_usuario)) AND isDefined("COOKIE.is_admin") and len(trim(COOKIE.is_admin))>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id_usuario#"/>
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value=""/>
                </cfif>)
            </cfquery>

            <cflocation url="/404/" addtoken="false"/>

        <cfelse>

            <cfthrow object="#arguments.exception#">

        </cfif>

        <cfreturn/>

    </cffunction--->

</cfcomponent>
