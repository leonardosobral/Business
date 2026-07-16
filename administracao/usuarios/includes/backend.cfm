<cfscript>
function userManagerBoolean(any value = "", boolean fallback = false) {
    if (isBoolean(arguments.value)) {
        return arguments.value;
    }

    if (isNull(arguments.value)) {
        return arguments.fallback;
    }

    return listFindNoCase("1,true,yes,on,sim", trim(arguments.value & "")) GT 0;
}

function userManagerFormValue(required string fieldName, string fallback = "") {
    return structKeyExists(FORM, arguments.fieldName) ? trim(FORM[arguments.fieldName] & "") : arguments.fallback;
}

function userManagerFormBoolean(required string fieldName, boolean fallback = false) {
    if (!structKeyExists(FORM, arguments.fieldName)) {
        return arguments.fallback;
    }

    return userManagerBoolean(FORM[arguments.fieldName], arguments.fallback);
}

function userManagerSlugify(required string value) {
    var slugValue = lCase(trim(arguments.value));

    slugValue = replaceList(slugValue, "à,á,â,ã,ä,é,è,ë,ê,í,ì,ï,î,ó,ò,õ,ö,ô,ú,ù,ü,û,ç", "a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c");
    slugValue = reReplace(slugValue, "[^a-z0-9]+", "-", "all");
    slugValue = reReplace(slugValue, "^-+|-+$", "", "all");

    return len(slugValue) ? slugValue : "atleta";
}

function userManagerPlaceholderEmail() {
    return "atleta-manual-" & left(lCase(replace(createUUID(), "-", "", "all")), 12) & "@temporario.roadrunners.invalid";
}

function userManagerAudit(
    required string actionName,
    required numeric targetUserId,
    required numeric targetPageId,
    required struct beforeData,
    required struct afterData
) {
    if (!VARIABLES.userManagerSchemaReady) {
        return;
    }

    queryExecute(
        "INSERT INTO tb_usuarios_gestao_auditoria
            (id_usuario_alvo, id_pagina_alvo, id_usuario_autor, acao, dados_anteriores, dados_novos, endereco_ip, user_agent)
         VALUES
            (:target_user_id, :target_page_id, :actor_user_id, :action_name, cast(:before_json AS jsonb), cast(:after_json AS jsonb), :remote_ip, :user_agent)",
        {
            target_user_id = { value = arguments.targetUserId GT 0 ? arguments.targetUserId : 0, cfsqltype = "cf_sql_integer", null = arguments.targetUserId LTE 0 },
            target_page_id = { value = arguments.targetPageId GT 0 ? arguments.targetPageId : 0, cfsqltype = "cf_sql_integer", null = arguments.targetPageId LTE 0 },
            actor_user_id = { value = VARIABLES.userManagerActorId, cfsqltype = "cf_sql_integer" },
            action_name = { value = left(arguments.actionName, 64), cfsqltype = "cf_sql_varchar" },
            before_json = { value = serializeJSON(arguments.beforeData), cfsqltype = "cf_sql_longvarchar" },
            after_json = { value = serializeJSON(arguments.afterData), cfsqltype = "cf_sql_longvarchar" },
            remote_ip = { value = left(structKeyExists(CGI, "remote_addr") ? CGI.remote_addr : "", 64), cfsqltype = "cf_sql_varchar" },
            user_agent = { value = left(structKeyExists(CGI, "http_user_agent") ? CGI.http_user_agent : "", 512), cfsqltype = "cf_sql_varchar" }
        }
    );
}

function userManagerMutationAccess(required numeric targetUserId, boolean destructive = false, boolean allowDeleted = false) {
    var result = { allowed = false, message = "Usuário não encontrado." };
    var targetQuery = queryExecute(
        "SELECT usr.id, usr.name, usr.email,
                coalesce(usr.is_admin, false) AS is_admin,
                coalesce(usr.is_dev, false) AS is_dev,
                coalesce(gest.excluido, false) AS gestao_excluido
         FROM tb_usuarios usr
         LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario = usr.id
         WHERE usr.id = :target_user_id",
        { target_user_id = { value = arguments.targetUserId, cfsqltype = "cf_sql_integer" } }
    );

    if (!targetQuery.recordcount) {
        return result;
    }

    result.target = queryGetRow(targetQuery, 1);

    if (arguments.destructive && arguments.targetUserId EQ VARIABLES.userManagerActorId) {
        result.message = "Você não pode desativar ou excluir a própria conta por este painel.";
        return result;
    }

    if (!arguments.allowDeleted && userManagerBoolean(targetQuery.gestao_excluido)) {
        result.message = "Restaure a conta excluída antes de realizar esta operação.";
        return result;
    }

    result.allowed = true;
    result.message = "";
    return result;
}
</cfscript>

<cfparam name="URL.pagina" default="1"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.status" default="ativos"/>
<cfparam name="URL.papel" default="todos"/>
<cfparam name="URL.user_id" default="0"/>
<cfparam name="URL.novo" default="0"/>
<cfparam name="URL.aba" default="conta"/>
<cfparam name="URL.feedback" default=""/>
<cfparam name="URL.mensagem" default=""/>

<cfset VARIABLES.userManagerActorId = val(qPerfil.id)/>
<cfset VARIABLES.userManagerActorIsAdmin = userManagerBoolean(qPerfil.is_admin)/>
<cfset VARIABLES.userManagerActorIsDev = userManagerBoolean(qPerfil.is_dev)/>
<cfset VARIABLES.userManagerActorCanManageAll = VARIABLES.userManagerActorIsAdmin OR VARIABLES.userManagerActorIsDev/>
<cfset VARIABLES.userManagerPage = max(1, val(URL.pagina))/>
<cfset VARIABLES.userManagerPerPage = 30/>
<cfset VARIABLES.userManagerOffset = (VARIABLES.userManagerPage - 1) * VARIABLES.userManagerPerPage/>
<cfset VARIABLES.userManagerSearch = trim(URL.busca & "")/>
<cfset VARIABLES.userManagerStatus = listFindNoCase("ativos,inativos,excluidos,todos", URL.status & "") ? lCase(URL.status) : "ativos"/>
<cfset VARIABLES.userManagerRole = listFindNoCase("todos,admin,dev,partner,com_strava,sem_pagina", URL.papel & "") ? lCase(URL.papel) : "todos"/>
<cfset VARIABLES.userManagerUserId = isValid("integer", URL.user_id) ? val(URL.user_id) : 0/>
<cfset VARIABLES.userManagerIsNew = userManagerBoolean(URL.novo)/>
<cfset VARIABLES.userManagerTab = listFindNoCase("conta,paginas,agendas,resultados,social,auditoria", URL.aba & "") ? lCase(URL.aba) : "conta"/>
<cfset VARIABLES.userManagerFeedback = trim(URL.feedback & "")/>
<cfset VARIABLES.userManagerMessage = trim(URL.mensagem & "")/>

<cfquery name="qUserManagerSchema">
    SELECT
        to_regclass('public.tb_usuarios_gestao') IS NOT NULL AS has_user_state,
        to_regclass('public.tb_paginas_gestao') IS NOT NULL AS has_page_state,
        to_regclass('public.tb_usuarios_gestao_auditoria') IS NOT NULL AS has_audit,
        to_regclass('public.tb_agendas') IS NOT NULL AS has_agendas
</cfquery>
<cfset VARIABLES.userManagerSchemaReady = userManagerBoolean(qUserManagerSchema.has_user_state) AND userManagerBoolean(qUserManagerSchema.has_page_state) AND userManagerBoolean(qUserManagerSchema.has_audit)/>
<cfset VARIABLES.userManagerHasAgendas = userManagerBoolean(qUserManagerSchema.has_agendas)/>

<cfif NOT structKeyExists(SESSION, "businessUserManagerCsrf") OR !len(trim(SESSION.businessUserManagerCsrf & ""))>
    <cfset SESSION.businessUserManagerCsrf = hash(createUUID() & now() & VARIABLES.userManagerActorId, "SHA-256")/>
</cfif>
<cfset VARIABLES.userManagerCsrf = SESSION.businessUserManagerCsrf/>

