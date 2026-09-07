<!--- Called only by the shared request boundary, before profile/tenant redirects. --->
<cfif CGI.request_method NEQ "POST"
    OR NOT structKeyExists(FORM,"credential") OR NOT isSimpleValue(FORM.credential)
    OR NOT structKeyExists(FORM,"business_login_csrf") OR NOT isSimpleValue(FORM.business_login_csrf)
    OR NOT structKeyExists(SESSION,"businessLoginCsrf")
    OR NOT len(SESSION.businessLoginCsrf)
    OR compare(FORM.business_login_csrf,SESSION.businessLoginCsrf) NEQ 0
    OR NOT structKeyExists(SESSION,"businessLoginNonce")>
    <cflocation url="/?login=1&auth_error=1" addtoken="false"/>
</cfif>
<cftry>
    <cflock name="RunnerHubBusiness.GoogleVerifier.v1" type="exclusive" timeout="8">
        <cfif NOT structKeyExists(APPLICATION,"businessGoogleVerifierV1")>
            <cfset APPLICATION.businessGoogleVerifierV1 = createObject("component","services.GoogleIdentityVerifier")
                .init("921450846888-qa9a1alk06v6i0ao4jbiihdfrn8j7528.apps.googleusercontent.com")/>
        </cfif>
    </cflock>
    <cfset user_data = APPLICATION.businessGoogleVerifierV1.verify(FORM.credential,SESSION.businessLoginNonce)/>
    <cfset structDelete(SESSION,"businessLoginNonce",false)/>
    <cfset structDelete(SESSION,"businessLoginCsrf",false)/>
    <cfcatch type="any">
        <!--- Never log tokens/claims or return provider exception details. --->
        <cflog file="business_auth" type="warning" text="Google sign-in verification rejected"/>
        <cflocation url="/?login=1&auth_error=1" addtoken="false"/>
    </cfcatch>
