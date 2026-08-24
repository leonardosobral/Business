<cfparam name="VARIABLES.cadastroErro" default=""/>
<cfparam name="VARIABLES.cadastroSucesso" default=""/>
<cfparam name="VARIABLES.cadastroSolicitacaoTablesReady" default="false"/>
<cfset VARIABLES.cadastroGoogleClientId = "921450846888-qa9a1alk06v6i0ao4jbiihdfrn8j7528.apps.googleusercontent.com"/>

<cfif NOT structKeyExists(SESSION, "cadastroGoogleCsrf") OR NOT len(trim(SESSION.cadastroGoogleCsrf & ""))>
    <cfset SESSION.cadastroGoogleCsrf = createUUID()/>
</cfif>

<cfparam name="FORM.nome_empresa" default=""/>
<cfparam name="FORM.tipo_titular" default="PJ"/>
<cfparam name="FORM.documento" default=""/>
<cfparam name="FORM.nome_responsavel" default=""/>
<cfparam name="FORM.email_responsavel" default=""/>
<cfparam name="FORM.telefone_responsavel" default=""/>
<cfparam name="FORM.site" default=""/>
<cfparam name="FORM.cidade" default=""/>
<cfparam name="FORM.estado" default=""/>
<cfparam name="FORM.tipo_prestador" default=""/>
<cfparam name="FORM.mensagem" default=""/>
<cfparam name="FORM.acao" default=""/>
<cfparam name="FORM.cadastro_csrf" default=""/>
<cfparam name="FORM.confirmar_conta_existente" default="0"/>
<cfset VARIABLES.cadastroTipoTitularList = "PF,PJ"/>
<cfset VARIABLES.cadastroTipoPrestadorList = "Organizador,Cronometragem,Assessoria,Marca/Patrocinador,Midia/Criador,Fornecedor,Agencia,Outro"/>
<cfset VARIABLES.cadastroSolicitacaoId = isDefined("URL.id") AND isNumeric(URL.id) ? int(URL.id) : 0/>
<cfset VARIABLES.cadastroExistingAccountConfirmationRequired = false/>
<cfset VARIABLES.cadastroExistingAccountConfirmed = FORM.confirmar_conta_existente EQ "1"/>
<cfset VARIABLES.cadastroExistingAccountName = ""/>

<cfif FORM.acao EQ "trocar_conta_google">
    <cfif len(trim(FORM.cadastro_csrf)) AND compare(FORM.cadastro_csrf, SESSION.cadastroGoogleCsrf) EQ 0>
        <cfset structDelete(SESSION, "cadastroGoogleIdentity", false)/>
        <cfset SESSION.cadastroGoogleCsrf = createUUID()/>
        <cflocation addtoken="false" url="/cadastro/"/>
    <cfelse>
        <cfset VARIABLES.cadastroErro = "A sessão expirou. Atualize a página e tente novamente."/>
    </cfif>
</cfif>

<cfset VARIABLES.cadastroGoogleAuthenticated = structKeyExists(SESSION, "cadastroGoogleIdentity")
    AND isStruct(SESSION.cadastroGoogleIdentity)
    AND structKeyExists(SESSION.cadastroGoogleIdentity, "sub")
    AND len(trim(SESSION.cadastroGoogleIdentity.sub & ""))
    AND structKeyExists(SESSION.cadastroGoogleIdentity, "email")
    AND isValid("email", SESSION.cadastroGoogleIdentity.email & "")
    AND structKeyExists(SESSION.cadastroGoogleIdentity, "name")
    AND len(trim(SESSION.cadastroGoogleIdentity.name & ""))/>

<cfif VARIABLES.cadastroGoogleAuthenticated>
    <cfset FORM.nome_responsavel = SESSION.cadastroGoogleIdentity.name/>
    <cfset FORM.email_responsavel = SESSION.cadastroGoogleIdentity.email/>
</cfif>

<cftry>
    <cfquery name="qCadastroSolicitacaoTableCheck">
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN (
            <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_cadastro_solicitacoes"/>
          )
    </cfquery>

    <cfset VARIABLES.cadastroSolicitacaoTableNames = ValueList(qCadastroSolicitacaoTableCheck.table_name)/>
    <cfset VARIABLES.cadastroSolicitacaoTablesReady = ListFindNoCase(VARIABLES.cadastroSolicitacaoTableNames, "tb_conta_cadastro_solicitacoes")/>

    <cfcatch type="any">
        <cfset VARIABLES.cadastroSolicitacaoTablesReady = false/>
    </cfcatch>
</cftry>

