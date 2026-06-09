<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.user_busca" default=""/>
<cfparam name="URL.evento_busca" default=""/>
<cfparam name="URL.conta_id" default=""/>
<cfparam name="VARIABLES.accountsSaveErrorMessage" default=""/>
<cfparam name="VARIABLES.accountsUserSaveErrorMessage" default=""/>
<cfparam name="VARIABLES.accountsEventSaveErrorMessage" default=""/>
<cfparam name="VARIABLES.accountsRegistrationSaveErrorMessage" default=""/>
<cfparam name="VARIABLES.accountsNoticeMessage" default=""/>

<cfset VARIABLES.accountsPage = max(1, int(URL.pagina))/>
<cfset VARIABLES.accountsPerPage = 25/>
<cfset VARIABLES.accountTipoTitularList = "PF,PJ"/>
<cfset VARIABLES.accountStatusList = "ATIVA,SUSPENSA,CANCELADA,PENDENTE"/>
<cfset VARIABLES.accountUserPapelList = "OWNER,ADMIN,OPERADOR,VISUALIZADOR"/>
<cfset VARIABLES.accountUserAssignablePapelList = VARIABLES.accountUserPapelList/>
<cfset VARIABLES.accountUserStatusList = "ATIVO,INATIVO,CONVIDADO,BLOQUEADO"/>
<cfset VARIABLES.accountEventStatusList = "ATIVO,INATIVO,PENDENTE"/>
<cfset VARIABLES.businessAccountsRealIsAdmin = false/>
<cfset VARIABLES.businessAccountsSimulationActive = isDefined("VARIABLES.businessAccountSimulationActive") AND VARIABLES.businessAccountSimulationActive/>
<cfset VARIABLES.businessAccountsScopedAccountIds = "0"/>
<cfset VARIABLES.businessAccountsManageUserAccountIds = "0"/>
<cfset VARIABLES.businessAccountsOperateAccountIds = "0"/>
<cfset VARIABLES.businessAccountsCanAccess = false/>
<cfset VARIABLES.businessAccountsCanAdminAll = false/>
<cfset VARIABLES.businessAccountsCanManageUsers = false/>
<cfset VARIABLES.businessAccountsCanManageEvents = false/>
<cfset VARIABLES.businessAccountRegistrationTableReady = false/>

<cfif isDefined("VARIABLES.businessRealIsAdmin")>
    <cfset VARIABLES.businessAccountsRealIsAdmin = VARIABLES.businessRealIsAdmin/>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin") AND qPerfil.is_admin>
    <cfset VARIABLES.businessAccountsRealIsAdmin = true/>
</cfif>

<cfif isDefined("VARIABLES.businessEffectiveAccountIds")
    AND len(trim(VARIABLES.businessEffectiveAccountIds))
    AND VARIABLES.businessEffectiveAccountIds NEQ "0">
    <cfset VARIABLES.businessAccountsScopedAccountIds = VARIABLES.businessEffectiveAccountIds/>
</cfif>

<cfif isDefined("VARIABLES.businessEffectiveAccountManagerIds")
    AND len(trim(VARIABLES.businessEffectiveAccountManagerIds))
    AND VARIABLES.businessEffectiveAccountManagerIds NEQ "0">
    <cfset VARIABLES.businessAccountsManageUserAccountIds = VARIABLES.businessEffectiveAccountManagerIds/>
</cfif>

<cfif isDefined("VARIABLES.businessEffectiveAccountOperatorIds")
    AND len(trim(VARIABLES.businessEffectiveAccountOperatorIds))
    AND VARIABLES.businessEffectiveAccountOperatorIds NEQ "0">
    <cfset VARIABLES.businessAccountsOperateAccountIds = VARIABLES.businessEffectiveAccountOperatorIds/>
</cfif>

<cfif VARIABLES.businessAccountsRealIsAdmin AND NOT VARIABLES.businessAccountsSimulationActive>
    <cfset VARIABLES.businessAccountsCanAccess = true/>
    <cfset VARIABLES.businessAccountsCanAdminAll = true/>
    <cfset VARIABLES.businessAccountsCanManageUsers = true/>
    <cfset VARIABLES.businessAccountsCanManageEvents = true/>
<cfelseif VARIABLES.businessAccountsScopedAccountIds NEQ "0">
    <cfset VARIABLES.businessAccountsCanAccess = true/>
    <cfif VARIABLES.businessAccountsManageUserAccountIds NEQ "0">
        <cfset VARIABLES.businessAccountsCanManageUsers = true/>
    </cfif>
    <cfset VARIABLES.accountUserAssignablePapelList = "ADMIN,OPERADOR,VISUALIZADOR"/>
</cfif>

<cfquery name="qBusinessAccountTableCheck">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN (
        <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_contas"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_usuarios"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_eventos"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_cadastro_solicitacoes"/>
      )
</cfquery>

<cfset VARIABLES.businessAccountTableNames = ValueList(qBusinessAccountTableCheck.table_name)/>
<cfset VARIABLES.businessAccountsTablesReady = ListFindNoCase(VARIABLES.businessAccountTableNames, "tb_contas")
    AND ListFindNoCase(VARIABLES.businessAccountTableNames, "tb_conta_usuarios")
    AND ListFindNoCase(VARIABLES.businessAccountTableNames, "tb_conta_eventos")/>
<cfset VARIABLES.businessAccountRegistrationTableReady = ListFindNoCase(VARIABLES.businessAccountTableNames, "tb_conta_cadastro_solicitacoes")/>

<cfif isDefined("URL.sucesso")>
    <cfif URL.sucesso EQ "conta">
        <cfset VARIABLES.accountsNoticeMessage = "Conta salva com sucesso."/>
    <cfelseif URL.sucesso EQ "excluida">
        <cfset VARIABLES.accountsNoticeMessage = "Conta excluida com sucesso."/>
    <cfelseif URL.sucesso EQ "usuario">
        <cfset VARIABLES.accountsNoticeMessage = "Vinculo de usuario salvo com sucesso."/>
    <cfelseif URL.sucesso EQ "removido">
        <cfset VARIABLES.accountsNoticeMessage = "Vinculo de usuario removido."/>
    <cfelseif URL.sucesso EQ "evento">
        <cfset VARIABLES.accountsNoticeMessage = "Vinculo de evento salvo com sucesso."/>
    <cfelseif URL.sucesso EQ "evento_removido">
        <cfset VARIABLES.accountsNoticeMessage = "Vinculo de evento removido."/>
    <cfelseif URL.sucesso EQ "solicitacao_aprovada">
        <cfset VARIABLES.accountsNoticeMessage = "Solicitacao aprovada e conta vinculada com sucesso."/>
    <cfelseif URL.sucesso EQ "solicitacao_recusada">
        <cfset VARIABLES.accountsNoticeMessage = "Solicitacao recusada com sucesso."/>
    </cfif>
</cfif>

