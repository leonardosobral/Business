<!--- Configurações privadas do perfil autenticado. Nunca confie em id_pagina enviado pelo cliente. --->

<cfif NOT Usuario.logado OR val(Usuario.id) LTE 0 OR val(Usuario.id_pagina) LTE 0>
    <cfheader statuscode="403"/>
    <cfabort/>
</cfif>

<cfif NOT structKeyExists(SESSION, "profileSettingsCsrfToken")
    OR NOT len(trim(SESSION.profileSettingsCsrfToken & ""))
    OR NOT structKeyExists(SESSION, "profileSettingsCsrfUserId")
    OR val(SESSION.profileSettingsCsrfUserId) NEQ val(Usuario.id)>
    <cfset SESSION.profileSettingsCsrfToken = lCase(hash(createUUID() & ":" & createUUID() & ":" & getTickCount(), "SHA-256"))/>
    <cfset SESSION.profileSettingsCsrfUserId = val(Usuario.id)/>
</cfif>

<cfset VARIABLES.profileSettingsCsrfToken = SESSION.profileSettingsCsrfToken/>
<cfset VARIABLES.profileSettingsStatus = structKeyExists(URL, "status") ? trim(URL.status & "") : ""/>
<cfset VARIABLES.profileSettingsHttpStatus = 200/>
<cfparam name="VARIABLES.profileSettingsSection" default="perfil"/>
<cfif NOT structKeyExists(VARIABLES, "profileSettingsPath") OR NOT len(trim(VARIABLES.profileSettingsPath & ""))>
    <cfset VARIABLES.profileSettingsPath = REQUEST.i18nBuildPath("profileSettings")/>
</cfif>

<cfscript>
function profileSettingsNormalizeTag(required string value) {
    var normalized = lCase(trim(arguments.value));

    normalized = replaceList(
        normalized,
        "à,á,â,ã,ä,é,è,ë,ê,í,ì,ï,î,ó,ò,õ,ö,ô,ú,ù,ü,û,ç",
        "a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c"
    );
    normalized = reReplace(normalized, "[^a-z0-9]+", "-", "all");
    normalized = reReplace(normalized, "^-+|-+$", "", "all");
    normalized = reReplace(normalized, "-{2,}", "-", "all");

    return left(normalized, 128);
}

function profileSettingsBooleanField(required string fieldName) {
    return structKeyExists(FORM, arguments.fieldName);
}

function profileSettingsNormalizePicsumCover(required string value) {
    var normalized = trim(arguments.value);

    if (!reFindNoCase("^https://picsum[.]photos/id/[0-9]+/[1-9][0-9]{0,5}/[1-9][0-9]{0,5}(?:[?]grayscale)?$", normalized)) {
        return "";
    }

    return left(listFirst(normalized, "?"), 255);
}
</cfscript>

<!--- Confirma a propriedade no servidor antes de qualquer mutação. --->
<cfquery datasource="runner_dba" name="qProfileSettingsOwner">
    SELECT pag.id_pagina,
           pag.tag,
           #createObject('component','services.VerifiedEntitlement').sql('pag')# AS verificado,
           pag.whatsapp,
           pag.whatsapp_publico,
           usr.is_admin AS account_is_admin,
           usr.strava_id,
           (
               coalesce(usr.strava_id, 0) > 0
               AND nullif(trim(usr.strava_access_token), '') IS NOT NULL
               AND nullif(trim(usr.strava_refresh_token), '') IS NOT NULL
           ) AS strava_connected,
           CASE lower(coalesce(usr.strava ->> 'profile_public', 'true'))
               WHEN 'false' THEN false
               WHEN '0' THEN false
               WHEN 'no' THEN false
               WHEN 'off' THEN false
               ELSE true
           END AS strava_publico
    FROM tb_paginas pag
    INNER JOIN tb_usuarios usr ON usr.id = pag.id_usuario_cadastro
    WHERE pag.id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
      AND pag.id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
    LIMIT 1
