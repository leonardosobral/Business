<cfinclude template="../includes/verified_backend.cfm"/>

<cfset VARIABLES.verifiedShowForm = qVerifiedPageEdit.recordcount OR (isDefined("URL.page_novo") AND URL.page_novo)/>

<style>
  .verified-table td,
  .verified-table th {
    vertical-align: middle;
  }

  .verified-cell {
    max-width: 320px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .verified-actions-cell {
    min-width: 220px;
    white-space: nowrap;
  }

  .verified-form-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
  }

  @media (max-width: 991.98px) {
    .verified-actions-cell {
      white-space: normal;
      min-width: 100%;
    }
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Verificados</h3>
              <p class="text-muted mb-0">Gerencie as páginas da <strong>tb_paginas</strong> com status de verificação ativo, vinculadas aos usuários da <strong>tb_usuarios</strong>.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Páginas verificadas</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qVerifiedPages.recordcount)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <div class="d-flex justify-content-end mb-3">
            <cfoutput><a class="btn btn-warning" href="./?pagina=#VARIABLES.verifiedPage#&page_novo=1">Adicionar verificado</a></cfoutput>
          </div>

          <cfif VARIABLES.verifiedShowForm>
            <div class="verified-form-card p-4 mb-4">
              <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                <div>
                  <h5 class="mb-1"><cfif qVerifiedPageEdit.recordcount>Editar verificação<cfelse>Novo verificado</cfif></h5>
                  <p class="text-muted small mb-0"><cfif qVerifiedPageEdit.recordcount>Atualize o status de verificação da página selecionada.<cfelse>Busque o usuário, e-mail, ID do usuário, ID da página ou nome da página antes de adicionar um novo verificado.</cfif></p>
                </div>
                <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.verifiedPage#">Fechar</a></cfoutput>
              </div>

              <cfif NOT qVerifiedPageEdit.recordcount>
                <cfoutput>
                  <form method="get" action="./" class="mb-4">
                    <input type="hidden" name="pagina" value="#VARIABLES.verifiedPage#"/>
                    <input type="hidden" name="page_novo" value="1"/>
                    <div class="row g-3 align-items-end">
                      <div class="col-12 col-lg-8">
                        <label class="form-label">Buscar usuário ou página</label>
                        <input class="form-control" type="text" name="user_busca" value="#htmlEditFormat(URL.user_busca)#" placeholder="Digite nome, e-mail, ID do usuário, ID da página, nome ou tag da página"/>
                      </div>
                      <div class="col-12 col-lg-4">
                        <button type="submit" class="btn btn-outline-warning w-100">Buscar</button>
                      </div>
                    </div>
                  </form>
                </cfoutput>
              </cfif>

              <cfoutput><form method="post" action="./?pagina=#VARIABLES.verifiedPage#"></cfoutput>
                <input type="hidden" name="verified_action" value="salvar"/>

                <div class="row g-3">
                  <div class="col-12 col-lg-8">
                    <label class="form-label">Página / usuário</label>
                    <cfif qVerifiedPageEdit.recordcount>
                      <input type="hidden" name="verified_page_id" value="<cfoutput>#qVerifiedPageEdit.id_pagina#</cfoutput>"/>
                      <div class="form-control bg-body-tertiary" style="min-height: 38px;">
                        <cfoutput>
                          Página ## #qVerifiedPageEdit.id_pagina# - #htmlEditFormat(qVerifiedPageEdit.pagina_nome)#
                          <cfif len(trim(qVerifiedPageEdit.tag))>
                            (#htmlEditFormat(qVerifiedPageEdit.tag)#)
                          </cfif>
                          <br/>
                          <span class="small text-muted">Usuário ## #qVerifiedPageEdit.id_usuario# - #htmlEditFormat(qVerifiedPageEdit.name)# - #htmlEditFormat(qVerifiedPageEdit.email)#</span>
                        </cfoutput>
                      </div>
                    <cfelse>
                      <select class="form-select" name="verified_page_id" required>
                        <option value="">Selecione uma página encontrada</option>
                        <cfoutput query="qVerifiedPagesSearch">
                          <option value="#qVerifiedPagesSearch.id_pagina#">
                            Página ## #qVerifiedPagesSearch.id_pagina# - #htmlEditFormat(qVerifiedPagesSearch.pagina_nome)#
                            <cfif len(trim(qVerifiedPagesSearch.tag))>
                              (#htmlEditFormat(qVerifiedPagesSearch.tag)#)
                            </cfif>
                            - Usuário ## #qVerifiedPagesSearch.id_usuario# - #htmlEditFormat(qVerifiedPagesSearch.name)# - #htmlEditFormat(qVerifiedPagesSearch.email)#
                          </option>
                        </cfoutput>
                      </select>
                      <cfif isDefined("URL.user_busca") AND len(trim(URL.user_busca)) AND NOT qVerifiedPagesSearch.recordcount>
                        <div class="small text-warning mt-2">Nenhuma página não verificada foi encontrada para esta busca.</div>
                      <cfelseif qVerifiedPagesSearch.recordcount>
                        <div class="small text-muted mt-2">Exibindo até 50 resultados para a busca informada.</div>
                      <cfelse>
                        <div class="small text-muted mt-2">Faça uma busca para carregar apenas as páginas relevantes.</div>
                      </cfif>
                    </cfif>
                  </div>

                  <div class="col-12 col-lg-4">
                    <label class="form-label d-block">Verificado</label>
                    <select class="form-select" name="verified_status">
                      <option value="true" <cfif qVerifiedPageEdit.recordcount AND qVerifiedPageEdit.verificado>selected</cfif><cfif NOT qVerifiedPageEdit.recordcount>selected</cfif>>Ativo</option>
                      <option value="false" <cfif qVerifiedPageEdit.recordcount AND NOT qVerifiedPageEdit.verificado>selected</cfif>>Inativo</option>
                    </select>
                  </div>
                </div>

                <div class="d-flex flex-wrap gap-2 mt-3">
                  <button type="submit" class="btn btn-warning"><cfif qVerifiedPageEdit.recordcount>Salvar alterações<cfelse>Adicionar verificado</cfif></button>
                  <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.verifiedPage#">Cancelar</a></cfoutput>
                </div>
              </form>
            </div>
          </cfif>

          <div class="table-responsive">
            <table class="table table-sm table-striped table-hover verified-table">
              <thead>
                <tr>
                  <th>ID Usuário</th>
                  <th>Nome</th>
                  <th>Página</th>
                  <th>Status</th>
                  <th class="verified-actions-cell">Ações</th>
                </tr>
              </thead>
              <tbody>
                <cfif qVerifiedPages.recordcount>
                  <cfoutput query="qVerifiedPages">
                    <tr>
                      <td class="verified-cell">#qVerifiedPages.id_usuario#</td>
                      <td class="verified-cell">
                        #htmlEditFormat(qVerifiedPages.name)#
                        <cfif len(trim(qVerifiedPages.email))>
                          <div class="small text-muted">#htmlEditFormat(qVerifiedPages.email)#</div>
                        </cfif>
                      </td>
                      <td class="verified-cell">
                        <cfif len(trim(qVerifiedPages.tag))>
                          <a href="https://roadrunners.run/atleta/#urlEncodedFormat(qVerifiedPages.tag)#" target="_blank" rel="noopener noreferrer">#htmlEditFormat(qVerifiedPages.pagina_nome)#</a>
                        <cfelse>
                          #htmlEditFormat(qVerifiedPages.pagina_nome)#
                        </cfif>
                        <div class="small text-muted">ID #qVerifiedPages.id_pagina#</div>
                        <cfif len(trim(qVerifiedPages.tag))>
                          <div class="small text-muted">#htmlEditFormat(qVerifiedPages.tag)#</div>
                        </cfif>
                      </td>
                      <td class="verified-cell">
                        <span class="badge <cfif qVerifiedPages.verificado>badge-success<cfelse>badge-secondary</cfif>"><cfif qVerifiedPages.verificado>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="verified-actions-cell">
                        <div class="d-flex flex-wrap gap-2">
                          <a class="btn btn-sm btn-outline-warning" href="./?pagina=#VARIABLES.verifiedPage#&page_id=#qVerifiedPages.id_pagina#">Editar</a>
                          <a class="btn btn-sm btn-outline-danger" href="./?pagina=#VARIABLES.verifiedPage#&verified_action=remover&page_id=#qVerifiedPages.id_pagina#" onclick="return confirm('Tem certeza que deseja remover o status de verificado desta página?');">Remover</a>
                        </div>
                      </td>
                    </tr>
                  </cfoutput>
                <cfelse>
                  <tr>
                    <td colspan="5" class="text-center text-muted py-4">Nenhuma página verificada cadastrada.</td>
                  </tr>
                </cfif>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>
