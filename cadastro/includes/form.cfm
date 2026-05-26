<form method="post" class="needs-validation" novalidate>

    <input type="hidden" name="acao" value="salvar_empresa"/>

    <div class="row mb-3 g-3">
        <div class="col-md-8">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="nome_fornecedor" id="txtNomeFornecedor" class="form-control" maxlength="128"
                       value="<cfif isDefined("FORM.nome_fornecedor")><cfoutput>#htmlEditFormat(FORM.nome_fornecedor)#</cfoutput></cfif>"
                       required/>
                <label class="form-label" for="txtNomeFornecedor">Nome da empresa</label>
                <div class="invalid-feedback">Informe o nome da empresa.</div>
            </div>
        </div>

        <div class="col-md-4">
            <select name="id_fornecedor_tipo" class="form-select" required>
                <option value="">Tipo de atuação</option>
                <cfoutput query="qCadastroTiposFornecedor">
                    <option value="#qCadastroTiposFornecedor.id_fornecedor_tipo#"
                        <cfif isDefined("FORM.id_fornecedor_tipo") AND FORM.id_fornecedor_tipo EQ qCadastroTiposFornecedor.id_fornecedor_tipo>selected</cfif>>
                        #qCadastroTiposFornecedor.descricao_tipo#
                    </option>
                </cfoutput>
            </select>
            <div class="invalid-feedback">Informe o tipo de atuação.</div>
        </div>
    </div>

    <div class="row mb-3 g-3">
        <div class="col-md-4">
            <select name="tipo_pessoa" class="form-select" required>
                <option value="">Pessoa</option>
                <option value="J" <cfif isDefined("FORM.tipo_pessoa") AND FORM.tipo_pessoa EQ "J">selected</cfif>>Jurídica</option>
                <option value="F" <cfif isDefined("FORM.tipo_pessoa") AND FORM.tipo_pessoa EQ "F">selected</cfif>>Física</option>
            </select>
            <div class="invalid-feedback">Informe o tipo de pessoa.</div>
        </div>

        <div class="col-md-4">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="cnpj_cpf" id="txtDocumentoEmpresa" class="form-control" maxlength="18"
                       value="<cfif isDefined("FORM.cnpj_cpf")><cfoutput>#htmlEditFormat(FORM.cnpj_cpf)#</cfoutput></cfif>"
                       required/>
                <label class="form-label" for="txtDocumentoEmpresa">CNPJ ou CPF</label>
                <div class="invalid-feedback">Informe o documento.</div>
            </div>
        </div>

        <div class="col-md-4">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="site_fornecedor" id="txtSiteFornecedor" class="form-control" maxlength="256"
                       value="<cfif isDefined("FORM.site_fornecedor")><cfoutput>#htmlEditFormat(FORM.site_fornecedor)#</cfoutput></cfif>"/>
                <label class="form-label" for="txtSiteFornecedor">Site</label>
            </div>
        </div>
    </div>

    <div class="row mb-3 g-3">
        <div class="col-md-8">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="cidade" id="txtCidadeFornecedor" class="form-control" maxlength="128"
                       value="<cfif isDefined("FORM.cidade")><cfoutput>#htmlEditFormat(FORM.cidade)#</cfoutput></cfif>"/>
                <label class="form-label" for="txtCidadeFornecedor">Cidade</label>
            </div>
        </div>

        <div class="col-md-4">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="estado" id="txtEstadoFornecedor" class="form-control" maxlength="2"
                       value="<cfif isDefined("FORM.estado")><cfoutput>#htmlEditFormat(FORM.estado)#</cfoutput></cfif>"/>
                <label class="form-label" for="txtEstadoFornecedor">UF</label>
            </div>
        </div>
    </div>

    <div class="mb-3">
        <div data-mdb-input-init class="form-outline">
            <textarea name="resumo_fornecedor" id="txtResumoFornecedor" class="form-control" rows="4"><cfif isDefined("FORM.resumo_fornecedor")><cfoutput>#htmlEditFormat(FORM.resumo_fornecedor)#</cfoutput></cfif></textarea>
            <label class="form-label" for="txtResumoFornecedor">Resumo da empresa</label>
        </div>
    </div>

    <button data-mdb-ripple-init type="submit" class="btn btn-primary btn-block" <cfif NOT qCadastroTiposFornecedor.recordcount>disabled</cfif>>
        Salvar empresa
    </button>

    <cfif NOT qCadastroTiposFornecedor.recordcount>
        <div class="alert alert-warning mt-3 mb-0">
            Nenhum tipo de atuação foi encontrado. Cadastre os tipos de fornecedores antes de salvar uma empresa.
        </div>
    </cfif>

</form>

<script>
    (() => {
        'use strict';

        const forms = document.querySelectorAll('.needs-validation');

        Array.prototype.slice.call(forms).forEach((form) => {
            form.addEventListener('submit', (event) => {
                if (!form.checkValidity()) {
                    event.preventDefault();
                    event.stopPropagation();
                }
                form.classList.add('was-validated');
            }, false);
        });
    })();
</script>
