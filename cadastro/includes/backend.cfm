<cfparam name="VARIABLES.cadastroErro" default=""/>
<cfparam name="VARIABLES.cadastroSucesso" default=""/>
<cfparam name="VARIABLES.cadastroSolicitacaoTablesReady" default="false"/>
<cfparam name="VARIABLES.cadastroVoucherTablesReady" default="false"/>
<cfparam name="VARIABLES.cadastroVoucherResgateSucesso" default="false"/>

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
<cfparam name="FORM.voucher_codigo" default=""/>

<cfif isDefined("URL.voucher") AND len(trim(URL.voucher)) AND NOT len(trim(FORM.voucher_codigo))>
    <cfset FORM.voucher_codigo = trim(URL.voucher)/>
<cfelseif isDefined("URL.codigo") AND len(trim(URL.codigo)) AND NOT len(trim(FORM.voucher_codigo))>
    <cfset FORM.voucher_codigo = trim(URL.codigo)/>
</cfif>

<cfset VARIABLES.cadastroTipoTitularList = "PF,PJ"/>
<cfset VARIABLES.cadastroTipoPrestadorList = "Organizador,Cronometragem,Assessoria,Marca/Patrocinador,Midia/Criador,Fornecedor,Agencia,Outro"/>
<cfset VARIABLES.cadastroSolicitacaoId = isDefined("URL.id") AND isNumeric(URL.id) ? int(URL.id) : 0/>

<cftry>
    <cfquery name="qCadastroSolicitacaoTableCheck">
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN (
            <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_cadastro_solicitacoes"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_vouchers"/>
          )
    </cfquery>

    <cfquery name="qCadastroVoucherColumnCheck">
        SELECT table_name,
               column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND (
            (
              table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_vouchers"/>
              AND column_name IN (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="id_conta"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="id_usuario_resgate"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="papel_resgate"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="data_resgate"/>
              )
            )
            OR
            (
              table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_cadastro_solicitacoes"/>
              AND column_name IN (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="id_ad_voucher"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="voucher_codigo"/>
              )
            )
          )
    </cfquery>

    <cfset VARIABLES.cadastroSolicitacaoTableNames = ValueList(qCadastroSolicitacaoTableCheck.table_name)/>
    <cfset VARIABLES.cadastroVoucherColumnNames = ""/>
    <cfloop query="qCadastroVoucherColumnCheck">
        <cfset VARIABLES.cadastroVoucherColumnNames = ListAppend(VARIABLES.cadastroVoucherColumnNames, qCadastroVoucherColumnCheck.table_name & "." & qCadastroVoucherColumnCheck.column_name)/>
    </cfloop>

    <cfset VARIABLES.cadastroSolicitacaoTablesReady = ListFindNoCase(VARIABLES.cadastroSolicitacaoTableNames, "tb_conta_cadastro_solicitacoes")/>
    <cfset VARIABLES.cadastroVoucherTablesReady = ListFindNoCase(VARIABLES.cadastroSolicitacaoTableNames, "tb_ad_vouchers")
        AND ListFindNoCase(VARIABLES.cadastroVoucherColumnNames, "tb_ad_vouchers.id_conta")
        AND ListFindNoCase(VARIABLES.cadastroVoucherColumnNames, "tb_ad_vouchers.id_usuario_resgate")
        AND ListFindNoCase(VARIABLES.cadastroVoucherColumnNames, "tb_ad_vouchers.papel_resgate")
        AND ListFindNoCase(VARIABLES.cadastroVoucherColumnNames, "tb_ad_vouchers.data_resgate")
        AND ListFindNoCase(VARIABLES.cadastroVoucherColumnNames, "tb_conta_cadastro_solicitacoes.id_ad_voucher")
        AND ListFindNoCase(VARIABLES.cadastroVoucherColumnNames, "tb_conta_cadastro_solicitacoes.voucher_codigo")/>

    <cfcatch type="any">
        <cfset VARIABLES.cadastroSolicitacaoTablesReady = false/>
        <cfset VARIABLES.cadastroVoucherTablesReady = false/>
    </cfcatch>
</cftry>

<cfif isDefined("URL.solicitacao") AND URL.solicitacao EQ "recebida">
    <cfset VARIABLES.cadastroSucesso = "Recebemos sua solicitacao de acesso. Nossa equipe vai revisar os dados e liberar a conta quando tudo estiver confirmado."/>
    <cfif VARIABLES.cadastroSolicitacaoId GT 0>
        <cfset VARIABLES.cadastroSucesso = VARIABLES.cadastroSucesso & " Protocolo: " & VARIABLES.cadastroSolicitacaoId & "."/>
    </cfif>
</cfif>