<cfif structKeyExists(FORM, "user_manager_action") AND len(trim(FORM.user_manager_action & ""))>
    <cfset VARIABLES.userManagerAction = lCase(trim(FORM.user_manager_action & ""))/>
    <cfset VARIABLES.userManagerPostedToken = userManagerFormValue("user_manager_csrf")/>
    <cfset VARIABLES.userManagerActionUserId = val(userManagerFormValue("user_id", "0"))/>
    <cfset VARIABLES.userManagerActionPageId = val(userManagerFormValue("page_id", "0"))/>
    <cfset VARIABLES.userManagerRedirectTab = userManagerFormValue("return_tab", "conta")/>
    <cfset VARIABLES.userManagerRedirectTab = listFindNoCase("conta,paginas,agendas,resultados,social,auditoria", VARIABLES.userManagerRedirectTab) ? lCase(VARIABLES.userManagerRedirectTab) : "conta"/>

    <cfif !len(VARIABLES.userManagerPostedToken) OR VARIABLES.userManagerPostedToken NEQ VARIABLES.userManagerCsrf>
        <cflocation addtoken="false" url="./?feedback=erro&mensagem=#urlEncodedFormat('A sessão do formulário expirou. Recarregue a página e tente novamente.')#"/>
    </cfif>

    <cfif !VARIABLES.userManagerSchemaReady>
        <cflocation addtoken="false" url="./?feedback=erro&mensagem=#urlEncodedFormat('Aplique user_management_schema.sql antes de usar as ações do gerenciador.')#"/>
    </cfif>

    <cftry>
        <cfswitch expression="#VARIABLES.userManagerAction#">
            <cfcase value="logar_como_dev">
                <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerActionUserId)/>
                <cfif !VARIABLES.userManagerAccess.allowed>
                    <cfthrow message="#VARIABLES.userManagerAccess.message#"/>
                </cfif>

                <cfquery name="qUserManagerHandoffUsers">
                    SELECT usr.id,
                           usr.email,
                           coalesce(usr.is_admin, false) AS is_admin,
                           coalesce(usr.is_dev, false) AS is_dev,
                           coalesce(gest.ativo, true) AS gestao_ativo,
                           coalesce(gest.excluido, false) AS gestao_excluido,
                           EXISTS (
                               SELECT 1
                               FROM tb_paginas_usuarios pu
                               INNER JOIN tb_paginas pag ON pag.id_pagina = pu.id_pagina
                               LEFT JOIN tb_paginas_gestao paggest ON paggest.id_pagina = pag.id_pagina
                               WHERE pu.id_usuario = usr.id
                                 AND coalesce(paggest.ativo, true) = true
                                 AND coalesce(paggest.excluido, false) = false
                           ) AS has_active_page
                    FROM tb_usuarios usr
                    LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario = usr.id
                    WHERE usr.id IN (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                    )
                </cfquery>

                <cfquery name="qUserManagerHandoffActor" dbtype="query">
                    SELECT * FROM qUserManagerHandoffUsers
                    WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                </cfquery>
                <cfquery name="qUserManagerHandoffTarget" dbtype="query">
                    SELECT * FROM qUserManagerHandoffUsers
                    WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                </cfquery>

                <cfif !qUserManagerHandoffActor.recordcount
                    OR !(userManagerBoolean(qUserManagerHandoffActor.is_admin) OR userManagerBoolean(qUserManagerHandoffActor.is_dev))>
                    <cfthrow message="Sua conta não possui autorização para iniciar a sessão no DEV."/>
                </cfif>
                <cfif !userManagerBoolean(qUserManagerHandoffActor.gestao_ativo)
                    OR userManagerBoolean(qUserManagerHandoffActor.gestao_excluido)
                    OR !userManagerBoolean(qUserManagerHandoffActor.has_active_page)>
                    <cfthrow message="Sua conta precisa estar ativa e vinculada a uma página ativa no Road Runners para iniciar o handoff."/>
                </cfif>
                <cfif !qUserManagerHandoffTarget.recordcount
                    OR !userManagerBoolean(qUserManagerHandoffTarget.gestao_ativo)
                    OR userManagerBoolean(qUserManagerHandoffTarget.gestao_excluido)>
                    <cfthrow message="A conta escolhida está inativa ou excluída."/>
                </cfif>
                <cfif !userManagerBoolean(qUserManagerHandoffTarget.has_active_page)>
                    <cfthrow message="A conta escolhida precisa ter pelo menos uma página ativa para ser carregada no DEV."/>
                </cfif>
                <cfif !structKeyExists(APPLICATION, "notificationDispatch")
                    OR !isStruct(APPLICATION.notificationDispatch)
                    OR !structKeyExists(APPLICATION.notificationDispatch, "secret")
                    OR !len(trim(APPLICATION.notificationDispatch.secret & ""))>
                    <cfthrow message="O segredo compartilhado de handoff não está configurado no Business."/>
                </cfif>

                <cfset VARIABLES.userManagerHandoffPayload = {
                    issuedAt = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
                    expiresAt = dateTimeFormat(dateAdd("s", 180, now()), "yyyy-mm-dd HH:nn:ss"),
                    origin = "business",
                    target = "dev",
                    originalUsuarioId = VARIABLES.userManagerActorId,
                    impersonateEmail = trim(qUserManagerHandoffTarget.email & ""),
                    redirectPath = "/atleta/",
                    nonce = createUUID()
                }/>
                <cfset VARIABLES.userManagerHandoffPayloadEncoded = toBase64(serializeJSON(VARIABLES.userManagerHandoffPayload))/>
                <cfset VARIABLES.userManagerHandoffSignature = lCase(hmac(
                    VARIABLES.userManagerHandoffPayloadEncoded,
                    APPLICATION.notificationDispatch.secret,
                    "HmacSHA256"
                ))/>
                <cfset VARIABLES.userManagerHandoffToken = VARIABLES.userManagerHandoffPayloadEncoded & "." & VARIABLES.userManagerHandoffSignature/>
                <cfset VARIABLES.userManagerHandoffUrl = "https://dev.roadrunners.run/?action=handoff_consume&token=" & urlEncodedFormat(VARIABLES.userManagerHandoffToken)/>

                <cfset userManagerAudit(
                    "usuario_impersonado_dev",
                    VARIABLES.userManagerActionUserId,
                    0,
                    {},
                    { ambiente = "dev", operador = VARIABLES.userManagerActorId }
                )/>
                <cflocation addtoken="false" url="#VARIABLES.userManagerHandoffUrl#"/>
            </cfcase>

            <cfcase value="salvar_usuario">
                <cfset VARIABLES.userManagerSaveName = userManagerFormValue("name")/>
                <cfset VARIABLES.userManagerSaveEmail = lCase(userManagerFormValue("email"))/>
                <cfset VARIABLES.userManagerSaveUserId = VARIABLES.userManagerActionUserId/>

                <cfif !len(VARIABLES.userManagerSaveName)>
                    <cfthrow message="Informe o nome do usuário."/>
                </cfif>
                <cfif !len(VARIABLES.userManagerSaveEmail)>
                    <cfset VARIABLES.userManagerSaveEmail = userManagerPlaceholderEmail()/>
                </cfif>
                <cfif !isValid("email", VARIABLES.userManagerSaveEmail)>
                    <cfthrow message="Informe um e-mail válido ou deixe o campo vazio para gerar um endereço temporário."/>
                </cfif>

                <cfquery name="qUserManagerDuplicateEmail">
                    SELECT id
                    FROM tb_usuarios
                    WHERE lower(email) = lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerSaveEmail#"/>)
                    <cfif VARIABLES.userManagerSaveUserId GT 0>
                        AND id <> <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerSaveUserId#"/>
                    </cfif>
                    LIMIT 1
                </cfquery>
                <cfif qUserManagerDuplicateEmail.recordcount>
                    <cfthrow message="Já existe uma conta com este e-mail."/>
                </cfif>

                <cfif VARIABLES.userManagerSaveUserId GT 0>
                    <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerSaveUserId)/>
                    <cfif !VARIABLES.userManagerAccess.allowed>
                        <cfthrow message="#VARIABLES.userManagerAccess.message#"/>
                    </cfif>
                    <cfif VARIABLES.userManagerSaveUserId EQ VARIABLES.userManagerActorId
                        AND NOT userManagerFormBoolean("is_admin")
                        AND NOT userManagerFormBoolean("is_dev")>
                        <cfthrow message="Mantenha pelo menos uma permissão ADMIN ou DEV na própria conta para não perder o acesso administrativo."/>
                    </cfif>

                    <cfquery name="qUserManagerBeforeSave">
                        SELECT id, name, email, username, aka, genero, pais, estado, cidade, cbat, assessoria,
                               is_admin, is_dev, is_partner, is_email_verified, optin_usuario
                        FROM tb_usuarios
                        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerSaveUserId#"/>
                    </cfquery>

                    <cfquery>
                        UPDATE tb_usuarios
                        SET name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerSaveName#"/>,
                            email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerSaveEmail#"/>,
                            username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('username')#" null="#!len(userManagerFormValue('username'))#"/>,
                            aka = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('aka')#" null="#!len(userManagerFormValue('aka'))#"/>,
                            genero = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('genero')#" null="#!len(userManagerFormValue('genero'))#"/>,
                            pais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(userManagerFormValue('pais', 'BR'))#"/>,
                            estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(userManagerFormValue('estado'))#" null="#!len(userManagerFormValue('estado'))#"/>,
                            cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('cidade')#" null="#!len(userManagerFormValue('cidade'))#"/>,
                            cep = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('cep')#" null="#!len(userManagerFormValue('cep'))#"/>,
                            endereco = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('endereco')#" null="#!len(userManagerFormValue('endereco'))#"/>,
                            data_nascimento = <cfqueryparam cfsqltype="cf_sql_date" value="#len(userManagerFormValue('data_nascimento')) ? userManagerFormValue('data_nascimento') : now()#" null="#!len(userManagerFormValue('data_nascimento'))#"/>,
                            ano_nascimento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(userManagerFormValue('ano_nascimento'))#" null="#val(userManagerFormValue('ano_nascimento')) LTE 0#"/>,
                            cbat = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('cbat')#" null="#!len(userManagerFormValue('cbat'))#"/>,
                            assessoria = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('assessoria')#" null="#!len(userManagerFormValue('assessoria'))#"/>,
                            ddi_usuario = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('ddi_usuario')#" null="#!len(userManagerFormValue('ddi_usuario'))#"/>,
                            ddd_usuario = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('ddd_usuario')#" null="#!len(userManagerFormValue('ddd_usuario'))#"/>,
                            telefone_usuario = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('telefone_usuario')#" null="#!len(userManagerFormValue('telefone_usuario'))#"/>,
                            imagem_usuario = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('imagem_usuario')#" null="#!len(userManagerFormValue('imagem_usuario'))#"/>,
                            tag_usuario = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('tag_usuario')#" null="#!len(userManagerFormValue('tag_usuario'))#"/>,
                            url_usuario = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('url_usuario')#" null="#!len(userManagerFormValue('url_usuario'))#"/>,
                            fonte_lead = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('fonte_lead')#" null="#!len(userManagerFormValue('fonte_lead'))#"/>,
                            manychat_subscriber_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#val(userManagerFormValue('manychat_subscriber_id'))#" null="#val(userManagerFormValue('manychat_subscriber_id')) LTE 0#"/>,
                            is_email_verified = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('is_email_verified')#"/>,
                            optin_usuario = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('optin_usuario')#"/>,
                            <cfif VARIABLES.userManagerActorCanManageAll>
                                is_admin = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('is_admin')#"/>,
                                is_dev = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('is_dev')#"/>,
                                is_partner = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('is_partner')#"/>,
                            </cfif>
                            data_alteracao = now()
                        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerSaveUserId#"/>
                    </cfquery>

                    <cfquery name="qUserManagerAfterSave">
                        SELECT id, name, email, username, aka, genero, pais, estado, cidade, cbat, assessoria,
                               is_admin, is_dev, is_partner, is_email_verified, optin_usuario
                        FROM tb_usuarios
                        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerSaveUserId#"/>
                    </cfquery>
                    <cfset userManagerAudit("usuario_atualizado", VARIABLES.userManagerSaveUserId, 0, queryGetRow(qUserManagerBeforeSave, 1), queryGetRow(qUserManagerAfterSave, 1))/>
                <cfelse>
                    <cfset VARIABLES.userManagerVerificationKey = lCase(replace(createUUID(), "-", "", "all"))/>
                    <cftransaction>
                        <cfquery name="qUserManagerCreatedUser">
                            INSERT INTO tb_usuarios
                            (
                                name, email, password, verification_key, is_email_verified, optin_usuario,
                                genero, pais, estado, cidade, data_nascimento, ano_nascimento, cbat, assessoria,
                                ddi_usuario, ddd_usuario, telefone_usuario, imagem_usuario,
                                <cfif VARIABLES.userManagerActorCanManageAll>is_admin, is_dev, is_partner,</cfif>
                                fonte_lead
                            )
                            VALUES
                            (
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerSaveName#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerSaveEmail#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerVerificationKey#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerVerificationKey#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('is_email_verified', true)#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('optin_usuario', true)#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('genero')#" null="#!len(userManagerFormValue('genero'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(userManagerFormValue('pais', 'BR'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(userManagerFormValue('estado'))#" null="#!len(userManagerFormValue('estado'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('cidade')#" null="#!len(userManagerFormValue('cidade'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_date" value="#len(userManagerFormValue('data_nascimento')) ? userManagerFormValue('data_nascimento') : now()#" null="#!len(userManagerFormValue('data_nascimento'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#val(userManagerFormValue('ano_nascimento'))#" null="#val(userManagerFormValue('ano_nascimento')) LTE 0#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('cbat')#" null="#!len(userManagerFormValue('cbat'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('assessoria')#" null="#!len(userManagerFormValue('assessoria'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('ddi_usuario')#" null="#!len(userManagerFormValue('ddi_usuario'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('ddd_usuario')#" null="#!len(userManagerFormValue('ddd_usuario'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('telefone_usuario')#" null="#!len(userManagerFormValue('telefone_usuario'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('imagem_usuario')#" null="#!len(userManagerFormValue('imagem_usuario'))#"/>,
                                <cfif VARIABLES.userManagerActorCanManageAll>
                                    <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('is_admin')#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('is_dev')#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('is_partner')#"/>,
                                </cfif>
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="business_user_manager"/>
                            )
                            RETURNING id
                        </cfquery>
                        <cfset VARIABLES.userManagerSaveUserId = val(qUserManagerCreatedUser.id)/>

                        <cfquery>
                            INSERT INTO tb_usuarios_gestao (id_usuario, ativo, excluido, id_usuario_alteracao)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerSaveUserId#"/>,
                                true,
                                false,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                            )
                        </cfquery>

                        <cfif userManagerFormBoolean("criar_pagina", true)>
                            <cfset VARIABLES.userManagerCreatedTag = userManagerSlugify(VARIABLES.userManagerSaveName)/>
                            <cfquery name="qUserManagerCreatedTagCheck">
                                SELECT id_pagina FROM tb_paginas
                                WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerCreatedTag#"/>
                            </cfquery>
                            <cfif qUserManagerCreatedTagCheck.recordcount>
                                <cfset VARIABLES.userManagerCreatedTag &= "-" & VARIABLES.userManagerSaveUserId/>
                            </cfif>

                            <cfquery name="qUserManagerCreatedPage">
                                INSERT INTO tb_paginas (id_usuario_cadastro, nome, tag, tag_prefix, perfil_publico)
                                VALUES (
                                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerSaveUserId#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerSaveName#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerCreatedTag#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="atleta"/>,
                                    true
                                )
                                RETURNING id_pagina
                            </cfquery>
                            <cfquery>
                                INSERT INTO tb_paginas_usuarios (id_pagina, id_usuario)
                                VALUES (
                                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qUserManagerCreatedPage.id_pagina#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerSaveUserId#"/>
                                )
                            </cfquery>
                            <cfquery>
                                INSERT INTO tb_paginas_gestao (id_pagina, ativo, excluido, id_usuario_alteracao)
                                VALUES (
                                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qUserManagerCreatedPage.id_pagina#"/>,
                                    true,
                                    false,
                                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                                )
                            </cfquery>
                        </cfif>
                    </cftransaction>

                    <cfset userManagerAudit("usuario_criado", VARIABLES.userManagerSaveUserId, 0, {}, { name = VARIABLES.userManagerSaveName, email = VARIABLES.userManagerSaveEmail })/>
                </cfif>

                <cflocation addtoken="false" url="./?user_id=#VARIABLES.userManagerSaveUserId#&aba=conta&feedback=sucesso&mensagem=#urlEncodedFormat('Dados da conta salvos com sucesso.')#"/>
            </cfcase>

            <cfcase value="alternar_usuario">
                <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerActionUserId, true)/>
                <cfif !VARIABLES.userManagerAccess.allowed><cfthrow message="#VARIABLES.userManagerAccess.message#"/></cfif>
                <cfset VARIABLES.userManagerNextActive = userManagerFormBoolean("ativo")/>

                <cfquery name="qUserManagerCurrentState">
                    SELECT coalesce(gest.ativo, true) AS ativo, coalesce(gest.excluido, false) AS excluido
                    FROM tb_usuarios usr
                    LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario = usr.id
                    WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                </cfquery>
                <cfif userManagerBoolean(qUserManagerCurrentState.excluido)>
                    <cfthrow message="Restaure a conta excluída antes de ativá-la."/>
                </cfif>

                <cfquery>
                    INSERT INTO tb_usuarios_gestao (id_usuario, ativo, excluido, motivo, data_alteracao, id_usuario_alteracao)
                    VALUES (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.userManagerNextActive#"/>,
                        false,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('motivo')#" null="#!len(userManagerFormValue('motivo'))#"/>,
                        now(),
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                    )
                    ON CONFLICT (id_usuario)
                    DO UPDATE SET ativo = excluded.ativo,
                                  motivo = excluded.motivo,
                                  data_alteracao = now(),
                                  id_usuario_alteracao = excluded.id_usuario_alteracao
                </cfquery>
                <cfset userManagerAudit(VARIABLES.userManagerNextActive ? "usuario_ativado" : "usuario_desativado", VARIABLES.userManagerActionUserId, 0, { ativo = userManagerBoolean(qUserManagerCurrentState.ativo) }, { ativo = VARIABLES.userManagerNextActive })/>
                <cflocation addtoken="false" url="./?user_id=#VARIABLES.userManagerActionUserId#&aba=conta&feedback=sucesso&mensagem=#urlEncodedFormat(VARIABLES.userManagerNextActive ? 'Conta ativada.' : 'Conta desativada e o acesso à plataforma foi bloqueado.')#"/>
            </cfcase>

            <cfcase value="excluir_usuario">
                <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerActionUserId, true)/>
                <cfif !VARIABLES.userManagerAccess.allowed><cfthrow message="#VARIABLES.userManagerAccess.message#"/></cfif>
                <cfquery>
                    INSERT INTO tb_usuarios_gestao
                        (id_usuario, ativo, excluido, motivo, data_alteracao, id_usuario_alteracao, data_exclusao, id_usuario_exclusao)
                    VALUES (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>,
                        false,
                        true,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('motivo', 'Exclusão administrativa')#"/>,
                        now(),
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>,
                        now(),
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                    )
                    ON CONFLICT (id_usuario)
                    DO UPDATE SET ativo = false,
                                  excluido = true,
                                  motivo = excluded.motivo,
                                  data_alteracao = now(),
                                  id_usuario_alteracao = excluded.id_usuario_alteracao,
                                  data_exclusao = now(),
                                  id_usuario_exclusao = excluded.id_usuario_exclusao
                </cfquery>
                <cfquery>
                    INSERT INTO tb_paginas_gestao
                        (id_pagina, ativo, excluido, motivo, data_alteracao, id_usuario_alteracao, data_exclusao, id_usuario_exclusao)
                    SELECT pu.id_pagina, false, true,
                           <cfqueryparam cfsqltype="cf_sql_varchar" value="Conta proprietária excluída"/>,
                           now(),
                           <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>,
                           now(),
                           <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                    FROM tb_paginas_usuarios pu
                    WHERE pu.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                    ON CONFLICT (id_pagina)
                    DO UPDATE SET ativo = false,
                                  excluido = true,
                                  motivo = excluded.motivo,
                                  data_alteracao = now(),
                                  id_usuario_alteracao = excluded.id_usuario_alteracao,
                                  data_exclusao = now(),
                                  id_usuario_exclusao = excluded.id_usuario_exclusao
                </cfquery>
                <cfset userManagerAudit("usuario_excluido", VARIABLES.userManagerActionUserId, 0, {}, { excluido = true, preservou_historico = true })/>
                <cflocation addtoken="false" url="./?status=excluidos&feedback=sucesso&mensagem=#urlEncodedFormat('Conta excluída logicamente. Os dados históricos foram preservados.')#"/>
            </cfcase>

            <cfcase value="restaurar_usuario">
                <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerActionUserId, false, true)/>
                <cfif !VARIABLES.userManagerAccess.allowed><cfthrow message="#VARIABLES.userManagerAccess.message#"/></cfif>
                <cfquery>
                    UPDATE tb_usuarios_gestao
                    SET ativo = true,
                        excluido = false,
                        motivo = null,
                        data_alteracao = now(),
                        id_usuario_alteracao = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>,
                        data_exclusao = null,
                        id_usuario_exclusao = null
                    WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                </cfquery>
                <cfset userManagerAudit("usuario_restaurado", VARIABLES.userManagerActionUserId, 0, { excluido = true }, { ativo = true, excluido = false })/>
                <cflocation addtoken="false" url="./?user_id=#VARIABLES.userManagerActionUserId#&feedback=sucesso&mensagem=#urlEncodedFormat('Conta restaurada. Reative os perfis desejados na aba Páginas.')#"/>
            </cfcase>

            <cfcase value="salvar_pagina">
                <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerActionUserId)/>
                <cfif !VARIABLES.userManagerAccess.allowed><cfthrow message="#VARIABLES.userManagerAccess.message#"/></cfif>
                <cfset VARIABLES.userManagerPageName = userManagerFormValue("nome")/>
                <cfset VARIABLES.userManagerPageTag = userManagerSlugify(userManagerFormValue("tag", VARIABLES.userManagerPageName))/>
                <cfif !len(VARIABLES.userManagerPageName)><cfthrow message="Informe o nome da página."/></cfif>

                <cfquery name="qUserManagerTagDuplicate">
                    SELECT id_pagina FROM tb_paginas
                    WHERE lower(tag) = lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerPageTag#"/>)
                    <cfif VARIABLES.userManagerActionPageId GT 0>
                        AND id_pagina <> <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>
                    </cfif>
                    LIMIT 1
                </cfquery>
                <cfif qUserManagerTagDuplicate.recordcount><cfthrow message="Já existe uma página com este slug."/></cfif>

                <cfif VARIABLES.userManagerActionPageId GT 0>
                    <cfquery name="qUserManagerOwnedPage">
                        SELECT pag.*
                        FROM tb_paginas pag
                        INNER JOIN tb_paginas_usuarios pu ON pu.id_pagina = pag.id_pagina
                        WHERE pag.id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>
                          AND pu.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                    </cfquery>
                    <cfif !qUserManagerOwnedPage.recordcount><cfthrow message="Página não vinculada a este usuário."/></cfif>

                    <cfquery>
                        UPDATE tb_paginas
                        SET nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerPageName#"/>,
                            apelido = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('apelido')#" null="#!len(userManagerFormValue('apelido'))#"/>,
                            tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerPageTag#"/>,
                            tag_prefix = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('tag_prefix', 'atleta')#"/>,
                            descricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('descricao')#" null="#!len(userManagerFormValue('descricao'))#"/>,
                            cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('pagina_cidade')#" null="#!len(userManagerFormValue('pagina_cidade'))#"/>,
                            uf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(userManagerFormValue('pagina_uf'))#" null="#!len(userManagerFormValue('pagina_uf'))#"/>,
                            id_cidade = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(userManagerFormValue('id_cidade'))#" null="#val(userManagerFormValue('id_cidade')) LTE 0#"/>,
                            path_imagem = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('path_imagem')#" null="#!len(userManagerFormValue('path_imagem'))#"/>,
                            verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('verificado')#"/>,
                            profissional = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('profissional')#"/>,
                            perfil_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('perfil_publico')#"/>,
                            instagram = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('instagram')#" null="#!len(userManagerFormValue('instagram'))#"/>,
                            instagram_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('instagram_publico')#"/>,
                            facebook = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('facebook')#" null="#!len(userManagerFormValue('facebook'))#"/>,
                            facebook_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('facebook_publico')#"/>,
                            whatsapp = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('whatsapp')#" null="#!len(userManagerFormValue('whatsapp'))#"/>,
                            whatsapp_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('whatsapp_publico')#"/>,
                            website = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('website')#" null="#!len(userManagerFormValue('website'))#"/>,
                            website_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('website_publico')#"/>,
                            youtube = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('youtube')#" null="#!len(userManagerFormValue('youtube'))#"/>,
                            youtube_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('youtube_publico')#"/>,
                            tiktok = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('tiktok')#" null="#!len(userManagerFormValue('tiktok'))#"/>,
                            tiktok_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('tiktok_publico')#"/>,
                            loja = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('loja')#" null="#!len(userManagerFormValue('loja'))#"/>,
                            loja_publico = <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('loja_publico')#"/>
                        WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>
                    </cfquery>
                    <cfset userManagerAudit("pagina_atualizada", VARIABLES.userManagerActionUserId, VARIABLES.userManagerActionPageId, queryGetRow(qUserManagerOwnedPage, 1), { nome = VARIABLES.userManagerPageName, tag = VARIABLES.userManagerPageTag })/>
                <cfelse>
                    <cftransaction>
                        <cfquery name="qUserManagerInsertedPage">
                            INSERT INTO tb_paginas
                                (
                                    id_usuario_cadastro, nome, apelido, tag, tag_prefix, descricao, cidade, uf, id_cidade,
                                    path_imagem, verificado, profissional, perfil_publico,
                                    instagram, instagram_publico, facebook, facebook_publico,
                                    whatsapp, whatsapp_publico, website, website_publico,
                                    youtube, youtube_publico, tiktok, tiktok_publico, loja, loja_publico
                                )
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerPageName#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('apelido')#" null="#!len(userManagerFormValue('apelido'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.userManagerPageTag#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('tag_prefix', 'atleta')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('descricao')#" null="#!len(userManagerFormValue('descricao'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('pagina_cidade')#" null="#!len(userManagerFormValue('pagina_cidade'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(userManagerFormValue('pagina_uf'))#" null="#!len(userManagerFormValue('pagina_uf'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#val(userManagerFormValue('id_cidade'))#" null="#val(userManagerFormValue('id_cidade')) LTE 0#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('path_imagem')#" null="#!len(userManagerFormValue('path_imagem'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('verificado')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('profissional')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('perfil_publico', true)#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('instagram')#" null="#!len(userManagerFormValue('instagram'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('instagram_publico')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('facebook')#" null="#!len(userManagerFormValue('facebook'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('facebook_publico')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('whatsapp')#" null="#!len(userManagerFormValue('whatsapp'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('whatsapp_publico')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('website')#" null="#!len(userManagerFormValue('website'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('website_publico')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('youtube')#" null="#!len(userManagerFormValue('youtube'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('youtube_publico')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('tiktok')#" null="#!len(userManagerFormValue('tiktok'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('tiktok_publico')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('loja')#" null="#!len(userManagerFormValue('loja'))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('loja_publico')#"/>
                            )
                            RETURNING id_pagina
                        </cfquery>
                        <cfset VARIABLES.userManagerActionPageId = val(qUserManagerInsertedPage.id_pagina)/>
                        <cfquery>
                            INSERT INTO tb_paginas_usuarios (id_pagina, id_usuario)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                            )
                        </cfquery>
                        <cfquery>
                            INSERT INTO tb_paginas_gestao (id_pagina, ativo, excluido, id_usuario_alteracao)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>,
                                true,
                                false,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                            )
                        </cfquery>
                    </cftransaction>
                    <cfset userManagerAudit("pagina_criada", VARIABLES.userManagerActionUserId, VARIABLES.userManagerActionPageId, {}, { nome = VARIABLES.userManagerPageName, tag = VARIABLES.userManagerPageTag })/>
                </cfif>
                <cflocation addtoken="false" url="./?user_id=#VARIABLES.userManagerActionUserId#&aba=paginas&feedback=sucesso&mensagem=#urlEncodedFormat('Página salva com sucesso.')#"/>
            </cfcase>

            <cfcase value="alternar_pagina,excluir_pagina,restaurar_pagina">
                <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerActionUserId, false, VARIABLES.userManagerAction EQ "restaurar_pagina")/>
                <cfif !VARIABLES.userManagerAccess.allowed><cfthrow message="#VARIABLES.userManagerAccess.message#"/></cfif>
                <cfquery name="qUserManagerPageOwnership">
                    SELECT pag.id_pagina, pag.nome, coalesce(gest.ativo, true) AS ativo, coalesce(gest.excluido, false) AS excluido
                    FROM tb_paginas pag
                    INNER JOIN tb_paginas_usuarios pu ON pu.id_pagina = pag.id_pagina
                    LEFT JOIN tb_paginas_gestao gest ON gest.id_pagina = pag.id_pagina
                    WHERE pag.id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>
                      AND pu.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                </cfquery>
                <cfif !qUserManagerPageOwnership.recordcount><cfthrow message="Página não vinculada a este usuário."/></cfif>

                <cfif VARIABLES.userManagerAction EQ "alternar_pagina">
                    <cfset VARIABLES.userManagerNextActive = userManagerFormBoolean("ativo")/>
                    <cfif userManagerBoolean(qUserManagerPageOwnership.excluido)><cfthrow message="Restaure a página antes de ativá-la."/></cfif>
                    <cfquery>
                        INSERT INTO tb_paginas_gestao (id_pagina, ativo, excluido, motivo, data_alteracao, id_usuario_alteracao)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.userManagerNextActive#"/>,
                            false,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('motivo')#" null="#!len(userManagerFormValue('motivo'))#"/>,
                            now(),
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                        )
                        ON CONFLICT (id_pagina)
                        DO UPDATE SET ativo = excluded.ativo, motivo = excluded.motivo,
                                      data_alteracao = now(), id_usuario_alteracao = excluded.id_usuario_alteracao
                    </cfquery>
                    <cfset VARIABLES.userManagerPageActionName = VARIABLES.userManagerNextActive ? "pagina_ativada" : "pagina_desativada"/>
                <cfelseif VARIABLES.userManagerAction EQ "excluir_pagina">
                    <cfquery>
                        INSERT INTO tb_paginas_gestao
                            (id_pagina, ativo, excluido, motivo, data_alteracao, id_usuario_alteracao, data_exclusao, id_usuario_exclusao)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>, false, true,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#userManagerFormValue('motivo', 'Exclusão administrativa')#"/>, now(),
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>, now(),
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                        )
                        ON CONFLICT (id_pagina)
                        DO UPDATE SET ativo = false, excluido = true, motivo = excluded.motivo,
                                      data_alteracao = now(), id_usuario_alteracao = excluded.id_usuario_alteracao,
                                      data_exclusao = now(), id_usuario_exclusao = excluded.id_usuario_exclusao
                    </cfquery>
                    <cfset VARIABLES.userManagerPageActionName = "pagina_excluida"/>
                <cfelse>
                    <cfquery>
                        UPDATE tb_paginas_gestao
                        SET ativo = true, excluido = false, motivo = null, data_alteracao = now(),
                            id_usuario_alteracao = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>,
                            data_exclusao = null, id_usuario_exclusao = null
                        WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionPageId#"/>
                    </cfquery>
                    <cfset VARIABLES.userManagerPageActionName = "pagina_restaurada"/>
                </cfif>

                <cfset userManagerAudit(VARIABLES.userManagerPageActionName, VARIABLES.userManagerActionUserId, VARIABLES.userManagerActionPageId, queryGetRow(qUserManagerPageOwnership, 1), { acao = VARIABLES.userManagerPageActionName })/>
                <cflocation addtoken="false" url="./?user_id=#VARIABLES.userManagerActionUserId#&aba=paginas&feedback=sucesso&mensagem=#urlEncodedFormat('Status da página atualizado.')#"/>
            </cfcase>

            <cfcase value="vincular_resultado,desvincular_resultado">
                <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerActionUserId)/>
                <cfif !VARIABLES.userManagerAccess.allowed><cfthrow message="#VARIABLES.userManagerAccess.message#"/></cfif>
                <cfset VARIABLES.userManagerResultId = val(userManagerFormValue("result_id", "0"))/>
                <cfif VARIABLES.userManagerResultId LTE 0><cfthrow message="Informe um ID de resultado válido."/></cfif>
                <cfquery name="qUserManagerResult">
                    SELECT id_resultado, id_usuario, nome, id_evento
                    FROM tb_resultados
                    WHERE id_resultado = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerResultId#"/>
                </cfquery>
                <cfif !qUserManagerResult.recordcount><cfthrow message="Resultado não encontrado."/></cfif>

                <cfif VARIABLES.userManagerAction EQ "vincular_resultado">
                    <cfif val(qUserManagerResult.id_usuario) GT 0 AND val(qUserManagerResult.id_usuario) NEQ VARIABLES.userManagerActionUserId>
                        <cfthrow message="Este resultado já está vinculado a outro usuário."/>
                    </cfif>
                    <cftransaction>
                        <cfquery>
                            UPDATE tb_resultados
                            SET id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                            WHERE id_resultado = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerResultId#"/>
                        </cfquery>
                        <cfquery>
                            INSERT INTO tb_resultados_vinculo
                                (id_resultado, id_usuario, vinculo_resultado, id_usuario_responsavel, vinculo_aprovado, data_aprovacao)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerResultId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>,
                                true,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>,
                                true,
                                now()
                            )
                            ON CONFLICT (id_resultado, id_usuario)
                            DO UPDATE SET vinculo_resultado = true, id_usuario_responsavel = excluded.id_usuario_responsavel,
                                          vinculo_aprovado = true, data_aprovacao = now()
                        </cfquery>
                    </cftransaction>
                    <cfset VARIABLES.userManagerResultActionName = "resultado_vinculado"/>
                <cfelse>
                    <cftransaction>
                        <cfquery>
                            UPDATE tb_resultados SET id_usuario = null
                            WHERE id_resultado = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerResultId#"/>
                              AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                        </cfquery>
                        <cfquery>
                            UPDATE tb_resultados_vinculo
                            SET vinculo_resultado = false, vinculo_aprovado = false, data_aprovacao = now(),
                                id_usuario_responsavel = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                            WHERE id_resultado = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerResultId#"/>
                              AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                        </cfquery>
                    </cftransaction>
                    <cfset VARIABLES.userManagerResultActionName = "resultado_desvinculado"/>
                </cfif>
                <cfset userManagerAudit(VARIABLES.userManagerResultActionName, VARIABLES.userManagerActionUserId, 0, queryGetRow(qUserManagerResult, 1), { id_resultado = VARIABLES.userManagerResultId })/>
                <cflocation addtoken="false" url="./?user_id=#VARIABLES.userManagerActionUserId#&aba=resultados&feedback=sucesso&mensagem=#urlEncodedFormat('Vínculo do resultado atualizado.')#"/>
            </cfcase>

            <cfcase value="adicionar_vinculo_social,aprovar_vinculo_social,remover_vinculo_social">
                <cfset VARIABLES.userManagerAccess = userManagerMutationAccess(VARIABLES.userManagerActionUserId)/>
                <cfif !VARIABLES.userManagerAccess.allowed><cfthrow message="#VARIABLES.userManagerAccess.message#"/></cfif>
                <cfset VARIABLES.userManagerOriginPageId = val(userManagerFormValue("origin_page_id", "0"))/>
                <cfset VARIABLES.userManagerDestinationPageId = val(userManagerFormValue("destination_page_id", "0"))/>
                <cfif VARIABLES.userManagerOriginPageId LTE 0 OR VARIABLES.userManagerDestinationPageId LTE 0 OR VARIABLES.userManagerOriginPageId EQ VARIABLES.userManagerDestinationPageId>
                    <cfthrow message="Informe páginas de origem e destino válidas."/>
                </cfif>

                <cfquery name="qUserManagerSocialOwnership">
                    SELECT count(*) AS total
                    FROM tb_paginas_usuarios
                    WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActionUserId#"/>
                      AND id_pagina IN (
                          <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerOriginPageId#"/>,
                          <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerDestinationPageId#"/>
                      )
                </cfquery>
                <cfif val(qUserManagerSocialOwnership.total) LTE 0><cfthrow message="O vínculo não envolve uma página deste usuário."/></cfif>

                <cfquery name="qUserManagerSocialPages">
                    SELECT count(*) AS total FROM tb_paginas
                    WHERE id_pagina IN (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerOriginPageId#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerDestinationPageId#"/>
                    )
                </cfquery>
                <cfif val(qUserManagerSocialPages.total) NEQ 2><cfthrow message="Uma das páginas informadas não existe."/></cfif>

                <cfif VARIABLES.userManagerAction EQ "adicionar_vinculo_social">
                    <cfquery>
                        INSERT INTO tb_paginas_vinculos
                            (id_pagina_origem, id_pagina_destino, tipo_vinculo, vinculo_validado, id_usuario_cadastro)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerOriginPageId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerDestinationPageId#"/>,
                            1,
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#userManagerFormBoolean('vinculo_validado', true)#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerActorId#"/>
                        )
                        ON CONFLICT (id_pagina_origem, id_pagina_destino, tipo_vinculo)
                        DO UPDATE SET vinculo_validado = excluded.vinculo_validado,
                                      id_usuario_cadastro = excluded.id_usuario_cadastro
                    </cfquery>
                    <cfset VARIABLES.userManagerSocialActionName = "vinculo_social_adicionado"/>
                <cfelseif VARIABLES.userManagerAction EQ "aprovar_vinculo_social">
                    <cfquery>
                        UPDATE tb_paginas_vinculos SET vinculo_validado = true
                        WHERE id_pagina_origem = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerOriginPageId#"/>
                          AND id_pagina_destino = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerDestinationPageId#"/>
                          AND tipo_vinculo = 1
                    </cfquery>
                    <cfset VARIABLES.userManagerSocialActionName = "vinculo_social_aprovado"/>
                <cfelse>
                    <cfquery>
                        DELETE FROM tb_paginas_vinculos
                        WHERE id_pagina_origem = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerOriginPageId#"/>
                          AND id_pagina_destino = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerDestinationPageId#"/>
                          AND tipo_vinculo = 1
                    </cfquery>
                    <cfset VARIABLES.userManagerSocialActionName = "vinculo_social_removido"/>
                </cfif>
                <cfset userManagerAudit(VARIABLES.userManagerSocialActionName, VARIABLES.userManagerActionUserId, 0, {}, { origem = VARIABLES.userManagerOriginPageId, destino = VARIABLES.userManagerDestinationPageId })/>
                <cflocation addtoken="false" url="./?user_id=#VARIABLES.userManagerActionUserId#&aba=social&feedback=sucesso&mensagem=#urlEncodedFormat('Relacionamento atualizado.')#"/>
            </cfcase>

            <cfdefaultcase>
                <cfthrow message="Ação não reconhecida."/>
            </cfdefaultcase>
        </cfswitch>
        <cfcatch type="any">
            <cfset VARIABLES.userManagerErrorTarget = VARIABLES.userManagerActionUserId GT 0 ? "&user_id=" & VARIABLES.userManagerActionUserId & "&aba=" & VARIABLES.userManagerRedirectTab : ""/>
            <cfset VARIABLES.userManagerErrorUrl = "./?feedback=erro&mensagem=" & urlEncodedFormat(len(trim(cfcatch.message & "")) ? cfcatch.message : "Não foi possível concluir a operação.") & VARIABLES.userManagerErrorTarget/>
            <cflocation addtoken="false" url="#VARIABLES.userManagerErrorUrl#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfquery name="qUserManagerCountries">
    SELECT cod_alpha2, coalesce(nome_pais_br, nome_pais) AS nome_pais
    FROM tb_paises_iso3166
    ORDER BY coalesce(nome_pais_br, nome_pais)
