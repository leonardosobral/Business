<cfset VARIABLES.permissionsShowForm = qPermissionUserEdit.recordcount OR (isDefined("URL.user_novo") AND URL.user_novo) OR len(trim(VARIABLES.permissionsSaveErrorMessage))/>
<cfset VARIABLES.permissionsUsingPostedState = len(trim(VARIABLES.permissionsSaveErrorMessage)) AND isDefined("FORM.permissions_action") AND FORM.permissions_action EQ "salvar"/>
<cfset VARIABLES.permissionsFormIsAdmin = VARIABLES.permissionsUsingPostedState ? (isDefined("FORM.permissions_is_admin") AND FORM.permissions_is_admin EQ "true") : (qPermissionUserEdit.recordcount AND qPermissionUserEdit.is_admin)/>
<cfset VARIABLES.permissionsFormIsDev = VARIABLES.permissionsUsingPostedState ? (isDefined("FORM.permissions_is_dev") AND FORM.permissions_is_dev EQ "true") : (qPermissionUserEdit.recordcount AND qPermissionUserEdit.is_dev)/>
<cfset VARIABLES.permissionsFormIsPartner = VARIABLES.permissionsUsingPostedState ? (isDefined("FORM.permissions_is_partner") AND FORM.permissions_is_partner EQ "true") : (qPermissionUserEdit.recordcount AND qPermissionUserEdit.is_partner)/>
<cfset VARIABLES.permissionsEditVerified = qPermissionUserEdit.recordcount AND (IsBoolean(qPermissionUserEdit.verificado) ? qPermissionUserEdit.verificado : ListFindNoCase("1,true,yes,on", trim(qPermissionUserEdit.verificado)) GT 0)/>
<cfset VARIABLES.permissionsFormIsVerified = VARIABLES.permissionsUsingPostedState ? (isDefined("FORM.permissions_is_verified") AND FORM.permissions_is_verified EQ "true") : VARIABLES.permissionsEditVerified/>
<cfset VARIABLES.permissionSelectedCompanies = []/>
<cfif VARIABLES.permissionsUsingPostedState AND isDefined("FORM.permissions_company_ids") AND len(trim(FORM.permissions_company_ids))>
  <cfset VARIABLES.permissionSelectedCompanies = ListToArray(FORM.permissions_company_ids)/>
<cfelseif qPermissionUserEdit.recordcount AND len(trim(qPermissionUserEdit.company_ids))>
  <cfset VARIABLES.permissionSelectedCompanies = ListToArray(qPermissionUserEdit.company_ids)/>
</cfif>