</cftry>
    <cfquery>
        INSERT INTO tb_usuarios
        (name, email, imagem_usuario, password,
        verification_key, is_email_verified, optin_usuario)
        VALUES
        (
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#ucase(user_data.name)#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>,
        <cfif isDefined("user_data.picture")>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.picture#"/>,
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

    <cfquery name="qPerfil">
        select * from tb_usuarios
        where email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#user_data.email#"/>
    </cfquery>

    <cfquery name="qBusinessGoogleSignInState">
        SELECT (
                   coalesce(usr.is_admin, false)
                   OR coalesce(usr.is_dev, false)
                   OR EXISTS (
                       SELECT 1
                       FROM tb_conta_usuarios cu
                       INNER JOIN tb_contas cont ON cont.id_conta = cu.id_conta
                       WHERE cu.id_usuario = usr.id
                         AND cu.status = 'ATIVO'::status_usuario_conta
                         AND cont.status = 'ATIVA'::status_conta
                   )
               ) AS has_business_access,
               EXISTS (
                   SELECT 1
                   FROM tb_conta_cadastro_solicitacoes sol
                   WHERE lower(sol.email_responsavel) = lower(usr.email)
                     AND sol.status = 'PENDENTE'::status_conta_cadastro_solicitacao
               ) AS has_pending_registration,
               coalesce(usr.is_partner,false) AS has_legacy_bi_access
        FROM tb_usuarios usr
        WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
        LIMIT 1
    </cfquery>

    <cfset VARIABLES.googleSignInSessionReturn = structKeyExists(SESSION,"researchLoginRedirect") ? SESSION.researchLoginRedirect : ""/>
    <cfset user_data.name = qPerfil.name/>
    <cfset sessionRotate()/>
    <cfset REQUEST.businessAuthSession.establish(SESSION,qPerfil.id,user_data)/>
    <cfset REQUEST.businessIdentity = REQUEST.businessAuthSession.identity(SESSION)/>
    <cfheader name="Set-Cookie" value="rr_logged_out=; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0; Path=/; Secure; SameSite=Lax"/>
    <cfset VARIABLES.googleSignInHasBusinessAccess = false/>
    <cfset VARIABLES.googleSignInHasPendingRegistration = false/>
    <cfset VARIABLES.googleSignInHasLegacyBiAccess = false/>
    <cfif qBusinessGoogleSignInState.recordcount>
        <cfset VARIABLES.googleSignInHasLegacyBiAccess = listFindNoCase("true,t,1,yes",trim(qBusinessGoogleSignInState.has_legacy_bi_access & "")) GT 0/>
        <cfif IsBoolean(qBusinessGoogleSignInState.has_business_access)>
            <cfset VARIABLES.googleSignInHasBusinessAccess = qBusinessGoogleSignInState.has_business_access/>
        <cfelseif ListFindNoCase("true,t,1,yes,sim", trim(qBusinessGoogleSignInState.has_business_access & ""))>
            <cfset VARIABLES.googleSignInHasBusinessAccess = true/>
        </cfif>

        <cfif IsBoolean(qBusinessGoogleSignInState.has_pending_registration)>
            <cfset VARIABLES.googleSignInHasPendingRegistration = qBusinessGoogleSignInState.has_pending_registration/>
        <cfelseif ListFindNoCase("true,t,1,yes,sim", trim(qBusinessGoogleSignInState.has_pending_registration & ""))>
            <cfset VARIABLES.googleSignInHasPendingRegistration = true/>
        </cfif>
    </cfif>

    <cfset VARIABLES.googleSignInRedirect = "/"/>
    <cfset VARIABLES.googleSignInRequestedRedirect = isDefined("FORM.redirect") AND len(trim(FORM.redirect & ""))
        ? trim(FORM.redirect & "")
        : VARIABLES.googleSignInSessionReturn/>
    <cfset VARIABLES.googleSignInValidRedirect = len(VARIABLES.googleSignInRequestedRedirect)
        AND left(VARIABLES.googleSignInRequestedRedirect, 1) EQ "/"
        AND left(VARIABLES.googleSignInRequestedRedirect, 2) NEQ "//"
        AND NOT find("\", VARIABLES.googleSignInRequestedRedirect)
        AND NOT find(chr(10), VARIABLES.googleSignInRequestedRedirect)
        AND NOT find(chr(13), VARIABLES.googleSignInRequestedRedirect)
        AND NOT findNoCase("logout=1", VARIABLES.googleSignInRequestedRedirect)/>
    <cfif VARIABLES.googleSignInValidRedirect AND left(VARIABLES.googleSignInRequestedRedirect, 10) EQ "/pesquisa/">
        <cfset VARIABLES.googleSignInRedirect = VARIABLES.googleSignInRequestedRedirect/>
    <cfelseif VARIABLES.googleSignInValidRedirect AND left(VARIABLES.googleSignInRequestedRedirect,4) EQ "/bi/"
        AND VARIABLES.googleSignInHasLegacyBiAccess>
        <cfset VARIABLES.googleSignInRedirect = VARIABLES.googleSignInRequestedRedirect/>
    <cfelseif VARIABLES.googleSignInHasBusinessAccess>
        <cfif VARIABLES.googleSignInValidRedirect>
            <cfset VARIABLES.googleSignInRedirect = VARIABLES.googleSignInRequestedRedirect/>
        </cfif>
    <cfelseif VARIABLES.googleSignInHasPendingRegistration>
        <cfset VARIABLES.googleSignInRedirect = "/"/>
    <cfelse>
        <cfset VARIABLES.googleSignInRedirect = "/cadastro/"/>
    </cfif>
    <cfset structDelete(SESSION, "researchLoginRedirect", false)/>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        ('googlesignin',<cfqueryparam cfsqltype="cf_sql_varchar" value="#qPerfil.id#,#qPerfil.name#,#qPerfil.email#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
    </cfquery>

    <cflocation addtoken="false" url="#VARIABLES.googleSignInRedirect#"/>
