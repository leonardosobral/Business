<cfparam name="VARIABLES.cadastroErro" default=""/>
<cfparam name="VARIABLES.cadastroSucesso" default=""/>
<cfparam name="VARIABLES.cadastroSolicitacaoTablesReady" default="false"/>

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
<cfset VARIABLES.cadastroTipoTitularList = "PF,PJ"/>
<cfset VARIABLES.cadastroTipoPrestadorList = "Organizador,Cronometragem,Assessoria,Marca/Patrocinador,Midia/Criador,Fornecedor,Agencia,Outro"/>
<cfset VARIABLES.cadastroSolicitacaoId = isDefined("URL.id") AND isNumeric(URL.id) ? int(URL.id) : 0/>

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
    <cfset VARIABLES.cadastroSucesso = "Recebemos sua solicitacao de acesso. Nossa equipe vai revisar os dados e liberar a conta quando tudo estiver confirmado."/>
    <cfif VARIABLES.cadastroSolicitacaoId GT 0>
        <cfset VARIABLES.cadastroSucesso = VARIABLES.cadastroSucesso & " Protocolo: " & VARIABLES.cadastroSolicitacaoId & "."/>
    </cfif>
</cfif>

<cfif isDefined("FORM.acao") AND FORM.acao EQ "solicitar_acesso">
    <cfset VARIABLES.cadastroNomeEmpresa = trim(FORM.nome_empresa)/>
    <cfset VARIABLES.cadastroTipoTitular = uCase(trim(FORM.tipo_titular))/>
    <cfset VARIABLES.cadastroDocumento = REReplace(trim(FORM.documento), "[^0-9]", "", "all")/>
    <cfset VARIABLES.cadastroNomeResponsavel = trim(FORM.nome_responsavel)/>
    <cfset VARIABLES.cadastroEmailResponsavel = lCase(trim(FORM.email_responsavel))/>
    <cfset VARIABLES.cadastroTelefoneResponsavel = trim(FORM.telefone_responsavel)/>
    <cfset VARIABLES.cadastroSite = trim(FORM.site)/>
    <cfset VARIABLES.cadastroCidade = trim(FORM.cidade)/>
    <cfset VARIABLES.cadastroEstado = uCase(left(trim(FORM.estado), 2))/>
    <cfset VARIABLES.cadastroTipoPrestador = trim(FORM.tipo_prestador)/>
    <cfset VARIABLES.cadastroMensagem = trim(FORM.mensagem)/>
    <cfset VARIABLES.cadastroErrors = []/>

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
            SELECT id_solicitacao
            FROM tb_conta_cadastro_solicitacoes
            WHERE status = 'PENDENTE'::status_conta_cadastro_solicitacao
              AND (
                documento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroDocumento#" maxlength="20"/>
                OR lower(email_responsavel) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEmailResponsavel#" maxlength="255"/>
              )
            ORDER BY data_criacao DESC
            LIMIT 1
        </cfquery>

        <cfif qCadastroSolicitacaoExistente.recordcount>
            <cflocation addtoken="false" url="/cadastro/?solicitacao=recebida&id=#qCadastroSolicitacaoExistente.id_solicitacao#"/>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cadastroErrors)>
        <cftry>
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
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroSite#" maxlength="256" null="#NOT len(VARIABLES.cadastroSite)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroCidade#" maxlength="128" null="#NOT len(VARIABLES.cadastroCidade)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEstado#" maxlength="2" null="#NOT len(VARIABLES.cadastroEstado)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTipoPrestador#" maxlength="80"/>,
                    <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cadastroMensagem#" null="#NOT len(VARIABLES.cadastroMensagem)#"/>,
                    (
                        SELECT id
                        FROM tb_usuarios
                        WHERE lower(email) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEmailResponsavel#" maxlength="255"/>
                        LIMIT 1
                    ),
                    'PENDENTE'::status_conta_cadastro_solicitacao
                )
                RETURNING id_solicitacao
            </cfquery>

            <cflocation addtoken="false" url="/cadastro/?solicitacao=recebida&id=#qCadastroSolicitacaoSalvar.id_solicitacao#"/>

            <cfcatch type="any">
                <cfset VARIABLES.cadastroErro = "Nao foi possivel registrar a solicitacao. " & cfcatch.message/>
            </cfcatch>
        </cftry>
    <cfelse>
        <cfset VARIABLES.cadastroErro = arrayToList(VARIABLES.cadastroErrors, " ")/>
    </cfif>
</cfif>