<style>
  .permissions-table td,
  .permissions-table th {
    vertical-align: middle;
  }

  .permissions-cell {
    max-width: 320px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .permissions-scope-cell {
    max-width: 360px;
    min-width: 240px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .permissions-actions-cell {
    width: 1%;
    min-width: 96px;
    white-space: nowrap;
  }

  .permissions-id-cell {
    white-space: nowrap;
  }

  .permissions-form-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
  }

  .permissions-company-select-hidden {
    display: none;
  }

  .permissions-company-list {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    min-height: 38px;
    padding: 0.75rem;
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 0.5rem;
    background: rgba(255,255,255,0.02);
  }

  .permissions-company-chip {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.4rem 0.65rem;
    border-radius: 999px;
    background: rgba(255,193,7,0.12);
    border: 1px solid rgba(255,193,7,0.35);
  }

  .permissions-company-chip button {
    border: 0;
    background: transparent;
    color: inherit;
    line-height: 1;
    padding: 0;
  }

  .permissions-company-empty {
    color: var(--bs-secondary-color);
  }

  @media (max-width: 991.98px) {
    .permissions-actions-cell {
      white-space: normal;
      min-width: 100%;
    }
  }
</style>

<section class="business-page">
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0 business-page-card">
        <div class="card-body business-page-body">

          <div class="business-page-header d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
            <div>
              <h3 class="business-page-title mb-1">Administração - Permissões</h3>
              <p class="text-muted mb-0">Gerencie os usuários com status especiais de <strong>ADMIN</strong>, <strong>DEV</strong> e <strong>PARTNER</strong> na <strong>tb_usuarios</strong>.</p>
            </div>
            <div class="text-lg-end d-flex gap-4">
              <div>
                <div class="small text-muted">Equipe interna</div>
                <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qPermissionUsers.recordcount)#</cfoutput></div>
              </div>
              <div>
                <div class="small text-muted">Partners</div>
                <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qPartnerUsers.recordcount)#</cfoutput></div>
              </div>
            </div>
          </div>

          <div class="d-flex justify-content-end mb-3">
            <cfoutput><a class="btn btn-warning" href="./?pagina=#VARIABLES.permissionsPage#&user_novo=1">Adicionar permissão</a></cfoutput>
          </div>

          <cfif VARIABLES.permissionsShowForm>
            <div class="permissions-form-card business-panel mb-4">
              <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                <div>
                  <h5 class="mb-1"><cfif qPermissionUserEdit.recordcount>Editar permissões<cfelse>Novo usuário especial</cfif></h5>
                  <p class="text-muted small mb-0"><cfif qPermissionUserEdit.recordcount>Defina se o usuário terá acesso administrativo, de desenvolvimento e/ou partner.<cfelse>Busque o usuário por nome, e-mail ou ID antes de conceder os status especiais.</cfif></p>
                </div>
                <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.permissionsPage#">Fechar</a></cfoutput>
              </div>

              <cfif len(trim(VARIABLES.permissionsSaveErrorMessage))>
                <div class="alert alert-danger" role="alert">
                  <cfoutput>#htmlEditFormat(VARIABLES.permissionsSaveErrorMessage)#</cfoutput>
                </div>
              </cfif>

              <cfif NOT qPermissionUserEdit.recordcount>
                <cfoutput>
                  <form method="get" action="./" class="business-filterbar mb-4">
                    <input type="hidden" name="pagina" value="#VARIABLES.permissionsPage#"/>
                    <input type="hidden" name="user_novo" value="1"/>
                    <div class="row g-3 align-items-end">
                      <div class="col-12 col-lg-8">
                        <label class="form-label">Buscar usuário</label>
                        <input class="form-control" type="text" name="user_busca" value="#htmlEditFormat(URL.user_busca)#" placeholder="Digite nome, e-mail ou ID do usuário"/>
                      </div>
                      <div class="col-12 col-lg-4">
                        <button type="submit" class="btn btn-outline-warning w-100">Buscar</button>
                      </div>
                    </div>
                  </form>
                </cfoutput>
              </cfif>

              <cfoutput><form method="post" action="./?pagina=#VARIABLES.permissionsPage#"></cfoutput>
                <input type="hidden" name="permissions_action" value="salvar"/>

                <div class="row g-3">
                  <div class="col-12 col-lg-6">
                    <label class="form-label">Usuário</label>
                    <cfif qPermissionUserEdit.recordcount>
                      <input type="hidden" name="permissions_user_id" value="<cfoutput>#qPermissionUserEdit.id#</cfoutput>"/>
                      <input type="hidden" name="permissions_page_id" value="<cfoutput>#qPermissionUserEdit.id_pagina#</cfoutput>"/>
                      <div class="form-control bg-body-tertiary d-flex align-items-center" style="min-height: 38px;">
                        <cfoutput>#htmlEditFormat(qPermissionUserEdit.name)# - #htmlEditFormat(qPermissionUserEdit.email)#</cfoutput>
                      </div>
                      <cfif len(trim(qPermissionUserEdit.pagina_tag))>
                        <div class="small text-muted mt-2"><cfoutput>Página vinculada: #htmlEditFormat(qPermissionUserEdit.pagina_tag)#</cfoutput></div>
                      <cfelseif len(trim(qPermissionUserEdit.id_pagina))>
                        <div class="small text-muted mt-2"><cfoutput>Página vinculada: ID #qPermissionUserEdit.id_pagina#</cfoutput></div>
                      <cfelse>
                        <div class="small text-warning mt-2">Este usuário não possui página vinculada na tb_paginas.</div>
                      </cfif>
                      <cfif len(trim(qPermissionUserEdit.permission_tags))>
                        <div class="small text-muted mt-2">
                          <cfoutput>Permissões correlacionadas: #htmlEditFormat(qPermissionUserEdit.permission_types)# · #htmlEditFormat(qPermissionUserEdit.permission_tags)#</cfoutput>
                        </div>
                      </cfif>
                      <cfif len(trim(qPermissionUserEdit.company_names))>
                        <div class="small text-muted mt-2">
                          <cfoutput>Empresas vinculadas: #htmlEditFormat(qPermissionUserEdit.company_names)#</cfoutput>
                        </div>
                      </cfif>
                    <cfelse>
                      <input type="hidden" name="permissions_page_id" id="permissions_page_id" value=""/>
                      <select class="form-select" name="permissions_user_id" required>
                        <option value="">Selecione um usuário encontrado</option>
                        <cfoutput query="qPermissionUsersSearch">
                          <option value="#qPermissionUsersSearch.id#" data-page-id="#qPermissionUsersSearch.id_pagina#">## #qPermissionUsersSearch.id# - #htmlEditFormat(qPermissionUsersSearch.name)# - #htmlEditFormat(qPermissionUsersSearch.email)#</option>
                        </cfoutput>
                      </select>
                      <cfif isDefined("URL.user_busca") AND len(trim(URL.user_busca)) AND NOT qPermissionUsersSearch.recordcount>
                        <div class="small text-warning mt-2">Nenhum usuário encontrado para esta busca.</div>
                      <cfelseif qPermissionUsersSearch.recordcount>
                        <div class="small text-muted mt-2">Exibindo até 50 resultados para a busca informada.</div>
                      <cfelse>
                        <div class="small text-muted mt-2">Faça uma busca para carregar apenas os usuários relevantes.</div>
                      </cfif>
                    </cfif>
                  </div>

                  <div class="col-12 col-lg-3">
                    <label class="form-label d-block">ADMIN</label>
                    <select class="form-select" name="permissions_is_admin">
                      <option value="true" <cfif VARIABLES.permissionsFormIsAdmin>selected</cfif>>Ativo</option>
                      <option value="false" <cfif NOT VARIABLES.permissionsFormIsAdmin>selected</cfif>>Inativo</option>
                    </select>
                  </div>

                  <div class="col-12 col-lg-3">
                    <label class="form-label d-block">DEV</label>
                    <select class="form-select" name="permissions_is_dev">
                      <option value="true" <cfif VARIABLES.permissionsFormIsDev>selected</cfif>>Ativo</option>
                      <option value="false" <cfif NOT VARIABLES.permissionsFormIsDev>selected</cfif>>Inativo</option>
                    </select>
                  </div>

                  <div class="col-12 col-lg-3">
                    <label class="form-label d-block">PARTNER</label>
                    <select class="form-select" name="permissions_is_partner">
                      <option value="true" <cfif VARIABLES.permissionsFormIsPartner>selected</cfif>>Ativo</option>
                      <option value="false" <cfif NOT VARIABLES.permissionsFormIsPartner>selected</cfif>>Inativo</option>
                    </select>
                  </div>

                  <div class="col-12 col-lg-3">
                    <label class="form-label d-block">VERIFIED</label>
                    <cfif qPermissionUserEdit.recordcount AND len(trim(qPermissionUserEdit.id_pagina))>
                      <select class="form-select" name="permissions_is_verified">
                        <option value="true" <cfif VARIABLES.permissionsFormIsVerified>selected</cfif>>Ativo</option>
                        <option value="false" <cfif NOT VARIABLES.permissionsFormIsVerified>selected</cfif>>Inativo</option>
                      </select>
                    <cfelse>
                      <select class="form-select" name="permissions_is_verified">
                        <option value="true" <cfif VARIABLES.permissionsFormIsVerified>selected</cfif>>Ativo</option>
                        <option value="false" <cfif NOT VARIABLES.permissionsFormIsVerified>selected</cfif>>Inativo</option>
                      </select>
                      <div class="small text-muted mt-2">Na inclusão nova, o status será aplicado se o usuário selecionado tiver página vinculada.</div>
                    </cfif>
                  </div>

                  <div class="col-12">
                    <label class="form-label">Empresas vinculadas</label>
                    <cfif qPermissionCompaniesList.recordcount>
                      <div class="row g-2">
                        <div class="col-12 col-lg-9">
                          <select class="form-select" id="permissions_company_picker">
                            <option value="">Selecione uma empresa para adicionar</option>
                            <cfoutput query="qPermissionCompaniesList">
                              <option value="#qPermissionCompaniesList.id_fornecedor#">
                                #htmlEditFormat(qPermissionCompaniesList.nome_fornecedor)#<cfif len(trim(qPermissionCompaniesList.tag_tipo))> - #htmlEditFormat(qPermissionCompaniesList.tag_tipo)#</cfif><cfif len(trim(qPermissionCompaniesList.tag_fornecedor))> (#htmlEditFormat(qPermissionCompaniesList.tag_fornecedor)#)</cfif>
                              </option>
                            </cfoutput>
                          </select>
                        </div>
                        <div class="col-12 col-lg-3">
                          <button class="btn btn-outline-warning w-100" type="button" id="permissions_company_add">Adicionar</button>
                        </div>
                      </div>

                      <select class="permissions-company-select-hidden" id="permissions_company_ids" name="permissions_company_ids" multiple size="8">
                        <cfoutput query="qPermissionCompaniesList">
                          <cfset VARIABLES.permissionCompanySelected = arrayFind(VARIABLES.permissionSelectedCompanies, qPermissionCompaniesList.id_fornecedor) GT 0/>
                          <option value="#qPermissionCompaniesList.id_fornecedor#"<cfif VARIABLES.permissionCompanySelected> selected</cfif>>
                            #htmlEditFormat(qPermissionCompaniesList.nome_fornecedor)#<cfif len(trim(qPermissionCompaniesList.tag_tipo))> - #htmlEditFormat(qPermissionCompaniesList.tag_tipo)#</cfif><cfif len(trim(qPermissionCompaniesList.tag_fornecedor))> (#htmlEditFormat(qPermissionCompaniesList.tag_fornecedor)#)</cfif>
                          </option>
                        </cfoutput>
                      </select>
                      <div class="permissions-company-list mt-2" id="permissions_company_list"></div>
                      <div class="small text-muted mt-2">Selecione uma empresa e clique em adicionar. A lista abaixo mostra os vínculos que serão salvos.</div>
                    <cfelse>
                      <div class="form-control bg-body-tertiary text-muted d-flex align-items-center" style="min-height: 38px;">Nenhuma empresa cadastrada em fornecedores.</div>
                    </cfif>
                  </div>
                </div>

                <div class="d-flex flex-wrap gap-2 mt-3">
                  <button type="submit" class="btn btn-warning"><cfif qPermissionUserEdit.recordcount>Salvar alterações<cfelse>Adicionar usuário</cfif></button>
                  <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.permissionsPage#">Cancelar</a></cfoutput>
                </div>
              </form>
            </div>
          </cfif>

          <h5 class="mb-3">Equipe interna</h5>
          <div class="table-responsive mb-5">
            <table class="table table-sm table-striped table-hover permissions-table business-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Nome</th>
                  <th>ADMIN</th>
                  <th>DEV</th>
                  <th>PARTNER</th>
                  <th>VERIFIED</th>
                  <th>Empresas</th>
                  <th>Permissões</th>
                  <th class="permissions-actions-cell">Ações</th>
                </tr>
              </thead>
              <tbody>
                <cfif qPermissionUsers.recordcount>
                  <cfoutput query="qPermissionUsers">
                    <cfset VARIABLES.permissionUserVerified = IsBoolean(qPermissionUsers.verificado) ? qPermissionUsers.verificado : ListFindNoCase("1,true,yes,on", trim(qPermissionUsers.verificado)) GT 0/>
                    <tr>
                      <td class="permissions-cell permissions-id-cell">#qPermissionUsers.id#</td>
                      <td class="permissions-cell">
                        <div>#htmlEditFormat(qPermissionUsers.name)#</div>
                        <div class="small text-muted">#htmlEditFormat(qPermissionUsers.email)#</div>
                      </td>
                      <td class="permissions-cell">
                        <span class="badge <cfif qPermissionUsers.is_admin>badge-success<cfelse>badge-secondary</cfif>"><cfif qPermissionUsers.is_admin>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="permissions-cell">
                        <span class="badge <cfif qPermissionUsers.is_dev>badge-info<cfelse>badge-secondary</cfif>"><cfif qPermissionUsers.is_dev>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="permissions-cell">
                        <span class="badge <cfif qPermissionUsers.is_partner>badge-primary<cfelse>badge-secondary</cfif>"><cfif qPermissionUsers.is_partner>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="permissions-cell">
                        <span class="badge <cfif VARIABLES.permissionUserVerified>badge-success<cfelse>badge-secondary</cfif>"><cfif VARIABLES.permissionUserVerified>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="permissions-scope-cell">
                        <cfif len(trim(qPermissionUsers.company_names))>
                          <div class="small fw-semibold">#htmlEditFormat(qPermissionUsers.company_names)#</div>
                          <cfif len(trim(qPermissionUsers.company_types)) OR len(trim(qPermissionUsers.company_tags))>
                            <div class="small text-muted">
                              <cfif len(trim(qPermissionUsers.company_types))>#htmlEditFormat(qPermissionUsers.company_types)#</cfif><cfif len(trim(qPermissionUsers.company_types)) AND len(trim(qPermissionUsers.company_tags))> · </cfif><cfif len(trim(qPermissionUsers.company_tags))>#htmlEditFormat(qPermissionUsers.company_tags)#</cfif>
                            </div>
                          </cfif>
                        <cfelse>
                          <span class="text-muted small">-</span>
                        </cfif>
                      </td>
                      <td class="permissions-scope-cell">
                        <cfif len(trim(qPermissionUsers.permission_tags))>
                          <div class="small fw-semibold"><cfif len(trim(qPermissionUsers.permission_types))>#htmlEditFormat(qPermissionUsers.permission_types)#<cfelse>Tag</cfif></div>
                          <div class="small text-muted">#htmlEditFormat(qPermissionUsers.permission_tags)#</div>
                        <cfelse>
                          <span class="text-muted small">Sem permissões correlacionadas</span>
                        </cfif>
                      </td>
                      <td class="permissions-actions-cell business-row-actions">
                        <div class="d-flex flex-wrap gap-2">
                          <a class="btn btn-sm btn-outline-warning" href="./?pagina=#VARIABLES.permissionsPage#&user_id=#qPermissionUsers.id#" title="Editar">
                            <i class="fa-solid fa-pen-to-square"></i>
                          </a>
                          <a class="btn btn-sm btn-outline-danger" href="./?pagina=#VARIABLES.permissionsPage#&permissions_action=remover&user_id=#qPermissionUsers.id#" onclick="return confirm('Tem certeza que deseja remover os status especiais deste usuário?');" title="Remover">
                            <i class="fa-solid fa-trash"></i>
                          </a>
                        </div>
                      </td>
                    </tr>
                  </cfoutput>
                <cfelse>
                  <tr>
                    <td colspan="9" class="text-center text-muted py-4">Nenhum usuário com status especial cadastrado.</td>
                  </tr>
                </cfif>
              </tbody>
            </table>
          </div>

          <h5 class="mb-3">Partners</h5>
          <div class="table-responsive">
            <table class="table table-sm table-striped table-hover permissions-table business-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Nome</th>
                  <th>PARTNER</th>
                  <th>VERIFIED</th>
                  <th>Empresas</th>
                  <th>Permissões</th>
                  <th class="permissions-actions-cell">Ações</th>
                </tr>
              </thead>
              <tbody>
                <cfif qPartnerUsers.recordcount>
                  <cfoutput query="qPartnerUsers">
                    <cfset VARIABLES.partnerUserVerified = IsBoolean(qPartnerUsers.verificado) ? qPartnerUsers.verificado : ListFindNoCase("1,true,yes,on", trim(qPartnerUsers.verificado)) GT 0/>
                    <tr>
                      <td class="permissions-cell permissions-id-cell">#qPartnerUsers.id#</td>
                      <td class="permissions-cell">
                        <div>#htmlEditFormat(qPartnerUsers.name)#</div>
                        <div class="small text-muted">#htmlEditFormat(qPartnerUsers.email)#</div>
                      </td>
                      <td class="permissions-cell">
                        <span class="badge <cfif qPartnerUsers.is_partner>badge-primary<cfelse>badge-secondary</cfif>"><cfif qPartnerUsers.is_partner>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="permissions-cell">
                        <span class="badge <cfif VARIABLES.partnerUserVerified>badge-success<cfelse>badge-secondary</cfif>"><cfif VARIABLES.partnerUserVerified>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="permissions-scope-cell">
                        <cfif len(trim(qPartnerUsers.company_names))>
                          <div class="small fw-semibold">#htmlEditFormat(qPartnerUsers.company_names)#</div>
                          <cfif len(trim(qPartnerUsers.company_types)) OR len(trim(qPartnerUsers.company_tags))>
                            <div class="small text-muted">
                              <cfif len(trim(qPartnerUsers.company_types))>#htmlEditFormat(qPartnerUsers.company_types)#</cfif><cfif len(trim(qPartnerUsers.company_types)) AND len(trim(qPartnerUsers.company_tags))> · </cfif><cfif len(trim(qPartnerUsers.company_tags))>#htmlEditFormat(qPartnerUsers.company_tags)#</cfif>
                            </div>
                          </cfif>
                        <cfelse>
                          <span class="text-muted small">-</span>
                        </cfif>
                      </td>
                      <td class="permissions-scope-cell">
                        <cfif len(trim(qPartnerUsers.permission_tags))>
                          <div class="small fw-semibold"><cfif len(trim(qPartnerUsers.permission_types))>#htmlEditFormat(qPartnerUsers.permission_types)#<cfelse>Tag</cfif></div>
                          <div class="small text-muted">#htmlEditFormat(qPartnerUsers.permission_tags)#</div>
                        <cfelse>
                          <span class="text-muted small">Sem permissões correlacionadas</span>
                        </cfif>
                      </td>
                      <td class="permissions-actions-cell business-row-actions">
                        <div class="d-flex flex-wrap gap-2">
                          <a class="btn btn-sm btn-outline-warning" href="./?pagina=#VARIABLES.permissionsPage#&user_id=#qPartnerUsers.id#" title="Editar">
                            <i class="fa-solid fa-pen-to-square"></i>
                          </a>
                          <a class="btn btn-sm btn-outline-danger" href="./?pagina=#VARIABLES.permissionsPage#&permissions_action=remover&user_id=#qPartnerUsers.id#" onclick="return confirm('Tem certeza que deseja remover os status especiais deste usuário?');" title="Remover">
                            <i class="fa-solid fa-trash"></i>
                          </a>
                        </div>
                      </td>
                    </tr>
                  </cfoutput>
                <cfelse>
                  <tr>
                    <td colspan="7" class="text-center text-muted py-4">Nenhum usuário partner cadastrado.</td>
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
    const companySelect = document.getElementById('permissions_company_ids');
    const companyPicker = document.getElementById('permissions_company_picker');
    const companyAddButton = document.getElementById('permissions_company_add');
    const companyList = document.getElementById('permissions_company_list');

    if (!companySelect || !companyPicker || !companyAddButton || !companyList) {
      return;
    }

    function renderCompanyList() {
      const selectedOptions = Array.from(companySelect.options).filter((option) => option.selected);
      companyList.innerHTML = '';

      if (!selectedOptions.length) {
        const emptyState = document.createElement('div');
        emptyState.className = 'permissions-company-empty small';
        emptyState.textContent = '-';
        companyList.appendChild(emptyState);
        return;
      }

      selectedOptions.forEach((option) => {
        const chip = document.createElement('div');
        chip.className = 'permissions-company-chip';

        const label = document.createElement('span');
        label.textContent = option.textContent.trim();
        chip.appendChild(label);

        const removeButton = document.createElement('button');
        removeButton.type = 'button';
        removeButton.setAttribute('aria-label', 'Remover empresa');
        removeButton.innerHTML = '<i class="fa-solid fa-xmark"></i>';
        removeButton.addEventListener('click', function () {
          option.selected = false;
          renderCompanyList();
        });

        chip.appendChild(removeButton);
        companyList.appendChild(chip);
      });
    }

    companyAddButton.addEventListener('click', function () {
      const companyId = companyPicker.value;

      if (!companyId) {
        return;
      }

      const hiddenOption = Array.from(companySelect.options).find((option) => option.value === companyId);
      if (hiddenOption) {
        hiddenOption.selected = true;
      }

      companyPicker.value = '';
      renderCompanyList();
    });

    companyPicker.addEventListener('change', function () {
      if (companyPicker.value) {
        companyAddButton.disabled = false;
      }
    });

    renderCompanyList();
  })();
</script>

<script>
  (function () {
    var userSelect = document.querySelector('select[name="permissions_user_id"]');
    var pageInput = document.getElementById('permissions_page_id');

    if (!userSelect || !pageInput) {
      return;
    }

    function syncPermissionPageId() {
      var selectedOption = userSelect.options[userSelect.selectedIndex];
      pageInput.value = selectedOption ? (selectedOption.getAttribute('data-page-id') || '') : '';
    }

    userSelect.addEventListener('change', syncPermissionPageId);
    syncPermissionPageId();
  })();
</script>
