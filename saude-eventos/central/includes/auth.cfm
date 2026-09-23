<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfparam name="VARIABLES.saudeAuthMode" default="fragment"/>

<!--- A identidade e o contexto de conta são sempre os mesmos do Business. --->
<cfinclude template="/includes/backend/backend_login.cfm"/>

<cfset VARIABLES.saudeHasAuthenticatedIdentity = isDefined("REQUEST.businessIdentity.id")
    AND len(trim(REQUEST.businessIdentity.id & ""))/>

<cfset VARIABLES.saudeRequestedEventId = 0/>
<cfif isDefined("URL.id_evento") AND isNumeric(URL.id_evento) AND val(URL.id_evento) GT 0>
    <cfset VARIABLES.saudeRequestedEventId = int(URL.id_evento)/>
<cfelseif isDefined("FORM.id_evento") AND isNumeric(FORM.id_evento) AND val(FORM.id_evento) GT 0>
    <cfset VARIABLES.saudeRequestedEventId = int(FORM.id_evento)/>
</cfif>

<cfset VARIABLES.saudeRequestedCourse = 0/>
<cfif isDefined("URL.percurso") AND isNumeric(URL.percurso) AND val(URL.percurso) GT 0>
    <cfset VARIABLES.saudeRequestedCourse = val(URL.percurso)/>
<cfelseif isDefined("FORM.percurso") AND isNumeric(FORM.percurso) AND val(FORM.percurso) GT 0>
    <cfset VARIABLES.saudeRequestedCourse = val(FORM.percurso)/>
</cfif>

<cfset VARIABLES.saudeReturnUrl = "/saude-eventos/central/"/>
<cfif VARIABLES.saudeRequestedEventId GT 0>
    <cfset VARIABLES.saudeReturnUrl &= "?id_evento=" & VARIABLES.saudeRequestedEventId/>
    <cfif VARIABLES.saudeRequestedCourse GT 0>
        <cfset VARIABLES.saudeReturnUrl &= "&percurso=" & VARIABLES.saudeRequestedCourse/>
    </cfif>
</cfif>