<cfset qBusinessAccountList = QueryNew("id_conta,nome_conta,tipo_titular,documento,nome_titular,email_principal,telefone_principal,status,data_criacao,data_atualizacao,total_usuarios,usuarios_ativos,total_eventos,eventos_ativos")/>
<cfset qBusinessAccountEdit = QueryNew("id_conta,nome_conta,tipo_titular,documento,nome_titular,email_principal,telefone_principal,status,data_criacao,data_atualizacao,total_usuarios,usuarios_ativos,total_eventos,eventos_ativos")/>
<cfset qBusinessAccountUsers = QueryNew("id_conta_usuario,id_conta,id_usuario,papel,status,data_convite,data_aceite,data_criacao,data_atualizacao,name,email,is_admin,is_partner")/>
<cfset qBusinessAccountUserSearch = QueryNew("id,name,email,is_admin,is_partner,papel,status")/>
<cfset qBusinessAccountEvents = QueryNew("id_conta_evento,id_conta,id_evento,status,data_criacao,data_atualizacao,nome_evento,tag,data_inicial,data_final,cidade,estado")/>
<cfset qBusinessAccountEventSearch = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado,status")/>
<cfset qBusinessAccountRegistrationRequests = QueryNew("id_solicitacao,nome_empresa,tipo_titular,documento,nome_responsavel,email_responsavel,telefone_responsavel,site,cidade,estado,tipo_prestador,mensagem,id_usuario,id_conta,status,data_criacao,nome_conta,usuario_nome")/>
<cfset qBusinessAccountRegistrationAccountOptions = QueryNew("id_conta,nome_conta,documento,status")/>

<cfset VARIABLES.accountsTotal = 0/>
<cfset VARIABLES.accountsFilteredTotal = 0/>
<cfset VARIABLES.accountsActiveTotal = 0/>
<cfset VARIABLES.accountsPendingTotal = 0/>
<cfset VARIABLES.accountsLinkedUsersTotal = 0/>
<cfset VARIABLES.accountsLinkedEventsTotal = 0/>
<cfset VARIABLES.accountsRegistrationPendingTotal = 0/>
<cfset VARIABLES.accountsRegistrationTotal = 0/>
<cfset VARIABLES.accountsTotalPages = 1/>
<cfset VARIABLES.accountsOffset = (VARIABLES.accountsPage - 1) * VARIABLES.accountsPerPage/>
<cfset VARIABLES.accountSearchTerm = trim(URL.busca)/>
<cfset VARIABLES.accountSearchDocument = REReplace(VARIABLES.accountSearchTerm, "[^0-9]", "", "all")/>
<cfset VARIABLES.accountsEditId = ""/>

<cfif NOT VARIABLES.businessAccountsTablesReady>
    <cfset VARIABLES.accountsSaveErrorMessage = "As tabelas tb_contas, tb_conta_usuarios e tb_conta_eventos ainda nao foram encontradas no banco. Aplique a DDL antes de usar este CRUD."/>
