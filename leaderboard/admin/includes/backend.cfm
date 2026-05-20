<cfparam name="URL.user_created" default="0"/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfscript>
    function leaderboardAdminGeneratePlaceholderEmail() {
        var rawToken = lCase(replace(createUUID(), "-", "", "all"));
        return "atleta-manual-" & left(rawToken, 12) & "@temporario.roadrunners.invalid";
    }

    function leaderboardAdminSlugify(required string value) {
        var slugValue = trim(arguments.value);

        slugValue = lCase(slugValue);
        slugValue = replace(slugValue, " ", "-", "all");
        slugValue = replaceList(slugValue, "à,á,â,ã,ä,é,è,ë,ê,í,ì,ï,î,ó,ò,õ,ö,ô,ú,ù,ü,û,ç,Ç", "a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c,c");
        slugValue = replaceList(slugValue, "',%,.,+,!,&,ª,º,°,’,/,\,(,)", "");
        slugValue = replace(slugValue, ",", "", "all");

        while (find("--", slugValue)) {
            slugValue = replace(slugValue, "--", "-", "all");
        }

        slugValue = reReplace(slugValue, "[^a-z0-9-]", "", "all");
        slugValue = reReplace(slugValue, "^-+|-+$", "", "all");

        if (!len(slugValue)) {
            slugValue = "atleta";
        }

        return slugValue;
    }
</cfscript>

<cfset VARIABLES.leaderboardAdminStatus = trim(isDefined("URL.status") ? URL.status : "")/>
<cfset VARIABLES.leaderboardAdminError = trim(isDefined("URL.error") ? URL.error : "")/>
<cfset VARIABLES.leaderboardAdminCreatedUserId = trim(isDefined("URL.user_id") ? URL.user_id : "")/>
<cfset VARIABLES.leaderboardAdminCreatedPageId = trim(isDefined("URL.page_id") ? URL.page_id : "")/>
<cfset VARIABLES.leaderboardAdminCreatedTag = trim(isDefined("URL.tag") ? URL.tag : "")/>

<cfset VARIABLES.leaderboardAdminDefaultEmail = leaderboardAdminGeneratePlaceholderEmail()/>
<cfset VARIABLES.leaderboardAdminFormEmail = trim(isDefined("FORM.manual_user_email") ? FORM.manual_user_email : VARIABLES.leaderboardAdminDefaultEmail)/>
<cfset VARIABLES.leaderboardAdminFormName = trim(isDefined("FORM.manual_user_name") ? FORM.manual_user_name : "")/>
<cfset VARIABLES.leaderboardAdminFormGender = uCase(trim(isDefined("FORM.manual_user_gender") ? FORM.manual_user_gender : ""))/>
<cfset VARIABLES.leaderboardAdminFormCountry = uCase(trim(isDefined("FORM.manual_user_country") ? FORM.manual_user_country : "BR"))/>
<cfset VARIABLES.leaderboardAdminFormCBAT = trim(isDefined("FORM.manual_user_cbat") ? FORM.manual_user_cbat : "")/>