</cfquery>

<cfif NOT qProfileSettingsOwner.recordcount>
    <cfheader statuscode="403"/>
    <cfabort/>
</cfif>

<!--- As colunas sao entregues por migration; manter defaults seguros durante deploy parcial. --->
<cfset VARIABLES.profileSettingsPerfilRunSchemaReady = false/>
<cfset VARIABLES.profileSettingsPerfilRunCoverSchemaReady = false/>
<cfset VARIABLES.profileSettingsPerfilRunTheme = "dark"/>
<cfset VARIABLES.profileSettingsPerfilRunShowEmail = true/>
<cfset VARIABLES.profileSettingsIsAdmin = qProfileSettingsOwner.account_is_admin/>
<cfset VARIABLES.profileSettingsStravaId = val(qProfileSettingsOwner.strava_id)/>
<cfset VARIABLES.profileSettingsStravaConnected = qProfileSettingsOwner.strava_connected/>
<cfset VARIABLES.profileSettingsStravaPublic = qProfileSettingsOwner.strava_publico/>
<cfset VARIABLES.profileSettingsPerfilRunShowWhatsapp = false/>
<cfset VARIABLES.profileSettingsPerfilRunDefaultCoverUrl = "https://picsum.photos/id/893/1600/700"/>
<cfset VARIABLES.profileSettingsPerfilRunCoverUrl = VARIABLES.profileSettingsPerfilRunDefaultCoverUrl/>
<cfset VARIABLES.profileSettingsPerfilRunWhatsappEligible = len(trim(qProfileSettingsOwner.whatsapp & ""))
    AND qProfileSettingsOwner.whatsapp_publico/>

<cfquery datasource="runner_dba" name="qProfileSettingsPerfilRunSchema">
    SELECT count(*) AS total
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_paginas'
      AND column_name IN (
          'perfilrun_tema',
          'perfilrun_contato_email',
          'perfilrun_contato_whatsapp'
      )
</cfquery>
<cfset VARIABLES.profileSettingsPerfilRunSchemaReady = val(qProfileSettingsPerfilRunSchema.total) EQ 3/>

<cfquery datasource="runner_dba" name="qProfileSettingsPerfilRunCoverSchema">
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_paginas'
      AND column_name = 'perfilrun_capa_url'
    LIMIT 1
</cfquery>
<cfset VARIABLES.profileSettingsPerfilRunCoverSchemaReady = qProfileSettingsPerfilRunCoverSchema.recordcount GT 0/>

<cfif VARIABLES.profileSettingsPerfilRunSchemaReady>
    <cfquery datasource="runner_dba" name="qProfileSettingsPerfilRun">
        SELECT perfilrun_tema,
               perfilrun_contato_email,
               perfilrun_contato_whatsapp
        FROM tb_paginas
        WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
          AND id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
        LIMIT 1
    </cfquery>

    <cfif qProfileSettingsPerfilRun.recordcount>
        <cfset VARIABLES.profileSettingsPerfilRunTheme = listFindNoCase("light,dark", qProfileSettingsPerfilRun.perfilrun_tema & "")
            ? lCase(qProfileSettingsPerfilRun.perfilrun_tema & "")
            : "dark"/>
        <cfset VARIABLES.profileSettingsPerfilRunShowEmail = qProfileSettingsPerfilRun.perfilrun_contato_email/>
        <cfset VARIABLES.profileSettingsPerfilRunShowWhatsapp = qProfileSettingsPerfilRun.perfilrun_contato_whatsapp
            AND VARIABLES.profileSettingsPerfilRunWhatsappEligible/>
    </cfif>

    <!--- Contato por e-mail é obrigatório para contas administrativas. --->
    <cfif VARIABLES.profileSettingsIsAdmin>
        <cfset VARIABLES.profileSettingsPerfilRunShowEmail = true/>
        <cfif qProfileSettingsPerfilRun.recordcount AND NOT qProfileSettingsPerfilRun.perfilrun_contato_email>
            <cfquery datasource="runner_dba" name="qProfileSettingsEnableAdminEmailContact">
                UPDATE tb_paginas
                SET perfilrun_contato_email = true
                WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                  AND id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                  AND perfilrun_contato_email = false
            </cfquery>
        </cfif>
    </cfif>
