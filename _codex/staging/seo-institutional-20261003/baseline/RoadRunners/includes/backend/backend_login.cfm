<!--- GOOGLE SIGN OUT --->

<cfset VARIABLES.authCookieDomain = listFirst(CGI.HTTP_HOST, ":")/>

<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cfif structKeyExists(REQUEST, "Usuario")>
        <cfset Usuario = REQUEST.Usuario/>
    <cfelse>
        <cfset Usuario = createObject("component", "includes.models.Usuario").init()/>
        <cfset REQUEST.Usuario = Usuario/>
    </cfif>
    <cftry>
        <cfquery>
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            ('googlesignout',<cfqueryparam cfsqltype="cf_sql_varchar" value="#Usuario.id#,#Usuario.name#,#Usuario.email#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
        </cfquery>
    <cfcatch type="any"></cfcatch>
    </cftry>
    <cfif structKeyExists(SESSION, "UsuarioCache")>
        <cfset StructClear(SESSION.UsuarioCache)/>
    </cfif>
    <cfif structKeyExists(SESSION, "devAuth")>
        <cfset StructDelete(SESSION, "devAuth", false)/>
    </cfif>
    <cfif structKeyExists(SESSION, "rrStravaPromptUserId")>
        <cfset StructDelete(SESSION, "rrStravaPromptUserId", false)/>
    </cfif>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="id" path="/" secure="yes" encodevalue="yes" value="" expires="now"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="name" path="/" secure="yes" encodevalue="yes" value="" expires="now"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="email" path="/" secure="yes" encodevalue="yes" value="" expires="now"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="imagem_usuario" path="/" secure="yes" encodevalue="yes" value="" expires="now"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="tag" path="/" secure="yes" encodevalue="yes" value="" expires="now"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="original_id" path="/" secure="yes" encodevalue="yes" value="" expires="now"/>
    <cfcookie domain="#VARIABLES.authCookieDomain#" name="rr_strava_prompt_session" path="/" secure="yes" samesite="Lax" encodevalue="yes" value="" expires="now"/>
    <cfset delSession = StructDelete(COOKIE, "id", true)/>
    <cfset delSession = StructDelete(COOKIE, "name", true)/>
    <cfset delSession = StructDelete(COOKIE, "email", true)/>
    <cfset delSession = StructDelete(COOKIE, "imagem_usuario", true)/>
    <cfset delSession = StructDelete(COOKIE, "tag", true)/>
    <cfset delSession = StructDelete(COOKIE, "original_id", true)/>
    <cfset delSession = StructDelete(COOKIE, "rr_strava_prompt_session", false)/>
    <cfset REQUEST.Usuario = createObject("component", "includes.models.Usuario").init()/>
    <cflocation addtoken="false" url="/"/>
</cfif>

<!--- GOOGLE SIGN IN --->

<cfif NOT structKeyExists(REQUEST, "userManagementStatusSchemaReady")>
    <cfset REQUEST.userManagementStatusSchemaReady = false/>
    <cfif structKeyExists(APPLICATION, "userManagementStatusSchemaReady") AND APPLICATION.userManagementStatusSchemaReady>
        <cfset REQUEST.userManagementStatusSchemaReady = true/>
    <cfelse>
        <cftry>
            <cfquery name="qLoginUserManagementSchema">
                SELECT
                    to_regclass('public.tb_usuarios_gestao') IS NOT NULL
                    AND to_regclass('public.tb_paginas_gestao') IS NOT NULL AS ready
            </cfquery>
            <cfset REQUEST.userManagementStatusSchemaReady = isBoolean(qLoginUserManagementSchema.ready)
                ? qLoginUserManagementSchema.ready
                : listFindNoCase("1,true,yes,on", trim(qLoginUserManagementSchema.ready & "")) GT 0/>
            <cfif REQUEST.userManagementStatusSchemaReady>
                <cfset APPLICATION.userManagementStatusSchemaReady = true/>
            </cfif>
            <cfcatch type="any">
                <cfset REQUEST.userManagementStatusSchemaReady = false/>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfif isDefined("URL.action") AND URL.action EQ "googlesignin" AND isDefined("URL.credential")>

    <cfif len(trim(URL.credential))>

        <!---cfdump var="#URL.credential#"--->
        <cfset id_token = listToArray(URL.credential, ".")/>
        <cfset fb_str = replacelist(id_token[2], "-,_", "+,/")>
        <cfset padding = repeatstring("=",4-len(fb_str) mod 4)>
        <cfset user_data = deserializeJSON(toString(BinaryDecode(fb_str & padding,"base64")))>
        <!---cfdump var="#user_data#"/--->

        <cfset token = Replace(Replace(ListGetAt(URL.credential, 2, "."), "-", "+", "ALL"), "_", "/", "ALL")>
        <cfset jstr = JavaCast("string", token)>
        <cfset decoder = CreateObject("java", "org.apache.commons.codec.binary.Base64")>
        <cfset user_data = deserializeJSON(toString(decoder.decodeBase64(jstr.getBytes())))>
        <!---cfdump var="#user_data#"/--->

        <cfset VARIABLES.googleProfileImageUrl = ""/>
        <cfif structKeyExists(user_data, "picture") AND len(trim(user_data.picture))>
            <cfset VARIABLES.googleProfileImageUrl = trim(user_data.picture)/>
            <cfif findNoCase("https://lh3.googleusercontent.com/", VARIABLES.googleProfileImageUrl) EQ 1>
                <cfset VARIABLES.googleProfileImageUrl = reReplaceNoCase(VARIABLES.googleProfileImageUrl, "=s[0-9]+(?:-[a-z]+)*$", "=s512-c")/>
            </cfif>
        </cfif>

        <!--- Identifica o primeiro cadastro antes do upsert usado também pelos logins recorrentes. --->
        <cfquery name="qGoogleAccountBeforeInsert" result="qGoogleAccountBeforeInsertMeta">
            SELECT id
            FROM tb_usuarios
            WHERE email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>
            LIMIT 1
        </cfquery>
        <cfset logQueryDebug("qGoogleAccountBeforeInsert", qGoogleAccountBeforeInsertMeta, "backend_login/google_account_before_insert", "sem cache", qGoogleAccountBeforeInsert)/>
        <cfset VARIABLES.loginCreatedAccount = NOT qGoogleAccountBeforeInsert.recordcount/>

        <cfquery>
            INSERT INTO tb_usuarios
            (name, email, imagem_usuario, password,
            verification_key, is_email_verified, optin_usuario)
            VALUES
            (
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.formatDisplayPersonName(user_data.name & '')#"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>,
            <cfif len(VARIABLES.googleProfileImageUrl)>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.googleProfileImageUrl#"/>,
            <cfelse>
               null,
            </cfif>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.sub#"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.sub#"/>,
            <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
            <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
            )
            ON CONFLICT (email)
            DO UPDATE SET
            data_alteracao  = now(),
            imagem_usuario  = excluded.imagem_usuario,
            verification_key = excluded.verification_key
            RETURNING *;
        </cfquery>

        <cfquery name="qGetUserGoogle" result="qGetUserGoogleMeta">
            select usr.*
            from tb_usuarios usr
            <cfif REQUEST.userManagementStatusSchemaReady>
                left join tb_usuarios_gestao usrgest on usrgest.id_usuario = usr.id
            </cfif>
            where usr.email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>
            <cfif REQUEST.userManagementStatusSchemaReady>
                and coalesce(usrgest.ativo, true) = true
                and coalesce(usrgest.excluido, false) = false
            </cfif>
        </cfquery>
        <cfset logQueryDebug("qGetUserGoogle", qGetUserGoogleMeta, "backend_login/get_user_google", "sem cache", qGetUserGoogle)/>

        <cfif NOT qGetUserGoogle.recordcount>
            <cflocation addtoken="false" url="/login/?status=conta_inativa"/>
        </cfif>

        <cfquery name="qCheckPagina" result="qCheckPaginaMeta">
            select * from tb_paginas
            where id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#qGetUserGoogle.id#"/>
        </cfquery>
        <cfset logQueryDebug("qCheckPagina", qCheckPaginaMeta, "backend_login/check_pagina", "sem cache", qCheckPagina)/>

        <cfif NOT qCheckPagina.recordcount>

            <cfset VARIABLES.tag = replaceList(lCase(qGetUserGoogle.name), " ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°’/\,()", "--aaaaaeeeeiiiiooooouuuucc", "ALL")/>
            <cfset VARIABLES.tag = replace(lCase(VARIABLES.tag), " ", "-", "ALL")/>
            <cfset VARIABLES.tag = replaceList(VARIABLES.tag, "à,á,â,ã,ä,é,è,ë,ê,í,ì,ï,î,ó,ò,õ,ö,ô,ú,ù,ü,û,ç,Ç", "a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c,c")/>
            <cfset VARIABLES.tag = replaceList(VARIABLES.tag, "',%,.,+,!,&,ª,º,°,’,/,\,(,)", "")/>
            <cfset VARIABLES.tag = replace(VARIABLES.tag, ",", "", "ALL")/>
            <cfset VARIABLES.tag = replace(VARIABLES.tag, "--", "-", "ALL")/>
            <cfset VARIABLES.tag = replace(VARIABLES.tag, "--", "-", "ALL")/>

            <cfquery name="qCheckTag" result="qCheckTagMeta">
                select * from tb_paginas
                where tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.tag#"/>
            </cfquery>
            <cfset logQueryDebug("qCheckTag", qCheckTagMeta, "backend_login/check_tag", "sem cache", qCheckTag)/>

            <cfif qCheckTag.recordcount>
                <cfset VARIABLES.tag = VARIABLES.tag & qGetUserGoogle.id/>
            </cfif>

            <cfquery datasource="runner_dba" name="qInsertPagina" result="qInsertPaginaMeta">
                INSERT INTO tb_paginas
                (nome, tag_prefix, tag, id_usuario_cadastro)
                VALUES
                (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qGetUserGoogle.name#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="atleta"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.tag#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qGetUserGoogle.id#"/>
                ) returning *
            </cfquery>
            <cfset logQueryDebug("qInsertPagina", qInsertPaginaMeta, "backend_login/insert_pagina", "sem cache", qInsertPagina)/>
            <cfquery datasource="runner_dba" name="qInsertPaginaUsuario" result="qInsertPaginaUsuarioMeta">
                INSERT INTO tb_paginas_usuarios
                (id_pagina, id_usuario)
                VALUES
                (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qInsertPagina.id_pagina#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qGetUserGoogle.id#"/>
                )
            </cfquery>
            <cfset logQueryDebug("qInsertPaginaUsuario", qInsertPaginaUsuarioMeta, "backend_login/insert_pagina_usuario", "sem cache")/>

        </cfif>

        <!--- Boas-vindas: criada apenas no primeiro cadastro e materializada pelo template 16. --->
        <cfif VARIABLES.loginCreatedAccount>
            <cftry>
                <cfinclude template="backend_notifications.cfm"/>
                <cfset VARIABLES.loginWelcomeNotificationId = rrNotificationsCreate(
                    val(qGetUserGoogle.id),
                    "",
                    "",
                    "",
                    16,
                    now(),
                    ""
                )/>
                <cfif VARIABLES.loginWelcomeNotificationId LTE 0>
                    <cfthrow message="A notificação de boas-vindas não foi materializada."/>
                </cfif>
                <cfcatch type="any">
                    <!--- A falha da notificação não deve invalidar a conta já criada; fica registrada para reprocessamento. --->
                    <cftry>
                        <cfquery>
                            INSERT INTO tb_log (log_item, log_item_id, log_user, site)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="cadastro_notificacao_falhou"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qGetUserGoogle.id#,16,#left(cfcatch.message, 300)#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>
                            )
                        </cfquery>
                        <cfcatch type="any"></cfcatch>
                    </cftry>
                </cfcatch>
            </cftry>
        </cfif>

        <cfcookie domain="#VARIABLES.authCookieDomain#" name="id" path="/" secure="yes" encodevalue="yes" value="#qGetUserGoogle.id#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
        <cfcookie domain="#VARIABLES.authCookieDomain#" name="name" path="/" secure="yes" encodevalue="yes" value="#qGetUserGoogle.name#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
        <cfcookie domain="#VARIABLES.authCookieDomain#" name="email" path="/" secure="yes" encodevalue="yes" value="#qGetUserGoogle.email#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
        <cfcookie domain="#VARIABLES.authCookieDomain#" name="imagem_usuario" path="/" secure="yes" encodevalue="yes" value="#qGetUserGoogle.imagem_usuario#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
        <cfcookie domain="#VARIABLES.authCookieDomain#" name="tag" path="/" secure="yes" encodevalue="yes" value="#qCheckPagina.recordCount ? qCheckPagina.tag : VARIABLES.tag#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>

        <cfif structKeyExists(SESSION, "UsuarioCache")>
            <cfset StructClear(SESSION.UsuarioCache)/>
        </cfif>
        <cfset SESSION.devAuth = {
            originalUsuarioId = qGetUserGoogle.id,
            originalEmail = qGetUserGoogle.email,
            isImpersonating = false
        }/>
        <cfset VARIABLES.loginHasActiveStrava = (
            val(qGetUserGoogle.strava_id & "") GT 0
            AND len(trim(qGetUserGoogle.strava_access_token & ""))
            AND len(trim(qGetUserGoogle.strava_refresh_token & ""))
        )/>
        <cfset VARIABLES.loginStravaPromptPermanentlyDismissed = (
            structKeyExists(COOKIE, "rr_strava_prompt_dismissed")
            AND trim(COOKIE.rr_strava_prompt_dismissed & "") EQ trim(qGetUserGoogle.id & "")
        )/>
        <cfif NOT VARIABLES.loginHasActiveStrava AND NOT VARIABLES.loginStravaPromptPermanentlyDismissed>
            <cfset SESSION.rrStravaPromptUserId = val(qGetUserGoogle.id)/>
        <cfelseif structKeyExists(SESSION, "rrStravaPromptUserId")>
            <cfset StructDelete(SESSION, "rrStravaPromptUserId", false)/>
        </cfif>
        <cfcookie domain="#VARIABLES.authCookieDomain#" name="rr_strava_prompt_session" path="/" secure="yes" samesite="Lax" encodevalue="yes" value="" expires="now"/>
        <cfset StructDelete(COOKIE, "rr_strava_prompt_session", false)/>

        <cfquery>
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            ('googlesignin',<cfqueryparam cfsqltype="cf_sql_varchar" value="#qGetUserGoogle.id#,#qGetUserGoogle.name#,#qGetUserGoogle.email#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
        </cfquery>

        <cfparam name="URL.redirect" default="/atleta/"/>
        <cfset VARIABLES.loginRedirectTarget = trim(URL.redirect)/>
        <cfif NOT len(VARIABLES.loginRedirectTarget)>
            <cfset VARIABLES.loginRedirectTarget = "/atleta/"/>
        </cfif>
        <cfif VARIABLES.loginRedirectTarget DOES NOT CONTAIN "://" AND left(VARIABLES.loginRedirectTarget, 1) NEQ "/">
            <cfset VARIABLES.loginRedirectTarget = "/" & VARIABLES.loginRedirectTarget/>
        </cfif>
        <cfif left(VARIABLES.loginRedirectTarget, 2) EQ "//">
            <cfset VARIABLES.loginRedirectTarget = "/atleta/"/>
        </cfif>
        <cfif (
            VARIABLES.loginRedirectTarget EQ "/"
            OR left(VARIABLES.loginRedirectTarget, 2) EQ "/?"
            OR reFindNoCase("^/login/?(\?.*)?$", VARIABLES.loginRedirectTarget)
        ) AND reFindNoCase("(^|[?&])acao=perfil($|[&])", VARIABLES.loginRedirectTarget)>
            <cfset VARIABLES.loginRedirectRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
            <cfset VARIABLES.loginRedirectRouteParams["tag"] = qCheckPagina.recordCount ? trim(qCheckPagina.tag) : trim(VARIABLES.tag) />
            <cfset REQUEST.currentRouteParams = VARIABLES.loginRedirectRouteParams />
            <cfset VARIABLES.loginRedirectTarget = REQUEST.i18nBuildPath("athlete") />
        </cfif>
        <cfif VARIABLES.loginRedirectTarget CONTAINS "?tag=" AND reFindNoCase("^/(en/athlete|es/atleta|atleta)/[^/]+/", VARIABLES.loginRedirectTarget)>
            <cfset VARIABLES.loginRedirectTarget = listFirst(VARIABLES.loginRedirectTarget, "?")/>
        </cfif>

        <cfif VARIABLES.loginRedirectTarget CONTAINS "requerlogin=perfil">
            <cfset VARIABLES.loginRedirectRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
            <cfset VARIABLES.loginRedirectRouteParams["tag"] = qCheckPagina.recordCount ? trim(qCheckPagina.tag) : trim(VARIABLES.tag) />
            <cfset REQUEST.currentRouteParams = VARIABLES.loginRedirectRouteParams />
            <cfset VARIABLES.loginRedirectProfilePath = REQUEST.i18nBuildPath("athlete") />
            <cflocation addtoken="false" url="#VARIABLES.loginRedirectProfilePath##VARIABLES.loginRedirectTarget#"/>
        <cfelse>
            <cflocation addtoken="false" url="#VARIABLES.loginRedirectTarget#"/>
        </cfif>

    <cfelse>

        <!---cfmail from="Runner Hub <contato@runnerhub.run>" to="leonardo.sobral@gmail.com" cc="contato@runnerhub.run"
                subject="GOOGLE CREDENTIAL INEXISTENTE" usetls="true"
                server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
                charset="utf-8" type="html" port="587">
            <cfif isDefined("CGI.REMOTE_ADDR") AND len(trim(CGI.REMOTE_ADDR))>
                <p>REMOTE_ADDR = #CGI.REMOTE_ADDR#</p>
            </cfif>
            <cfif isDefined("CGI.HTTP_USER_AGENT") AND len(trim(CGI.HTTP_USER_AGENT))>
                <p>HTTP_USER_AGENT = #CGI.HTTP_USER_AGENT#</p>
            </cfif>
            <cfif isDefined("CGI.SERVER_NAME") AND len(trim(CGI.SERVER_NAME))>
                <p>SERVER_NAME = #CGI.SERVER_NAME#</p>
            </cfif>
            <cfif isDefined("CGI.SCRIPT_NAME") AND len(trim(CGI.SCRIPT_NAME))>
                <p>SCRIPT_NAME = #CGI.SCRIPT_NAME#</p>
            </cfif>
            <cfif isDefined("CGI.QUERY_STRING") AND len(trim(CGI.QUERY_STRING))>
                <p>QUERY_STRING = #CGI.QUERY_STRING#</p>
            </cfif>
        </cfmail--->

    </cfif>

</cfif>