<cfif isDefined("URL.solicitacao") AND URL.solicitacao EQ "recebida">
    <cfif VARIABLES.cadastroGoogleAuthenticated
        AND VARIABLES.cadastroSolicitacaoTablesReady
        AND VARIABLES.cadastroSolicitacaoId GT 0>
        <cfquery name="qCadastroSolicitacaoRecebidaResponsavel">
            SELECT id_solicitacao
            FROM tb_conta_cadastro_solicitacoes
            WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cadastroSolicitacaoId#"/>
              AND lower(email_responsavel) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(SESSION.cadastroGoogleIdentity.email))#" maxlength="255"/>
              AND status = 'PENDENTE'::status_conta_cadastro_solicitacao
            LIMIT 1
        </cfquery>

        <cfif qCadastroSolicitacaoRecebidaResponsavel.recordcount>
            <cflocation addtoken="false" url="/"/>
        </cfif>
    </cfif>

    <cfset VARIABLES.cadastroSucesso = "Recebemos sua solicitacao de acesso. Nossa equipe vai revisar os dados e liberar a conta quando tudo estiver confirmado."/>
    <cfif VARIABLES.cadastroSolicitacaoId GT 0>
        <cfset VARIABLES.cadastroSucesso = VARIABLES.cadastroSucesso & " Protocolo: " & VARIABLES.cadastroSolicitacaoId & "."/>
    </cfif>
</cfif>