<cfelseif NOT VARIABLES.businessAccountsCanAccess>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND VARIABLES.businessAccountRegistrationTableReady
    AND isDefined("FORM.account_registration_action")>

    <cfset VARIABLES.accountRegistrationAction = lCase(trim(FORM.account_registration_action))/>
    <cfset VARIABLES.accountRegistrationRequestId = isDefined("FORM.id_solicitacao") ? trim(FORM.id_solicitacao) : ""/>
    <cfset VARIABLES.accountRegistrationExistingAccountId = isDefined("FORM.id_conta_existente") ? trim(FORM.id_conta_existente) : ""/>
    <cfset VARIABLES.accountRegistrationReviewNote = isDefined("FORM.observacao_revisor") ? trim(FORM.observacao_revisor) : ""/>
    <cfset VARIABLES.accountRegistrationErrors = []/>
    <cfset VARIABLES.accountRegistrationRedirectUrl = ""/>

    <cfif NOT VARIABLES.businessAccountsCanAdminAll>
        <cfset arrayAppend(VARIABLES.accountRegistrationErrors, "Apenas administradores internos podem revisar solicitacoes de cadastro.")/>
    </cfif>

    <cfif NOT listFindNoCase("aprovar,recusar", VARIABLES.accountRegistrationAction)>
        <cfset arrayAppend(VARIABLES.accountRegistrationErrors, "Acao de solicitacao invalida.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountRegistrationRequestId) OR NOT isNumeric(VARIABLES.accountRegistrationRequestId)>
        <cfset arrayAppend(VARIABLES.accountRegistrationErrors, "Solicitacao invalida.")/>
    </cfif>

    <cfif len(VARIABLES.accountRegistrationExistingAccountId) AND NOT isNumeric(VARIABLES.accountRegistrationExistingAccountId)>
        <cfset arrayAppend(VARIABLES.accountRegistrationErrors, "Conta existente invalida.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountRegistrationErrors)>
        <cftry>
            <cftransaction>
                <cfquery name="qBusinessAccountRegistrationReview">
                    SELECT *
                    FROM tb_conta_cadastro_solicitacoes
                    WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountRegistrationRequestId#"/>
                    LIMIT 1
                </cfquery>

                <cfif NOT qBusinessAccountRegistrationReview.recordcount>
                    <cfset arrayAppend(VARIABLES.accountRegistrationErrors, "Solicitacao nao encontrada.")/>
                <cfelseif qBusinessAccountRegistrationReview.status NEQ "PENDENTE">
                    <cfset arrayAppend(VARIABLES.accountRegistrationErrors, "Esta solicitacao ja foi revisada.")/>
                </cfif>

                <cfif NOT arrayLen(VARIABLES.accountRegistrationErrors) AND VARIABLES.accountRegistrationAction EQ "recusar">
                    <cfquery>
                        UPDATE tb_conta_cadastro_solicitacoes
                        SET status = 'RECUSADA'::status_conta_cadastro_solicitacao,
                            id_usuario_revisor = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                            observacao_revisor = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.accountRegistrationReviewNote#" null="#NOT len(VARIABLES.accountRegistrationReviewNote)#"/>,
                            data_revisao = now()
                        WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountRegistrationReview.id_solicitacao#"/>
                    </cfquery>

                    <cfset VARIABLES.accountRegistrationRedirectUrl = "./?sucesso=solicitacao_recusada"/>
                </cfif>

                <cfif NOT arrayLen(VARIABLES.accountRegistrationErrors) AND VARIABLES.accountRegistrationAction EQ "aprovar">
                    <cfset VARIABLES.accountRegistrationTargetAccountId = ""/>

                    <cfif len(VARIABLES.accountRegistrationExistingAccountId)>
                        <cfquery name="qBusinessAccountRegistrationExistingAccount">
                            SELECT id_conta
                            FROM tb_contas
                            WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountRegistrationExistingAccountId#"/>
                            LIMIT 1
                        </cfquery>

                        <cfif qBusinessAccountRegistrationExistingAccount.recordcount>
                            <cfset VARIABLES.accountRegistrationTargetAccountId = qBusinessAccountRegistrationExistingAccount.id_conta/>
                        <cfelse>
                            <cfset arrayAppend(VARIABLES.accountRegistrationErrors, "Conta existente nao encontrada.")/>
                        </cfif>
                    <cfelse>
                        <cfquery name="qBusinessAccountRegistrationAccountByDocument">
                            SELECT id_conta
                            FROM tb_contas
                            WHERE documento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.documento#" maxlength="20"/>
                            LIMIT 1
                        </cfquery>

                        <cfif qBusinessAccountRegistrationAccountByDocument.recordcount>
                            <cfset VARIABLES.accountRegistrationTargetAccountId = qBusinessAccountRegistrationAccountByDocument.id_conta/>
                        <cfelse>
                            <cfquery name="qBusinessAccountRegistrationCreateAccount">
                                INSERT INTO tb_contas
                                (
                                    nome_conta,
                                    tipo_titular,
                                    documento,
                                    nome_titular,
                                    email_principal,
                                    telefone_principal,
                                    status
                                )
                                VALUES
                                (
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.nome_empresa#" maxlength="160"/>,
                                    CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.tipo_titular#"/> AS tipo_titular_conta),
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.documento#" maxlength="20"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.nome_responsavel#" maxlength="200"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.email_responsavel#" maxlength="255"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.telefone_responsavel#" maxlength="30" null="#NOT len(trim(qBusinessAccountRegistrationReview.telefone_responsavel))#"/>,
                                    'ATIVA'::status_conta
                                )
                                RETURNING id_conta
                            </cfquery>

                            <cfset VARIABLES.accountRegistrationTargetAccountId = qBusinessAccountRegistrationCreateAccount.id_conta/>
                        </cfif>
                    </cfif>

                    <cfif NOT arrayLen(VARIABLES.accountRegistrationErrors)>
                        <cfquery name="qBusinessAccountRegistrationOwnerUser">
                            INSERT INTO tb_usuarios
                            (
                                name,
                                email,
                                password,
                                verification_key,
                                is_email_verified,
                                optin_usuario,
                                telefone_usuario,
                                cidade,
                                estado,
                                is_partner,
                                fonte_lead
                            )
                            VALUES
                            (
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#ucase(qBusinessAccountRegistrationReview.nome_responsavel)#" maxlength="256"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(qBusinessAccountRegistrationReview.email_responsavel)#" maxlength="256"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(qBusinessAccountRegistrationReview.email_responsavel & now(), 'SHA-256')#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(qBusinessAccountRegistrationReview.email_responsavel, 'SHA-256')#" maxlength="250"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(qBusinessAccountRegistrationReview.telefone_responsavel), 24)#" maxlength="24" null="#NOT len(trim(qBusinessAccountRegistrationReview.telefone_responsavel))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.cidade#" null="#NOT len(trim(qBusinessAccountRegistrationReview.cidade))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qBusinessAccountRegistrationReview.estado#" maxlength="2" null="#NOT len(trim(qBusinessAccountRegistrationReview.estado))#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="business_cadastro" maxlength="32"/>
                            )
                            ON CONFLICT (email)
                            DO UPDATE SET
                                data_alteracao = now(),
                                is_partner = true,
                                telefone_usuario = COALESCE(NULLIF(tb_usuarios.telefone_usuario, ''), EXCLUDED.telefone_usuario),
                                cidade = COALESCE(NULLIF(tb_usuarios.cidade, ''), EXCLUDED.cidade),
                                estado = COALESCE(NULLIF(tb_usuarios.estado, ''), EXCLUDED.estado)
                            RETURNING id
                        </cfquery>

                        <cfquery>
                            INSERT INTO tb_conta_usuarios
                            (
                                id_conta,
                                id_usuario,
                                papel,
                                status,
                                usuario_convite,
                                data_convite,
                                data_aceite
                            )
                            VALUES
                            (
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountRegistrationTargetAccountId#"/>,
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountRegistrationOwnerUser.id#"/>,
                                'OWNER'::papel_usuario_conta,
                                'ATIVO'::status_usuario_conta,
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                                now(),
                                now()
                            )
                            ON CONFLICT (id_conta, id_usuario)
                            DO UPDATE SET
                                papel = 'OWNER'::papel_usuario_conta,
                                status = 'ATIVO'::status_usuario_conta,
                                data_aceite = COALESCE(tb_conta_usuarios.data_aceite, now()),
                                data_atualizacao = now()
                        </cfquery>

                        <cfquery>
                            UPDATE tb_conta_cadastro_solicitacoes
                            SET status = 'APROVADA'::status_conta_cadastro_solicitacao,
                                id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountRegistrationTargetAccountId#"/>,
                                id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountRegistrationOwnerUser.id#"/>,
                                id_usuario_revisor = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                                observacao_revisor = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.accountRegistrationReviewNote#" null="#NOT len(VARIABLES.accountRegistrationReviewNote)#"/>,
                                data_revisao = now()
                            WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountRegistrationReview.id_solicitacao#"/>
                        </cfquery>

                        <cfset VARIABLES.accountRegistrationRedirectUrl = "./?conta_id=#VARIABLES.accountRegistrationTargetAccountId#&sucesso=solicitacao_aprovada"/>
                    </cfif>
                </cfif>
            </cftransaction>

            <cfif len(VARIABLES.accountRegistrationRedirectUrl)>
                <cflocation addtoken="false" url="#VARIABLES.accountRegistrationRedirectUrl#"/>
            </cfif>

            <cfcatch type="any">
                <cfset VARIABLES.accountsRegistrationSaveErrorMessage = "Nao foi possivel revisar a solicitacao. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif arrayLen(VARIABLES.accountRegistrationErrors)>
        <cfset VARIABLES.accountsRegistrationSaveErrorMessage = arrayToList(VARIABLES.accountRegistrationErrors, " ")/>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND isDefined("FORM.account_action")
    AND FORM.account_action EQ "excluir"
    AND isDefined("FORM.id_conta")
    AND len(trim(FORM.id_conta))
    AND isNumeric(FORM.id_conta)>

    <cfif NOT VARIABLES.businessAccountsCanAdminAll>
        <cfset VARIABLES.accountsSaveErrorMessage = "Apenas administradores internos podem excluir contas."/>
    <cfelse>
        <cftry>
            <cfquery>
                DELETE FROM tb_contas
                WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#FORM.id_conta#"/>
            </cfquery>

            <cflocation addtoken="false" url="./?sucesso=excluida"/>
            <cfcatch type="any">
                <cfset VARIABLES.accountsSaveErrorMessage = "Nao foi possivel excluir a conta. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND isDefined("FORM.account_action")
    AND FORM.account_action EQ "salvar">

    <cfset VARIABLES.accountFormId = isDefined("FORM.id_conta") ? trim(FORM.id_conta) : ""/>
    <cfset VARIABLES.accountNome = isDefined("FORM.nome_conta") ? trim(FORM.nome_conta) : ""/>
    <cfset VARIABLES.accountTipoTitular = isDefined("FORM.tipo_titular") ? uCase(trim(FORM.tipo_titular)) : ""/>
    <cfset VARIABLES.accountDocumento = isDefined("FORM.documento") ? REReplace(trim(FORM.documento), "[^0-9]", "", "all") : ""/>
    <cfset VARIABLES.accountNomeTitular = isDefined("FORM.nome_titular") ? trim(FORM.nome_titular) : ""/>
    <cfset VARIABLES.accountEmail = isDefined("FORM.email_principal") ? lCase(trim(FORM.email_principal)) : ""/>
    <cfset VARIABLES.accountTelefone = isDefined("FORM.telefone_principal") ? trim(FORM.telefone_principal) : ""/>
    <cfset VARIABLES.accountStatus = isDefined("FORM.status") ? uCase(trim(FORM.status)) : ""/>
    <cfset VARIABLES.accountSaveErrors = []/>

    <cfif NOT VARIABLES.businessAccountsCanAdminAll>
        <cfset arrayAppend(VARIABLES.accountSaveErrors, "Apenas administradores internos podem criar ou editar dados cadastrais da conta.")/>
    </cfif>

    <cfif len(VARIABLES.accountFormId) AND NOT isNumeric(VARIABLES.accountFormId)>
        <cfset arrayAppend(VARIABLES.accountSaveErrors, "Conta invalida.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountNome)>
        <cfset arrayAppend(VARIABLES.accountSaveErrors, "Informe o nome da conta.")/>
    </cfif>

    <cfif NOT listFindNoCase(VARIABLES.accountTipoTitularList, VARIABLES.accountTipoTitular)>
        <cfset arrayAppend(VARIABLES.accountSaveErrors, "Informe se o titular e PF ou PJ.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountDocumento)>
        <cfset arrayAppend(VARIABLES.accountSaveErrors, "Informe o documento da conta.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountNomeTitular)>
        <cfset arrayAppend(VARIABLES.accountSaveErrors, "Informe o nome do titular.")/>
    </cfif>

    <cfif NOT listFindNoCase(VARIABLES.accountStatusList, VARIABLES.accountStatus)>
        <cfset arrayAppend(VARIABLES.accountSaveErrors, "Informe um status valido.")/>
    </cfif>

    <cfif len(VARIABLES.accountEmail) AND NOT isValid("email", VARIABLES.accountEmail)>
        <cfset arrayAppend(VARIABLES.accountSaveErrors, "Informe um e-mail principal valido.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountSaveErrors)>
        <cfquery name="qBusinessAccountDuplicate">
            SELECT id_conta
            FROM tb_contas
            WHERE documento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountDocumento#" maxlength="20"/>
              <cfif len(VARIABLES.accountFormId)>
                AND id_conta <> <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountFormId#"/>
              </cfif>
            LIMIT 1
        </cfquery>

        <cfif qBusinessAccountDuplicate.recordcount>
            <cfset arrayAppend(VARIABLES.accountSaveErrors, "Ja existe uma conta com este documento.")/>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountSaveErrors)>
        <cftry>
            <cfif len(VARIABLES.accountFormId)>
                <cfquery name="qBusinessAccountSave">
                    UPDATE tb_contas
                    SET nome_conta = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountNome#" maxlength="160"/>,
                        tipo_titular = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountTipoTitular#"/> AS tipo_titular_conta),
                        documento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountDocumento#" maxlength="20"/>,
                        nome_titular = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountNomeTitular#" maxlength="200"/>,
                        email_principal = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountEmail#" maxlength="255" null="#NOT len(VARIABLES.accountEmail)#"/>,
                        telefone_principal = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountTelefone#" maxlength="30" null="#NOT len(VARIABLES.accountTelefone)#"/>,
                        status = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountStatus#"/> AS status_conta),
                        data_atualizacao = now()
                    WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountFormId#"/>
                    RETURNING id_conta
                </cfquery>
            <cfelse>
                <cfquery name="qBusinessAccountSave">
                    INSERT INTO tb_contas
                    (
                        nome_conta,
                        tipo_titular,
                        documento,
                        nome_titular,
                        email_principal,
                        telefone_principal,
                        status
                    )
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountNome#" maxlength="160"/>,
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountTipoTitular#"/> AS tipo_titular_conta),
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountDocumento#" maxlength="20"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountNomeTitular#" maxlength="200"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountEmail#" maxlength="255" null="#NOT len(VARIABLES.accountEmail)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountTelefone#" maxlength="30" null="#NOT len(VARIABLES.accountTelefone)#"/>,
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountStatus#"/> AS status_conta)
                    )
                    RETURNING id_conta
                </cfquery>
            </cfif>

            <cfif qBusinessAccountSave.recordcount>
                <cflocation addtoken="false" url="./?conta_id=#qBusinessAccountSave.id_conta#&sucesso=conta"/>
            <cfelse>
                <cfset VARIABLES.accountsSaveErrorMessage = "Nao foi possivel salvar a conta informada."/>
            </cfif>

            <cfcatch type="any">
                <cfset VARIABLES.accountsSaveErrorMessage = "Nao foi possivel salvar a conta. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    <cfelse>
        <cfset VARIABLES.accountsSaveErrorMessage = arrayToList(VARIABLES.accountSaveErrors, " ")/>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND isDefined("URL.account_user_action")
    AND URL.account_user_action EQ "remover"
    AND isDefined("URL.conta_id")
    AND len(trim(URL.conta_id))
    AND isNumeric(URL.conta_id)
    AND isDefined("URL.id_usuario")
    AND len(trim(URL.id_usuario))
    AND isNumeric(URL.id_usuario)>

    <cfif NOT VARIABLES.businessAccountsCanManageUsers
        OR (NOT VARIABLES.businessAccountsCanAdminAll AND NOT ListFind(VARIABLES.businessAccountsManageUserAccountIds, URL.conta_id))>
        <cfset VARIABLES.accountsUserSaveErrorMessage = "Voce nao tem permissao para remover este vinculo."/>
    <cfelse>
        <cftry>
            <cfquery name="qBusinessAccountUserRemoveCheck">
                SELECT papel::text AS papel,
                       id_usuario
                FROM tb_conta_usuarios
                WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.conta_id#"/>
                  AND id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.id_usuario#"/>
                LIMIT 1
            </cfquery>

            <cfif qBusinessAccountUserRemoveCheck.recordcount
                AND NOT VARIABLES.businessAccountsCanAdminAll
                AND qBusinessAccountUserRemoveCheck.papel EQ "OWNER">
                <cfset VARIABLES.accountsUserSaveErrorMessage = "Apenas administradores internos podem remover um OWNER da conta."/>
            </cfif>

            <cfif qBusinessAccountUserRemoveCheck.recordcount
                AND NOT VARIABLES.businessAccountsCanAdminAll
                AND isDefined("COOKIE.id")
                AND isNumeric(COOKIE.id)
                AND qBusinessAccountUserRemoveCheck.id_usuario EQ COOKIE.id>
                <cfset VARIABLES.accountsUserSaveErrorMessage = "Voce nao pode remover seu proprio vinculo da conta."/>
            </cfif>

            <cfif NOT len(trim(VARIABLES.accountsUserSaveErrorMessage))>
            <cfquery>
                DELETE FROM tb_conta_usuarios
                WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.conta_id#"/>
                  AND id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.id_usuario#"/>
            </cfquery>

            <cflocation addtoken="false" url="./?conta_id=#URL.conta_id#&sucesso=removido"/>
            </cfif>
            <cfcatch type="any">
                <cfset VARIABLES.accountsUserSaveErrorMessage = "Nao foi possivel remover o vinculo. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND isDefined("FORM.account_user_action")
    AND FORM.account_user_action EQ "convidar">

    <cfset VARIABLES.accountUserInviteAccountId = isDefined("FORM.id_conta") ? trim(FORM.id_conta) : ""/>
    <cfset VARIABLES.accountUserInviteName = isDefined("FORM.nome_usuario") ? trim(FORM.nome_usuario) : ""/>
    <cfset VARIABLES.accountUserInviteEmail = isDefined("FORM.email_usuario") ? lCase(trim(FORM.email_usuario)) : ""/>
    <cfset VARIABLES.accountUserInvitePapel = isDefined("FORM.papel") ? uCase(trim(FORM.papel)) : "OPERADOR"/>
    <cfset VARIABLES.accountUserInviteErrors = []/>

    <cfif NOT VARIABLES.businessAccountsCanManageUsers>
        <cfset arrayAppend(VARIABLES.accountUserInviteErrors, "Voce nao tem permissao para adicionar usuarios.")/>
    <cfelseif NOT VARIABLES.businessAccountsCanAdminAll
        AND (NOT len(VARIABLES.accountUserInviteAccountId) OR NOT ListFind(VARIABLES.businessAccountsManageUserAccountIds, VARIABLES.accountUserInviteAccountId))>
        <cfset arrayAppend(VARIABLES.accountUserInviteErrors, "Voce nao tem permissao para alterar usuarios desta conta.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountUserInviteAccountId) OR NOT isNumeric(VARIABLES.accountUserInviteAccountId)>
        <cfset arrayAppend(VARIABLES.accountUserInviteErrors, "Conta invalida para o usuario.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountUserInviteName)>
        <cfset arrayAppend(VARIABLES.accountUserInviteErrors, "Informe o nome do usuario.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountUserInviteEmail) OR NOT isValid("email", VARIABLES.accountUserInviteEmail)>
        <cfset arrayAppend(VARIABLES.accountUserInviteErrors, "Informe um e-mail valido para o usuario.")/>
    </cfif>

    <cfif NOT listFindNoCase(VARIABLES.accountUserAssignablePapelList, VARIABLES.accountUserInvitePapel)>
        <cfset arrayAppend(VARIABLES.accountUserInviteErrors, "Informe um papel permitido para o usuario.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountUserInviteErrors)>
        <cfquery name="qBusinessAccountInviteAccountCheck">
            SELECT id_conta
            FROM tb_contas
            WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserInviteAccountId#"/>
            LIMIT 1
        </cfquery>

        <cfif NOT qBusinessAccountInviteAccountCheck.recordcount>
            <cfset arrayAppend(VARIABLES.accountUserInviteErrors, "Conta nao encontrada.")/>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountUserInviteErrors)>
        <cftry>
            <cftransaction>
                <cfquery name="qBusinessAccountInviteUser">
                    INSERT INTO tb_usuarios
                    (
                        name,
                        email,
                        password,
                        verification_key,
                        is_email_verified,
                        optin_usuario,
                        is_partner,
                        fonte_lead
                    )
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#ucase(VARIABLES.accountUserInviteName)#" maxlength="256"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountUserInviteEmail#" maxlength="256"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(VARIABLES.accountUserInviteEmail & now(), 'SHA-256')#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(VARIABLES.accountUserInviteEmail, 'SHA-256')#" maxlength="250"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="business_convite" maxlength="32"/>
                    )
                    ON CONFLICT (email)
                    DO UPDATE SET
                        data_alteracao = now(),
                        is_partner = true,
                        name = CASE
                            WHEN length(coalesce(tb_usuarios.name, '')) = 0 THEN EXCLUDED.name
                            ELSE tb_usuarios.name
                        END
                    RETURNING id
                </cfquery>

                <cfquery>
                    INSERT INTO tb_conta_usuarios
                    (
                        id_conta,
                        id_usuario,
                        papel,
                        status,
                        usuario_convite,
                        data_convite,
                        data_aceite
                    )
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserInviteAccountId#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountInviteUser.id#"/>,
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountUserInvitePapel#"/> AS papel_usuario_conta),
                        'ATIVO'::status_usuario_conta,
                        <cfif isDefined("COOKIE.id") AND isNumeric(COOKIE.id)>
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#COOKIE.id#"/>
                        <cfelse>
                            NULL
                        </cfif>,
                        now(),
                        now()
                    )
                    ON CONFLICT (id_conta, id_usuario)
                    DO UPDATE SET
                        papel = EXCLUDED.papel,
                        status = 'ATIVO'::status_usuario_conta,
                        data_aceite = COALESCE(tb_conta_usuarios.data_aceite, now()),
                        data_atualizacao = now()
                </cfquery>
            </cftransaction>

            <cflocation addtoken="false" url="./?conta_id=#VARIABLES.accountUserInviteAccountId#&sucesso=usuario"/>
            <cfcatch type="any">
                <cfset VARIABLES.accountsUserSaveErrorMessage = "Nao foi possivel adicionar o usuario. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    <cfelse>
        <cfset VARIABLES.accountsUserSaveErrorMessage = arrayToList(VARIABLES.accountUserInviteErrors, " ")/>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND isDefined("FORM.account_user_action")
    AND FORM.account_user_action EQ "salvar">

    <cfset VARIABLES.accountUserAccountId = isDefined("FORM.id_conta") ? trim(FORM.id_conta) : ""/>
    <cfset VARIABLES.accountUserId = isDefined("FORM.id_usuario") ? trim(FORM.id_usuario) : ""/>
    <cfset VARIABLES.accountUserPapel = isDefined("FORM.papel") ? uCase(trim(FORM.papel)) : ""/>
    <cfset VARIABLES.accountUserStatus = isDefined("FORM.status") ? uCase(trim(FORM.status)) : ""/>
    <cfset VARIABLES.accountUserSaveErrors = []/>

    <cfif NOT VARIABLES.businessAccountsCanManageUsers>
        <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Voce nao tem permissao para salvar vinculos de usuarios.")/>
    <cfelseif NOT VARIABLES.businessAccountsCanAdminAll
        AND (NOT len(VARIABLES.accountUserAccountId) OR NOT ListFind(VARIABLES.businessAccountsManageUserAccountIds, VARIABLES.accountUserAccountId))>
        <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Voce nao tem permissao para alterar usuarios desta conta.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountUserAccountId) OR NOT isNumeric(VARIABLES.accountUserAccountId)>
        <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Conta invalida para o vinculo.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountUserId) OR NOT isNumeric(VARIABLES.accountUserId)>
        <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Usuario invalido para o vinculo.")/>
    </cfif>

    <cfif NOT listFindNoCase(VARIABLES.accountUserAssignablePapelList, VARIABLES.accountUserPapel)>
        <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Informe um papel valido para o usuario.")/>
    </cfif>

    <cfif NOT listFindNoCase(VARIABLES.accountUserStatusList, VARIABLES.accountUserStatus)>
        <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Informe um status valido para o usuario.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountUserSaveErrors)>
        <cfquery name="qBusinessAccountUserAccountCheck">
            SELECT id_conta
            FROM tb_contas
            WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserAccountId#"/>
            LIMIT 1
        </cfquery>

        <cfif NOT qBusinessAccountUserAccountCheck.recordcount>
            <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Conta nao encontrada.")/>
        </cfif>

        <cfquery name="qBusinessAccountUserCheck">
            SELECT id
            FROM tb_usuarios
            WHERE id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserId#"/>
            LIMIT 1
        </cfquery>

        <cfif NOT qBusinessAccountUserCheck.recordcount>
            <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Usuario nao encontrado.")/>
        </cfif>

        <cfquery name="qBusinessAccountUserExistingLink">
            SELECT papel::text AS papel
            FROM tb_conta_usuarios
            WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserAccountId#"/>
              AND id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserId#"/>
            LIMIT 1
        </cfquery>

        <cfif qBusinessAccountUserExistingLink.recordcount
            AND NOT VARIABLES.businessAccountsCanAdminAll
            AND qBusinessAccountUserExistingLink.papel EQ "OWNER">
            <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Apenas administradores internos podem alterar um OWNER da conta.")/>
        </cfif>

        <cfif NOT VARIABLES.businessAccountsCanAdminAll
            AND isDefined("COOKIE.id")
            AND isNumeric(COOKIE.id)
            AND VARIABLES.accountUserId EQ COOKIE.id
            AND (NOT ListFindNoCase("OWNER,ADMIN", VARIABLES.accountUserPapel) OR VARIABLES.accountUserStatus NEQ "ATIVO")>
            <cfset arrayAppend(VARIABLES.accountUserSaveErrors, "Voce nao pode remover seu proprio acesso de gestao da conta.")/>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountUserSaveErrors)>
        <cftry>
            <cfquery>
                INSERT INTO tb_conta_usuarios
                (
                    id_conta,
                    id_usuario,
                    papel,
                    status,
                    usuario_convite,
                    data_convite,
                    data_aceite
                )
                VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserAccountId#"/>,
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserId#"/>,
                    CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountUserPapel#"/> AS papel_usuario_conta),
                    CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountUserStatus#"/> AS status_usuario_conta),
                    <cfif isDefined("COOKIE.id") AND isNumeric(COOKIE.id)>
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#COOKIE.id#"/>
                    <cfelse>
                        NULL
                    </cfif>,
                    now(),
                    <cfif VARIABLES.accountUserStatus EQ "ATIVO">
                        now()
                    <cfelse>
                        NULL
                    </cfif>
                )
                ON CONFLICT (id_conta, id_usuario)
                DO UPDATE SET
                    papel = EXCLUDED.papel,
                    status = EXCLUDED.status,
                    data_aceite = CASE
                        WHEN EXCLUDED.status = 'ATIVO'::status_usuario_conta THEN COALESCE(tb_conta_usuarios.data_aceite, now())
                        ELSE tb_conta_usuarios.data_aceite
                    END,
                    data_atualizacao = now()
            </cfquery>

            <cflocation addtoken="false" url="./?conta_id=#VARIABLES.accountUserAccountId#&sucesso=usuario"/>
            <cfcatch type="any">
                <cfset VARIABLES.accountsUserSaveErrorMessage = "Nao foi possivel salvar o vinculo. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    <cfelse>
        <cfset VARIABLES.accountsUserSaveErrorMessage = arrayToList(VARIABLES.accountUserSaveErrors, " ")/>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND isDefined("URL.account_event_action")
    AND URL.account_event_action EQ "remover"
    AND isDefined("URL.conta_id")
    AND len(trim(URL.conta_id))
    AND isNumeric(URL.conta_id)
    AND isDefined("URL.id_evento")
    AND len(trim(URL.id_evento))
    AND isNumeric(URL.id_evento)>

    <cfif NOT VARIABLES.businessAccountsCanManageEvents>
        <cfset VARIABLES.accountsEventSaveErrorMessage = "Apenas administradores internos podem remover vinculos de eventos."/>
    <cfelse>
        <cftry>
            <cfquery>
                DELETE FROM tb_conta_eventos
                WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.conta_id#"/>
                  AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
            </cfquery>

            <cflocation addtoken="false" url="./?conta_id=#URL.conta_id#&sucesso=evento_removido"/>
            <cfcatch type="any">
                <cfset VARIABLES.accountsEventSaveErrorMessage = "Nao foi possivel remover o vinculo de evento. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND isDefined("FORM.account_event_action")
    AND FORM.account_event_action EQ "salvar">

    <cfset VARIABLES.accountEventAccountId = isDefined("FORM.id_conta") ? trim(FORM.id_conta) : ""/>
    <cfset VARIABLES.accountEventId = isDefined("FORM.id_evento") ? trim(FORM.id_evento) : ""/>
    <cfset VARIABLES.accountEventStatus = isDefined("FORM.status") ? uCase(trim(FORM.status)) : ""/>
    <cfset VARIABLES.accountEventSaveErrors = []/>

    <cfif NOT VARIABLES.businessAccountsCanManageEvents>
        <cfset arrayAppend(VARIABLES.accountEventSaveErrors, "Apenas administradores internos podem salvar vinculos de eventos.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountEventAccountId) OR NOT isNumeric(VARIABLES.accountEventAccountId)>
        <cfset arrayAppend(VARIABLES.accountEventSaveErrors, "Conta invalida para o vinculo de evento.")/>
    </cfif>

    <cfif NOT len(VARIABLES.accountEventId) OR NOT isNumeric(VARIABLES.accountEventId)>
        <cfset arrayAppend(VARIABLES.accountEventSaveErrors, "Evento invalido para o vinculo.")/>
    </cfif>

    <cfif NOT listFindNoCase(VARIABLES.accountEventStatusList, VARIABLES.accountEventStatus)>
        <cfset arrayAppend(VARIABLES.accountEventSaveErrors, "Informe um status valido para o evento.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountEventSaveErrors)>
        <cfquery name="qBusinessAccountEventAccountCheck">
            SELECT id_conta
            FROM tb_contas
            WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountEventAccountId#"/>
            LIMIT 1
        </cfquery>

        <cfif NOT qBusinessAccountEventAccountCheck.recordcount>
            <cfset arrayAppend(VARIABLES.accountEventSaveErrors, "Conta nao encontrada.")/>
        </cfif>

        <cfquery name="qBusinessAccountEventCheck">
            SELECT id_evento
            FROM tb_evento_corridas
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.accountEventId#"/>
            LIMIT 1
        </cfquery>

        <cfif NOT qBusinessAccountEventCheck.recordcount>
            <cfset arrayAppend(VARIABLES.accountEventSaveErrors, "Evento nao encontrado.")/>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.accountEventSaveErrors)>
        <cftry>
            <cfquery>
                INSERT INTO tb_conta_eventos
                (
                    id_conta,
                    id_evento,
                    status,
                    usuario_cadastro
                )
                VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountEventAccountId#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.accountEventId#"/>,
                    CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.accountEventStatus#"/> AS status_conta_evento),
                    <cfif isDefined("COOKIE.id") AND isNumeric(COOKIE.id)>
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#COOKIE.id#"/>
                    <cfelse>
                        NULL
                    </cfif>
                )
                ON CONFLICT (id_conta, id_evento)
                DO UPDATE SET
                    status = EXCLUDED.status,
                    data_atualizacao = now()
            </cfquery>

            <cflocation addtoken="false" url="./?conta_id=#VARIABLES.accountEventAccountId#&sucesso=evento"/>
            <cfcatch type="any">
                <cfset VARIABLES.accountsEventSaveErrorMessage = "Nao foi possivel salvar o vinculo de evento. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    <cfelse>
        <cfset VARIABLES.accountsEventSaveErrorMessage = arrayToList(VARIABLES.accountEventSaveErrors, " ")/>
    </cfif>
