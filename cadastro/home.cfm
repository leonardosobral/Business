<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

            <div class="bg-light bg-opacity-10 rounded p-3">

                <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                    <div>
                        <h3 class="mb-2">Cadastro da empresa</h3>
                        <p class="text-muted mb-0">
                            Informe os dados da empresa que deve ficar vinculada ao seu usuário no RunnerHub Business.
                        </p>
                    </div>
                    <div class="text-lg-end">
                        <span class="badge badge-warning">em verificação</span>
                    </div>
                </div>

                <cfif len(trim(VARIABLES.cadastroSucesso))>
                    <div class="alert alert-success">
                        <cfoutput>#VARIABLES.cadastroSucesso#</cfoutput>
                    </div>
                </cfif>

                <cfif len(trim(VARIABLES.cadastroErro))>
                    <div class="alert alert-danger">
                        <cfoutput>#VARIABLES.cadastroErro#</cfoutput>
                    </div>
                </cfif>

                <cfinclude template="includes/form.cfm"/>

            </div>

            <cfif qCadastroEmpresasUsuario.recordcount>
                <hr/>

                <h5 class="mb-3">Empresas vinculadas ao seu usuário</h5>

                <div class="table-responsive">
                    <table class="table table-sm table-striped table-hover align-middle">
                        <thead>
                            <tr>
                                <th>Empresa</th>
                                <th>Atuação</th>
                                <th>Documento</th>
                                <th>Cidade/UF</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <cfoutput query="qCadastroEmpresasUsuario">
                                <tr>
                                    <td>
                                        <strong>#htmlEditFormat(qCadastroEmpresasUsuario.nome_fornecedor)#</strong>
                                        <cfif len(trim(qCadastroEmpresasUsuario.site_fornecedor))>
                                            <cfset VARIABLES.cadastroSiteUrl = trim(qCadastroEmpresasUsuario.site_fornecedor)/>
                                            <cfif NOT reFindNoCase("^https?://", VARIABLES.cadastroSiteUrl)>
                                                <cfset VARIABLES.cadastroSiteUrl = "https://" & VARIABLES.cadastroSiteUrl/>
                                            </cfif>
                                            <br/><a href="#htmlEditFormat(VARIABLES.cadastroSiteUrl)#" target="_blank" rel="noopener">#htmlEditFormat(qCadastroEmpresasUsuario.site_fornecedor)#</a>
                                        </cfif>
                                    </td>
                                    <td>#htmlEditFormat(len(trim(qCadastroEmpresasUsuario.descricao_tipo)) ? qCadastroEmpresasUsuario.descricao_tipo : qCadastroEmpresasUsuario.tipo_relacionamento)#</td>
                                    <td>#htmlEditFormat(qCadastroEmpresasUsuario.cnpj_cpf)#</td>
                                    <td>#htmlEditFormat(qCadastroEmpresasUsuario.cidade)#<cfif len(trim(qCadastroEmpresasUsuario.estado))>/#htmlEditFormat(qCadastroEmpresasUsuario.estado)#</cfif></td>
                                    <td>
                                        <cfif qCadastroEmpresasUsuario.ativo>
                                            <span class="badge badge-success">ativa</span>
                                        <cfelse>
                                            <span class="badge badge-secondary">inativa</span>
                                        </cfif>
                                        <cfif qCadastroEmpresasUsuario.status EQ 1>
                                            <span class="badge badge-warning">em verificação</span>
                                        </cfif>
                                    </td>
                                </tr>
                            </cfoutput>
                        </tbody>
                    </table>
                </div>
            </cfif>

        </div>

      </div>

    </div>

  </div>

</section>