<cfif isDefined("FORM.acao") AND FORM.acao EQ "solicitar_acesso">
    <cfset VARIABLES.cadastroNomeEmpresa = trim(FORM.nome_empresa)/>
    <cfset VARIABLES.cadastroTipoTitular = uCase(trim(FORM.tipo_titular))/>
    <cfset VARIABLES.cadastroDocumento = REReplace(trim(FORM.documento), "[^0-9]", "", "all")/>
    <cfset VARIABLES.cadastroNomeResponsavel = VARIABLES.cadastroGoogleAuthenticated ? trim(SESSION.cadastroGoogleIdentity.name) : ""/>
    <cfset VARIABLES.cadastroEmailResponsavel = VARIABLES.cadastroGoogleAuthenticated ? lCase(trim(SESSION.cadastroGoogleIdentity.email)) : ""/>
    <cfset VARIABLES.cadastroTelefoneResponsavel = trim(FORM.telefone_responsavel)/>
    <cfset VARIABLES.cadastroSite = trim(FORM.site)/>
    <cfset VARIABLES.cadastroCidade = trim(FORM.cidade)/>
    <cfset VARIABLES.cadastroEstado = uCase(left(trim(FORM.estado), 2))/>
    <cfset VARIABLES.cadastroTipoPrestador = trim(FORM.tipo_prestador)/>
    <cfset VARIABLES.cadastroMensagem = trim(FORM.mensagem)/>
    <cfset VARIABLES.cadastroErrors = []/>

    <cfif NOT VARIABLES.cadastroGoogleAuthenticated>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Confirme sua identidade com o Google antes de enviar a solicitação.")/>
    </cfif>

    <cfif NOT len(trim(FORM.cadastro_csrf)) OR compare(FORM.cadastro_csrf, SESSION.cadastroGoogleCsrf) NEQ 0>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "A sessão do formulário expirou. Atualize a página e tente novamente.")/>
    </cfif>

    <cfif NOT VARIABLES.cadastroSolicitacaoTablesReady>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "O cadastro externo ainda depende da aplicacao da DDL de solicitacoes de conta.")/>
    </cfif>

    <cfif NOT len(VARIABLES.cadastroNomeEmpresa)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe o nome da empresa.")/>
    </cfif>

    <cfif NOT listFindNoCase(VARIABLES.cadastroTipoTitularList, VARIABLES.cadastroTipoTitular)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe se o titular e PF ou PJ.")/>
    </cfif>

    <cfif NOT len(VARIABLES.cadastroDocumento)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe o CPF ou CNPJ.")/>
    </cfif>

    <cfif NOT len(VARIABLES.cadastroNomeResponsavel)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe o nome do responsavel.")/>
    </cfif>

    <cfif NOT len(VARIABLES.cadastroEmailResponsavel) OR NOT isValid("email", VARIABLES.cadastroEmailResponsavel)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe um e-mail valido para o responsavel.")/>
    </cfif>

    <cfif NOT len(VARIABLES.cadastroTipoPrestador)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe o tipo de prestador de servico.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cadastroErrors)>
        <cfquery name="qCadastroSolicitacaoExistente">
            SELECT sol.id_solicitacao,
                   sol.id_conta,
                   sol.id_usuario,
                   cont.status::text AS status_conta,
                   CASE WHEN cu.id_conta IS NOT NULL THEN true ELSE false END AS possui_workspace_provisorio
            FROM tb_conta_cadastro_solicitacoes sol
            LEFT JOIN tb_contas cont ON cont.id_conta = sol.id_conta
            LEFT JOIN tb_usuarios usr
                ON lower(usr.email) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEmailResponsavel#" maxlength="255"/>
            LEFT JOIN tb_conta_usuarios cu
                ON cu.id_conta = sol.id_conta
               AND cu.id_usuario = usr.id
               AND cu.papel = 'OWNER'::papel_usuario_conta
               AND cu.status = 'ATIVO'::status_usuario_conta
            WHERE sol.status = 'PENDENTE'::status_conta_cadastro_solicitacao
              AND (
                sol.documento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroDocumento#" maxlength="20"/>
                OR lower(sol.email_responsavel) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEmailResponsavel#" maxlength="255"/>
              )
            ORDER BY sol.data_criacao DESC
            LIMIT 1
        </cfquery>

        <cfif qCadastroSolicitacaoExistente.recordcount>
            <cfset SESSION.cadastroGoogleCsrf = createUUID()/>
            <cflocation addtoken="false" url="/"/>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cadastroErrors)>
        <cfquery name="qCadastroContaDocumentoExistente">
            SELECT id_conta,
                   nome_conta
            FROM tb_contas
            WHERE documento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroDocumento#" maxlength="20"/>
            LIMIT 1
        </cfquery>

        <cfif qCadastroContaDocumentoExistente.recordcount>
            <cfset VARIABLES.cadastroExistingAccountName = qCadastroContaDocumentoExistente.nome_conta/>
            <cfset FORM.nome_empresa = qCadastroContaDocumentoExistente.nome_conta/>
            <cfif NOT VARIABLES.cadastroExistingAccountConfirmed>
                <cfset VARIABLES.cadastroExistingAccountConfirmationRequired = true/>
            </cfif>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cadastroErrors) AND NOT VARIABLES.cadastroExistingAccountConfirmationRequired>
        <cftry>
            <cftransaction>
                <cfquery name="qCadastroResponsavel">
                    SELECT id
                    FROM tb_usuarios
                    WHERE lower(email) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEmailResponsavel#" maxlength="255"/>
                    LIMIT 1
                </cfquery>

                <cfif NOT qCadastroResponsavel.recordcount>
                    <cfthrow message="O usuario autenticado nao foi encontrado. Entre novamente com o Google."/>
                </cfif>

                <cfset VARIABLES.cadastroSolicitacaoNomeEmpresa = VARIABLES.cadastroNomeEmpresa/>
                <cfif qCadastroContaDocumentoExistente.recordcount>
                    <cfset VARIABLES.cadastroContaId = qCadastroContaDocumentoExistente.id_conta/>
                    <cfset VARIABLES.cadastroSolicitacaoNomeEmpresa = qCadastroContaDocumentoExistente.nome_conta/>
                <cfelse>
                    <cfquery name="qCadastroContaCriar">
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
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroNomeEmpresa#" maxlength="160"/>,
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTipoTitular#"/> AS tipo_titular_conta),
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroDocumento#" maxlength="20"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroNomeResponsavel#" maxlength="200"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEmailResponsavel#" maxlength="255"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTelefoneResponsavel#" maxlength="30" null="#NOT len(VARIABLES.cadastroTelefoneResponsavel)#"/>,
                            'PENDENTE'::status_conta
                        )
                        RETURNING id_conta
                    </cfquery>

                    <cfset VARIABLES.cadastroContaId = qCadastroContaCriar.id_conta/>
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
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cadastroContaId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroResponsavel.id#"/>,
                            'OWNER'::papel_usuario_conta,
                            'ATIVO'::status_usuario_conta,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroResponsavel.id#"/>,
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
                </cfif>

                <cfquery name="qCadastroSolicitacaoSalvar">
                    INSERT INTO tb_conta_cadastro_solicitacoes
                    (
                        nome_empresa,
                        tipo_titular,
                        documento,
                        nome_responsavel,
                        email_responsavel,
                        telefone_responsavel,
                        site,
                        cidade,
                        estado,
                        tipo_prestador,
                        mensagem,
                        id_usuario,
                        id_conta,
                        status
                    )
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroSolicitacaoNomeEmpresa#" maxlength="160"/>,
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTipoTitular#"/> AS tipo_titular_conta),
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroDocumento#" maxlength="20"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroNomeResponsavel#" maxlength="200"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEmailResponsavel#" maxlength="255"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTelefoneResponsavel#" maxlength="30" null="#NOT len(VARIABLES.cadastroTelefoneResponsavel)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroSite#" maxlength="256" null="#NOT len(VARIABLES.cadastroSite)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroCidade#" maxlength="128" null="#NOT len(VARIABLES.cadastroCidade)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEstado#" maxlength="2" null="#NOT len(VARIABLES.cadastroEstado)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTipoPrestador#" maxlength="80"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cadastroMensagem#" null="#NOT len(VARIABLES.cadastroMensagem)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroResponsavel.id#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cadastroContaId#"/>,
                        'PENDENTE'::status_conta_cadastro_solicitacao
                    )
                    RETURNING id_solicitacao
                </cfquery>
            </cftransaction>

            <cfset SESSION.cadastroGoogleCsrf = createUUID()/>
            <cflocation addtoken="false" url="/"/>

            <cfcatch type="any">
                <cfset VARIABLES.cadastroErro = "Nao foi possivel registrar a solicitacao. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    <cfelseif arrayLen(VARIABLES.cadastroErrors)>
        <cfset VARIABLES.cadastroErro = arrayToList(VARIABLES.cadastroErrors, " ")/>
    </cfif>
</cfif>
