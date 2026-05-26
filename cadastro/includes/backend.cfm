<cfparam name="VARIABLES.cadastroErro" default=""/>
<cfparam name="VARIABLES.cadastroSucesso" default=""/>

<cfif isDefined("URL.sucesso") AND URL.sucesso EQ "empresa">
    <cfset VARIABLES.cadastroSucesso = "Empresa cadastrada e vinculada ao seu usuário."/>
</cfif>

<cfquery name="qCadastroTiposFornecedor">
    SELECT id_fornecedor_tipo, descricao_tipo, tag_tipo
    FROM tb_fornecedores_tipos
    ORDER BY descricao_tipo
</cfquery>

<cfif isDefined("FORM.acao") AND FORM.acao EQ "salvar_empresa">
    <cfset VARIABLES.cadastroNomeFornecedor = isDefined("FORM.nome_fornecedor") ? trim(FORM.nome_fornecedor) : ""/>
    <cfset VARIABLES.cadastroTipoPessoa = isDefined("FORM.tipo_pessoa") ? uCase(left(trim(FORM.tipo_pessoa), 1)) : ""/>
    <cfset VARIABLES.cadastroDocumento = isDefined("FORM.cnpj_cpf") ? reReplace(trim(FORM.cnpj_cpf), "[^0-9]", "", "all") : ""/>
    <cfset VARIABLES.cadastroSite = isDefined("FORM.site_fornecedor") ? trim(FORM.site_fornecedor) : ""/>
    <cfset VARIABLES.cadastroCidade = isDefined("FORM.cidade") ? trim(FORM.cidade) : ""/>
    <cfset VARIABLES.cadastroEstado = isDefined("FORM.estado") ? uCase(left(trim(FORM.estado), 2)) : ""/>
    <cfset VARIABLES.cadastroResumo = isDefined("FORM.resumo_fornecedor") ? trim(FORM.resumo_fornecedor) : ""/>
    <cfset VARIABLES.cadastroErrors = []/>

    <cfif NOT len(VARIABLES.cadastroNomeFornecedor)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe o nome da empresa.")/>
    </cfif>

    <cfif NOT listFindNoCase("J,F", VARIABLES.cadastroTipoPessoa)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe se o cadastro é de pessoa jurídica ou física.")/>
    </cfif>

    <cfif NOT len(VARIABLES.cadastroDocumento)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe o CNPJ ou CPF.")/>
    </cfif>

    <cfif NOT isDefined("FORM.id_fornecedor_tipo") OR NOT isNumeric(FORM.id_fornecedor_tipo)>
        <cfset arrayAppend(VARIABLES.cadastroErrors, "Informe o tipo de atuação da empresa.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cadastroErrors)>
        <cfquery name="qCadastroTipoFornecedor">
            SELECT id_fornecedor_tipo, descricao_tipo, tag_tipo
            FROM tb_fornecedores_tipos
            WHERE id_fornecedor_tipo = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_fornecedor_tipo#"/>
        </cfquery>

        <cfif NOT qCadastroTipoFornecedor.recordcount>
            <cfset arrayAppend(VARIABLES.cadastroErrors, "Tipo de atuação não encontrado.")/>
        <cfelse>
            <cfset VARIABLES.cadastroTagTipo = lCase(trim(qCadastroTipoFornecedor.tag_tipo))/>

            <cfif NOT len(VARIABLES.cadastroTagTipo)>
                <cfset VARIABLES.cadastroDescricaoTipo = lCase(trim(qCadastroTipoFornecedor.descricao_tipo))/>
                <cfif findNoCase("organ", VARIABLES.cadastroDescricaoTipo)>
                    <cfset VARIABLES.cadastroTagTipo = "org"/>
                <cfelseif findNoCase("timer", VARIABLES.cadastroDescricaoTipo) OR findNoCase("cronom", VARIABLES.cadastroDescricaoTipo)>
                    <cfset VARIABLES.cadastroTagTipo = "timer"/>
                <cfelseif findNoCase("assess", VARIABLES.cadastroDescricaoTipo)>
                    <cfset VARIABLES.cadastroTagTipo = "assessoria"/>
                <cfelseif findNoCase("creator", VARIABLES.cadastroDescricaoTipo) OR findNoCase("midia", VARIABLES.cadastroDescricaoTipo) OR findNoCase("media", VARIABLES.cadastroDescricaoTipo)>
                    <cfset VARIABLES.cadastroTagTipo = "creator"/>
                <cfelse>
                    <cfset VARIABLES.cadastroTagTipo = "fornecedor"/>
                </cfif>
            </cfif>
        </cfif>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cadastroErrors)>
        <cfquery name="qCadastroFornecedorExistente">
            SELECT id_fornecedor
            FROM tb_fornecedores
            WHERE cnpj_cpf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroDocumento#"/>
            ORDER BY id_fornecedor
            LIMIT 1
        </cfquery>

        <cfif qCadastroFornecedorExistente.recordcount>
            <cfquery name="qCadastroFornecedorSalvar">
                UPDATE tb_fornecedores
                SET nome_fornecedor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroNomeFornecedor#" maxlength="128"/>,
                    tipo_pessoa = <cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.cadastroTipoPessoa#" maxlength="1"/>,
                    tag_tipo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTagTipo#"/>,
                    site_fornecedor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroSite#" null="#NOT len(VARIABLES.cadastroSite)#"/>,
                    cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroCidade#" null="#NOT len(VARIABLES.cadastroCidade)#"/>,
                    estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEstado#" maxlength="2" null="#NOT len(VARIABLES.cadastroEstado)#"/>,
                    resumo_fornecedor = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroResumo#" null="#NOT len(VARIABLES.cadastroResumo)#"/>,
                    data_alteracao = now(),
                    usuario_alteracao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(qPerfil.email, 64)#" maxlength="64"/>
                WHERE id_fornecedor = <cfqueryparam cfsqltype="cf_sql_integer" value="#qCadastroFornecedorExistente.id_fornecedor#"/>
                RETURNING id_fornecedor
            </cfquery>
        <cfelse>
            <cfquery name="qCadastroFornecedorSalvar">
                INSERT INTO tb_fornecedores
                (
                    nome_fornecedor,
                    tipo_pessoa,
                    cnpj_cpf,
                    tag_tipo,
                    site_fornecedor,
                    cidade,
                    estado,
                    resumo_fornecedor,
                    usuario_cadastro,
                    status
                )
                VALUES
                (
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroNomeFornecedor#" maxlength="128"/>,
                    <cfqueryparam cfsqltype="cf_sql_char" value="#VARIABLES.cadastroTipoPessoa#" maxlength="1"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroDocumento#" maxlength="14"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTagTipo#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroSite#" null="#NOT len(VARIABLES.cadastroSite)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroCidade#" null="#NOT len(VARIABLES.cadastroCidade)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroEstado#" maxlength="2" null="#NOT len(VARIABLES.cadastroEstado)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroResumo#" null="#NOT len(VARIABLES.cadastroResumo)#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(qPerfil.email, 64)#" maxlength="64"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>
                )
                RETURNING id_fornecedor
            </cfquery>
        </cfif>

        <cfquery>
            DELETE FROM tb_usuarios_fornecedores
            WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
              AND id_fornecedor = <cfqueryparam cfsqltype="cf_sql_integer" value="#qCadastroFornecedorSalvar.id_fornecedor#"/>
        </cfquery>

        <cfquery>
            INSERT INTO tb_usuarios_fornecedores
            (id_usuario, id_fornecedor, id_tipo_fornecedor, tipo_relacionamento)
            VALUES
            (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qCadastroFornecedorSalvar.id_fornecedor#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#qCadastroTipoFornecedor.id_fornecedor_tipo#"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cadastroTagTipo#" maxlength="32"/>
            )
        </cfquery>

        <cflocation addtoken="false" url="/cadastro/?sucesso=empresa"/>
    <cfelse>
        <cfset VARIABLES.cadastroErro = arrayToList(VARIABLES.cadastroErrors, " ")/>
    </cfif>
</cfif>

<cfquery name="qCadastroEmpresasUsuario">
    SELECT forn.*,
           usrforn.id_tipo_fornecedor,
           usrforn.tipo_relacionamento,
           tip.descricao_tipo
    FROM tb_usuarios_fornecedores usrforn
    INNER JOIN tb_fornecedores forn ON usrforn.id_fornecedor = forn.id_fornecedor
    LEFT JOIN tb_fornecedores_tipos tip ON usrforn.id_tipo_fornecedor = tip.id_fornecedor_tipo
    WHERE usrforn.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
    ORDER BY forn.nome_fornecedor
</cfquery>