</cfquery>

<cfquery name="qUserManagerStates">
    SELECT uf, nome_uf FROM tb_uf ORDER BY nome_uf
</cfquery>

<cfset qUserManagerUser = queryNew("id")/>
<cfset qUserManagerPages = queryNew("id_pagina")/>
<cfset qUserManagerAgendas = queryNew("id_agenda")/>
<cfset qUserManagerResults = queryNew("id_resultado")/>
<cfset qUserManagerSocial = queryNew("id_pagina_origem")/>
<cfset qUserManagerAudit = queryNew("id_auditoria")/>

<cfif VARIABLES.userManagerUserId GT 0>
    <cfquery name="qUserManagerUser">
        SELECT usr.id, usr.name, usr.email, usr.is_email_verified, usr.data_criacao,
               usr.ddd_usuario, usr.telefone_usuario, usr.imagem_usuario, usr.is_admin, usr.optin_usuario,
               usr.strava_id, usr.strava_profile, usr.data_alteracao, usr.username, usr.tag_usuario,
               usr.url_usuario, usr.fonte_lead, usr.cidade, usr.estado, usr.data_nascimento, usr.aka,
               usr.assessoria, usr.is_dev, usr.is_partner, usr.genero, usr.cbat, usr.pais, usr.cep,
               usr.ddi_usuario, usr.endereco, usr.manychat_subscriber_id, usr.ano_nascimento,
               <cfif VARIABLES.userManagerSchemaReady>
                   coalesce(gest.ativo, true) AS gestao_ativo,
                   coalesce(gest.excluido, false) AS gestao_excluido,
                   gest.motivo AS gestao_motivo,
                   gest.data_alteracao AS gestao_data_alteracao,
                   gest.data_exclusao AS gestao_data_exclusao,
               <cfelse>
                   true AS gestao_ativo,
                   false AS gestao_excluido,
                   null::text AS gestao_motivo,
                   null::timestamp AS gestao_data_alteracao,
                   null::timestamp AS gestao_data_exclusao,
               </cfif>
               (SELECT count(*) FROM tb_paginas_usuarios pu WHERE pu.id_usuario = usr.id) AS total_paginas,
               (
                   SELECT count(*)
                   FROM (
                       SELECT res.id_resultado
                       FROM tb_resultados res
                       WHERE res.id_usuario = usr.id

                       UNION

                       SELECT vin.id_resultado
                       FROM tb_resultados_vinculo vin
                       WHERE vin.id_usuario = usr.id
                         AND vin.vinculo_resultado = true
                   ) resultados_usuario
               ) AS total_resultados,
               <cfif VARIABLES.userManagerHasAgendas>
                   (SELECT count(*) FROM tb_agendas age WHERE age.id_usuario = usr.id) AS total_agendas
               <cfelse>
                   0::bigint AS total_agendas
               </cfif>
        FROM tb_usuarios usr
        <cfif VARIABLES.userManagerSchemaReady>
            LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario = usr.id
        </cfif>
        WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>
    </cfquery>

    <cfif NOT qUserManagerUser.recordcount>
        <cflocation addtoken="false" url="./?feedback=erro&mensagem=#urlEncodedFormat('Usuário não encontrado.')#"/>
    </cfif>

    <cfif qUserManagerUser.recordcount>
        <cfquery name="qUserManagerPages">
            SELECT pag.*,
                   <cfif VARIABLES.userManagerSchemaReady>
                       coalesce(gest.ativo, true) AS gestao_ativo,
                       coalesce(gest.excluido, false) AS gestao_excluido,
                       gest.motivo AS gestao_motivo,
                   <cfelse>
                       true AS gestao_ativo,
                       false AS gestao_excluido,
                       null::text AS gestao_motivo,
                   </cfif>
                   (SELECT count(*) FROM tb_paginas_vinculos vin WHERE vin.id_pagina_destino = pag.id_pagina AND vin.tipo_vinculo = 1 AND vin.vinculo_validado = true) AS seguidores,
                   (SELECT count(*) FROM tb_paginas_vinculos vin WHERE vin.id_pagina_origem = pag.id_pagina AND vin.tipo_vinculo = 1 AND vin.vinculo_validado = true) AS seguindo
            FROM tb_paginas pag
            INNER JOIN tb_paginas_usuarios pu ON pu.id_pagina = pag.id_pagina
            <cfif VARIABLES.userManagerSchemaReady>
                LEFT JOIN tb_paginas_gestao gest ON gest.id_pagina = pag.id_pagina
            </cfif>
            WHERE pu.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>
            ORDER BY <cfif VARIABLES.userManagerSchemaReady>coalesce(gest.excluido, false), coalesce(gest.ativo, true) DESC,</cfif> pag.id_pagina
        </cfquery>

        <cfif VARIABLES.userManagerTab EQ "agendas" AND VARIABLES.userManagerHasAgendas>
            <cfquery name="qUserManagerAgendas">
                SELECT age.id_agenda, age.nome, age.descricao, age.modo, age.status, age.dominio_permitido,
                       age.data_criacao, age.data_atualizacao,
                       (SELECT count(*) FROM tb_agenda_eventos evt WHERE evt.id_agenda = age.id_agenda) AS eventos_manuais,
                       (SELECT count(*) FROM tb_agenda_filtros fil WHERE fil.id_agenda = age.id_agenda) AS filtros
                FROM tb_agendas age
                WHERE age.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>
                ORDER BY age.data_atualizacao DESC, age.id_agenda DESC
                LIMIT 100
            </cfquery>
        </cfif>

        <cfif VARIABLES.userManagerTab EQ "resultados">
            <cfquery name="qUserManagerResults">
                WITH resultados_usuario AS (
                    SELECT res.id_resultado, true AS vinculo_direto
                    FROM tb_resultados res
                    WHERE res.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>

                    UNION ALL

                    SELECT vin.id_resultado, false AS vinculo_direto
                    FROM tb_resultados_vinculo vin
                    WHERE vin.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>
                      AND vin.vinculo_resultado = true
                      AND NOT EXISTS (
                          SELECT 1
                          FROM tb_resultados res_direto
                          WHERE res_direto.id_resultado = vin.id_resultado
                            AND res_direto.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>
                      )
                )
                SELECT res.id_resultado, res.id_evento, res.nome, res.num_peito, res.modalidade, res.percurso,
                       res.tempo_total, res.classificacao_total, res.data_nascimento,
                       evt.nome_evento, evt.data_final, evt.cidade, evt.estado, evt.tag,
                       usrres.vinculo_direto
                FROM resultados_usuario usrres
                INNER JOIN tb_resultados res ON res.id_resultado = usrres.id_resultado
                INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
                ORDER BY evt.data_final DESC, res.id_resultado DESC
                LIMIT 200
            </cfquery>
        </cfif>

        <cfif VARIABLES.userManagerTab EQ "social">
            <cfquery name="qUserManagerSocial">
                SELECT vin.id_pagina_origem, vin.id_pagina_destino, vin.vinculo_validado, vin.data_cadastramento,
                       origem.nome AS origem_nome, origem.tag AS origem_tag, origem.tag_prefix AS origem_prefix,
                       destino.nome AS destino_nome, destino.tag AS destino_tag, destino.tag_prefix AS destino_prefix,
                       EXISTS (
                           SELECT 1 FROM tb_paginas_usuarios own_origin
                           WHERE own_origin.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>
                             AND own_origin.id_pagina = vin.id_pagina_origem
                       ) AS usuario_seguindo
                FROM tb_paginas_vinculos vin
                INNER JOIN tb_paginas origem ON origem.id_pagina = vin.id_pagina_origem
                INNER JOIN tb_paginas destino ON destino.id_pagina = vin.id_pagina_destino
                WHERE vin.tipo_vinculo = 1
                  AND (
                      vin.id_pagina_origem IN (SELECT id_pagina FROM tb_paginas_usuarios WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>)
                      OR vin.id_pagina_destino IN (SELECT id_pagina FROM tb_paginas_usuarios WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>)
                  )
                ORDER BY vin.data_cadastramento DESC
                LIMIT 300
            </cfquery>
        </cfif>

        <cfif VARIABLES.userManagerTab EQ "auditoria" AND VARIABLES.userManagerSchemaReady>
            <cfquery name="qUserManagerAudit">
                SELECT aud.*, autor.name AS autor_nome, pag.nome AS pagina_nome
                FROM tb_usuarios_gestao_auditoria aud
                LEFT JOIN tb_usuarios autor ON autor.id = aud.id_usuario_autor
                LEFT JOIN tb_paginas pag ON pag.id_pagina = aud.id_pagina_alvo
                WHERE aud.id_usuario_alvo = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerUserId#"/>
                ORDER BY aud.data_criacao DESC, aud.id_auditoria DESC
                LIMIT 150
            </cfquery>
        </cfif>
    </cfif>