<cfif isDefined("FORM.acao") AND FORM.acao EQ "resgatar_voucher">
    <cfset VARIABLES.cadastroVoucherCodigo = uCase(trim(FORM.voucher_codigo))/>
    <cfset VARIABLES.cadastroVoucherCodigo = REReplace(VARIABLES.cadastroVoucherCodigo, "[^A-Z0-9-]", "", "all")/>
    <cfset VARIABLES.cadastroErrors = []/>

    <cfif NOT len(VARIABLES.cadastroVoucherCodigo)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe o codigo do voucher.")/>
    </cfif>

    <cfif NOT VARIABLES.cadastroVoucherTablesReady>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "A estrutura de vouchers ainda nao foi aplicada.")/>
    </cfif>

    <cfif NOT isDefined("COOKIE.id") OR NOT len(trim(COOKIE.id)) OR NOT isNumeric(COOKIE.id)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Faca login antes de resgatar o voucher.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cadastroErrors)>
        <cftry>
            <cftransaction>
                <cfquery name="qCadastroVoucherResgateCheck">
                    SELECT vou.id_ad_voucher,
                           vou.codigo,
                           vou.id_conta,
                           vou.status,
                           vou.credito,
                           vou.data_expiracao,
                           vou.papel_resgate::text AS papel_resgate,
                           cont.nome_conta
                    FROM tb_ad_vouchers vou
                    INNER JOIN tb_contas cont ON cont.id_conta = vou.id_conta
                    WHERE lower(vou.codigo) = lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroVoucherCodigo#"/>)
                    LIMIT 1
                    FOR UPDATE
                </cfquery>

                <cfquery name="qCadastroVoucherResgateUsuario">
                    SELECT id,
                           name,
                           email
                    FROM tb_usuarios
                    WHERE id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#COOKIE.id#"/>
                    LIMIT 1
                </cfquery>

                <cfif NOT qCadastroVoucherResgateUsuario.recordcount>
                    <cfset arrayAppend(VARIABLES.cadastroErrors, "Nao foi possivel identificar o usuario logado para resgatar o voucher.")/>
                <cfelseif NOT qCadastroVoucherResgateCheck.recordcount>
                    <cfset arrayAppend(VARIABLES.cadastroErrors, "Voucher nao encontrado.")/>
                <cfelseif qCadastroVoucherResgateCheck.status NEQ 1>
                    <cfset arrayAppend(VARIABLES.cadastroErrors, "Este voucher nao esta disponivel para resgate.")/>
                <cfelseif len(trim(qCadastroVoucherResgateCheck.data_expiracao)) AND isDate(qCadastroVoucherResgateCheck.data_expiracao) AND dateCompare(qCadastroVoucherResgateCheck.data_expiracao, now(), "d") LT 0>
                    <cfset arrayAppend(VARIABLES.cadastroErrors, "Este voucher esta expirado.")/>
                </cfif>

                <cfif NOT arrayLen(VARIABLES.cadastroErrors)>
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
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroVoucherResgateCheck.id_conta#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroVoucherResgateUsuario.id#"/>,
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#qCadastroVoucherResgateCheck.papel_resgate#"/> AS papel_usuario_conta),
                            'ATIVO'::status_usuario_conta,
                            NULL,
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

                    <cfquery>
                        UPDATE tb_ad_vouchers
                        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>,
                            id_usuario_resgate = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroVoucherResgateUsuario.id#"/>,
                            data_resgate = now(),
                            credito_disponivel = COALESCE(credito_disponivel, credito, 0),
                            data_atualizacao = now()
                        WHERE id_ad_voucher = <cfqueryparam cfsqltype="cf_sql_integer" value="#qCadastroVoucherResgateCheck.id_ad_voucher#"/>
                          AND status = <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>
                    </cfquery>

                    <cflocation addtoken="false" url="/administracao/contas/?conta_id=#qCadastroVoucherResgateCheck.id_conta#&voucher=resgatado"/>
                </cfif>
            </cftransaction>

            <cfcatch type="any">
                <cfset arrayAppend(VARIABLES.cadastroErrors, "Nao foi possivel resgatar o voucher. " & cfcatch.message)/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif arrayLen(VARIABLES.cadastroErrors)>
        <cfset VARIABLES.cadastroErro = arrayToList(VARIABLES.cadastroErrors, " ")/>
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
    <cfset VARIABLES.cadastroVoucherCodigo = uCase(trim(FORM.voucher_codigo))/>
    <cfset VARIABLES.cadastroVoucherCodigo = REReplace(VARIABLES.cadastroVoucherCodigo, "[^A-Z0-9-]", "", "all")/>
    <cfset VARIABLES.cadastroVoucherId = ""/>
    <cfset VARIABLES.cadastroVoucherContaId = ""/>
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

    <cfif len(VARIABLES.cadastroVoucherCodigo)>
        <cfif NOT VARIABLES.cadastroVoucherTablesReady>
            <cfset arrayAppend(VARIABLES.cadastroErrors, "A estrutura de vouchers ainda nao foi aplicada.")/>
        <cfelse>
            <cfquery name="qCadastroVoucherCheck">
                SELECT vou.id_ad_voucher,
                       vou.codigo,
                       vou.id_conta,
                       vou.status,
                       vou.credito,
                       vou.data_expiracao,
                       vou.papel_resgate::text AS papel_resgate,
                       cont.nome_conta
                FROM tb_ad_vouchers vou
                INNER JOIN tb_contas cont ON cont.id_conta = vou.id_conta
                WHERE lower(vou.codigo) = lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroVoucherCodigo#"/>)
                LIMIT 1
            </cfquery>

            <cfif NOT qCadastroVoucherCheck.recordcount>
                <cfset arrayAppend(VARIABLES.cadastroErrors, "Voucher nao encontrado.")/>
            <cfelseif qCadastroVoucherCheck.status NEQ 1>
                <cfset arrayAppend(VARIABLES.cadastroErrors, "Este voucher nao esta disponivel para resgate.")/>
            <cfelseif len(trim(qCadastroVoucherCheck.data_expiracao)) AND isDate(qCadastroVoucherCheck.data_expiracao) AND dateCompare(qCadastroVoucherCheck.data_expiracao, now(), "d") LT 0>
                <cfset arrayAppend(VARIABLES.cadastroErrors, "Este voucher esta expirado.")/>
            <cfelse>
                <cfset VARIABLES.cadastroVoucherId = qCadastroVoucherCheck.id_ad_voucher/>
                <cfset VARIABLES.cadastroVoucherContaId = qCadastroVoucherCheck.id_conta/>
            </cfif>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cadastroErrors)
        AND len(VARIABLES.cadastroVoucherId)
        AND isDefined("COOKIE.id")
        AND len(trim(COOKIE.id))
        AND isNumeric(COOKIE.id)>
        <cftry>
            <cftransaction>
                <cfquery name="qCadastroVoucherUsuarioLogado">
                    SELECT id,
                           name,
                           email
                    FROM tb_usuarios
                    WHERE id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#COOKIE.id#"/>
                    LIMIT 1
                </cfquery>

                <cfif NOT qCadastroVoucherUsuarioLogado.recordcount>
                    <cfset arrayAppend(VARIABLES.cadastroErrors, "Nao foi possivel identificar o usuario logado para resgatar o voucher.")/>
                </cfif>

                <cfif NOT arrayLen(VARIABLES.cadastroErrors)>
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
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cadastroVoucherContaId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroVoucherUsuarioLogado.id#"/>,
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#qCadastroVoucherCheck.papel_resgate#"/> AS papel_usuario_conta),
                            'ATIVO'::status_usuario_conta,
                            NULL,
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

                    <cfquery>
                        UPDATE tb_ad_vouchers
                        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>,
                            id_usuario_resgate = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroVoucherUsuarioLogado.id#"/>,
                            data_resgate = now(),
                            credito_disponivel = COALESCE(credito_disponivel, credito, 0),
                            data_atualizacao = now()
                        WHERE id_ad_voucher = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cadastroVoucherId#"/>
                          AND status = <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>
                    </cfquery>

                    <cflocation addtoken="false" url="/administracao/contas/?conta_id=#VARIABLES.cadastroVoucherContaId#&voucher=resgatado"/>
                </cfif>
            </cftransaction>

            <cfcatch type="any">
                <cfset arrayAppend(VARIABLES.cadastroErrors, "Nao foi possivel resgatar o voucher. " & cfcatch.message)/>
            </cfcatch>
        </cftry>
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
            <cfif VARIABLES.cadastroVoucherTablesReady AND len(VARIABLES.cadastroVoucherId)>
                <cfquery>
                    UPDATE tb_conta_cadastro_solicitacoes
                    SET id_ad_voucher = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cadastroVoucherId#"/>,
                        voucher_codigo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroVoucherCodigo#" maxlength="80"/>
                    WHERE id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCadastroSolicitacaoExistente.id_solicitacao#"/>
                      AND id_ad_voucher IS NULL
                </cfquery>
            </cfif>
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
                    <cfif VARIABLES.cadastroVoucherTablesReady>
                        id_ad_voucher,
                        voucher_codigo,
                    </cfif>
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
                    <cfif VARIABLES.cadastroVoucherTablesReady>
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cadastroVoucherId#" null="#NOT len(VARIABLES.cadastroVoucherId)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroVoucherCodigo#" maxlength="80" null="#NOT len(VARIABLES.cadastroVoucherCodigo)#"/>,
                    </cfif>
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
