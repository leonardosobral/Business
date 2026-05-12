<cfset VARIABLES.permissionsShowForm = qPermissionUserEdit.recordcount OR (isDefined("URL.user_novo") AND URL.user_novo)/>

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

  .permissions-actions-cell {
    min-width: 220px;
    white-space: nowrap;
  }

  .permissions-form-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
  }

  @media (max-width: 991.98px) {
    .permissions-actions-cell {
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
              <h3 class="mb-1">Administração - Permissões</h3>
              <p class="text-muted mb-0">Gerencie os usuários com status especiais de <strong>ADMIN</strong> e <strong>DEV</strong> na <strong>tb_usuarios</strong>.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Usuários especiais</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qPermissionUsers.recordcount)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <div class="d-flex justify-content-end mb-3">
            <cfoutput><a class="btn btn-warning" href="./?pagina=#VARIABLES.permissionsPage#&user_novo=1">Adicionar permissão</a></cfoutput>
          </div>

          <cfif VARIABLES.permissionsShowForm>
            <div class="permissions-form-card p-4 mb-4">
              <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                <div>
                  <h5 class="mb-1"><cfif qPermissionUserEdit.recordcount>Editar permissões<cfelse>Novo usuário especial</cfif></h5>
                  <p class="text-muted small mb-0"><cfif qPermissionUserEdit.recordcount>Defina se o usuário terá acesso administrativo e/ou de desenvolvimento.<cfelse>Busque o usuário por nome, e-mail ou ID antes de conceder os status especiais.</cfif></p>
                </div>
                <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.permissionsPage#">Fechar</a></cfoutput>
              </div>

              <cfif NOT qPermissionUserEdit.recordcount>
                <cfoutput>
                  <form method="get" action="./" class="mb-4">
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
                      <div class="form-control bg-body-tertiary d-flex align-items-center" style="min-height: 38px;">
                        <cfoutput>#htmlEditFormat(qPermissionUserEdit.name)# - #htmlEditFormat(qPermissionUserEdit.email)#</cfoutput>
                      </div>
                    <cfelse>
                      <select class="form-select" name="permissions_user_id" required>
                        <option value="">Selecione um usuário encontrado</option>
                        <cfoutput query="qPermissionUsersSearch">
                          <option value="#qPermissionUsersSearch.id#">## #qPermissionUsersSearch.id# - #htmlEditFormat(qPermissionUsersSearch.name)# - #htmlEditFormat(qPermissionUsersSearch.email)#</option>
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
                      <option value="true" <cfif qPermissionUserEdit.recordcount AND qPermissionUserEdit.is_admin>selected</cfif>>Ativo</option>
                      <option value="false" <cfif NOT qPermissionUserEdit.recordcount OR NOT qPermissionUserEdit.is_admin>selected</cfif>>Inativo</option>
                    </select>
                  </div>

                  <div class="col-12 col-lg-3">
                    <label class="form-label d-block">DEV</label>
                    <select class="form-select" name="permissions_is_dev">
                      <option value="true" <cfif qPermissionUserEdit.recordcount AND qPermissionUserEdit.is_dev>selected</cfif>>Ativo</option>
                      <option value="false" <cfif NOT qPermissionUserEdit.recordcount OR NOT qPermissionUserEdit.is_dev>selected</cfif>>Inativo</option>
                    </select>
                  </div>
                </div>

                <div class="d-flex flex-wrap gap-2 mt-3">
                  <button type="submit" class="btn btn-warning"><cfif qPermissionUserEdit.recordcount>Salvar alterações<cfelse>Adicionar usuário</cfif></button>
                  <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.permissionsPage#">Cancelar</a></cfoutput>
                </div>
              </form>
            </div>
          </cfif>

          <div class="table-responsive">
            <table class="table table-sm table-striped table-hover permissions-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Nome</th>
                  <th>Email</th>
                  <th>ADMIN</th>
                  <th>DEV</th>
                  <th class="permissions-actions-cell">Ações</th>
                </tr>
              </thead>
              <tbody>
                <cfif qPermissionUsers.recordcount>
                  <cfoutput query="qPermissionUsers">
                    <tr>
                      <td class="permissions-cell">#qPermissionUsers.id#</td>
                      <td class="permissions-cell">#htmlEditFormat(qPermissionUsers.name)#</td>
                      <td class="permissions-cell">#htmlEditFormat(qPermissionUsers.email)#</td>
                      <td class="permissions-cell">
                        <span class="badge <cfif qPermissionUsers.is_admin>badge-success<cfelse>badge-secondary</cfif>"><cfif qPermissionUsers.is_admin>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="permissions-cell">
                        <span class="badge <cfif qPermissionUsers.is_dev>badge-info<cfelse>badge-secondary</cfif>"><cfif qPermissionUsers.is_dev>Ativo<cfelse>Inativo</cfif></span>
                      </td>
                      <td class="permissions-actions-cell">
                        <div class="d-flex flex-wrap gap-2">
                          <a class="btn btn-sm btn-outline-warning" href="./?pagina=#VARIABLES.permissionsPage#&user_id=#qPermissionUsers.id#">Editar</a>
                          <a class="btn btn-sm btn-outline-danger" href="./?pagina=#VARIABLES.permissionsPage#&permissions_action=remover&user_id=#qPermissionUsers.id#" onclick="return confirm('Tem certeza que deseja remover os status especiais deste usuário?');">Remover</a>
                        </div>
                      </td>
                    </tr>
                  </cfoutput>
                <cfelse>
                  <tr>
                    <td colspan="6" class="text-center text-muted py-4">Nenhum usuário com status especial cadastrado.</td>
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