<cfelseif !VARIABLES.userManagerIsNew>
    <cfquery name="qUserManagerStats">
        SELECT count(*) AS total,
               count(*) FILTER (WHERE <cfif VARIABLES.userManagerSchemaReady>coalesce(gest.ativo, true) AND NOT coalesce(gest.excluido, false)<cfelse>true</cfif>) AS ativos,
               count(*) FILTER (WHERE <cfif VARIABLES.userManagerSchemaReady>NOT coalesce(gest.ativo, true) AND NOT coalesce(gest.excluido, false)<cfelse>false</cfif>) AS inativos,
               count(*) FILTER (WHERE <cfif VARIABLES.userManagerSchemaReady>coalesce(gest.excluido, false)<cfelse>false</cfif>) AS excluidos,
               count(*) FILTER (WHERE usr.strava_id IS NOT NULL) AS com_strava
        FROM tb_usuarios usr
        <cfif VARIABLES.userManagerSchemaReady>
            LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario = usr.id
        </cfif>
    </cfquery>

    <cfquery name="qUserManagerTotal">
        SELECT count(*) AS total
        FROM tb_usuarios usr
        <cfif VARIABLES.userManagerSchemaReady>
            LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario = usr.id
        </cfif>
        WHERE 1 = 1
        <cfif len(VARIABLES.userManagerSearch)>
            AND (
                usr.name ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.userManagerSearch#%"/>
                OR usr.email ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.userManagerSearch#%"/>
                OR usr.username ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.userManagerSearch#%"/>
                <cfif isValid("integer", VARIABLES.userManagerSearch)>
                    OR usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.userManagerSearch)#"/>
                </cfif>
            )
        </cfif>
        <cfif VARIABLES.userManagerSchemaReady>
            <cfswitch expression="#VARIABLES.userManagerStatus#">
                <cfcase value="ativos">AND coalesce(gest.ativo, true) = true AND coalesce(gest.excluido, false) = false</cfcase>
                <cfcase value="inativos">AND coalesce(gest.ativo, true) = false AND coalesce(gest.excluido, false) = false</cfcase>
                <cfcase value="excluidos">AND coalesce(gest.excluido, false) = true</cfcase>
            </cfswitch>
        </cfif>
        <cfswitch expression="#VARIABLES.userManagerRole#">
            <cfcase value="admin">AND usr.is_admin = true</cfcase>
            <cfcase value="dev">AND usr.is_dev = true</cfcase>
            <cfcase value="partner">AND usr.is_partner = true</cfcase>
            <cfcase value="com_strava">AND usr.strava_id IS NOT NULL</cfcase>
            <cfcase value="sem_pagina">AND NOT EXISTS (SELECT 1 FROM tb_paginas_usuarios pu WHERE pu.id_usuario = usr.id)</cfcase>
        </cfswitch>
    </cfquery>
    <cfset VARIABLES.userManagerTotal = val(qUserManagerTotal.total)/>
    <cfset VARIABLES.userManagerPagesTotal = max(1, ceiling(VARIABLES.userManagerTotal / VARIABLES.userManagerPerPage))/>
    <cfif VARIABLES.userManagerPage GT VARIABLES.userManagerPagesTotal>
        <cfset VARIABLES.userManagerPage = VARIABLES.userManagerPagesTotal/>
        <cfset VARIABLES.userManagerOffset = (VARIABLES.userManagerPage - 1) * VARIABLES.userManagerPerPage/>
    </cfif>

    <cfquery name="qUserManagerUsers">
        SELECT usr.id, usr.name, usr.email, usr.username, usr.imagem_usuario, usr.strava_profile, usr.strava_id,
               usr.is_admin, usr.is_dev, usr.is_partner, usr.data_criacao, usr.data_alteracao,
               <cfif VARIABLES.userManagerSchemaReady>
                   coalesce(gest.ativo, true) AS gestao_ativo,
                   coalesce(gest.excluido, false) AS gestao_excluido,
                   gest.motivo AS gestao_motivo,
               <cfelse>
                   true AS gestao_ativo,
                   false AS gestao_excluido,
                   null::text AS gestao_motivo,
               </cfif>
               page_info.total_paginas,
               page_info.pagina_principal,
               page_info.pagina_tag,
               (SELECT count(*) FROM tb_resultados res WHERE res.id_usuario = usr.id) AS total_resultados
        FROM tb_usuarios usr
        <cfif VARIABLES.userManagerSchemaReady>
            LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario = usr.id
        </cfif>
        LEFT JOIN LATERAL (
            SELECT count(*) AS total_paginas,
                   min(pag.nome) AS pagina_principal,
                   min(pag.tag) AS pagina_tag
            FROM tb_paginas_usuarios pu
            INNER JOIN tb_paginas pag ON pag.id_pagina = pu.id_pagina
            WHERE pu.id_usuario = usr.id
        ) page_info ON true
        WHERE 1 = 1
        <cfif len(VARIABLES.userManagerSearch)>
            AND (
                usr.name ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.userManagerSearch#%"/>
                OR usr.email ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.userManagerSearch#%"/>
                OR usr.username ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.userManagerSearch#%"/>
                <cfif isValid("integer", VARIABLES.userManagerSearch)>
                    OR usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.userManagerSearch)#"/>
                </cfif>
            )
        </cfif>
        <cfif VARIABLES.userManagerSchemaReady>
            <cfswitch expression="#VARIABLES.userManagerStatus#">
                <cfcase value="ativos">AND coalesce(gest.ativo, true) = true AND coalesce(gest.excluido, false) = false</cfcase>
                <cfcase value="inativos">AND coalesce(gest.ativo, true) = false AND coalesce(gest.excluido, false) = false</cfcase>
                <cfcase value="excluidos">AND coalesce(gest.excluido, false) = true</cfcase>
            </cfswitch>
        </cfif>
        <cfswitch expression="#VARIABLES.userManagerRole#">
            <cfcase value="admin">AND usr.is_admin = true</cfcase>
            <cfcase value="dev">AND usr.is_dev = true</cfcase>
            <cfcase value="partner">AND usr.is_partner = true</cfcase>
            <cfcase value="com_strava">AND usr.strava_id IS NOT NULL</cfcase>
            <cfcase value="sem_pagina">AND NOT EXISTS (SELECT 1 FROM tb_paginas_usuarios pu WHERE pu.id_usuario = usr.id)</cfcase>
        </cfswitch>
        ORDER BY usr.id DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerPerPage#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.userManagerOffset#"/>
    </cfquery>
</cfif>