</cfif>

<cfif len(trim(URL.conta_id)) AND isNumeric(URL.conta_id)>
    <cfset VARIABLES.accountsEditId = trim(URL.conta_id)/>
<cfelseif isDefined("FORM.account_action")
    AND FORM.account_action EQ "salvar"
    AND isDefined("FORM.id_conta")
    AND len(trim(FORM.id_conta))
    AND isNumeric(FORM.id_conta)>
    <cfset VARIABLES.accountsEditId = trim(FORM.id_conta)/>
<cfelseif isDefined("FORM.account_user_action")
    AND FORM.account_user_action EQ "salvar"
    AND isDefined("FORM.id_conta")
    AND len(trim(FORM.id_conta))
    AND isNumeric(FORM.id_conta)>
    <cfset VARIABLES.accountsEditId = trim(FORM.id_conta)/>
<cfelseif isDefined("FORM.account_event_action")
    AND FORM.account_event_action EQ "salvar"
    AND isDefined("FORM.id_conta")
    AND len(trim(FORM.id_conta))
    AND isNumeric(FORM.id_conta)>
    <cfset VARIABLES.accountsEditId = trim(FORM.id_conta)/>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND NOT VARIABLES.businessAccountsCanAdminAll
    AND VARIABLES.businessAccountsScopedAccountIds NEQ "0">
    <cfset VARIABLES.accountsDefaultScopedAccountId = listFirst(VARIABLES.businessAccountsScopedAccountIds)/>
    <cfif NOT len(VARIABLES.accountsEditId)>
        <cfset VARIABLES.accountsEditId = VARIABLES.accountsDefaultScopedAccountId/>
    <cfelseif NOT ListFind(VARIABLES.businessAccountsScopedAccountIds, VARIABLES.accountsEditId)>
        <cflocation addtoken="false" url="./?conta_id=#VARIABLES.accountsDefaultScopedAccountId#"/>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady>
    <cfquery name="qBusinessAccountStats">
        SELECT count(*) AS total_contas,
               count(*) FILTER (WHERE status = 'ATIVA'::status_conta) AS total_ativas,
               count(*) FILTER (WHERE status = 'PENDENTE'::status_conta) AS total_pendentes,
               (
                   SELECT count(DISTINCT id_usuario)
                   FROM tb_conta_usuarios
                   <cfif NOT VARIABLES.businessAccountsCanAdminAll>
                       WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessAccountsScopedAccountIds#" list="true"/>)
                   </cfif>
               ) AS total_usuarios,
               (
                   SELECT count(DISTINCT id_evento)
                   FROM tb_conta_eventos
                   WHERE status = 'ATIVO'::status_conta_evento
                   <cfif NOT VARIABLES.businessAccountsCanAdminAll>
                       AND id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessAccountsScopedAccountIds#" list="true"/>)
                   </cfif>
               ) AS total_eventos
        FROM tb_contas
        WHERE 1 = 1
        <cfif NOT VARIABLES.businessAccountsCanAdminAll>
            AND id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessAccountsScopedAccountIds#" list="true"/>)
        </cfif>
    </cfquery>

    <cfset VARIABLES.accountsTotal = val(qBusinessAccountStats.total_contas)/>
    <cfset VARIABLES.accountsActiveTotal = val(qBusinessAccountStats.total_ativas)/>
    <cfset VARIABLES.accountsPendingTotal = val(qBusinessAccountStats.total_pendentes)/>
    <cfset VARIABLES.accountsLinkedUsersTotal = val(qBusinessAccountStats.total_usuarios)/>
    <cfset VARIABLES.accountsLinkedEventsTotal = val(qBusinessAccountStats.total_eventos)/>

    <cfquery name="qBusinessAccountCount">
        SELECT count(*) AS total_contas
        FROM tb_contas tc
        WHERE 1 = 1
        <cfif NOT VARIABLES.businessAccountsCanAdminAll>
            AND tc.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessAccountsScopedAccountIds#" list="true"/>)
        </cfif>
        <cfif len(VARIABLES.accountSearchTerm)>
            AND (
                unaccent(upper(coalesce(tc.nome_conta, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountSearchTerm#%"/>))
                OR unaccent(upper(coalesce(tc.nome_titular, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountSearchTerm#%"/>))
                OR unaccent(upper(coalesce(tc.email_principal, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountSearchTerm#%"/>))
                <cfif len(VARIABLES.accountSearchDocument)>
                    OR tc.documento LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountSearchDocument#%"/>
                </cfif>
            )
        </cfif>
    </cfquery>

    <cfset VARIABLES.accountsFilteredTotal = val(qBusinessAccountCount.total_contas)/>
    <cfset VARIABLES.accountsTotalPages = max(1, ceiling(VARIABLES.accountsFilteredTotal / VARIABLES.accountsPerPage))/>

    <cfquery name="qBusinessAccountList">
        SELECT tc.id_conta,
               tc.nome_conta,
               tc.tipo_titular::text AS tipo_titular,
               tc.documento,
               tc.nome_titular,
               tc.email_principal,
               tc.telefone_principal,
               tc.status::text AS status,
               tc.data_criacao,
               tc.data_atualizacao,
               coalesce(users_count.total_usuarios, 0) AS total_usuarios,
               coalesce(users_count.usuarios_ativos, 0) AS usuarios_ativos,
               coalesce(events_count.total_eventos, 0) AS total_eventos,
               coalesce(events_count.eventos_ativos, 0) AS eventos_ativos
        FROM tb_contas tc
        LEFT JOIN (
            SELECT id_conta,
                   count(*) AS total_usuarios,
                   count(*) FILTER (WHERE status = 'ATIVO'::status_usuario_conta) AS usuarios_ativos
            FROM tb_conta_usuarios
            GROUP BY id_conta
        ) users_count ON users_count.id_conta = tc.id_conta
        LEFT JOIN (
            SELECT id_conta,
                   count(*) AS total_eventos,
                   count(*) FILTER (WHERE status = 'ATIVO'::status_conta_evento) AS eventos_ativos
            FROM tb_conta_eventos
            GROUP BY id_conta
        ) events_count ON events_count.id_conta = tc.id_conta
        WHERE 1 = 1
        <cfif NOT VARIABLES.businessAccountsCanAdminAll>
            AND tc.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessAccountsScopedAccountIds#" list="true"/>)
        </cfif>
        <cfif len(VARIABLES.accountSearchTerm)>
            AND (
                unaccent(upper(coalesce(tc.nome_conta, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountSearchTerm#%"/>))
                OR unaccent(upper(coalesce(tc.nome_titular, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountSearchTerm#%"/>))
                OR unaccent(upper(coalesce(tc.email_principal, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountSearchTerm#%"/>))
                <cfif len(VARIABLES.accountSearchDocument)>
                    OR tc.documento LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountSearchDocument#%"/>
                </cfif>
            )
        </cfif>
        ORDER BY tc.data_atualizacao DESC, tc.nome_conta
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.accountsPerPage#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.accountsOffset#"/>
    </cfquery>

    <cfif len(VARIABLES.accountsEditId)>
        <cfquery name="qBusinessAccountEdit">
            SELECT tc.id_conta,
                   tc.nome_conta,
                   tc.tipo_titular::text AS tipo_titular,
                   tc.documento,
                   tc.nome_titular,
                   tc.email_principal,
                   tc.telefone_principal,
                   tc.status::text AS status,
                   tc.data_criacao,
                   tc.data_atualizacao,
                   coalesce(users_count.total_usuarios, 0) AS total_usuarios,
                   coalesce(users_count.usuarios_ativos, 0) AS usuarios_ativos,
                   coalesce(events_count.total_eventos, 0) AS total_eventos,
                   coalesce(events_count.eventos_ativos, 0) AS eventos_ativos
            FROM tb_contas tc
            LEFT JOIN (
                SELECT id_conta,
                       count(*) AS total_usuarios,
                       count(*) FILTER (WHERE status = 'ATIVO'::status_usuario_conta) AS usuarios_ativos
                FROM tb_conta_usuarios
                GROUP BY id_conta
            ) users_count ON users_count.id_conta = tc.id_conta
            LEFT JOIN (
                SELECT id_conta,
                       count(*) AS total_eventos,
                       count(*) FILTER (WHERE status = 'ATIVO'::status_conta_evento) AS eventos_ativos
                FROM tb_conta_eventos
                GROUP BY id_conta
            ) events_count ON events_count.id_conta = tc.id_conta
            WHERE tc.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountsEditId#"/>
            <cfif NOT VARIABLES.businessAccountsCanAdminAll>
                AND tc.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessAccountsScopedAccountIds#" list="true"/>)
            </cfif>
            LIMIT 1
        </cfquery>

        <cfif qBusinessAccountEdit.recordcount>
            <cfquery name="qBusinessAccountUsers">
                SELECT cu.id_conta_usuario,
                       cu.id_conta,
                       cu.id_usuario,
                       cu.papel::text AS papel,
                       cu.status::text AS status,
                       cu.data_convite,
                       cu.data_aceite,
                       cu.data_criacao,
                       cu.data_atualizacao,
                       usr.name,
                       usr.email,
                       coalesce(usr.is_admin, false) AS is_admin,
                       coalesce(usr.is_partner, false) AS is_partner
                FROM tb_conta_usuarios cu
                INNER JOIN tb_usuarios usr ON usr.id = cu.id_usuario
                WHERE cu.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountEdit.id_conta#"/>
                ORDER BY CASE cu.papel
                    WHEN 'OWNER'::papel_usuario_conta THEN 1
                    WHEN 'ADMIN'::papel_usuario_conta THEN 2
                    WHEN 'OPERADOR'::papel_usuario_conta THEN 3
                    ELSE 4
                END,
                usr.name,
                usr.email
            </cfquery>

            <cfif VARIABLES.businessAccountsCanManageUsers AND len(trim(URL.user_busca))>
                <cfset VARIABLES.accountUserSearchTerm = trim(URL.user_busca)/>
                <cfquery name="qBusinessAccountUserSearch">
                    SELECT usr.id,
                           usr.name,
                           usr.email,
                           coalesce(usr.is_admin, false) AS is_admin,
                           coalesce(usr.is_partner, false) AS is_partner,
                           cu.papel::text AS papel,
                           cu.status::text AS status
                    FROM tb_usuarios usr
                    LEFT JOIN tb_conta_usuarios cu
                        ON cu.id_usuario = usr.id
                       AND cu.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountEdit.id_conta#"/>
                    WHERE
                        <cfif isNumeric(VARIABLES.accountUserSearchTerm)>
                            usr.id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.accountUserSearchTerm#"/>
                            OR
                        </cfif>
                        unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountUserSearchTerm#%"/>))
                        OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountUserSearchTerm#%"/>))
                    ORDER BY usr.name, usr.email
                    LIMIT 50
                </cfquery>
            </cfif>

            <cfquery name="qBusinessAccountEvents">
                SELECT ce.id_conta_evento,
                       ce.id_conta,
                       ce.id_evento,
                       ce.status::text AS status,
                       ce.data_criacao,
                       ce.data_atualizacao,
                       evt.nome_evento,
                       evt.tag,
                       evt.data_inicial,
                       evt.data_final,
                       evt.cidade,
                       evt.estado
                FROM tb_conta_eventos ce
                INNER JOIN tb_evento_corridas evt ON evt.id_evento = ce.id_evento
                WHERE ce.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountEdit.id_conta#"/>
                ORDER BY CASE ce.status
                    WHEN 'ATIVO'::status_conta_evento THEN 1
                    WHEN 'PENDENTE'::status_conta_evento THEN 2
                    ELSE 3
                END,
                evt.data_final DESC NULLS LAST,
                evt.nome_evento
            </cfquery>

            <cfif VARIABLES.businessAccountsCanManageEvents AND len(trim(URL.evento_busca))>
                <cfset VARIABLES.accountEventSearchTerm = trim(URL.evento_busca)/>
                <cfquery name="qBusinessAccountEventSearch">
                    SELECT evt.id_evento,
                           evt.nome_evento,
                           evt.tag,
                           evt.data_inicial,
                           evt.data_final,
                           evt.cidade,
                           evt.estado,
                           ce.status::text AS status
                    FROM tb_evento_corridas evt
                    LEFT JOIN tb_conta_eventos ce
                        ON ce.id_evento = evt.id_evento
                       AND ce.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qBusinessAccountEdit.id_conta#"/>
                    WHERE evt.ativo = true
                      AND (
                        <cfif isNumeric(VARIABLES.accountEventSearchTerm)>
                            evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.accountEventSearchTerm#"/>
                            OR
                        </cfif>
                        unaccent(upper(coalesce(evt.nome_evento, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountEventSearchTerm#%"/>))
                        OR unaccent(upper(coalesce(evt.tag, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountEventSearchTerm#%"/>))
                        OR unaccent(upper(coalesce(evt.cidade, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.accountEventSearchTerm#%"/>))
                      )
                    ORDER BY evt.data_final DESC NULLS LAST, evt.nome_evento
                    LIMIT 50
                </cfquery>
            </cfif>
        </cfif>
    </cfif>
</cfif>

<cfif VARIABLES.businessAccountsTablesReady
    AND VARIABLES.businessAccountRegistrationTableReady
    AND VARIABLES.businessAccountsCanAdminAll>
    <cfquery name="qBusinessAccountRegistrationAccountOptions">
        SELECT id_conta,
               nome_conta,
               documento,
               status::text AS status
        FROM tb_contas
        ORDER BY
            CASE WHEN status = 'ATIVA'::status_conta THEN 0 ELSE 1 END,
            nome_conta
        LIMIT 250
    </cfquery>

    <cfquery name="qBusinessAccountRegistrationStats">
        SELECT count(*) AS total_solicitacoes,
               count(*) FILTER (WHERE status = 'PENDENTE'::status_conta_cadastro_solicitacao) AS total_pendentes
        FROM tb_conta_cadastro_solicitacoes
    </cfquery>

    <cfset VARIABLES.accountsRegistrationTotal = val(qBusinessAccountRegistrationStats.total_solicitacoes)/>
    <cfset VARIABLES.accountsRegistrationPendingTotal = val(qBusinessAccountRegistrationStats.total_pendentes)/>

    <cfquery name="qBusinessAccountRegistrationRequests">
        SELECT sol.id_solicitacao,
               sol.nome_empresa,
               sol.tipo_titular::text AS tipo_titular,
               sol.documento,
               sol.nome_responsavel,
               sol.email_responsavel,
               sol.telefone_responsavel,
               sol.site,
               sol.cidade,
               sol.estado,
               sol.tipo_prestador,
               sol.mensagem,
               sol.id_usuario,
               sol.id_conta,
               sol.status::text AS status,
               sol.data_criacao,
               cont.nome_conta,
               usr.name AS usuario_nome
        FROM tb_conta_cadastro_solicitacoes sol
        LEFT JOIN tb_contas cont ON cont.id_conta = sol.id_conta
        LEFT JOIN tb_usuarios usr ON usr.id = sol.id_usuario
        WHERE sol.status = 'PENDENTE'::status_conta_cadastro_solicitacao
        ORDER BY sol.data_criacao ASC
        LIMIT 25
    </cfquery>
</cfif>