<cfif isDefined("FORM.manual_user_action") AND FORM.manual_user_action EQ "create_manual_user">
    <cfset VARIABLES.leaderboardAdminFormEmail = trim(isDefined("FORM.manual_user_email") ? FORM.manual_user_email : "")/>
    <cfset VARIABLES.leaderboardAdminFormName = trim(isDefined("FORM.manual_user_name") ? FORM.manual_user_name : "")/>
    <cfset VARIABLES.leaderboardAdminFormGender = uCase(trim(isDefined("FORM.manual_user_gender") ? FORM.manual_user_gender : ""))/>
    <cfset VARIABLES.leaderboardAdminFormCountry = uCase(trim(isDefined("FORM.manual_user_country") ? FORM.manual_user_country : ""))/>
    <cfset VARIABLES.leaderboardAdminFormCBAT = trim(isDefined("FORM.manual_user_cbat") ? FORM.manual_user_cbat : "")/>

    <cfif NOT len(VARIABLES.leaderboardAdminFormEmail)>
        <cfset VARIABLES.leaderboardAdminFormEmail = leaderboardAdminGeneratePlaceholderEmail()/>
    </cfif>

    <cfset VARIABLES.leaderboardAdminValidationError = ""/>

    <cfif NOT len(VARIABLES.leaderboardAdminFormName)>
        <cfset VARIABLES.leaderboardAdminValidationError = "nome_obrigatorio"/>
    <cfelseif NOT len(VARIABLES.leaderboardAdminFormGender) OR NOT listFindNoCase("M,F", VARIABLES.leaderboardAdminFormGender)>
        <cfset VARIABLES.leaderboardAdminValidationError = "sexo_invalido"/>
    <cfelseif NOT len(VARIABLES.leaderboardAdminFormCountry)>
        <cfset VARIABLES.leaderboardAdminValidationError = "pais_obrigatorio"/>
    <cfelseif NOT isValid("email", VARIABLES.leaderboardAdminFormEmail)>
        <cfset VARIABLES.leaderboardAdminValidationError = "email_invalido"/>
    </cfif>

    <cfif len(VARIABLES.leaderboardAdminValidationError)>
        <cflocation addtoken="false" url="./?status=erro&error=#urlEncodedFormat(VARIABLES.leaderboardAdminValidationError)#"/>
    </cfif>

    <cfquery name="qLeaderboardAdminEmailCheck">
        SELECT id
        FROM tb_usuarios
        WHERE email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminFormEmail#"/>
        LIMIT 1
    </cfquery>

    <cfif qLeaderboardAdminEmailCheck.recordcount>
        <cflocation addtoken="false" url="./?status=erro&error=email_duplicado"/>
    </cfif>

    <cfset VARIABLES.leaderboardAdminVerificationKey = lCase(replace(createUUID(), "-", "", "all"))/>

    <cftry>
        <cftransaction>
            <cfquery name="qLeaderboardAdminInsertUser">
                INSERT INTO tb_usuarios
                (
                    name,
                    email,
                    password,
                    verification_key,
                    is_email_verified,
                    optin_usuario,
                    genero,
                    pais,
                    cbat
                )
                VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#ucase(VARIABLES.leaderboardAdminFormName)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminFormEmail#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminVerificationKey#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminVerificationKey#"/>,
                    <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
                    <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminFormGender#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminFormCountry#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminFormCBAT#" null="#NOT len(VARIABLES.leaderboardAdminFormCBAT)#"/>
                )
                RETURNING id, name, email
            </cfquery>

            <cfset VARIABLES.leaderboardAdminBaseTag = leaderboardAdminSlugify(VARIABLES.leaderboardAdminFormName)/>
            <cfset VARIABLES.leaderboardAdminResolvedTag = VARIABLES.leaderboardAdminBaseTag/>

            <cfquery name="qLeaderboardAdminTagCheck">
                SELECT id_pagina
                FROM tb_paginas
                WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminResolvedTag#"/>
                LIMIT 1
            </cfquery>

            <cfif qLeaderboardAdminTagCheck.recordcount>
                <cfset VARIABLES.leaderboardAdminResolvedTag = VARIABLES.leaderboardAdminBaseTag & qLeaderboardAdminInsertUser.id/>

                <cfquery name="qLeaderboardAdminTagCheckFinal">
                    SELECT id_pagina
                    FROM tb_paginas
                    WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminResolvedTag#"/>
                    LIMIT 1
                </cfquery>

                <cfif qLeaderboardAdminTagCheckFinal.recordcount>
                    <cfset VARIABLES.leaderboardAdminResolvedTag = VARIABLES.leaderboardAdminBaseTag & "-" & qLeaderboardAdminInsertUser.id & "-" & dateTimeFormat(now(), "HHnnss")/>
                </cfif>
            </cfif>

            <cfquery name="qLeaderboardAdminInsertPage">
                INSERT INTO tb_paginas
                (
                    nome,
                    tag_prefix,
                    tag,
                    id_usuario_cadastro
                )
                VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#ucase(VARIABLES.leaderboardAdminFormName)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="atleta"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.leaderboardAdminResolvedTag#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qLeaderboardAdminInsertUser.id#"/>
                )
                RETURNING id_pagina, tag
            </cfquery>

            <cfquery>
                INSERT INTO tb_paginas_usuarios
                (
                    id_pagina,
                    id_usuario
                )
                VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qLeaderboardAdminInsertPage.id_pagina#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qLeaderboardAdminInsertUser.id#"/>
                )
            </cfquery>
        </cftransaction>

        <cftry>
            <cfquery>
                INSERT INTO tb_log
                (
                    log_item,
                    log_item_id,
                    log_user,
                    site
                )
                VALUES
                (
                    'leaderboard_manual_user_create',
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#qLeaderboardAdminInsertUser.id#,#qLeaderboardAdminInsertUser.email#,#qLeaderboardAdminInsertPage.id_pagina#,#qLeaderboardAdminInsertPage.tag#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#isDefined('COOKIE.id') ? COOKIE.id : cgi.remote_addr#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>
                )
            </cfquery>
        <cfcatch type="any"></cfcatch>
        </cftry>

        <cflocation addtoken="false" url="./?status=criado&user_id=#qLeaderboardAdminInsertUser.id#&page_id=#qLeaderboardAdminInsertPage.id_pagina#&tag=#urlEncodedFormat(qLeaderboardAdminInsertPage.tag)#"/>
    <cfcatch type="any">
        <cflocation addtoken="false" url="./?status=erro&error=#urlEncodedFormat(len(trim(cfcatch.message)) ? cfcatch.message : 'erro_inesperado')#"/>
    </cfcatch>
    </cftry>
</cfif>

<cfquery name="qLeaderboardAdminCountries">
    SELECT cod_alpha2,
           COALESCE(nome_pais_br, nome_pais) AS nome_pais
    FROM tb_paises_iso3166
    ORDER BY COALESCE(nome_pais_br, nome_pais)
</cfquery>
