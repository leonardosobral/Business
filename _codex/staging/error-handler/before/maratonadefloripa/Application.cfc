<cfcomponent
        displayname="Application"
        output="true"
        hint="Handle the application.">


    <!--- APPLICATION SETUP --->
    <cfset THIS.Name = "MaratonaDeFloripa" />
    <cfset THIS.ApplicationTimeout = CreateTimeSpan( 2, 0, 0, 0 ) />
    <cfset THIS.SessionManagement = true />
    <cfset THIS.SetClientCookies = true />
    <cfset THIS.SearchImplicitScopes = true />
    <cfset THIS.SessionTimeout = createTimeSpan( 0, 0, 50, 0 ) />
    <cfset THIS.datasource = "runnerhub"/>
    <cfset THIS.mappings = {
        "/config" = expandPath("./config")
    } />
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
        <cfset APPLICATION.codSite = "MIF"/>
        <cfset APPLICATION.nomeSite = "Maratona Internacional de Floripa"/>
        <cfset APPLICATION.dominio = "maratonadefloripa.com.br"/>
        <cfset APPLICATION.baseCanonica = "https://maratonadefloripa.com.br"/>
        <cfset APPLICATION.ga = "G-ERLSN88604"/>

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

        <cfset initSessionUsuarioCache()/>
        <cfset REQUEST.Usuario = buildRequestUsuario()/>

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
                <cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND structKeyExists(REQUEST.Usuario, "logado") AND REQUEST.Usuario.logado>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.Usuario.id#"/>
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

    <cffunction name="initSessionUsuarioCache" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(SESSION, "UsuarioCache") OR NOT isStruct(SESSION.UsuarioCache)>
            <cfset SESSION.UsuarioCache = structNew() />
        </cfif>

        <cfreturn />
    </cffunction>

    <cffunction name="buildEmptyUsuario" access="private" returntype="any" output="false">
        <cfset var usuario = createObject("component", "includes.models.Usuario") />

        <cfreturn usuario />
    </cffunction>

    <cffunction name="buildRequestUsuario" access="private" returntype="any" output="false">
        <cfset var usuario = buildEmptyUsuario() />
        <cfset var cookieId = "" />
        <cfset var cacheCore = structNew() />
        <cfset var qUsuarioCore = "" />

        <cfif NOT structKeyExists(COOKIE, "id") OR NOT len(trim(COOKIE.id))>
            <cfreturn usuario />
        </cfif>

        <cfset cookieId = trim(COOKIE.id) />

        <cfif NOT isValid("integer", cookieId)>
            <cfif structKeyExists(SESSION.UsuarioCache, "core")>
                <cfset structDelete(SESSION.UsuarioCache, "core", false) />
            </cfif>

            <cfreturn usuario />
        </cfif>

        <cfif structKeyExists(SESSION, "UsuarioCache")
            AND structKeyExists(SESSION.UsuarioCache, "core")
            AND isStruct(SESSION.UsuarioCache.core)
            AND structKeyExists(SESSION.UsuarioCache.core, "id")
            AND structKeyExists(SESSION.UsuarioCache.core, "data")
            AND isStruct(SESSION.UsuarioCache.core.data)
            AND structKeyExists(SESSION.UsuarioCache.core, "expiresAt")
            AND isDate(SESSION.UsuarioCache.core.expiresAt)
            AND SESSION.UsuarioCache.core.id EQ val(cookieId)
            AND SESSION.UsuarioCache.core.expiresAt GT now()>

            <cfset cacheCore = duplicate(SESSION.UsuarioCache.core.data) />
            <cfset usuario = createObject("component", "includes.models.Usuario").init(cacheCore) />
            <cfset usuario.logado = true />

            <cfreturn usuario />
        </cfif>

        <cfquery name="qUsuarioCore">
            SELECT
                usr.id,
                usr.email,
                usr.is_admin,
                usr.is_partner,
                usr.is_dev,
                usr.strava_id,
                usr.name,
                usr.aka,
                usr.fonte_lead,
                usr.ano_nascimento,
                usr.assessoria,
                coalesce('https://roadrunners.run/assets/paginas/' || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
                pag.tag,
                pag.id_pagina,
                coalesce(pag.nome, usr.name) as nome,
                pag.verificado,
                pag.cidade,
                pag.uf,
                pag.uf as estado,
                pag.perfil_publico,
                pag.instagram,
                pag.instagram_publico,
                pag.youtube,
                pag.youtube_publico,
                pag.tiktok,
                pag.tiktok_publico,
                pag.website,
                pag.website_publico,
                pag.loja,
                pag.loja_publico,
                pag.whatsapp,
                pag.whatsapp_publico,
                pag.descricao,
                usr.inscricao_366,
                (
                    select produto
                    from desafios
                    where desafio = 'desafio365'
                    and id_usuario = usr.id
                    and status = 'C'
                ) as inscricao_365
            FROM tb_usuarios usr
            inner join tb_paginas_usuarios pgusr on usr.id = pgusr.id_usuario
            inner join tb_paginas pag on pag.id_pagina = pgusr.id_pagina
            WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#cookieId#"/>
        </cfquery>

        <cfif qUsuarioCore.recordcount>
            <cfset usuario = createObject("component", "includes.models.Usuario").init(QueryGetRow(qUsuarioCore, 1)) />
            <cfset usuario.logado = true />
            <cfset SESSION.UsuarioCache.core = {
                id = usuario.id,
                data = usuario.toStruct(),
                loadedAt = now(),
                expiresAt = dateAdd("n", 15, now())
            } />
        <cfelse>
            <cfif structKeyExists(SESSION.UsuarioCache, "core")>
                <cfset structDelete(SESSION.UsuarioCache, "core", false) />
            </cfif>
        </cfif>

        <cfreturn usuario />
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


    <cffunction
            name="OnError"
            access="public"
            returntype="void"
            output="true"
            hint="Fires when an exception occures that is not caught by a try/catch.">

        <!--- Define arguments. --->
        <cfargument name="exception" required="true">
        <cfargument name="eventname" type="string" required="true">
        <cfset var errortext = "">
        <cfset var usuarioLogId = "" />

        <cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND structKeyExists(REQUEST.Usuario, "logado") AND REQUEST.Usuario.logado>
            <cfset usuarioLogId = REQUEST.Usuario.id />
        <cfelseif structKeyExists(COOKIE, "id") AND len(trim(COOKIE.id))>
            <cfset usuarioLogId = trim(COOKIE.id) />
        </cfif>

        <cfif NOT isDefined("URL.debug") AND CGI.HTTP_HOST DOES NOT CONTAIN 'dev.'>

            <cfsavecontent variable="errortext">
                <cfoutput>
                    An error occurred: http://#cgi.server_name##cgi.script_name#?#cgi.query_string#
                Time: #dateFormat(now(), "short")# #timeFormat(now(), "short")#

                    <cfdump var="#arguments.exception#" label="Error">
                    <cfdump var="#form#" label="Form">
                    <cfdump var="#url#" label="URL">

                </cfoutput>
            </cfsavecontent>

            <!---cfmail from="Runner Hub <contato@runnerhub.run>" to="leonardo.sobral@gmail.com" cc="contato@runnerhub.run"
                    subject="Erro de código: #arguments.exception.message#" usetls="true"
                    server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
                    charset="utf-8" type="html" port="587">
                #errortext#
            </cfmail--->

            <cfquery>
                INSERT INTO tb_log
                (log_item, log_item_id, log_user, site)
                VALUES
                (
                'erro',
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#errortext#"/>,
                <cfif len(trim(usuarioLogId))>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#usuarioLogId#"/>,
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#SESSION.SESSIONID#"/>,
                </cfif>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>
                )
            </cfquery>

            <cflocation url="/404/" addtoken="false"/>

        <cfelse>

            <cfthrow object="#arguments.exception#">

        </cfif>

        <cfreturn/>

    </cffunction>

</cfcomponent>