<cfif NOT structKeyExists(SESSION, "saudeBusinessCsrfToken") OR NOT len(trim(SESSION.saudeBusinessCsrfToken & ""))>
    <cfset SESSION.saudeBusinessCsrfToken = lCase(hash(createUUID() & now() & getTickCount(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.saudeCsrfToken = SESSION.saudeBusinessCsrfToken/>

<cfset VARIABLES.saudeAuthorized = isDefined("qPerfil") AND qPerfil.recordcount GT 0/>
<cfset VARIABLES.saudeIsGlobalAdmin = VARIABLES.saudeAuthorized
    AND isDefined("VARIABLES.businessEffectiveIsAdmin")
    AND VARIABLES.businessEffectiveIsAdmin/>
<cfset VARIABLES.saudeIsMedical = VARIABLES.saudeAuthorized
    AND NOT VARIABLES.saudeIsGlobalAdmin
    AND isDefined("VARIABLES.businessCurrentAccountRole")
    AND compareNoCase(trim(VARIABLES.businessCurrentAccountRole & ""), "MEDICO") EQ 0/>
<cfset VARIABLES.saudeCanOperate = VARIABLES.saudeIsGlobalAdmin OR VARIABLES.saudeIsMedical/>
<cfset VARIABLES.saudeCanViewMedicalData = VARIABLES.saudeIsMedical/>
<cfset VARIABLES.saudeCanUnlinkBib = VARIABLES.saudeIsGlobalAdmin/>
<cfset VARIABLES.saudeViewEventIds = "0"/>
<cfif VARIABLES.saudeAuthorized AND isDefined("qEventosConta") AND qEventosConta.recordcount>
    <cfset VARIABLES.saudeViewEventIds = valueList(qEventosConta.id_evento)/>
</cfif>

<cfset VARIABLES.saudeEventAuthorized = VARIABLES.saudeAuthorized
    AND (
        VARIABLES.saudeRequestedEventId EQ 0
        OR VARIABLES.saudeIsGlobalAdmin
        OR listFind(VARIABLES.saudeViewEventIds, VARIABLES.saudeRequestedEventId)
    )/>
<cfset VARIABLES.saudeMaskPrivateData = false/>

<cfif NOT VARIABLES.saudeAuthorized OR NOT VARIABLES.saudeEventAuthorized>
    <!--- Se o usuário possui acesso por outra conta, ativa essa conta e preserva a URL da Central. --->
    <cfif VARIABLES.saudeAuthMode EQ "page"
        AND VARIABLES.saudeHasAuthenticatedIdentity
        AND VARIABLES.saudeRequestedEventId GT 0
        AND NOT VARIABLES.saudeIsGlobalAdmin>
        <cfquery name="qSaudeAlternateEventAccess" datasource="runnerhub">
            SELECT cu.id_conta
            FROM tb_conta_usuarios cu
            INNER JOIN tb_contas cont
                ON cont.id_conta = cu.id_conta
               AND cont.status = 'ATIVA'::status_conta
            INNER JOIN tb_conta_eventos ce
                ON ce.id_conta = cu.id_conta
               AND ce.status = 'ATIVO'::status_conta_evento
            WHERE cu.id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#REQUEST.businessIdentity.id#"/>
              AND cu.status = 'ATIVO'::status_usuario_conta
              AND ce.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saudeRequestedEventId#"/>
            ORDER BY CASE WHEN cu.papel = 'MEDICO'::papel_usuario_conta THEN 0 ELSE 1 END,
                     cu.id_conta
            LIMIT 1
        </cfquery>

        <cfif qSaudeAlternateEventAccess.recordcount>
            <cfset SESSION.businessActiveAccountId = qSaudeAlternateEventAccess.id_conta/>
            <cfset SESSION.businessAccountSelectionConfirmed = true/>
            <cfset structDelete(SESSION, "businessSimulatedAccountId", false)/>
            <cflocation addtoken="false" url="#VARIABLES.saudeReturnUrl#"/>
        </cfif>
    </cfif>

    <cfset VARIABLES.saudeDeniedStatus = VARIABLES.saudeHasAuthenticatedIdentity ? 403 : 401/>
    <cfset VARIABLES.saudeDeniedStatusText = VARIABLES.saudeHasAuthenticatedIdentity ? "Forbidden" : "Unauthorized"/>
    <cfset VARIABLES.saudeDeniedMessage = VARIABLES.saudeHasAuthenticatedIdentity
        ? "Este evento não está vinculado à conta ativa do seu usuário."
        : "Sua sessão expirou. Entre novamente no Business."/>

    <cfif VARIABLES.saudeAuthMode EQ "page">
        <cfif NOT VARIABLES.saudeHasAuthenticatedIdentity>
            <cflocation addtoken="false" url="/?login=1&redirect=#urlEncodedFormat(VARIABLES.saudeReturnUrl)#"/>
        <cfelseif VARIABLES.saudeRequestedEventId GT 0>
            <cfset VARIABLES.saudeAccessRequestAllowed = true/>
            <cfinclude template="/saude-eventos/central/access-request.cfm"/>
        <cfelse>
            <cflocation addtoken="false" url="/saude-eventos/"/>
        </cfif>
    <cfelseif VARIABLES.saudeAuthMode EQ "json">
        <cfcontent type="application/json; charset=utf-8" reset="true"/>
        <cfheader statuscode="#VARIABLES.saudeDeniedStatus#" statustext="#VARIABLES.saudeDeniedStatusText#"/>
        <cfoutput>#serializeJSON({success=false,message=VARIABLES.saudeDeniedMessage})#</cfoutput>
    <cfelseif VARIABLES.saudeAuthMode EQ "table">
        <cfcontent type="text/html; charset=utf-8" reset="true"/>
        <cfheader statuscode="#VARIABLES.saudeDeniedStatus#" statustext="#VARIABLES.saudeDeniedStatusText#"/>
        <cfoutput><tr><td colspan="6" class="saude-empty-row">#encodeForHTML(VARIABLES.saudeDeniedMessage)#</td></tr></cfoutput>
    <cfelse>
        <cfcontent type="text/html; charset=utf-8" reset="true"/>
        <cfheader statuscode="#VARIABLES.saudeDeniedStatus#" statustext="#VARIABLES.saudeDeniedStatusText#"/>
        <cfoutput><div class="saude-drawer-empty"><i class="fa-solid fa-lock"></i><h2>Acesso restrito</h2><p>#encodeForHTML(VARIABLES.saudeDeniedMessage)#</p></div></cfoutput>
    </cfif>
    <cfabort/>
</cfif>
