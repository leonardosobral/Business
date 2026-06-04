<cfinclude template="../includes/runner_apps_backend.cfm"/>

<cfset VARIABLES.runnerAppsShowGroupForm = qRunnerAppGroupEdit.recordcount OR (isDefined("URL.grupo_novo") AND URL.grupo_novo) OR FORM.acao EQ "salvar_grupo"/>
<cfset VARIABLES.runnerAppsShowAppForm = qRunnerAppEdit.recordcount OR (isDefined("URL.app_novo") AND URL.app_novo) OR FORM.acao EQ "salvar_app"/>
<cfset VARIABLES.runnerAppsActiveTotal = 0/>
<cfif qRunnerApps.recordcount>
  <cfloop query="qRunnerApps">
    <cfif runnerAppsNormalizeBoolean(qRunnerApps.ativo)>
      <cfset VARIABLES.runnerAppsActiveTotal = VARIABLES.runnerAppsActiveTotal + 1/>
    </cfif>
  </cfloop>
</cfif>

<style>
  .runner-app-icon {
    width: 52px;
    height: 52px;
    border-radius: 0.75rem;
    background: #050505;
    object-fit: cover;
  }

  .runner-app-table td,
  .runner-app-table th {
    vertical-align: middle;
  }

  .runner-app-url {
    max-width: 360px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .runner-app-actions {
    width: 210px;
    white-space: nowrap;
  }

  .runner-app-api-code {
    font-size: 0.78rem;
    white-space: pre-wrap;
    word-break: break-word;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-xl-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Runner Apps</h3>
              <p class="text-muted mb-0">Gerencie os itens exibidos no menu Runner Apps consumido pelos sites da plataforma.</p>
            </div>
            <cfif VARIABLES.runnerAppsTablesReady AND isDefined("qPerfil") AND qPerfil.recordcount AND qPerfil.is_admin>
              <div class="d-flex gap-2 align-items-start">
                <a class="btn btn-outline-light" href="./?grupo_novo=1">Nova linha</a>
                <a class="btn btn-warning" href="./?app_novo=1">Novo app</a>
              </div>
            </cfif>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">Voce nao tem permissao para gerenciar o Runner Apps.</div>
          <cfelseif NOT VARIABLES.runnerAppsTablesReady>
            <div class="alert alert-warning mb-0">
              As tabelas do Runner Apps ainda nao existem. Rode o script em
              <a href="/portal/runner-apps/runner_apps_schema.sql" target="_blank" rel="noopener">/portal/runner-apps/runner_apps_schema.sql</a>
              e recarregue esta pagina.
            </div>
          <cfelse>
            <cfif len(trim(VARIABLES.runnerAppsAlert.type)) AND len(trim(VARIABLES.runnerAppsAlert.message))>
              <cfoutput><div class="alert alert-#VARIABLES.runnerAppsAlert.type#">#htmlEditFormat(VARIABLES.runnerAppsAlert.message)#</div></cfoutput>
            </cfif>

            <div class="row gx-xl-3 mb-4">
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Linhas</div>
                    <div class="h4 mb-0"><cfoutput>#qRunnerAppGroups.recordcount#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Apps</div>
                    <div class="h4 mb-0"><cfoutput>#qRunnerApps.recordcount#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Ativos</div>
                    <div class="h4 mb-0"><cfoutput>#VARIABLES.runnerAppsActiveTotal#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">API</div>
                    <div class="small runner-app-api-code"><cfoutput>#runnerAppsBuildBaseUrl()#/api/portal/runner-apps/</cfoutput></div>
                  </div>
                </div>
              </div>
            </div>

            <cfif VARIABLES.runnerAppsShowGroupForm>
              <cfset VARIABLES.runnerAppsGroupFormId = qRunnerAppGroupEdit.recordcount ? qRunnerAppGroupEdit.id_group[1] : (isDefined("FORM.id_group") ? FORM.id_group : "")/>
              <cfset VARIABLES.runnerAppsGroupFormName = qRunnerAppGroupEdit.recordcount ? qRunnerAppGroupEdit.nome[1] : (isDefined("FORM.grupo_nome") ? FORM.grupo_nome : "")/>
              <cfset VARIABLES.runnerAppsGroupFormDescription = qRunnerAppGroupEdit.recordcount ? qRunnerAppGroupEdit.descricao[1] : (isDefined("FORM.grupo_descricao") ? FORM.grupo_descricao : "")/>
              <cfset VARIABLES.runnerAppsGroupFormOrder = qRunnerAppGroupEdit.recordcount ? qRunnerAppGroupEdit.ordem[1] : (isDefined("FORM.grupo_ordem") ? FORM.grupo_ordem : qRunnerAppGroups.recordcount + 1)/>
              <cfset VARIABLES.runnerAppsGroupFormActive = qRunnerAppGroupEdit.recordcount ? runnerAppsNormalizeBoolean(qRunnerAppGroupEdit.ativo[1]) : (NOT isDefined("FORM.acao") OR isDefined("FORM.grupo_ativo"))/>

              <div class="card shadow-0 border border-white border-opacity-10 mb-4">
                <div class="card-body">
                  <div class="d-flex justify-content-between align-items-start gap-3">
                    <div>
                      <h5 class="mb-1"><cfif qRunnerAppGroupEdit.recordcount>Editar linha<cfelse>Nova linha</cfif></h5>
                    </div>
                    <a class="btn btn-sm btn-outline-light" href="./">Fechar</a>
                  </div>
                  <hr/>
                  <form method="post" action="./">
                    <input type="hidden" name="acao" value="salvar_grupo"/>
                    <input type="hidden" name="id_group" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsGroupFormId)#</cfoutput>"/>
                    <div class="row g-3 align-items-end">
                      <div class="col-md-4">
                        <label class="form-label">Nome da linha</label>
                        <input class="form-control" type="text" name="grupo_nome" required value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsGroupFormName)#</cfoutput>"/>
                      </div>
                      <div class="col-md-5">
                        <label class="form-label">Descricao</label>
                        <input class="form-control" type="text" name="grupo_descricao" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsGroupFormDescription)#</cfoutput>"/>
                      </div>
                      <div class="col-md-1">
                        <label class="form-label">Ordem</label>
                        <input class="form-control" type="number" min="1" name="grupo_ordem" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsGroupFormOrder)#</cfoutput>"/>
                      </div>
                      <div class="col-md-1">
                        <div class="form-check">
                          <input class="form-check-input" type="checkbox" name="grupo_ativo" value="1" id="grupoAtivo" <cfif VARIABLES.runnerAppsGroupFormActive>checked</cfif>/>
                          <label class="form-check-label" for="grupoAtivo">Ativa</label>
                        </div>
                      </div>
                      <div class="col-md-1 text-md-end">
                        <button class="btn btn-warning" type="submit">Salvar</button>
                      </div>
                    </div>
                  </form>
                </div>
              </div>
            </cfif>

            <cfif VARIABLES.runnerAppsShowAppForm>
              <cfset VARIABLES.runnerAppsAppFormId = qRunnerAppEdit.recordcount ? qRunnerAppEdit.id_app[1] : (isDefined("FORM.id_app") ? FORM.id_app : "")/>
              <cfset VARIABLES.runnerAppsAppFormGroup = qRunnerAppEdit.recordcount ? qRunnerAppEdit.id_group[1] : (isDefined("FORM.id_group") ? FORM.id_group : (qRunnerAppGroups.recordcount ? qRunnerAppGroups.id_group[1] : ""))/>
              <cfset VARIABLES.runnerAppsAppFormName = qRunnerAppEdit.recordcount ? qRunnerAppEdit.nome[1] : (isDefined("FORM.app_nome") ? FORM.app_nome : "")/>
              <cfset VARIABLES.runnerAppsAppFormUrl = qRunnerAppEdit.recordcount ? qRunnerAppEdit.url[1] : (isDefined("FORM.app_url") ? FORM.app_url : "")/>
              <cfset VARIABLES.runnerAppsAppFormImage = qRunnerAppEdit.recordcount ? qRunnerAppEdit.imagem_url[1] : (isDefined("FORM.app_imagem_url") ? FORM.app_imagem_url : "")/>
              <cfset VARIABLES.runnerAppsAppFormOriginal = qRunnerAppEdit.recordcount ? qRunnerAppEdit.imagem_original[1] : (isDefined("FORM.app_imagem_original_atual") ? FORM.app_imagem_original_atual : "")/>
              <cfset VARIABLES.runnerAppsAppFormAlt = qRunnerAppEdit.recordcount ? qRunnerAppEdit.alt_text[1] : (isDefined("FORM.app_alt_text") ? FORM.app_alt_text : "")/>
              <cfset VARIABLES.runnerAppsAppFormNewTab = qRunnerAppEdit.recordcount ? runnerAppsNormalizeBoolean(qRunnerAppEdit.abrir_nova_aba[1]) : (isDefined("FORM.app_abrir_nova_aba") AND runnerAppsNormalizeBoolean(FORM.app_abrir_nova_aba))/>
              <cfset VARIABLES.runnerAppsAppFormRel = qRunnerAppEdit.recordcount ? qRunnerAppEdit.rel[1] : (isDefined("FORM.app_rel") ? FORM.app_rel : "")/>
              <cfset VARIABLES.runnerAppsAppFormOrder = qRunnerAppEdit.recordcount ? qRunnerAppEdit.ordem[1] : (isDefined("FORM.app_ordem") ? FORM.app_ordem : 1)/>
              <cfset VARIABLES.runnerAppsAppFormActive = qRunnerAppEdit.recordcount ? runnerAppsNormalizeBoolean(qRunnerAppEdit.ativo[1]) : (NOT isDefined("FORM.acao") OR isDefined("FORM.app_ativo"))/>

              <div class="card shadow-0 border border-white border-opacity-10 mb-4">
                <div class="card-body">
                  <div class="d-flex justify-content-between align-items-start gap-3">
                    <div>
                      <h5 class="mb-1"><cfif qRunnerAppEdit.recordcount>Editar app<cfelse>Novo app</cfif></h5>
                    </div>
                    <a class="btn btn-sm btn-outline-light" href="./">Fechar</a>
                  </div>
                  <hr/>
                  <form method="post" action="./" enctype="multipart/form-data">
                    <input type="hidden" name="acao" value="salvar_app"/>
                    <input type="hidden" name="id_app" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormId)#</cfoutput>"/>
                    <input type="hidden" name="app_imagem_atual" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormImage)#</cfoutput>"/>
                    <input type="hidden" name="app_imagem_original_atual" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormOriginal)#</cfoutput>"/>

                    <div class="row g-3">
                      <div class="col-md-3">
                        <label class="form-label">Linha</label>
                        <select class="form-select" name="id_group" required>
                          <cfoutput query="qRunnerAppGroups">
                            <option value="#qRunnerAppGroups.id_group#" <cfif qRunnerAppGroups.id_group EQ val(VARIABLES.runnerAppsAppFormGroup)>selected</cfif>>#htmlEditFormat(qRunnerAppGroups.nome)#</option>
                          </cfoutput>
                        </select>
                      </div>
                      <div class="col-md-4">
                        <label class="form-label">Nome</label>
                        <input class="form-control" type="text" name="app_nome" required value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormName)#</cfoutput>"/>
                      </div>
                      <div class="col-md-5">
                        <label class="form-label">URL</label>
                        <input class="form-control" type="text" name="app_url" required value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormUrl)#</cfoutput>"/>
                      </div>

                      <div class="col-md-5">
                        <label class="form-label">URL do icone</label>
                        <input class="form-control" type="text" name="app_imagem_url" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormImage)#</cfoutput>"/>
                      </div>
                      <div class="col-md-4">
                        <label class="form-label">Upload do icone</label>
                        <input class="form-control" type="file" name="app_icone" accept=".jpg,.jpeg,.png,.gif,.webp,.svg"/>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Alt text</label>
                        <input class="form-control" type="text" name="app_alt_text" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormAlt)#</cfoutput>"/>
                      </div>

                      <div class="col-md-2">
                        <label class="form-label">Ordem</label>
                        <input class="form-control" type="number" min="1" name="app_ordem" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormOrder)#</cfoutput>"/>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Abrir</label>
                        <select class="form-select" name="app_abrir_nova_aba">
                          <option value="0" <cfif NOT VARIABLES.runnerAppsAppFormNewTab>selected</cfif>>Mesma janela</option>
                          <option value="1" <cfif VARIABLES.runnerAppsAppFormNewTab>selected</cfif>>Nova aba</option>
                        </select>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Rel</label>
                        <input class="form-control" type="text" name="app_rel" placeholder="noopener" value="<cfoutput>#htmlEditFormat(VARIABLES.runnerAppsAppFormRel)#</cfoutput>"/>
                      </div>
                      <div class="col-md-2 d-flex align-items-end">
                        <div class="form-check mb-2">
                          <input class="form-check-input" type="checkbox" name="app_ativo" value="1" id="appAtivo" <cfif VARIABLES.runnerAppsAppFormActive>checked</cfif>/>
                          <label class="form-check-label" for="appAtivo">Ativo</label>
                        </div>
                      </div>
                      <div class="col-md-2 text-md-end d-flex align-items-end justify-content-md-end">
                        <button class="btn btn-warning" type="submit">Salvar</button>
                      </div>
                    </div>
                  </form>
                </div>
              </div>
            </cfif>

            <cfif qRunnerAppGroups.recordcount>
              <cfloop query="qRunnerAppGroups">
                <cfquery name="qRunnerAppsInGroup" dbtype="query">
                  SELECT *
                  FROM qRunnerApps
                  WHERE id_group = #val(qRunnerAppGroups.id_group)#
                  ORDER BY ordem ASC, id_app ASC
                </cfquery>

                <div class="card shadow-0 border border-white border-opacity-10 mb-4">
                  <div class="card-body">
                    <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                      <div>
                        <cfoutput>
                          <h5 class="mb-1">#htmlEditFormat(qRunnerAppGroups.nome)#</h5>
                          <div class="small text-muted">Ordem #qRunnerAppGroups.ordem# · #qRunnerAppGroups.total_apps# app(s) · #qRunnerAppGroups.active_apps# ativo(s)</div>
                        </cfoutput>
                      </div>
                      <div class="d-flex flex-wrap gap-2">
                        <cfoutput>
                          <a class="btn btn-sm btn-outline-secondary" href="./?grupo_editar=#qRunnerAppGroups.id_group#">Editar linha</a>
                          <a class="btn btn-sm <cfif runnerAppsNormalizeBoolean(qRunnerAppGroups.ativo)>btn-outline-warning<cfelse>btn-outline-success</cfif>" href="./?acao=toggle_group&id_group=#qRunnerAppGroups.id_group#&ativo=#NOT runnerAppsNormalizeBoolean(qRunnerAppGroups.ativo)#">
                            <cfif runnerAppsNormalizeBoolean(qRunnerAppGroups.ativo)>Ocultar linha<cfelse>Exibir linha</cfif>
                          </a>
                          <a class="btn btn-sm btn-outline-danger" href="./?acao=delete_group&id_group=#qRunnerAppGroups.id_group#" onclick="return confirm('Remover esta linha? Ela precisa estar sem apps vinculados.');">Remover linha</a>
                        </cfoutput>
                      </div>
                    </div>

                    <div class="table-responsive">
                      <table class="table table-sm table-hover runner-app-table mb-0">
                        <thead>
                          <tr>
                            <th>Icone</th>
                            <th>Nome</th>
                            <th>URL</th>
                            <th>Ordem</th>
                            <th>Status</th>
                            <th class="runner-app-actions">Acoes</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfif qRunnerAppsInGroup.recordcount>
                            <cfoutput query="qRunnerAppsInGroup">
                              <cfset VARIABLES.runnerAppActive = runnerAppsNormalizeBoolean(qRunnerAppsInGroup.ativo)/>
                              <tr>
                                <td>
                                  <img class="runner-app-icon" src="#htmlEditFormat(runnerAppsAssetUrl(qRunnerAppsInGroup.imagem_url))#" alt="#htmlEditFormat(qRunnerAppsInGroup.alt_text)#"/>
                                </td>
                                <td>
                                  <div class="fw-semibold">#htmlEditFormat(qRunnerAppsInGroup.nome)#</div>
                                  <div class="small text-muted">#htmlEditFormat(qRunnerAppsInGroup.alt_text)#</div>
                                </td>
                                <td class="runner-app-url">
                                  <a href="#htmlEditFormat(qRunnerAppsInGroup.url)#" target="_blank" rel="noopener">#htmlEditFormat(qRunnerAppsInGroup.url)#</a>
                                  <div class="small text-muted"><cfif runnerAppsNormalizeBoolean(qRunnerAppsInGroup.abrir_nova_aba)>Nova aba<cfelse>Mesma janela</cfif><cfif len(trim(qRunnerAppsInGroup.rel))> · rel: #htmlEditFormat(qRunnerAppsInGroup.rel)#</cfif></div>
                                </td>
                                <td>#qRunnerAppsInGroup.ordem#</td>
                                <td>
                                  <span class="badge <cfif VARIABLES.runnerAppActive>badge-success<cfelse>badge-secondary</cfif>"><cfif VARIABLES.runnerAppActive>Ativo<cfelse>Oculto</cfif></span>
                                </td>
                                <td class="runner-app-actions">
                                  <div class="d-flex flex-wrap gap-2">
                                    <a class="btn btn-sm btn-outline-secondary" href="./?app_editar=#qRunnerAppsInGroup.id_app#">Editar</a>
                                    <a class="btn btn-sm <cfif VARIABLES.runnerAppActive>btn-outline-warning<cfelse>btn-outline-success</cfif>" href="./?acao=toggle_app&id_app=#qRunnerAppsInGroup.id_app#&ativo=#NOT VARIABLES.runnerAppActive#">
                                      <cfif VARIABLES.runnerAppActive>Ocultar<cfelse>Exibir</cfif>
                                    </a>
                                    <a class="btn btn-sm btn-outline-danger" href="./?acao=delete_app&id_app=#qRunnerAppsInGroup.id_app#" onclick="return confirm('Remover este app do Runner Apps?');">Remover</a>
                                  </div>
                                </td>
                              </tr>
                            </cfoutput>
                          <cfelse>
                            <tr>
                              <td colspan="6" class="text-muted text-center py-4">Nenhum app nesta linha.</td>
                            </tr>
                          </cfif>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </cfloop>
            <cfelse>
              <div class="alert alert-info mb-0">Nenhuma linha cadastrada.</div>
            </cfif>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
