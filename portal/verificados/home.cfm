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

  .verified-filter-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
    background: rgba(255,255,255,0.02);
  }

  .verified-status-action-form {
    margin: 0;
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
              <div class="small text-muted">Páginas encontradas</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qVerifiedPages.recordcount)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <div class="verified-filter-card p-3 mb-3">
            <cfoutput>
              <form method="get" action="./">
                <input type="hidden" name="pagina" value="1"/>
                <div class="row g-3 align-items-end">
                  <div class="col-12 col-lg-2">
                    <label class="form-label">Status</label>
                    <select class="form-select" name="filter_status">
                      <option value="active" <cfif VARIABLES.verifiedFilterStatus EQ "active">selected</cfif>>Ativos</option>
                      <option value="inactive" <cfif VARIABLES.verifiedFilterStatus EQ "inactive">selected</cfif>>Inativos</option>
                      <option value="all" <cfif VARIABLES.verifiedFilterStatus EQ "all">selected</cfif>>Todos</option>
                    </select>
                  </div>

                  <div class="col-12 col-lg-2">
                    <label class="form-label">Combinação</label>
                    <select class="form-select" name="filter_logic">
                      <option value="any" <cfif VARIABLES.verifiedFilterLogic EQ "any">selected</cfif>>Qualquer regra (OU)</option>
                      <option value="all" <cfif VARIABLES.verifiedFilterLogic EQ "all">selected</cfif>>Todas as regras (E)</option>
                    </select>
                  </div>

                  <div class="col-12 col-lg-2">
                    <label class="form-label">Desafio</label>
                    <select class="form-select" name="filter_desafio">
                      <option value="">Qualquer desafio</option>
                      <cfset VARIABLES.verifiedLastChallengeOption = "__none__"/>
                      <cfloop query="qVerifiedChallengeProducts">
                        <cfif qVerifiedChallengeProducts.desafio NEQ VARIABLES.verifiedLastChallengeOption>
                          <option value="#htmlEditFormat(qVerifiedChallengeProducts.desafio)#" <cfif VARIABLES.verifiedFilterDesafio EQ qVerifiedChallengeProducts.desafio>selected</cfif>>#htmlEditFormat(qVerifiedChallengeProducts.desafio)#</option>
                          <cfset VARIABLES.verifiedLastChallengeOption = qVerifiedChallengeProducts.desafio/>
                        </cfif>
                      </cfloop>
                    </select>
                  </div>

                  <div class="col-12 col-lg-3">
                    <label class="form-label">Inscrição / produto</label>
                    <select class="form-select" name="filter_produto">
                      <option value="">Qualquer produto</option>
                      <cfloop query="qVerifiedChallengeProducts">
                        <option value="#htmlEditFormat(qVerifiedChallengeProducts.produto)#" <cfif VARIABLES.verifiedFilterProduto EQ qVerifiedChallengeProducts.produto>selected</cfif>>
                          #htmlEditFormat(qVerifiedChallengeProducts.desafio)# / #htmlEditFormat(qVerifiedChallengeProducts.nome_produto)# (#htmlEditFormat(qVerifiedChallengeProducts.produto)#)
                        </option>
                      </cfloop>
                    </select>
                  </div>

                  <div class="col-12 col-lg-3">
                    <label class="form-label d-block">Status especiais</label>
                    <div class="d-flex flex-wrap gap-3">
                      <div class="form-check">
                        <input class="form-check-input" type="checkbox" id="filterAdmin" name="filter_admin" value="true" <cfif VARIABLES.verifiedFilterAdmin>checked</cfif>/>
                        <label class="form-check-label" for="filterAdmin">ADMIN</label>
                      </div>
                      <div class="form-check">
                        <input class="form-check-input" type="checkbox" id="filterDev" name="filter_dev" value="true" <cfif VARIABLES.verifiedFilterDev>checked</cfif>/>
                        <label class="form-check-label" for="filterDev">DEV</label>
                      </div>
                      <div class="form-check">
                        <input class="form-check-input" type="checkbox" id="filterPartner" name="filter_partner" value="true" <cfif VARIABLES.verifiedFilterPartner>checked</cfif>/>
                        <label class="form-check-label" for="filterPartner">PARTNER</label>
                      </div>
                    </div>
                  </div>

                  <div class="col-12 d-flex flex-wrap justify-content-between gap-2">
                    <div class="small text-muted">
                      Exemplo: selecione o produto VIP do Todo Santo Dia e marque ADMIN, DEV ou PARTNER com combinação OU.
                    </div>
                    <div class="d-flex gap-2">
                      <button type="submit" class="btn btn-outline-warning">Aplicar regras</button>
                      <a class="btn btn-outline-secondary" href="./">Limpar</a>
                    </div>
                  </div>
                </div>
              </form>
            </cfoutput>
          </div>

          <div class="d-flex justify-content-end mb-3">
            <cfoutput><a class="btn btn-warning" href="./?#VARIABLES.verifiedBaseQueryString#&page_novo=1">Adicionar verificado</a></cfoutput>
          </div>

          <cfif VARIABLES.verifiedShowForm>
            <div class="verified-form-card p-4 mb-4">
              <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                <div>
                  <h5 class="mb-1"><cfif qVerifiedPageEdit.recordcount>Editar verificação<cfelse>Novo verificado</cfif></h5>
                  <p class="text-muted small mb-0"><cfif qVerifiedPageEdit.recordcount>Atualize o status de verificação da página selecionada.<cfelse>Busque o usuário, e-mail, ID do usuário, ID da página ou nome da página antes de adicionar um novo verificado.</cfif></p>
                </div>
                <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?#VARIABLES.verifiedBaseQueryString#">Fechar</a></cfoutput>
              </div>

              <cfif NOT qVerifiedPageEdit.recordcount>
                <cfoutput>
                  <form method="get" action="./" class="mb-4">
                    <input type="hidden" name="pagina" value="#VARIABLES.verifiedPage#"/>
                    <input type="hidden" name="page_novo" value="1"/>
                    <input type="hidden" name="filter_status" value="#htmlEditFormat(VARIABLES.verifiedFilterStatus)#"/>
                    <input type="hidden" name="filter_logic" value="#htmlEditFormat(VARIABLES.verifiedFilterLogic)#"/>
                    <input type="hidden" name="filter_desafio" value="#htmlEditFormat(VARIABLES.verifiedFilterDesafio)#"/>
                    <input type="hidden" name="filter_produto" value="#htmlEditFormat(VARIABLES.verifiedFilterProduto)#"/>
                    <cfif VARIABLES.verifiedFilterAdmin><input type="hidden" name="filter_admin" value="true"/></cfif>
                    <cfif VARIABLES.verifiedFilterDev><input type="hidden" name="filter_dev" value="true"/></cfif>
                    <cfif VARIABLES.verifiedFilterPartner><input type="hidden" name="filter_partner" value="true"/></cfif>
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

              <cfoutput><form method="post" action="./?#VARIABLES.verifiedBaseQueryString#"></cfoutput>
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
                  <cfoutput><a class="btn btn-outline-secondary" href="./?#VARIABLES.verifiedBaseQueryString#">Cancelar</a></cfoutput>
                </div>
              </form>
            </div>
          </cfif>

          <cfoutput>
            <form id="verifiedBulkStatusForm" method="post" action="./?#VARIABLES.verifiedBaseQueryString#" class="verified-filter-card p-3 mb-3">
              <input type="hidden" name="verified_action" value="bulk_status"/>
              <div class="row g-3 align-items-end">
                <div class="col-12 col-lg-4">
                  <label class="form-label">Alterar selecionados para</label>
                  <select class="form-select" name="verified_status">
                    <option value="true">Ativo</option>
                    <option value="false">Inativo</option>
                  </select>
                </div>
                <div class="col-12 col-lg-8">
                  <div class="d-flex flex-wrap justify-content-lg-end gap-2">
                    <button type="submit" class="btn btn-warning" onclick="return document.querySelectorAll('.verified-bulk-checkbox:checked').length > 0 ? confirm('Deseja alterar o status das páginas selecionadas?') : (alert('Selecione ao menos uma página.'), false);">Aplicar em selecionados</button>
                  </div>
                  <div class="small text-muted mt-2 text-lg-end">Use o checkbox no cabeçalho para selecionar todos os itens visíveis.</div>
                </div>
              </div>
            </form>
          </cfoutput>

          <div class="table-responsive">
            <table class="table table-sm table-striped table-hover verified-table">
              <thead>
                <tr>
                  <th style="width: 42px;">
                    <input class="form-check-input" type="checkbox" id="verifiedSelectAll" aria-label="Selecionar todos os itens visíveis"/>
                  </th>
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
                      <td>
                        <input class="form-check-input verified-bulk-checkbox" type="checkbox" name="verified_page_ids" value="#qVerifiedPages.id_pagina#" form="verifiedBulkStatusForm" aria-label="Selecionar página #qVerifiedPages.id_pagina#"/>
                      </td>
                      <td class="verified-cell">#qVerifiedPages.id_usuario#</td>
                      <td class="verified-cell">
                        #htmlEditFormat(qVerifiedPages.name)#
                        <cfif len(trim(qVerifiedPages.email))>
                          <div class="small text-muted">#htmlEditFormat(qVerifiedPages.email)#</div>
                        </cfif>
                        <div class="d-flex flex-wrap gap-1 mt-1">
                          <cfif qVerifiedPages.is_admin><span class="badge badge-warning">ADMIN</span></cfif>
                          <cfif qVerifiedPages.is_dev><span class="badge badge-info">DEV</span></cfif>
                          <cfif qVerifiedPages.is_partner><span class="badge badge-success">PARTNER</span></cfif>
                        </div>
                        <cfif len(trim(qVerifiedPages.desafios_usuario))>
                          <div class="small text-muted mt-1">#htmlEditFormat(qVerifiedPages.desafios_usuario)#</div>
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
                          <form class="verified-status-action-form" method="post" action="./?#VARIABLES.verifiedBaseQueryString#">
                            <input type="hidden" name="verified_action" value="toggle"/>
                            <input type="hidden" name="verified_page_id" value="#qVerifiedPages.id_pagina#"/>
                            <input type="hidden" name="verified_status" value="<cfif qVerifiedPages.verificado>false<cfelse>true</cfif>"/>
                            <button type="submit" class="btn btn-sm <cfif qVerifiedPages.verificado>btn-outline-danger<cfelse>btn-outline-success</cfif>" onclick="return confirm('Deseja <cfif qVerifiedPages.verificado>desativar<cfelse>ativar</cfif> a verificação desta página?');"><cfif qVerifiedPages.verificado>Desativar<cfelse>Ativar</cfif></button>
                          </form>
                        </div>
                      </td>
                    </tr>
                  </cfoutput>
                <cfelse>
                  <tr>
                    <td colspan="6" class="text-center text-muted py-4">Nenhuma página encontrada para os filtros selecionados.</td>
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

<script>
  (function () {
    const selectAll = document.getElementById('verifiedSelectAll');
    const rowCheckboxes = Array.from(document.querySelectorAll('.verified-bulk-checkbox'));

    if (!selectAll || !rowCheckboxes.length) {
      return;
    }

    const syncSelectAllState = function () {
      const checkedCount = rowCheckboxes.filter(function (checkbox) { return checkbox.checked; }).length;
      selectAll.checked = checkedCount === rowCheckboxes.length;
      selectAll.indeterminate = checkedCount > 0 && checkedCount < rowCheckboxes.length;
    };

    selectAll.addEventListener('change', function () {
      rowCheckboxes.forEach(function (checkbox) {
        checkbox.checked = selectAll.checked;
      });
      syncSelectAllState();
    });

    rowCheckboxes.forEach(function (checkbox) {
      checkbox.addEventListener('change', syncSelectAllState);
    });
  })();
</script>