</cfif>

<cfif VARIABLES.profileSettingsPerfilRunCoverSchemaReady>
    <cfquery datasource="runner_dba" name="qProfileSettingsPerfilRunCover">
        SELECT perfilrun_capa_url
        FROM tb_paginas
        WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
          AND id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
        LIMIT 1
    </cfquery>

    <cfif qProfileSettingsPerfilRunCover.recordcount>
        <cfset VARIABLES.profileSettingsPerfilRunStoredCoverUrl = profileSettingsNormalizePicsumCover(qProfileSettingsPerfilRunCover.perfilrun_capa_url & "")/>
        <cfif len(VARIABLES.profileSettingsPerfilRunStoredCoverUrl)>
            <cfset VARIABLES.profileSettingsPerfilRunCoverUrl = VARIABLES.profileSettingsPerfilRunStoredCoverUrl/>
        </cfif>
    </cfif>
</cfif>
<cfset VARIABLES.profileSettingsPerfilRunCoverDisplayUrl = VARIABLES.profileSettingsPerfilRunCoverUrl & "?grayscale"/>

<!--- A página de integrações continua funcional durante deploy parcial da migration do canal. --->
<cfset VARIABLES.profileSettingsVickyWhatsappSchemaReady = false/>
<cfset VARIABLES.profileSettingsVickyWhatsappLinks = []/>
<cfset VARIABLES.profileSettingsVickyInstagramSchemaReady = false/>
<cfset VARIABLES.profileSettingsVickyInstagramLinks = []/>
<cfquery datasource="runner_dba" name="qProfileSettingsVickyWhatsappSchema">
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'tb_vicky_channel_link'
    LIMIT 1
</cfquery>
<cfset VARIABLES.profileSettingsVickyWhatsappSchemaReady = qProfileSettingsVickyWhatsappSchema.recordcount GT 0/>
<cfset VARIABLES.profileSettingsVickyInstagramSchemaReady = VARIABLES.profileSettingsVickyWhatsappSchemaReady/>
<cfif VARIABLES.profileSettingsVickyWhatsappSchemaReady>
    <cfset VARIABLES.profileSettingsVickyWhatsappRepository = createObject("component", "repositories.VickyWhatsappRepository").init("runner_dba")/>
    <cfset VARIABLES.profileSettingsVickyWhatsappLinks = VARIABLES.profileSettingsVickyWhatsappRepository.getActiveLinksForUser(val(Usuario.id))/>
    <cfset VARIABLES.profileSettingsVickyInstagramRepository = createObject("component", "repositories.VickyInstagramRepository").init("runner_dba")/>
    <cfset VARIABLES.profileSettingsVickyInstagramLinks = VARIABLES.profileSettingsVickyInstagramRepository.getActiveLinksForUser(val(Usuario.id))/>
</cfif>

