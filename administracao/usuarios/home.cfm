<cfscript>
function userManagerDisplayValue(any value = "", string fallback = "-") {
    return !isNull(arguments.value) && len(trim(arguments.value & "")) ? trim(arguments.value & "") : arguments.fallback;
}

function userManagerDateInput(any value = "") {
    return !isNull(arguments.value) && isDate(arguments.value) ? dateFormat(arguments.value, "yyyy-mm-dd") : "";
}
</cfscript>

<cfset VARIABLES.userManagerShowingDetail = qUserManagerUser.recordcount GT 0/>
<cfset VARIABLES.userManagerCanMutateDetail = VARIABLES.userManagerShowingDetail AND (VARIABLES.userManagerActorIsAdmin OR (!userManagerBoolean(qUserManagerUser.is_admin) AND !userManagerBoolean(qUserManagerUser.is_dev)))/>

<style>
  .user-manager-shell {
    --um-accent: #fab120;
    --um-surface: rgba(255, 255, 255, .035);
    --um-border: rgba(255, 255, 255, .09);
  }

  .user-manager-hero,
  .user-manager-panel,
  .user-manager-metric,
  .user-manager-page-card {
    border: 1px solid var(--um-border);
    background: var(--um-surface);
    border-radius: 1rem;
  }

  .user-manager-hero {
    position: relative;
    overflow: hidden;
  }

  .user-manager-hero::after {
    content: "";
    position: absolute;
    width: 240px;
    height: 240px;
    right: -95px;
    top: -120px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(250, 177, 32, .2), transparent 68%);
    pointer-events: none;
  }

  .user-manager-avatar {
    width: 64px;
    height: 64px;
    border-radius: 18px;
    object-fit: cover;
    background: rgba(255, 255, 255, .08);
    border: 1px solid rgba(255, 255, 255, .12);
  }

  .user-manager-avatar-sm {
    width: 42px;
    height: 42px;
    border-radius: 12px;
    object-fit: cover;
    background: rgba(255, 255, 255, .08);
  }

  .user-manager-metric {
    min-height: 104px;
    padding: 1rem;
  }

  .user-manager-metric-icon {
    width: 34px;
    height: 34px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 11px;
    color: var(--um-accent);
    background: rgba(250, 177, 32, .12);
  }

  .user-manager-status-dot {
    width: .58rem;
    height: .58rem;
    display: inline-block;
    border-radius: 50%;
    background: #51cf66;
    box-shadow: 0 0 0 4px rgba(81, 207, 102, .1);
  }

  .user-manager-status-dot.is-inactive {
    background: #ff6b6b;
    box-shadow: 0 0 0 4px rgba(255, 107, 107, .1);
  }

  .user-manager-status-dot.is-deleted {
    background: #868e96;
    box-shadow: 0 0 0 4px rgba(134, 142, 150, .1);
  }

  .user-manager-table th,
  .user-manager-table td {
    vertical-align: middle;
  }

  .user-manager-table .user-manager-id {
    white-space: nowrap;
    width: 1%;
  }

  .user-manager-actions {
    white-space: nowrap;
    width: 1%;
  }

  .user-manager-tabs {
    display: flex;
    gap: .45rem;
    overflow-x: auto;
    padding-bottom: .25rem;
    scrollbar-width: thin;
  }

  .user-manager-tabs .btn {
    flex: 0 0 auto;
    border-radius: 999px;
  }

  .user-manager-form-section {
    padding: 1.1rem;
    border: 1px solid var(--um-border);
    border-radius: .85rem;
    background: rgba(0, 0, 0, .08);
  }

  .user-manager-form-section-title {
    font-size: .8rem;
    letter-spacing: .08em;
    text-transform: uppercase;
    color: var(--bs-secondary-color);
  }

  .user-manager-page-card summary {
    cursor: pointer;
    list-style: none;
  }

  .user-manager-page-card summary::-webkit-details-marker {
    display: none;
  }

  .user-manager-page-card[open] summary {
    border-bottom: 1px solid var(--um-border);
  }

  .user-manager-danger-zone {
    border: 1px solid rgba(255, 107, 107, .25);
    background: rgba(255, 107, 107, .045);
  }

  .user-manager-empty {
    min-height: 180px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
  }

  @media (max-width: 767.98px) {
    .user-manager-table thead {
      display: none;
    }

    .user-manager-table,
    .user-manager-table tbody,
    .user-manager-table tr,
    .user-manager-table td {
      display: block;
      width: 100%;
    }

    .user-manager-table tr {
      padding: .8rem 0;
      border-bottom: 1px solid var(--um-border);
    }

    .user-manager-table td {
      border: 0;
      padding: .3rem .45rem;
    }

    .user-manager-table td[data-label]::before {
      content: attr(data-label);
      display: block;
      color: var(--bs-secondary-color);
      font-size: .7rem;
      text-transform: uppercase;
      letter-spacing: .06em;
      margin-bottom: .15rem;
    }

    .user-manager-actions {
      white-space: normal;
    }
  }
</style>

