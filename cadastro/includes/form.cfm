<form method="post" action="/cadastro/" class="needs-validation" novalidate>

    <input type="hidden" name="acao" value="solicitar_acesso"/>

    <div class="row mb-3 g-3">
        <div class="col-md-8">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="nome_empresa" id="txtNomeEmpresa" class="form-control" maxlength="160"
                       value="<cfoutput>#htmlEditFormat(FORM.nome_empresa)#</cfoutput>" required/>
                <label class="form-label" for="txtNomeEmpresa">Nome da empresa</label>
                <div class="invalid-feedback">Informe o nome da empresa.</div>
            </div>
        </div>

        <div class="col-md-4">
            <select name="tipo_prestador" class="form-select" required>
                <option value="">Tipo de prestador</option>
                <cfloop list="#VARIABLES.cadastroTipoPrestadorList#" item="tipoPrestadorOption">
                    <cfoutput>
                        <option value="#htmlEditFormat(tipoPrestadorOption)#" <cfif FORM.tipo_prestador EQ tipoPrestadorOption>selected</cfif>>#htmlEditFormat(tipoPrestadorOption)#</option>
                    </cfoutput>
                </cfloop>
            </select>
            <div class="invalid-feedback">Informe o tipo de prestador.</div>
        </div>
    </div>

    <div class="row mb-3 g-3">
        <div class="col-md-4">
            <select name="tipo_titular" class="form-select" required>
                <option value="PJ" <cfif FORM.tipo_titular EQ "PJ">selected</cfif>>Pessoa juridica</option>
                <option value="PF" <cfif FORM.tipo_titular EQ "PF">selected</cfif>>Pessoa fisica</option>
            </select>
            <div class="invalid-feedback">Informe o tipo de titular.</div>
        </div>

        <div class="col-md-4">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="documento" id="txtDocumentoEmpresa" class="form-control" maxlength="20"
                       value="<cfoutput>#htmlEditFormat(FORM.documento)#</cfoutput>" required/>
                <label class="form-label" for="txtDocumentoEmpresa">CNPJ ou CPF</label>
                <div class="invalid-feedback">Informe o documento.</div>
            </div>
        </div>

        <div class="col-md-4">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="site" id="txtSiteEmpresa" class="form-control" maxlength="256"
                       value="<cfoutput>#htmlEditFormat(FORM.site)#</cfoutput>"/>
                <label class="form-label" for="txtSiteEmpresa">Site</label>
            </div>
        </div>
    </div>

    <div class="row mb-3 g-3">
        <div class="col-md-5">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="nome_responsavel" id="txtNomeResponsavel" class="form-control" maxlength="200"
                       value="<cfoutput>#htmlEditFormat(FORM.nome_responsavel)#</cfoutput>" required/>
                <label class="form-label" for="txtNomeResponsavel">Responsavel</label>
                <div class="invalid-feedback">Informe o responsavel.</div>
            </div>
        </div>

        <div class="col-md-4">
            <div data-mdb-input-init class="form-outline">
                <input type="email" name="email_responsavel" id="txtEmailResponsavel" class="form-control" maxlength="255"
                       value="<cfoutput>#htmlEditFormat(FORM.email_responsavel)#</cfoutput>" required/>
                <label class="form-label" for="txtEmailResponsavel">E-mail</label>
                <div class="invalid-feedback">Informe um e-mail valido.</div>
            </div>
        </div>

        <div class="col-md-3">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="telefone_responsavel" id="txtTelefoneResponsavel" class="form-control" maxlength="30"
                       value="<cfoutput>#htmlEditFormat(FORM.telefone_responsavel)#</cfoutput>"/>
                <label class="form-label" for="txtTelefoneResponsavel">Telefone</label>
            </div>
        </div>
    </div>

    <div class="row mb-3 g-3">
        <div class="col-md-8">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="cidade" id="txtCidadeEmpresa" class="form-control" maxlength="128"
                       value="<cfoutput>#htmlEditFormat(FORM.cidade)#</cfoutput>"/>
                <label class="form-label" for="txtCidadeEmpresa">Cidade</label>
            </div>
        </div>

        <div class="col-md-4">
            <div data-mdb-input-init class="form-outline">
                <input type="text" name="estado" id="txtEstadoEmpresa" class="form-control" maxlength="2"
                       value="<cfoutput>#htmlEditFormat(FORM.estado)#</cfoutput>"/>
                <label class="form-label" for="txtEstadoEmpresa">UF</label>
            </div>
        </div>
    </div>

    <div class="mb-3">
        <div data-mdb-input-init class="form-outline">
            <textarea name="mensagem" id="txtMensagemCadastro" class="form-control" rows="4"><cfoutput>#htmlEditFormat(FORM.mensagem)#</cfoutput></textarea>
            <label class="form-label" for="txtMensagemCadastro">Mensagem para analise</label>
        </div>
    </div>

    <div class="mb-3">
        <div data-mdb-input-init class="form-outline">
            <input type="text" name="voucher_codigo" id="txtVoucherCodigo" class="form-control" maxlength="80"
                   value="<cfoutput>#htmlEditFormat(FORM.voucher_codigo)#</cfoutput>"/>
            <label class="form-label" for="txtVoucherCodigo">Codigo de voucher</label>
        </div>
        <div class="form-text text-muted">Preencha somente se recebeu um codigo de credito Run Pro.</div>
    </div>

    <button data-mdb-ripple-init type="submit" class="btn btn-warning btn-block" <cfif NOT VARIABLES.cadastroSolicitacaoTablesReady>disabled</cfif>>
        Enviar solicitacao
    </button>

    <cfif NOT VARIABLES.cadastroSolicitacaoTablesReady>
        <div class="alert alert-warning mt-3 mb-0">
            O cadastro externo ainda depende da tabela <code>tb_conta_cadastro_solicitacoes</code>.
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
