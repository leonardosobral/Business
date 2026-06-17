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

        <cfset var system = createObject("java", "java.lang.System")/>
        <cfset var environment = system.getenv()/>
        <cfset var businessLocalConfig = {}/>
        <cfset var businessLocalConfigPath = getDirectoryFromPath(getCurrentTemplatePath()) & "config/business.local.cfm"/>
        <cfif fileExists(businessLocalConfigPath)>
            <cfinclude template="config/business.local.cfm"/>
            <cfif structKeyExists(VARIABLES, "businessLocalConfig") AND isStruct(VARIABLES.businessLocalConfig)>
                <cfset businessLocalConfig = duplicate(VARIABLES.businessLocalConfig)/>
            </cfif>
        </cfif>
        <cfset var pushDispatchSecret = structKeyExists(environment, "RR_HANDOFF_SECRET") ? trim(environment["RR_HANDOFF_SECRET"]) : ""/>
        <cfset var pushDispatchUrl = structKeyExists(environment, "RR_PUSH_DISPATCH_URL") ? trim(environment["RR_PUSH_DISPATCH_URL"]) : "https://roadrunners.run/api/push/send.cfm"/>
        <cfset var notificationDispatchUrl = structKeyExists(environment, "RR_NOTIFICATION_DISPATCH_URL") ? trim(environment["RR_NOTIFICATION_DISPATCH_URL"]) : ""/>
        <cfset var pushDispatchTimeoutSeconds = structKeyExists(environment, "RR_PUSH_DISPATCH_TIMEOUT_SECONDS") ? val(environment["RR_PUSH_DISPATCH_TIMEOUT_SECONDS"]) : 20/>
        <cfset var pushPublicKey = structKeyExists(environment, "RR_PUSH_PUBLIC_KEY") ? trim(environment["RR_PUSH_PUBLIC_KEY"]) : (structKeyExists(businessLocalConfig, "pushPublicKey") ? trim(businessLocalConfig.pushPublicKey) : "")/>
        <cfset var pushPrivateKey = structKeyExists(environment, "RR_PUSH_PRIVATE_KEY") ? trim(environment["RR_PUSH_PRIVATE_KEY"]) : (structKeyExists(businessLocalConfig, "pushPrivateKey") ? trim(businessLocalConfig.pushPrivateKey) : "")/>
        <cfset var pushSubject = structKeyExists(environment, "RR_PUSH_SUBJECT") ? trim(environment["RR_PUSH_SUBJECT"]) : (structKeyExists(businessLocalConfig, "pushSubject") ? trim(businessLocalConfig.pushSubject) : "mailto:contato@runnerhub.run")/>
        <cfset var contentAdminBaseUrl = structKeyExists(environment, "RR_CONTENT_ADMIN_BASE_URL") ? trim(environment["RR_CONTENT_ADMIN_BASE_URL"]) : "https://conteudo.roadrunners.run"/>
        <cfset var eventoApiToken = structKeyExists(environment, "RR_EVENTO_API_TOKEN") ? trim(environment["RR_EVENTO_API_TOKEN"]) : (structKeyExists(businessLocalConfig, "eventoApiToken") ? trim(businessLocalConfig.eventoApiToken) : "")/>
        <cfset var uptimeRobotApiKey = structKeyExists(environment, "UPTIMEROBOT_API_KEY") ? trim(environment["UPTIMEROBOT_API_KEY"]) : (structKeyExists(businessLocalConfig, "uptimeRobotApiKey") ? trim(businessLocalConfig.uptimeRobotApiKey) : "")/>
        <cfset var uptimeRobotApiUrl = structKeyExists(environment, "UPTIMEROBOT_API_URL") ? trim(environment["UPTIMEROBOT_API_URL"]) : (structKeyExists(businessLocalConfig, "uptimeRobotApiUrl") ? trim(businessLocalConfig.uptimeRobotApiUrl) : "https://api.uptimerobot.com/v2/getMonitors")/>
        <cfset var uptimeRobotTimeoutSeconds = structKeyExists(environment, "UPTIMEROBOT_TIMEOUT_SECONDS") ? val(environment["UPTIMEROBOT_TIMEOUT_SECONDS"]) : (structKeyExists(businessLocalConfig, "uptimeRobotTimeoutSeconds") ? val(businessLocalConfig.uptimeRobotTimeoutSeconds) : 15)/>
        <cfset var uptimeRobotCacheSeconds = structKeyExists(environment, "UPTIMEROBOT_CACHE_SECONDS") ? val(environment["UPTIMEROBOT_CACHE_SECONDS"]) : (structKeyExists(businessLocalConfig, "uptimeRobotCacheSeconds") ? val(businessLocalConfig.uptimeRobotCacheSeconds) : 120)/>

        <cfif NOT len(notificationDispatchUrl)>
            <cfset notificationDispatchUrl = pushDispatchUrl/>
        </cfif>
        <cfif findNoCase("/api/push/send.cfm", notificationDispatchUrl)>
            <cfset notificationDispatchUrl = replaceNoCase(notificationDispatchUrl, "/api/push/send.cfm", "/api/notifications/integrations/dispatch.cfm", "one")/>
        <cfelseif findNoCase("/api/push/send-notifications.cfm", notificationDispatchUrl)>
            <cfset notificationDispatchUrl = replaceNoCase(notificationDispatchUrl, "/api/push/send-notifications.cfm", "/api/notifications/integrations/dispatch.cfm", "one")/>
        <cfelseif NOT len(notificationDispatchUrl)>
            <cfset notificationDispatchUrl = "https://roadrunners.run/api/notifications/integrations/dispatch.cfm"/>
        </cfif>

        <!--- APPLICATION VARIABLES --->
        <cfset APPLICATION.codSite = "RH"/>
        <cfset APPLICATION.nomeSite = "Runner Hub"/>
        <cfset APPLICATION.dominio = "runnerhub.run"/>
        <cfset APPLICATION.baseCanonica = "https://runnerhub.run"/>
        <cfset APPLICATION.ga = ""/>
        <cfset APPLICATION.pushDispatch = {
            url = len(pushDispatchUrl) ? pushDispatchUrl : "https://roadrunners.run/api/push/send.cfm",
            secret = len(pushDispatchSecret) ? pushDispatchSecret : hash("RoadRunners::handoff::roadrunners.run::v1", "SHA-256"),
            timeoutSeconds = pushDispatchTimeoutSeconds GT 0 ? pushDispatchTimeoutSeconds : 20
        }/>
        <cfset APPLICATION.notificationDispatch = {
            url = len(notificationDispatchUrl) ? notificationDispatchUrl : "https://roadrunners.run/api/notifications/integrations/dispatch.cfm",
            secret = len(pushDispatchSecret) ? pushDispatchSecret : hash("RoadRunners::handoff::roadrunners.run::v1", "SHA-256"),
            timeoutSeconds = pushDispatchTimeoutSeconds GT 0 ? pushDispatchTimeoutSeconds : 20
        }/>
        <cfset APPLICATION.pwaPush = {
            enabled = (len(pushPublicKey) GT 0 AND len(pushPrivateKey) GT 0),
            publicKey = pushPublicKey,
            privateKey = pushPrivateKey,
            subject = len(pushSubject) ? pushSubject : "mailto:contato@runnerhub.run"
        }/>
        <cfset APPLICATION.contentAdmin = {
            baseUrl = len(contentAdminBaseUrl) ? contentAdminBaseUrl : "https://conteudo.roadrunners.run"
        }/>
        <cfset APPLICATION.eventoApiToken = eventoApiToken/>
        <cfset APPLICATION.uptimeRobot = {
            enabled = len(uptimeRobotApiKey) GT 0,
            apiKey = uptimeRobotApiKey,
            apiUrl = len(uptimeRobotApiUrl) ? uptimeRobotApiUrl : "https://api.uptimerobot.com/v2/getMonitors",
            timeoutSeconds = uptimeRobotTimeoutSeconds GT 0 ? uptimeRobotTimeoutSeconds : 15,
            cacheSeconds = uptimeRobotCacheSeconds GT 0 ? uptimeRobotCacheSeconds : 120
        }/>

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

</cfcomponent>