<section class="business-page user-manager-shell">
  <div class="card shadow-0 business-page-card">
    <div class="card-body business-page-body">
      <cfif len(VARIABLES.userManagerFeedback) AND len(VARIABLES.userManagerMessage)>
        <div class="alert <cfif VARIABLES.userManagerFeedback EQ 'sucesso'>alert-success<cfelse>alert-danger</cfif> mb-4" role="alert">
          <cfoutput>#htmlEditFormat(VARIABLES.userManagerMessage)#</cfoutput>
        </div>
      </cfif>

      <cfif NOT VARIABLES.userManagerSchemaReady>
        <div class="alert alert-warning d-flex gap-3 align-items-start mb-4" role="alert">
          <i class="fa-solid fa-database mt-1"></i>
          <div>
            <strong>Estrutura administrativa pendente.</strong>
            <div class="small mt-1">A listagem permanece disponível, mas ativação, exclusão lógica e auditoria exigem a aplicação de <code>administracao/usuarios/user_management_schema.sql</code>.</div>
          </div>
        </div>
      </cfif>

      <cfif VARIABLES.userManagerIsNew OR VARIABLES.userManagerShowingDetail>
        <cfset VARIABLES.userManagerFormUserId = VARIABLES.userManagerShowingDetail ? val(qUserManagerUser.id) : 0/>
        <cfset VARIABLES.userManagerFormIsDeleted = VARIABLES.userManagerShowingDetail AND userManagerBoolean(qUserManagerUser.gestao_excluido)/>
        <cfset VARIABLES.userManagerFormIsActive = !VARIABLES.userManagerShowingDetail OR userManagerBoolean(qUserManagerUser.gestao_ativo)/>
        <cfset VARIABLES.userManagerAvatar = VARIABLES.userManagerShowingDetail ? userManagerDisplayValue(qUserManagerUser.imagem_usuario, userManagerDisplayValue(qUserManagerUser.strava_profile, "/assets/user.png")) : "/assets/user.png"/>

        <div class="user-manager-hero p-3 p-lg-4 mb-4">
          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 position-relative" style="z-index:1;">
            <div class="d-flex align-items-center gap-3">
              <img class="user-manager-avatar" src="<cfoutput>#htmlEditFormat(VARIABLES.userManagerAvatar)#</cfoutput>" alt=""/>
              <div>
                <div class="d-flex flex-wrap align-items-center gap-2 mb-1">
                  <h3 class="mb-0"><cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(qUserManagerUser.name)#</cfoutput><cfelse>Novo usuário</cfif></h3>
                  <cfif VARIABLES.userManagerShowingDetail>
                    <span class="user-manager-status-dot <cfif VARIABLES.userManagerFormIsDeleted>is-deleted<cfelseif NOT VARIABLES.userManagerFormIsActive>is-inactive</cfif>" aria-hidden="true"></span>
                    <span class="small text-muted"><cfif VARIABLES.userManagerFormIsDeleted>Excluído<cfelseif VARIABLES.userManagerFormIsActive>Ativo<cfelse>Inativo</cfif></span>
                  </cfif>
                </div>
                <cfif VARIABLES.userManagerShowingDetail>
                  <div class="text-muted small"><cfoutput>## #qUserManagerUser.id# · #htmlEditFormat(qUserManagerUser.email)#</cfoutput></div>
                  <div class="d-flex flex-wrap gap-1 mt-2">
                    <cfif userManagerBoolean(qUserManagerUser.is_admin)><span class="badge badge-warning">ADMIN</span></cfif>
                    <cfif userManagerBoolean(qUserManagerUser.is_dev)><span class="badge badge-info">DEV</span></cfif>
                    <cfif userManagerBoolean(qUserManagerUser.is_partner)><span class="badge badge-primary">PARTNER</span></cfif>
                    <cfif val(qUserManagerUser.strava_id) GT 0><span class="badge badge-danger"><i class="fa-brands fa-strava me-1"></i>STRAVA</span></cfif>
                  </div>
                <cfelse>
                  <div class="text-muted small">Crie a conta e, opcionalmente, seu primeiro perfil público em uma única operação.</div>
                </cfif>
              </div>
            </div>

            <div class="d-flex flex-wrap align-items-center gap-2">
              <a class="btn btn-sm btn-outline-secondary" href="./"><i class="fa-solid fa-arrow-left me-2"></i>Voltar</a>
              <cfif VARIABLES.userManagerShowingDetail AND !VARIABLES.userManagerFormIsDeleted AND VARIABLES.userManagerFormIsActive>
                <cfoutput>
                  <form method="post" action="./" target="_blank" class="m-0">
                    <input type="hidden" name="user_manager_action" value="logar_como_dev"/>
                    <input type="hidden" name="user_manager_csrf" value="#htmlEditFormat(VARIABLES.userManagerCsrf)#"/>
                    <input type="hidden" name="user_id" value="#qUserManagerUser.id#"/>
                    <input type="hidden" name="return_tab" value="#htmlEditFormat(VARIABLES.userManagerTab)#"/>
                    <button class="btn btn-sm btn-warning" type="submit" title="Abrir o ambiente DEV autenticado como este usuário">
                      <i class="fa-solid fa-user-secret me-2"></i>Logar como no DEV
                    </button>
                  </form>
                </cfoutput>
              </cfif>
            </div>
          </div>
        </div>

        <cfif VARIABLES.userManagerShowingDetail>
          <div class="row g-3 mb-4">
            <div class="col-6 col-lg-3">
              <div class="user-manager-metric">
                <div class="d-flex justify-content-between align-items-start"><span class="small text-muted">Páginas</span><span class="user-manager-metric-icon"><i class="fa-regular fa-id-card"></i></span></div>
                <div class="h3 mb-0 mt-2"><cfoutput>#LSNumberFormat(qUserManagerUser.total_paginas)#</cfoutput></div>
              </div>
            </div>
            <div class="col-6 col-lg-3">
              <div class="user-manager-metric">
                <div class="d-flex justify-content-between align-items-start"><span class="small text-muted">Agendas</span><span class="user-manager-metric-icon"><i class="fa-regular fa-calendar-days"></i></span></div>
                <div class="h3 mb-0 mt-2"><cfoutput>#LSNumberFormat(qUserManagerUser.total_agendas)#</cfoutput></div>
              </div>
            </div>
            <div class="col-6 col-lg-3">
              <div class="user-manager-metric">
                <div class="d-flex justify-content-between align-items-start"><span class="small text-muted">Resultados</span><span class="user-manager-metric-icon"><i class="fa-solid fa-medal"></i></span></div>
                <div class="h3 mb-0 mt-2"><cfoutput>#LSNumberFormat(qUserManagerUser.total_resultados)#</cfoutput></div>
              </div>
            </div>
            <div class="col-6 col-lg-3">
              <div class="user-manager-metric">
                <div class="d-flex justify-content-between align-items-start"><span class="small text-muted">Cadastro</span><span class="user-manager-metric-icon"><i class="fa-regular fa-clock"></i></span></div>
                <div class="fw-semibold mt-3"><cfoutput>#dateFormat(qUserManagerUser.data_criacao, "dd/mm/yyyy")#</cfoutput></div>
              </div>
            </div>
          </div>

          <div class="user-manager-tabs mb-4" aria-label="Seções do usuário">
            <cfloop list="conta,paginas,agendas,resultados,social,auditoria" index="VARIABLES.userManagerTabItem">
              <cfset VARIABLES.userManagerTabLabels = {conta="Conta",paginas="Páginas",agendas="Agendas",resultados="Resultados",social="Seguidores",auditoria="Auditoria"}/>
              <cfoutput><a class="btn btn-sm <cfif VARIABLES.userManagerTab EQ VARIABLES.userManagerTabItem>btn-warning<cfelse>btn-outline-secondary</cfif>" href="./?user_id=#qUserManagerUser.id#&amp;aba=#VARIABLES.userManagerTabItem#">#VARIABLES.userManagerTabLabels[VARIABLES.userManagerTabItem]#</a></cfoutput>
            </cfloop>
          </div>
        </cfif>

        <cfif VARIABLES.userManagerIsNew OR VARIABLES.userManagerTab EQ "conta">
          <div class="user-manager-panel p-3 p-lg-4">
            <div class="d-flex justify-content-between align-items-start gap-3 mb-4">
              <div>
                <h5 class="mb-1"><cfif VARIABLES.userManagerShowingDetail>Dados da conta<cfelse>Criar conta</cfif></h5>
                <p class="text-muted small mb-0">Credenciais e tokens de integrações não são exibidos nem editados por segurança.</p>
              </div>
              <cfif VARIABLES.userManagerShowingDetail AND NOT VARIABLES.userManagerCanMutateDetail>
                <span class="badge badge-secondary">Somente leitura para DEV</span>
              </cfif>
            </div>

            <form method="post" action="./">
              <input type="hidden" name="user_manager_action" value="salvar_usuario"/>
              <input type="hidden" name="user_manager_csrf" value="<cfoutput>#VARIABLES.userManagerCsrf#</cfoutput>"/>
              <input type="hidden" name="user_id" value="<cfoutput>#VARIABLES.userManagerFormUserId#</cfoutput>"/>
              <input type="hidden" name="return_tab" value="conta"/>

              <fieldset <cfif VARIABLES.userManagerShowingDetail AND (!VARIABLES.userManagerCanMutateDetail OR VARIABLES.userManagerFormIsDeleted)>disabled</cfif>>
                <div class="user-manager-form-section mb-3">
                  <div class="user-manager-form-section-title mb-3">Identificação</div>
                  <div class="row g-3">
                    <div class="col-12 col-lg-6">
                      <label class="form-label">Nome *</label>
                      <input class="form-control" name="name" required maxlength="256" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(qUserManagerUser.name)#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-12 col-lg-6">
                      <label class="form-label">E-mail</label>
                      <input class="form-control" type="email" name="email" maxlength="256" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(qUserManagerUser.email)#</cfoutput></cfif>" placeholder="Vazio gera um e-mail temporário"/>
                    </div>
                    <div class="col-12 col-md-6 col-lg-3">
                      <label class="form-label">Username</label>
                      <input class="form-control" name="username" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.username, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-12 col-md-6 col-lg-3">
                      <label class="form-label">Nome conhecido / AKA</label>
                      <input class="form-control" name="aka" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.aka, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-6 col-lg-3">
                      <label class="form-label">Sexo</label>
                      <select class="form-select" name="genero">
                        <option value="">Não informado</option>
                        <option value="M" <cfif VARIABLES.userManagerShowingDetail AND qUserManagerUser.genero EQ "M">selected</cfif>>Masculino</option>
                        <option value="F" <cfif VARIABLES.userManagerShowingDetail AND qUserManagerUser.genero EQ "F">selected</cfif>>Feminino</option>
                      </select>
                    </div>
                    <div class="col-6 col-lg-3">
                      <label class="form-label">CBAT</label>
                      <input class="form-control" name="cbat" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.cbat, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-6 col-lg-3">
                      <label class="form-label">Nascimento</label>
                      <input class="form-control" type="date" name="data_nascimento" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#userManagerDateInput(qUserManagerUser.data_nascimento)#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-6 col-lg-3">
                      <label class="form-label">Ano de nascimento</label>
                      <input class="form-control" type="number" min="1900" max="2100" name="ano_nascimento" value="<cfif VARIABLES.userManagerShowingDetail AND val(qUserManagerUser.ano_nascimento) GT 0><cfoutput>#qUserManagerUser.ano_nascimento#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-12 col-lg-6">
                      <label class="form-label">Assessoria</label>
                      <input class="form-control" name="assessoria" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.assessoria, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-12 col-lg-6">
                      <label class="form-label">Imagem da conta</label>
                      <input class="form-control" name="imagem_usuario" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.imagem_usuario, ''))#</cfoutput></cfif>" placeholder="URL ou caminho já existente"/>
                    </div>
                  </div>
                </div>

                <div class="user-manager-form-section mb-3">
                  <div class="user-manager-form-section-title mb-3">Localização e contato</div>
                  <div class="row g-3">
                    <div class="col-12 col-md-4">
                      <label class="form-label">País</label>
                      <select class="form-select" name="pais">
                        <cfoutput query="qUserManagerCountries">
                          <option value="#qUserManagerCountries.cod_alpha2#" <cfif (VARIABLES.userManagerShowingDetail AND qUserManagerUser.pais EQ qUserManagerCountries.cod_alpha2) OR (!VARIABLES.userManagerShowingDetail AND qUserManagerCountries.cod_alpha2 EQ "BR")>selected</cfif>>#htmlEditFormat(qUserManagerCountries.nome_pais)#</option>
                        </cfoutput>
                      </select>
                    </div>
                    <div class="col-6 col-md-2">
                      <label class="form-label">Estado</label>
                      <select class="form-select" name="estado">
                        <option value="">-</option>
                        <cfoutput query="qUserManagerStates"><option value="#qUserManagerStates.uf#" <cfif VARIABLES.userManagerShowingDetail AND qUserManagerUser.estado EQ qUserManagerStates.uf>selected</cfif>>#qUserManagerStates.uf#</option></cfoutput>
                      </select>
                    </div>
                    <div class="col-6 col-md-3">
                      <label class="form-label">Cidade</label>
                      <input class="form-control" name="cidade" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.cidade, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-6 col-md-3">
                      <label class="form-label">CEP</label>
                      <input class="form-control" name="cep" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.cep, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-12 col-md-6">
                      <label class="form-label">Endereço</label>
                      <input class="form-control" name="endereco" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.endereco, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-4 col-md-2">
                      <label class="form-label">DDI</label>
                      <input class="form-control" name="ddi_usuario" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.ddi_usuario, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-4 col-md-2">
                      <label class="form-label">DDD</label>
                      <input class="form-control" name="ddd_usuario" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.ddd_usuario, ''))#</cfoutput></cfif>"/>
                    </div>
                    <div class="col-4 col-md-2">
                      <label class="form-label">Telefone</label>
                      <input class="form-control" name="telefone_usuario" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.telefone_usuario, ''))#</cfoutput></cfif>"/>
                    </div>
                  </div>
                </div>

                <div class="user-manager-form-section mb-3">
                  <div class="user-manager-form-section-title mb-3">Plataforma e permissões</div>
                  <div class="row g-3">
                    <div class="col-12 col-md-4"><label class="form-label">Tag de usuário</label><input class="form-control" name="tag_usuario" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.tag_usuario, ''))#</cfoutput></cfif>"/></div>
                    <div class="col-12 col-md-4"><label class="form-label">URL do usuário</label><input class="form-control" name="url_usuario" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.url_usuario, ''))#</cfoutput></cfif>"/></div>
                    <div class="col-12 col-md-4"><label class="form-label">Fonte do lead</label><input class="form-control" name="fonte_lead" value="<cfif VARIABLES.userManagerShowingDetail><cfoutput>#htmlEditFormat(userManagerDisplayValue(qUserManagerUser.fonte_lead, ''))#</cfoutput></cfif>"/></div>
                    <div class="col-12 col-md-4"><label class="form-label">ManyChat subscriber ID</label><input class="form-control" type="number" name="manychat_subscriber_id" value="<cfif VARIABLES.userManagerShowingDetail AND val(qUserManagerUser.manychat_subscriber_id) GT 0><cfoutput>#qUserManagerUser.manychat_subscriber_id#</cfoutput></cfif>"/></div>
                    <div class="col-12 col-md-8 d-flex flex-wrap align-items-end gap-4 pb-2">
                      <div class="form-check"><input class="form-check-input" type="checkbox" name="is_email_verified" value="true" id="um-email-verified"<cfif !VARIABLES.userManagerShowingDetail OR userManagerBoolean(qUserManagerUser.is_email_verified)> checked</cfif>/><label class="form-check-label" for="um-email-verified">E-mail verificado</label></div>
                      <div class="form-check"><input class="form-check-input" type="checkbox" name="optin_usuario" value="true" id="um-optin"<cfif !VARIABLES.userManagerShowingDetail OR userManagerBoolean(qUserManagerUser.optin_usuario)> checked</cfif>/><label class="form-check-label" for="um-optin">Opt-in</label></div>
                    </div>
                    <cfif VARIABLES.userManagerActorIsAdmin>
                      <div class="col-12 d-flex flex-wrap gap-4 pt-2 border-top border-secondary-subtle">
                        <div class="form-check"><input class="form-check-input" type="checkbox" name="is_admin" value="true" id="um-admin"<cfif VARIABLES.userManagerShowingDetail AND userManagerBoolean(qUserManagerUser.is_admin)> checked</cfif>/><label class="form-check-label" for="um-admin">ADMIN</label></div>
                        <div class="form-check"><input class="form-check-input" type="checkbox" name="is_dev" value="true" id="um-dev"<cfif VARIABLES.userManagerShowingDetail AND userManagerBoolean(qUserManagerUser.is_dev)> checked</cfif>/><label class="form-check-label" for="um-dev">DEV</label></div>
                        <div class="form-check"><input class="form-check-input" type="checkbox" name="is_partner" value="true" id="um-partner"<cfif VARIABLES.userManagerShowingDetail AND userManagerBoolean(qUserManagerUser.is_partner)> checked</cfif>/><label class="form-check-label" for="um-partner">PARTNER</label></div>
                      </div>
                    </cfif>
                    <cfif NOT VARIABLES.userManagerShowingDetail>
                      <div class="col-12 pt-2 border-top border-secondary-subtle">
                        <div class="form-check"><input class="form-check-input" type="checkbox" name="criar_pagina" value="true" id="um-create-page" checked/><label class="form-check-label" for="um-create-page">Criar também uma página de atleta com slug automático</label></div>
                      </div>
                    </cfif>
                  </div>
                </div>

                <div class="d-flex flex-wrap gap-2">
                  <button class="btn btn-warning" type="submit"><i class="fa-solid fa-check me-2"></i>Salvar conta</button>
                  <a class="btn btn-outline-secondary" href="./">Cancelar</a>
                </div>
              </fieldset>
            </form>

            <cfif VARIABLES.userManagerShowingDetail>
              <div class="user-manager-form-section mt-4">
                <div class="user-manager-form-section-title mb-3">Integrações protegidas</div>
                <div class="row g-3 small">
                  <div class="col-12 col-md-4"><div class="text-muted">Strava</div><div class="fw-semibold"><cfif val(qUserManagerUser.strava_id) GT 0><cfoutput>Ativo · atleta ## #qUserManagerUser.strava_id#</cfoutput><cfelse>Não conectado</cfif></div></div>
                  <div class="col-12 col-md-4"><div class="text-muted">Última alteração da conta</div><div class="fw-semibold"><cfif isDate(qUserManagerUser.data_alteracao)><cfoutput>#dateTimeFormat(qUserManagerUser.data_alteracao, "dd/mm/yyyy HH:nn")#</cfoutput><cfelse>-</cfif></div></div>
                  <div class="col-12 col-md-4"><div class="text-muted">Chaves e tokens</div><div class="fw-semibold">Ocultos por segurança</div></div>
                </div>
              </div>
            </cfif>

            <cfif VARIABLES.userManagerShowingDetail AND VARIABLES.userManagerCanMutateDetail AND VARIABLES.userManagerSchemaReady>
              <div class="user-manager-form-section user-manager-danger-zone mt-4">
                <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
                  <div>
                    <div class="user-manager-form-section-title text-danger mb-1">Controle de acesso</div>
                    <p class="small text-muted mb-0">Desativar bloqueia o login. Excluir é uma exclusão lógica: preserva resultados, agendas e auditoria.</p>
                  </div>
                  <div class="d-flex flex-wrap gap-2">
                    <cfif VARIABLES.userManagerFormIsDeleted>
                      <form method="post" action="./">
                        <input type="hidden" name="user_manager_action" value="restaurar_usuario"/><input type="hidden" name="user_manager_csrf" value="<cfoutput>#VARIABLES.userManagerCsrf#</cfoutput>"/><input type="hidden" name="user_id" value="<cfoutput>#qUserManagerUser.id#</cfoutput>"/>
                        <button class="btn btn-outline-success" type="submit"><i class="fa-solid fa-rotate-left me-2"></i>Restaurar conta</button>
                      </form>
                    <cfelse>
                      <form method="post" action="./" data-confirm="Confirma a alteração de acesso desta conta?">
                        <input type="hidden" name="user_manager_action" value="alternar_usuario"/><input type="hidden" name="user_manager_csrf" value="<cfoutput>#VARIABLES.userManagerCsrf#</cfoutput>"/><input type="hidden" name="user_id" value="<cfoutput>#qUserManagerUser.id#</cfoutput>"/><input type="hidden" name="ativo" value="<cfif VARIABLES.userManagerFormIsActive>false<cfelse>true</cfif>"/>
                        <button class="btn btn-outline-warning" type="submit"><cfif VARIABLES.userManagerFormIsActive>Desativar<cfelse>Ativar</cfif></button>
                      </form>
                      <form method="post" action="./" data-confirm="Excluir logicamente esta conta e todas as páginas vinculadas? O histórico será preservado.">
                        <input type="hidden" name="user_manager_action" value="excluir_usuario"/><input type="hidden" name="user_manager_csrf" value="<cfoutput>#VARIABLES.userManagerCsrf#</cfoutput>"/><input type="hidden" name="user_id" value="<cfoutput>#qUserManagerUser.id#</cfoutput>"/><input type="hidden" name="motivo" value="Exclusão administrativa pelo gerenciador"/>
                        <button class="btn btn-outline-danger" type="submit"><i class="fa-regular fa-trash-can me-2"></i>Excluir conta</button>
                      </form>
                    </cfif>
                  </div>
                </div>
              </div>
            </cfif>
          </div>
        </cfif>

        <cfif VARIABLES.userManagerShowingDetail AND VARIABLES.userManagerTab EQ "paginas">
          <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-3 mb-3">
            <div><h5 class="mb-1">Páginas vinculadas</h5><p class="small text-muted mb-0">Edite perfis, privacidade, redes e estado administrativo separadamente.</p></div>
          </div>

          <cfif VARIABLES.userManagerCanMutateDetail AND NOT VARIABLES.userManagerFormIsDeleted>
            <details class="user-manager-page-card mb-3">
              <summary class="p-3 d-flex justify-content-between align-items-center gap-3">
                <span><i class="fa-solid fa-circle-plus text-warning me-2"></i><strong>Criar nova página</strong></span>
                <span class="small text-muted">Abrir formulário</span>
              </summary>
              <div class="p-3"><cfinclude template="includes/page_form.cfm"/></div>
            </details>
          </cfif>

          <cfif qUserManagerPages.recordcount>
            <cfloop query="qUserManagerPages">
              <cfset VARIABLES.userManagerPageRow = queryGetRow(qUserManagerPages, qUserManagerPages.currentRow)/>
              <details class="user-manager-page-card mb-3">
                <cfoutput>
                <summary class="p-3 d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-2">
                  <div class="d-flex align-items-center gap-3">
                    <span class="user-manager-status-dot <cfif userManagerBoolean(qUserManagerPages.gestao_excluido)>is-deleted<cfelseif NOT userManagerBoolean(qUserManagerPages.gestao_ativo)>is-inactive</cfif>"></span>
                    <div>
                      <div class="fw-semibold">#htmlEditFormat(qUserManagerPages.nome)#</div>
                      <div class="small text-muted">## #qUserManagerPages.id_pagina# · /#htmlEditFormat(qUserManagerPages.tag_prefix)#/#htmlEditFormat(qUserManagerPages.tag)#/ · #LSNumberFormat(qUserManagerPages.seguidores)# seguidores</div>
                    </div>
                  </div>
                  <div class="d-flex flex-wrap gap-2">
                    <a class="btn btn-sm btn-outline-secondary" target="_blank" rel="noopener" href="https://roadrunners.run/#urlEncodedFormat(qUserManagerPages.tag_prefix)#/#urlEncodedFormat(qUserManagerPages.tag)#/"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
                    <span class="badge <cfif userManagerBoolean(qUserManagerPages.verificado)>badge-success<cfelse>badge-secondary</cfif>"><cfif userManagerBoolean(qUserManagerPages.verificado)>Verificada<cfelse>Não verificada</cfif></span>
                    <span class="badge <cfif userManagerBoolean(qUserManagerPages.gestao_ativo) AND NOT userManagerBoolean(qUserManagerPages.gestao_excluido)>badge-info<cfelse>badge-secondary</cfif>"><cfif userManagerBoolean(qUserManagerPages.gestao_excluido)>Excluída<cfelseif userManagerBoolean(qUserManagerPages.gestao_ativo)>Ativa<cfelse>Inativa</cfif></span>
                  </div>
                </summary>
                </cfoutput>
                <div class="p-3">
                  <cfif VARIABLES.userManagerCanMutateDetail AND NOT userManagerBoolean(qUserManagerPages.gestao_excluido)>
                    <cfinclude template="includes/page_form.cfm"/>
                  <cfelse>
                    <div class="alert alert-secondary small">Esta página está em modo somente leitura.</div>
                  </cfif>

                  <cfif VARIABLES.userManagerCanMutateDetail AND VARIABLES.userManagerSchemaReady>
                    <div class="d-flex flex-wrap gap-2 pt-3 mt-3 border-top border-secondary-subtle">
                      <cfif userManagerBoolean(qUserManagerPages.gestao_excluido)>
                        <cfoutput><form method="post" action="./"><input type="hidden" name="user_manager_action" value="restaurar_pagina"/><input type="hidden" name="user_manager_csrf" value="#VARIABLES.userManagerCsrf#"/><input type="hidden" name="user_id" value="#qUserManagerUser.id#"/><input type="hidden" name="page_id" value="#qUserManagerPages.id_pagina#"/><input type="hidden" name="return_tab" value="paginas"/><button class="btn btn-sm btn-outline-success" type="submit">Restaurar</button></form></cfoutput>
                      <cfelse>
                        <cfoutput><form method="post" action="./"><input type="hidden" name="user_manager_action" value="alternar_pagina"/><input type="hidden" name="user_manager_csrf" value="#VARIABLES.userManagerCsrf#"/><input type="hidden" name="user_id" value="#qUserManagerUser.id#"/><input type="hidden" name="page_id" value="#qUserManagerPages.id_pagina#"/><input type="hidden" name="return_tab" value="paginas"/><input type="hidden" name="ativo" value="#userManagerBoolean(qUserManagerPages.gestao_ativo) ? 'false' : 'true'#"/><button class="btn btn-sm btn-outline-warning" type="submit"><cfif userManagerBoolean(qUserManagerPages.gestao_ativo)>Desativar<cfelse>Ativar</cfif></button></form>
                        <form method="post" action="./" data-confirm="Excluir logicamente esta página?"><input type="hidden" name="user_manager_action" value="excluir_pagina"/><input type="hidden" name="user_manager_csrf" value="#VARIABLES.userManagerCsrf#"/><input type="hidden" name="user_id" value="#qUserManagerUser.id#"/><input type="hidden" name="page_id" value="#qUserManagerPages.id_pagina#"/><input type="hidden" name="return_tab" value="paginas"/><button class="btn btn-sm btn-outline-danger" type="submit">Excluir página</button></form></cfoutput>
                      </cfif>
                    </div>
                  </cfif>
                </div>
              </details>
            </cfloop>
          <cfelse>
            <div class="user-manager-panel user-manager-empty p-4"><i class="fa-regular fa-id-card fa-2x text-muted mb-3"></i><h6>Nenhuma página vinculada</h6><p class="small text-muted mb-0">Crie o primeiro perfil desta conta pelo formulário acima.</p></div>
          </cfif>
        </cfif>

        <cfif VARIABLES.userManagerShowingDetail AND VARIABLES.userManagerTab EQ "agendas">
          <div class="user-manager-panel p-3 p-lg-4">
            <div class="d-flex justify-content-between align-items-start gap-3 mb-3"><div><h5 class="mb-1">Agendas do usuário</h5><p class="small text-muted mb-0">A edição completa continua centralizada no gerenciador de Agendas.</p></div><a class="btn btn-sm btn-outline-warning" href="/portal/agendas/?agenda_nova=1">Nova agenda</a></div>
            <div class="table-responsive">
              <table class="table table-hover user-manager-table mb-0">
                <thead><tr><th>ID</th><th>Agenda</th><th>Modo</th><th>Status</th><th>Composição</th><th class="user-manager-actions">Ação</th></tr></thead>
                <tbody>
                  <cfif qUserManagerAgendas.recordcount>
                    <cfoutput query="qUserManagerAgendas"><tr><td class="user-manager-id" data-label="ID">#qUserManagerAgendas.id_agenda#</td><td data-label="Agenda"><div class="fw-semibold">#htmlEditFormat(qUserManagerAgendas.nome)#</div><div class="small text-muted">#htmlEditFormat(qUserManagerAgendas.dominio_permitido)#</div></td><td data-label="Modo">#htmlEditFormat(qUserManagerAgendas.modo)#</td><td data-label="Status"><span class="badge badge-secondary">#htmlEditFormat(qUserManagerAgendas.status)#</span></td><td data-label="Composição"><span class="small">#qUserManagerAgendas.eventos_manuais# eventos · #qUserManagerAgendas.filtros# filtros</span></td><td class="user-manager-actions" data-label="Ação"><a class="btn btn-sm btn-outline-warning" href="/portal/agendas/?agenda_id=#qUserManagerAgendas.id_agenda#">Editar</a></td></tr></cfoutput>
                  <cfelse><tr><td colspan="6"><div class="user-manager-empty"><i class="fa-regular fa-calendar-xmark fa-2x text-muted mb-3"></i><span class="text-muted">Nenhuma agenda vinculada.</span></div></td></tr></cfif>
                </tbody>
              </table>
            </div>
          </div>
        </cfif>

        <cfif VARIABLES.userManagerShowingDetail AND VARIABLES.userManagerTab EQ "resultados">
          <div class="user-manager-panel p-3 p-lg-4">
            <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
              <div><h5 class="mb-1">Resultados vinculados</h5><p class="small text-muted mb-0">Vínculos são alterados sem excluir o resultado esportivo original.</p></div>
              <cfif VARIABLES.userManagerCanMutateDetail AND NOT VARIABLES.userManagerFormIsDeleted>
                <form method="post" action="./" class="d-flex gap-2">
                  <input type="hidden" name="user_manager_action" value="vincular_resultado"/><input type="hidden" name="user_manager_csrf" value="<cfoutput>#VARIABLES.userManagerCsrf#</cfoutput>"/><input type="hidden" name="user_id" value="<cfoutput>#qUserManagerUser.id#</cfoutput>"/><input type="hidden" name="return_tab" value="resultados"/>
                  <input class="form-control form-control-sm" type="number" min="1" name="result_id" placeholder="ID do resultado" required/><button class="btn btn-sm btn-outline-warning" type="submit">Vincular</button>
                </form>
              </cfif>
            </div>
            <div class="table-responsive"><table class="table table-hover user-manager-table mb-0"><thead><tr><th>ID</th><th>Evento</th><th>Resultado</th><th>Tempo</th><th class="user-manager-actions">Ação</th></tr></thead><tbody>
              <cfif qUserManagerResults.recordcount>
                <cfoutput query="qUserManagerResults"><tr><td class="user-manager-id" data-label="ID">#qUserManagerResults.id_resultado#</td><td data-label="Evento"><div class="fw-semibold">#htmlEditFormat(qUserManagerResults.nome_evento)#</div><div class="small text-muted">#dateFormat(qUserManagerResults.data_final,"dd/mm/yyyy")# · #htmlEditFormat(userManagerDisplayValue(qUserManagerResults.cidade))#/#htmlEditFormat(userManagerDisplayValue(qUserManagerResults.estado))#</div></td><td data-label="Resultado"><div>#htmlEditFormat(qUserManagerResults.nome)#</div><div class="small text-muted">#htmlEditFormat(userManagerDisplayValue(qUserManagerResults.modalidade))# · #userManagerDisplayValue(qUserManagerResults.percurso)# km · peito #userManagerDisplayValue(qUserManagerResults.num_peito)#</div></td><td data-label="Tempo">#userManagerDisplayValue(qUserManagerResults.tempo_total)#</td><td class="user-manager-actions" data-label="Ação"><cfif VARIABLES.userManagerCanMutateDetail><form method="post" action="./" data-confirm="Desvincular este resultado do usuário?"><input type="hidden" name="user_manager_action" value="desvincular_resultado"/><input type="hidden" name="user_manager_csrf" value="#VARIABLES.userManagerCsrf#"/><input type="hidden" name="user_id" value="#qUserManagerUser.id#"/><input type="hidden" name="return_tab" value="resultados"/><input type="hidden" name="result_id" value="#qUserManagerResults.id_resultado#"/><button class="btn btn-sm btn-outline-danger" type="submit"><i class="fa-solid fa-link-slash"></i></button></form></cfif></td></tr></cfoutput>
              <cfelse><tr><td colspan="5"><div class="user-manager-empty"><i class="fa-solid fa-medal fa-2x text-muted mb-3"></i><span class="text-muted">Nenhum resultado vinculado.</span></div></td></tr></cfif>
            </tbody></table></div>
          </div>
        </cfif>

        <cfif VARIABLES.userManagerShowingDetail AND VARIABLES.userManagerTab EQ "social">
          <div class="user-manager-panel p-3 p-lg-4">
            <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
              <div><h5 class="mb-1">Seguidores e seguindo</h5><p class="small text-muted mb-0">Cada vínculo conecta uma página de origem a uma página de destino.</p></div>
              <cfif VARIABLES.userManagerCanMutateDetail AND qUserManagerPages.recordcount>
                <form method="post" action="./" class="d-flex flex-wrap gap-2 align-items-end">
                  <input type="hidden" name="user_manager_action" value="adicionar_vinculo_social"/><input type="hidden" name="user_manager_csrf" value="<cfoutput>#VARIABLES.userManagerCsrf#</cfoutput>"/><input type="hidden" name="user_id" value="<cfoutput>#qUserManagerUser.id#</cfoutput>"/><input type="hidden" name="return_tab" value="social"/>
                  <div><label class="form-label small">Página deste usuário</label><select class="form-select form-select-sm" name="origin_page_id"><cfoutput query="qUserManagerPages"><option value="#qUserManagerPages.id_pagina#">#htmlEditFormat(qUserManagerPages.nome)#</option></cfoutput></select></div>
                  <div><label class="form-label small">Seguir página ID</label><input class="form-control form-control-sm" type="number" min="1" name="destination_page_id" required/></div>
                  <input type="hidden" name="vinculo_validado" value="true"/><button class="btn btn-sm btn-outline-warning" type="submit">Adicionar</button>
                </form>
              </cfif>
            </div>
            <div class="table-responsive"><table class="table table-hover user-manager-table mb-0"><thead><tr><th>Direção</th><th>Origem</th><th>Destino</th><th>Status</th><th>Data</th><th class="user-manager-actions">Ação</th></tr></thead><tbody>
              <cfif qUserManagerSocial.recordcount>
                <cfoutput query="qUserManagerSocial"><tr><td data-label="Direção"><span class="badge <cfif userManagerBoolean(qUserManagerSocial.usuario_seguindo)>badge-info<cfelse>badge-primary</cfif>"><cfif userManagerBoolean(qUserManagerSocial.usuario_seguindo)>Seguindo<cfelse>Seguidor</cfif></span></td><td data-label="Origem"><div class="fw-semibold">#htmlEditFormat(qUserManagerSocial.origem_nome)#</div><div class="small text-muted">Página ## #qUserManagerSocial.id_pagina_origem#</div></td><td data-label="Destino"><div class="fw-semibold">#htmlEditFormat(qUserManagerSocial.destino_nome)#</div><div class="small text-muted">Página ## #qUserManagerSocial.id_pagina_destino#</div></td><td data-label="Status"><span class="badge <cfif userManagerBoolean(qUserManagerSocial.vinculo_validado)>badge-success<cfelse>badge-warning</cfif>"><cfif userManagerBoolean(qUserManagerSocial.vinculo_validado)>Confirmado<cfelse>Pendente</cfif></span></td><td data-label="Data">#dateTimeFormat(qUserManagerSocial.data_cadastramento,"dd/mm/yyyy HH:nn")#</td><td class="user-manager-actions" data-label="Ação"><div class="d-flex gap-1"><cfif VARIABLES.userManagerCanMutateDetail AND NOT userManagerBoolean(qUserManagerSocial.vinculo_validado)><form method="post" action="./"><input type="hidden" name="user_manager_action" value="aprovar_vinculo_social"/><input type="hidden" name="user_manager_csrf" value="#VARIABLES.userManagerCsrf#"/><input type="hidden" name="user_id" value="#qUserManagerUser.id#"/><input type="hidden" name="return_tab" value="social"/><input type="hidden" name="origin_page_id" value="#qUserManagerSocial.id_pagina_origem#"/><input type="hidden" name="destination_page_id" value="#qUserManagerSocial.id_pagina_destino#"/><button class="btn btn-sm btn-outline-success" title="Aprovar"><i class="fa-solid fa-check"></i></button></form></cfif><cfif VARIABLES.userManagerCanMutateDetail><form method="post" action="./" data-confirm="Remover este relacionamento?"><input type="hidden" name="user_manager_action" value="remover_vinculo_social"/><input type="hidden" name="user_manager_csrf" value="#VARIABLES.userManagerCsrf#"/><input type="hidden" name="user_id" value="#qUserManagerUser.id#"/><input type="hidden" name="return_tab" value="social"/><input type="hidden" name="origin_page_id" value="#qUserManagerSocial.id_pagina_origem#"/><input type="hidden" name="destination_page_id" value="#qUserManagerSocial.id_pagina_destino#"/><button class="btn btn-sm btn-outline-danger" title="Remover"><i class="fa-solid fa-xmark"></i></button></form></cfif></div></td></tr></cfoutput>
              <cfelse><tr><td colspan="6"><div class="user-manager-empty"><i class="fa-solid fa-user-group fa-2x text-muted mb-3"></i><span class="text-muted">Nenhum relacionamento encontrado.</span></div></td></tr></cfif>
            </tbody></table></div>
          </div>
        </cfif>

        <cfif VARIABLES.userManagerShowingDetail AND VARIABLES.userManagerTab EQ "auditoria">
          <div class="user-manager-panel p-3 p-lg-4">
            <div class="mb-3"><h5 class="mb-1">Auditoria administrativa</h5><p class="small text-muted mb-0">Registro imutável das ações realizadas por este gerenciador.</p></div>
            <div class="table-responsive"><table class="table table-hover user-manager-table mb-0"><thead><tr><th>Data</th><th>Ação</th><th>Autor</th><th>Página</th><th>Origem</th></tr></thead><tbody>
              <cfif qUserManagerAudit.recordcount>
                <cfoutput query="qUserManagerAudit"><tr><td data-label="Data">#dateTimeFormat(qUserManagerAudit.data_criacao,"dd/mm/yyyy HH:nn:ss")#</td><td data-label="Ação"><span class="badge badge-secondary">#htmlEditFormat(replace(qUserManagerAudit.acao,"_"," ","all"))#</span></td><td data-label="Autor">#htmlEditFormat(userManagerDisplayValue(qUserManagerAudit.autor_nome, "Sistema"))#</td><td data-label="Página">#htmlEditFormat(userManagerDisplayValue(qUserManagerAudit.pagina_nome))#</td><td data-label="Origem"><span class="small">#htmlEditFormat(userManagerDisplayValue(qUserManagerAudit.endereco_ip))#</span></td></tr></cfoutput>
              <cfelse><tr><td colspan="5"><div class="user-manager-empty"><i class="fa-solid fa-shield-halved fa-2x text-muted mb-3"></i><span class="text-muted">Nenhum registro de auditoria.</span></div></td></tr></cfif>
            </tbody></table></div>
          </div>
        </cfif>
      <cfelse>
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-4">
          <div><h3 class="business-page-title mb-1">Administração - Usuários</h3><p class="text-muted mb-0">Gerencie contas, perfis e relacionamentos da plataforma em um único lugar.</p></div>
          <a class="btn btn-warning align-self-lg-start" href="./?novo=1"><i class="fa-solid fa-user-plus me-2"></i>Novo usuário</a>
        </div>

        <div class="row g-3 mb-4">
          <div class="col-6 col-lg"><div class="user-manager-metric"><div class="d-flex justify-content-between"><span class="small text-muted">Total</span><span class="user-manager-metric-icon"><i class="fa-solid fa-users"></i></span></div><div class="h3 mt-2 mb-0"><cfoutput>#LSNumberFormat(qUserManagerStats.total)#</cfoutput></div></div></div>
          <div class="col-6 col-lg"><div class="user-manager-metric"><div class="d-flex justify-content-between"><span class="small text-muted">Ativos</span><span class="user-manager-metric-icon"><i class="fa-solid fa-user-check"></i></span></div><div class="h3 mt-2 mb-0"><cfoutput>#LSNumberFormat(qUserManagerStats.ativos)#</cfoutput></div></div></div>
          <div class="col-6 col-lg"><div class="user-manager-metric"><div class="d-flex justify-content-between"><span class="small text-muted">Inativos</span><span class="user-manager-metric-icon"><i class="fa-solid fa-user-lock"></i></span></div><div class="h3 mt-2 mb-0"><cfoutput>#LSNumberFormat(qUserManagerStats.inativos)#</cfoutput></div></div></div>
          <div class="col-6 col-lg"><div class="user-manager-metric"><div class="d-flex justify-content-between"><span class="small text-muted">Excluídos</span><span class="user-manager-metric-icon"><i class="fa-solid fa-user-xmark"></i></span></div><div class="h3 mt-2 mb-0"><cfoutput>#LSNumberFormat(qUserManagerStats.excluidos)#</cfoutput></div></div></div>
          <div class="col-12 col-lg"><div class="user-manager-metric"><div class="d-flex justify-content-between"><span class="small text-muted">Com Strava</span><span class="user-manager-metric-icon"><i class="fa-brands fa-strava"></i></span></div><div class="h3 mt-2 mb-0"><cfoutput>#LSNumberFormat(qUserManagerStats.com_strava)#</cfoutput></div></div></div>
        </div>

        <form class="user-manager-panel p-3 mb-4" method="get" action="./">
          <div class="row g-3 align-items-end">
            <div class="col-12 col-lg-6"><label class="form-label">Buscar usuário</label><div class="input-group"><span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span><input class="form-control" name="busca" value="<cfoutput>#htmlEditFormat(VARIABLES.userManagerSearch)#</cfoutput>" placeholder="Nome, e-mail, username ou ID"/></div></div>
            <div class="col-6 col-lg-2"><label class="form-label">Status</label><select class="form-select" name="status"><option value="ativos" <cfif VARIABLES.userManagerStatus EQ "ativos">selected</cfif>>Ativos</option><option value="inativos" <cfif VARIABLES.userManagerStatus EQ "inativos">selected</cfif>>Inativos</option><option value="excluidos" <cfif VARIABLES.userManagerStatus EQ "excluidos">selected</cfif>>Excluídos</option><option value="todos" <cfif VARIABLES.userManagerStatus EQ "todos">selected</cfif>>Todos</option></select></div>
            <div class="col-6 col-lg-2"><label class="form-label">Perfil</label><select class="form-select" name="papel"><option value="todos">Todos</option><option value="admin" <cfif VARIABLES.userManagerRole EQ "admin">selected</cfif>>ADMIN</option><option value="dev" <cfif VARIABLES.userManagerRole EQ "dev">selected</cfif>>DEV</option><option value="partner" <cfif VARIABLES.userManagerRole EQ "partner">selected</cfif>>PARTNER</option><option value="com_strava" <cfif VARIABLES.userManagerRole EQ "com_strava">selected</cfif>>Com Strava</option><option value="sem_pagina" <cfif VARIABLES.userManagerRole EQ "sem_pagina">selected</cfif>>Sem página</option></select></div>
            <div class="col-12 col-lg-2"><button class="btn btn-outline-warning w-100" type="submit">Aplicar filtros</button></div>
          </div>
        </form>

        <div class="user-manager-panel p-2 p-lg-3">
          <div class="d-flex justify-content-between align-items-center px-2 pb-3"><span class="small text-muted"><cfoutput>#LSNumberFormat(VARIABLES.userManagerTotal)# usuário(s) encontrado(s)</cfoutput></span><span class="small text-muted"><cfoutput>Página #VARIABLES.userManagerPage# de #VARIABLES.userManagerPagesTotal#</cfoutput></span></div>
          <div class="table-responsive"><table class="table table-hover user-manager-table mb-0"><thead><tr><th>ID</th><th>Usuário</th><th>Status</th><th>Perfis</th><th>Resultados</th><th>Cadastro</th><th class="user-manager-actions">Ações</th></tr></thead><tbody>
            <cfif qUserManagerUsers.recordcount>
              <cfoutput query="qUserManagerUsers">
                <cfset VARIABLES.userManagerListAvatar = userManagerDisplayValue(qUserManagerUsers.imagem_usuario, userManagerDisplayValue(qUserManagerUsers.strava_profile, "/assets/user.png"))/>
                <tr>
                  <td class="user-manager-id" data-label="ID">#qUserManagerUsers.id#</td>
                  <td data-label="Usuário"><div class="d-flex align-items-center gap-2"><img class="user-manager-avatar-sm" src="#htmlEditFormat(VARIABLES.userManagerListAvatar)#" alt=""/><div><div class="fw-semibold">#htmlEditFormat(qUserManagerUsers.name)#</div><div class="small text-muted">#htmlEditFormat(qUserManagerUsers.email)#</div><div class="d-flex flex-wrap gap-1 mt-1"><cfif userManagerBoolean(qUserManagerUsers.is_admin)><span class="badge badge-warning">ADMIN</span></cfif><cfif userManagerBoolean(qUserManagerUsers.is_dev)><span class="badge badge-info">DEV</span></cfif><cfif userManagerBoolean(qUserManagerUsers.is_partner)><span class="badge badge-primary">PARTNER</span></cfif></div></div></div></td>
                  <td data-label="Status"><div class="d-flex align-items-center gap-2"><span class="user-manager-status-dot <cfif userManagerBoolean(qUserManagerUsers.gestao_excluido)>is-deleted<cfelseif NOT userManagerBoolean(qUserManagerUsers.gestao_ativo)>is-inactive</cfif>"></span><span><cfif userManagerBoolean(qUserManagerUsers.gestao_excluido)>Excluído<cfelseif userManagerBoolean(qUserManagerUsers.gestao_ativo)>Ativo<cfelse>Inativo</cfif></span></div></td>
                  <td data-label="Perfis"><div class="fw-semibold">#LSNumberFormat(qUserManagerUsers.total_paginas)#</div><cfif len(trim(qUserManagerUsers.pagina_principal & ""))><div class="small text-muted">#htmlEditFormat(qUserManagerUsers.pagina_principal)#</div></cfif></td>
                  <td data-label="Resultados">#LSNumberFormat(qUserManagerUsers.total_resultados)#</td>
                  <td data-label="Cadastro"><span class="small">#dateFormat(qUserManagerUsers.data_criacao,"dd/mm/yyyy")#</span></td>
                  <td class="user-manager-actions" data-label="Ações"><div class="d-flex gap-1"><a class="btn btn-sm btn-outline-warning" href="./?user_id=#qUserManagerUsers.id#" title="Abrir ficha"><i class="fa-solid fa-pen-to-square"></i></a><cfif userManagerBoolean(qUserManagerUsers.gestao_ativo) AND !userManagerBoolean(qUserManagerUsers.gestao_excluido)><form method="post" action="./" target="_blank" class="m-0"><input type="hidden" name="user_manager_action" value="logar_como_dev"/><input type="hidden" name="user_manager_csrf" value="#htmlEditFormat(VARIABLES.userManagerCsrf)#"/><input type="hidden" name="user_id" value="#qUserManagerUsers.id#"/><input type="hidden" name="return_tab" value="conta"/><button class="btn btn-sm btn-outline-secondary" type="submit" title="Logar como no DEV"><i class="fa-solid fa-user-secret"></i></button></form></cfif></div></td>
                </tr>
              </cfoutput>
            <cfelse><tr><td colspan="7"><div class="user-manager-empty"><i class="fa-solid fa-user-slash fa-2x text-muted mb-3"></i><h6>Nenhum usuário encontrado</h6><p class="small text-muted mb-0">Ajuste os filtros ou crie uma nova conta.</p></div></td></tr></cfif>
          </tbody></table></div>

          <cfif VARIABLES.userManagerPagesTotal GT 1>
            <nav class="d-flex justify-content-center pt-3" aria-label="Paginação de usuários"><ul class="pagination pagination-sm mb-0">
              <cfset VARIABLES.userManagerPageStart = max(1, VARIABLES.userManagerPage - 2)/><cfset VARIABLES.userManagerPageEnd = min(VARIABLES.userManagerPagesTotal, VARIABLES.userManagerPage + 2)/>
              <cfoutput><li class="page-item <cfif VARIABLES.userManagerPage LTE 1>disabled</cfif>"><a class="page-link" href="./?pagina=#max(1,VARIABLES.userManagerPage-1)#&amp;busca=#urlEncodedFormat(VARIABLES.userManagerSearch)#&amp;status=#VARIABLES.userManagerStatus#&amp;papel=#VARIABLES.userManagerRole#">Anterior</a></li></cfoutput>
              <cfloop from="#VARIABLES.userManagerPageStart#" to="#VARIABLES.userManagerPageEnd#" index="VARIABLES.userManagerPageIndex"><cfoutput><li class="page-item <cfif VARIABLES.userManagerPageIndex EQ VARIABLES.userManagerPage>active</cfif>"><a class="page-link" href="./?pagina=#VARIABLES.userManagerPageIndex#&amp;busca=#urlEncodedFormat(VARIABLES.userManagerSearch)#&amp;status=#VARIABLES.userManagerStatus#&amp;papel=#VARIABLES.userManagerRole#">#VARIABLES.userManagerPageIndex#</a></li></cfoutput></cfloop>
              <cfoutput><li class="page-item <cfif VARIABLES.userManagerPage GTE VARIABLES.userManagerPagesTotal>disabled</cfif>"><a class="page-link" href="./?pagina=#min(VARIABLES.userManagerPagesTotal,VARIABLES.userManagerPage+1)#&amp;busca=#urlEncodedFormat(VARIABLES.userManagerSearch)#&amp;status=#VARIABLES.userManagerStatus#&amp;papel=#VARIABLES.userManagerRole#">Próxima</a></li></cfoutput>
            </ul></nav>
          </cfif>
        </div>
      </cfif>
    </div>
  </div>
</section>

<script>
document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll("form[data-confirm]").forEach(function (form) {
    form.addEventListener("submit", function (event) {
      if (!window.confirm(form.getAttribute("data-confirm"))) {
        event.preventDefault();
      }
    });
  });
});
</script>