<cfif uCase(CGI.REQUEST_METHOD) EQ "POST">
    <cfparam name="FORM.instagram" default=""/>
    <cfparam name="FORM.youtube" default=""/>
    <cfparam name="FORM.tiktok" default=""/>
    <cfparam name="FORM.website" default=""/>
    <cfparam name="FORM.loja" default=""/>
    <cfparam name="FORM.whatsapp" default=""/>
    <cfset VARIABLES.profileSettingsAction = structKeyExists(FORM, "action") ? trim(FORM.action & "") : ""/>
    <cfset VARIABLES.profileSettingsExpectedAction = {
        "perfil" = "editar_configuracoes",
        "integracoes" = "gerenciar_integracoes",
        "links" = "editar_redes_sociais",
        "privacidade" = "editar_privacidade",
        "perfilrun" = "editar_perfilrun"
    }/>
    <cfset VARIABLES.profileSettingsSubmittedToken = structKeyExists(FORM, "csrf_token") ? trim(FORM.csrf_token & "") : ""/>
    <cfset VARIABLES.profileSettingsCsrfValid = len(VARIABLES.profileSettingsSubmittedToken)
        AND compare(VARIABLES.profileSettingsSubmittedToken, VARIABLES.profileSettingsCsrfToken) EQ 0/>

    <cfif NOT VARIABLES.profileSettingsCsrfValid>
        <cfset VARIABLES.profileSettingsStatus = "security-error"/>
        <cfset VARIABLES.profileSettingsHttpStatus = 403/>
    <cfelseif NOT structKeyExists(VARIABLES.profileSettingsExpectedAction, VARIABLES.profileSettingsSection)
        OR VARIABLES.profileSettingsAction NEQ VARIABLES.profileSettingsExpectedAction[VARIABLES.profileSettingsSection]>
        <cfset VARIABLES.profileSettingsStatus = "invalid"/>
        <cfset VARIABLES.profileSettingsHttpStatus = 400/>
    <cfelseif VARIABLES.profileSettingsAction EQ "gerenciar_integracoes">
        <cfset VARIABLES.profileSettingsIntegrationOperation = structKeyExists(FORM, "integration_operation") ? lCase(trim(FORM.integration_operation & "")) : ""/>
        <cfif NOT listFindNoCase("disconnect_vicky_whatsapp,disconnect_vicky_instagram", VARIABLES.profileSettingsIntegrationOperation)
            OR (VARIABLES.profileSettingsIntegrationOperation EQ "disconnect_vicky_whatsapp" AND NOT VARIABLES.profileSettingsVickyWhatsappSchemaReady)
            OR (VARIABLES.profileSettingsIntegrationOperation EQ "disconnect_vicky_instagram" AND NOT VARIABLES.profileSettingsVickyInstagramSchemaReady)>
            <cfset VARIABLES.profileSettingsStatus = "invalid"/>
            <cfset VARIABLES.profileSettingsHttpStatus = 400/>
        <cfelseif VARIABLES.profileSettingsIntegrationOperation EQ "disconnect_vicky_whatsapp">
            <cfset VARIABLES.profileSettingsRevokedWhatsappLinks = VARIABLES.profileSettingsVickyWhatsappRepository.revokeUserLinks(val(Usuario.id))/>
            <cflocation addtoken="false" statuscode="303" url="#REQUEST.i18nBuildPath('profileSettingsIntegrations')#?status=whatsapp-disconnected"/>
        <cfelse>
            <cfset VARIABLES.profileSettingsRevokedInstagramLinks = VARIABLES.profileSettingsVickyInstagramRepository.revokeUserLinks(val(Usuario.id))/>
            <cflocation addtoken="false" statuscode="303" url="#REQUEST.i18nBuildPath('profileSettingsIntegrations')#?status=instagram-disconnected"/>
        </cfif>
    <cfelseif VARIABLES.profileSettingsAction EQ "editar_configuracoes">
        <cfset VARIABLES.profileSettingsName = structKeyExists(FORM, "nome") ? trim(FORM.nome & "") : ""/>
        <cfset VARIABLES.profileSettingsCity = structKeyExists(FORM, "cidade") ? trim(FORM.cidade & "") : ""/>
        <cfset VARIABLES.profileSettingsCountry = structKeyExists(FORM, "pais") ? uCase(trim(FORM.pais & "")) : "BR"/>
        <cfset VARIABLES.profileSettingsRegion = structKeyExists(FORM, "uf") ? trim(FORM.uf & "") : ""/>
        <cfset VARIABLES.profileSettingsDescription = structKeyExists(FORM, "descricao") ? trim(FORM.descricao & "") : ""/>
        <cfset VARIABLES.profileSettingsTag = profileSettingsNormalizeTag(structKeyExists(FORM, "tag") ? FORM.tag & "" : "")/>

        <cfif structKeyExists(REQUEST, "formatDisplayPersonName")>
            <cfset VARIABLES.profileSettingsName = REQUEST.formatDisplayPersonName(VARIABLES.profileSettingsName)/>
            <cfset VARIABLES.profileSettingsCity = REQUEST.formatDisplayCity(VARIABLES.profileSettingsCity)/>
            <cfif VARIABLES.profileSettingsCountry NEQ "BR">
                <cfset VARIABLES.profileSettingsRegion = REQUEST.formatDisplayPersonName(VARIABLES.profileSettingsRegion)/>
            </cfif>
        </cfif>

        <cfif VARIABLES.profileSettingsCountry EQ "BR">
            <cfset VARIABLES.profileSettingsRegion = uCase(VARIABLES.profileSettingsRegion)/>
        </cfif>

        <cfset VARIABLES.profileSettingsName = left(VARIABLES.profileSettingsName, 128)/>
        <cfset VARIABLES.profileSettingsCity = left(VARIABLES.profileSettingsCity, 128)/>
        <cfset VARIABLES.profileSettingsRegion = left(VARIABLES.profileSettingsRegion, 128)/>
        <cfset VARIABLES.profileSettingsDescription = left(VARIABLES.profileSettingsDescription, 150)/>

        <cfif NOT len(VARIABLES.profileSettingsName)
            OR NOT len(VARIABLES.profileSettingsTag)
            OR NOT len(VARIABLES.profileSettingsCity)
            OR NOT reFind("^[A-Z]{2}$", VARIABLES.profileSettingsCountry)>
            <cfset VARIABLES.profileSettingsStatus = "invalid"/>
            <cfset VARIABLES.profileSettingsHttpStatus = 400/>
        <cfelse>
            <cfquery datasource="runner_dba" name="qProfileSettingsTagConflict">
                SELECT id_pagina
                FROM tb_paginas
                WHERE lower(tag) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsTag#"/>
                  AND id_pagina <> <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                LIMIT 1
            </cfquery>

            <cfif qProfileSettingsTagConflict.recordcount>
                <cflocation
                    addtoken="false"
                    statuscode="303"
                    url="#VARIABLES.profileSettingsPath#?status=tag-taken&tag_value=#urlEncodedFormat(VARIABLES.profileSettingsTag)###perfil"/>
            </cfif>

            <cfif NOT structKeyExists(REQUEST, "usuarioPartnerInfoColumnAvailable")>
                <cfquery datasource="runner_dba" name="qProfileSettingsPartnerInfoColumn">
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'tb_usuarios'
                      AND column_name = 'partner_info'
                    LIMIT 1
                </cfquery>
                <cfset REQUEST.usuarioPartnerInfoColumnAvailable = qProfileSettingsPartnerInfoColumn.recordcount GT 0/>
            </cfif>

            <cftransaction>
                <cfquery datasource="runner_dba" name="qProfileSettingsUpdatePage">
                    UPDATE tb_paginas
                    SET nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsName#"/>,
                        tag_prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="atleta"/>,
                        tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsTag#"/>,
                        cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsCity#"/>,
                        uf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsCountry EQ 'BR' ? VARIABLES.profileSettingsRegion : VARIABLES.profileSettingsCountry#"/>,
                        descricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsDescription#"/>
                    WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                      AND id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                </cfquery>

                <cfquery datasource="runner_dba" name="qProfileSettingsUpdateUser">
                    UPDATE tb_usuarios
                    SET name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsName#"/>,
                        cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsCity#"/>,
                        estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsRegion#"/>,
                        <cfif REQUEST.usuarioPartnerInfoColumnAvailable>
                            partner_info = jsonb_set(
                                coalesce(partner_info, '{}'::jsonb),
                                '{location_region}',
                                to_jsonb(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsRegion#"/>::text),
                                true
                            ),
                        </cfif>
                        pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsCountry#"/>
                    WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                </cfquery>
            </cftransaction>

            <cfset Usuario.name = VARIABLES.profileSettingsName/>
            <cfset Usuario.nome = VARIABLES.profileSettingsName/>
            <cfset Usuario.tag = VARIABLES.profileSettingsTag/>
            <cfset Usuario.cidade = VARIABLES.profileSettingsCity/>
            <cfset Usuario.estado = VARIABLES.profileSettingsRegion/>
            <cfset Usuario.uf = VARIABLES.profileSettingsCountry EQ "BR" ? VARIABLES.profileSettingsRegion : VARIABLES.profileSettingsCountry/>
            <cfset Usuario.pais = VARIABLES.profileSettingsCountry/>
            <cfset REQUEST.Usuario = Usuario/>

            <cfcookie domain="#VARIABLES.authCookieDomain#" name="name" path="/" secure="yes" encodevalue="yes" value="#VARIABLES.profileSettingsName#" expires="#createTimeSpan(30, 0, 0, 0)#"/>
            <cfcookie domain="#VARIABLES.authCookieDomain#" name="tag" path="/" secure="yes" encodevalue="yes" value="#VARIABLES.profileSettingsTag#" expires="#createTimeSpan(30, 0, 0, 0)#"/>

            <cfif structKeyExists(SESSION, "UsuarioCache") AND isStruct(SESSION.UsuarioCache)>
                <cfif structKeyExists(SESSION.UsuarioCache, "core")>
                    <cfset structDelete(SESSION.UsuarioCache, "core", false)/>
                </cfif>
                <cfif structKeyExists(SESSION.UsuarioCache, "resultados")>
                    <cfset structDelete(SESSION.UsuarioCache, "resultados", false)/>
                </cfif>
            </cfif>

            <cflocation addtoken="false" statuscode="303" url="#VARIABLES.profileSettingsPath#?status=saved##perfil"/>
        </cfif>
    <cfelseif VARIABLES.profileSettingsAction EQ "editar_redes_sociais">
        <cftransaction>
            <cfquery datasource="runner_dba" name="qProfileSettingsUpdateLinks">
                UPDATE tb_paginas
                SET instagram = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.instagram & ''), 128)#"/>,
                    instagram_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#profileSettingsBooleanField('instagram_publico')#"/>,
                    youtube = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.youtube & ''), 128)#"/>,
                    youtube_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#profileSettingsBooleanField('youtube_publico')#"/>,
                    tiktok = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.tiktok & ''), 128)#"/>,
                    tiktok_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#profileSettingsBooleanField('tiktok_publico')#"/>,
                    website = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.website & ''), 128)#"/>,
                    website_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#profileSettingsBooleanField('website_publico')#"/>,
                    loja = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.loja & ''), 128)#"/>,
                    loja_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#profileSettingsBooleanField('loja_publico')#"/>,
                    whatsapp = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.whatsapp & ''), 128)#"/>,
                    whatsapp_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#profileSettingsBooleanField('whatsapp_publico')#"/>
                WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                  AND id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
            </cfquery>

            <cfif VARIABLES.profileSettingsStravaConnected>
                <cfquery datasource="runner_dba" name="qProfileSettingsUpdateStravaVisibility">
                    UPDATE tb_usuarios
                    SET strava = jsonb_set(
                        CASE
                            WHEN jsonb_typeof(strava) = 'object' THEN strava
                            ELSE '{}'::jsonb
                        END,
                        '{profile_public}',
                        to_jsonb(CAST(<cfqueryparam cfsqltype="cf_sql_bit" value="#profileSettingsBooleanField('strava_publico')#"/> AS boolean)),
                        true
                    )
                    WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
                </cfquery>
            </cfif>
        </cftransaction>

        <cfif structKeyExists(SESSION, "UsuarioCache") AND isStruct(SESSION.UsuarioCache) AND structKeyExists(SESSION.UsuarioCache, "core")>
            <cfset structDelete(SESSION.UsuarioCache, "core", false)/>
        </cfif>

        <cflocation addtoken="false" statuscode="303" url="#REQUEST.i18nBuildPath('profileSettingsLinks')#?status=saved"/>
    <cfelseif VARIABLES.profileSettingsAction EQ "editar_privacidade">
        <cfquery datasource="runner_dba" name="qProfileSettingsUpdatePrivacy">
            UPDATE tb_paginas
            SET perfil_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#profileSettingsBooleanField('perfil_publico')#"/>
            WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
              AND id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
        </cfquery>

        <cfset Usuario.perfil_publico = profileSettingsBooleanField("perfil_publico")/>
        <cfset REQUEST.Usuario = Usuario/>
        <cfif structKeyExists(SESSION, "UsuarioCache") AND isStruct(SESSION.UsuarioCache) AND structKeyExists(SESSION.UsuarioCache, "core")>
            <cfset structDelete(SESSION.UsuarioCache, "core", false)/>
        </cfif>

        <cflocation addtoken="false" statuscode="303" url="#REQUEST.i18nBuildPath('profileSettingsPrivacy')#?status=saved"/>
    <cfelseif VARIABLES.profileSettingsAction EQ "editar_perfilrun">
        <cfset VARIABLES.profileSettingsPerfilRunSubmittedTheme = structKeyExists(FORM, "perfilrun_tema")
            ? lCase(trim(FORM.perfilrun_tema & ""))
            : ""/>
        <cfset VARIABLES.profileSettingsPerfilRunSubmittedCoverUrl = profileSettingsNormalizePicsumCover(
            structKeyExists(FORM, "perfilrun_capa_url") ? FORM.perfilrun_capa_url & "" : ""
        )/>

        <cfif NOT qProfileSettingsOwner.verificado
            OR NOT VARIABLES.profileSettingsPerfilRunSchemaReady
            OR NOT listFindNoCase("light,dark", VARIABLES.profileSettingsPerfilRunSubmittedTheme)
            OR (VARIABLES.profileSettingsPerfilRunCoverSchemaReady AND NOT len(VARIABLES.profileSettingsPerfilRunSubmittedCoverUrl))>
            <cfset VARIABLES.profileSettingsStatus = "invalid"/>
            <cfset VARIABLES.profileSettingsHttpStatus = 400/>
        <cfelse>
            <cfset VARIABLES.profileSettingsPerfilRunShowEmail = VARIABLES.profileSettingsIsAdmin
                OR profileSettingsBooleanField("perfilrun_contato_email")/>
            <cfset VARIABLES.profileSettingsPerfilRunShowWhatsapp = profileSettingsBooleanField("perfilrun_contato_whatsapp")
                AND VARIABLES.profileSettingsPerfilRunWhatsappEligible/>

            <cfquery datasource="runner_dba" name="qProfileSettingsUpdatePerfilRun">
                UPDATE tb_paginas
                SET perfilrun_tema = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsPerfilRunSubmittedTheme#"/>,
                    perfilrun_contato_email = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.profileSettingsPerfilRunShowEmail#"/>,
                    perfilrun_contato_whatsapp = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.profileSettingsPerfilRunShowWhatsapp#"/>
                    <cfif VARIABLES.profileSettingsPerfilRunCoverSchemaReady>
                        , perfilrun_capa_url = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.profileSettingsPerfilRunSubmittedCoverUrl#"/>
                    </cfif>
                WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id_pagina#"/>
                  AND id_usuario_cadastro = <cfqueryparam cfsqltype="cf_sql_integer" value="#Usuario.id#"/>
            </cfquery>

            <cflocation addtoken="false" statuscode="303" url="#REQUEST.i18nBuildPath('profileSettingsPerfilRun')#?status=saved"/>
        </cfif>
    </cfif>
</cfif>

<cfif VARIABLES.profileSettingsHttpStatus NEQ 200>
    <cfheader statuscode="#VARIABLES.profileSettingsHttpStatus#"/>
</cfif>
