<cfset VARIABLES.accountsUsingPostedAccount = len(trim(VARIABLES.accountsSaveErrorMessage))
    AND isDefined("FORM.account_action")
    AND FORM.account_action EQ "salvar"/>
<cfset VARIABLES.accountsShowForm = VARIABLES.businessAccountsCanAdminAll
    AND (VARIABLES.accountsUsingPostedAccount
    OR (isDefined("URL.conta_nova") AND URL.conta_nova)
    OR (isDefined("URL.editar_conta") AND URL.editar_conta AND qBusinessAccountEdit.recordcount))/>

<cfif VARIABLES.accountsUsingPostedAccount>
    <cfset VARIABLES.accountFormId = isDefined("FORM.id_conta") ? trim(FORM.id_conta) : ""/>
    <cfset VARIABLES.accountFormNome = isDefined("FORM.nome_conta") ? trim(FORM.nome_conta) : ""/>
    <cfset VARIABLES.accountFormTipoTitular = isDefined("FORM.tipo_titular") ? uCase(trim(FORM.tipo_titular)) : "PJ"/>
    <cfset VARIABLES.accountFormDocumento = isDefined("FORM.documento") ? trim(FORM.documento) : ""/>
    <cfset VARIABLES.accountFormNomeTitular = isDefined("FORM.nome_titular") ? trim(FORM.nome_titular) : ""/>
    <cfset VARIABLES.accountFormEmail = isDefined("FORM.email_principal") ? trim(FORM.email_principal) : ""/>
    <cfset VARIABLES.accountFormTelefone = isDefined("FORM.telefone_principal") ? trim(FORM.telefone_principal) : ""/>
    <cfset VARIABLES.accountFormStatus = isDefined("FORM.status") ? uCase(trim(FORM.status)) : "PENDENTE"/>
<cfelseif qBusinessAccountEdit.recordcount>
    <cfset VARIABLES.accountFormId = qBusinessAccountEdit.id_conta/>
    <cfset VARIABLES.accountFormNome = qBusinessAccountEdit.nome_conta/>
    <cfset VARIABLES.accountFormTipoTitular = qBusinessAccountEdit.tipo_titular/>
    <cfset VARIABLES.accountFormDocumento = qBusinessAccountEdit.documento/>
    <cfset VARIABLES.accountFormNomeTitular = qBusinessAccountEdit.nome_titular/>
    <cfset VARIABLES.accountFormEmail = qBusinessAccountEdit.email_principal/>
    <cfset VARIABLES.accountFormTelefone = qBusinessAccountEdit.telefone_principal/>
    <cfset VARIABLES.accountFormStatus = qBusinessAccountEdit.status/>
<cfelse>
    <cfset VARIABLES.accountFormId = ""/>
    <cfset VARIABLES.accountFormNome = ""/>
    <cfset VARIABLES.accountFormTipoTitular = "PJ"/>
    <cfset VARIABLES.accountFormDocumento = ""/>
    <cfset VARIABLES.accountFormNomeTitular = ""/>
    <cfset VARIABLES.accountFormEmail = ""/>
    <cfset VARIABLES.accountFormTelefone = ""/>
    <cfset VARIABLES.accountFormStatus = "PENDENTE"/>
</cfif>

<cfset VARIABLES.accountManagementTab = lCase(trim(URL.tab))/>
<cfif NOT listFindNoCase("usuarios,vouchers,eventos", VARIABLES.accountManagementTab)>
    <cfif len(trim(URL.evento_busca)) OR (isDefined("URL.sucesso") AND listFindNoCase("evento,evento_removido", URL.sucesso))>
        <cfset VARIABLES.accountManagementTab = "eventos"/>
    <cfelseif isDefined("URL.sucesso") AND URL.sucesso EQ "voucher">
        <cfset VARIABLES.accountManagementTab = "vouchers"/>
    <cfelse>
        <cfset VARIABLES.accountManagementTab = "usuarios"/>
    </cfif>
</cfif>
<cfif VARIABLES.accountManagementTab EQ "vouchers" AND NOT VARIABLES.businessAccountsCanAdminAll>
    <cfset VARIABLES.accountManagementTab = "usuarios"/>
</cfif>

<style>
  .accounts-page .accounts-kpis {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: .75rem;
  }

  .accounts-page .accounts-kpi {
    border: 1px solid rgba(255,255,255,.1);
    border-radius: 8px;
    padding: .9rem 1rem;
    background: rgba(255,255,255,.03);
  }

  .accounts-page .accounts-kpi-label {
    color: var(--mdb-secondary-color);
    font-size: .78rem;
    text-transform: uppercase;
    letter-spacing: 0;
  }

  .accounts-page .accounts-kpi-value {
    font-size: 1.6rem;
    font-weight: 700;
    line-height: 1.1;
  }

  .accounts-page .accounts-panel {
    border: 1px solid rgba(255,255,255,.1);
    border-radius: 8px;
    background: rgba(255,255,255,.025);
  }

  .accounts-page .accounts-table td,
  .accounts-page .accounts-table th {
    vertical-align: middle;
  }

  .accounts-page .accounts-cell {
    max-width: 300px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .accounts-page .accounts-status {
    display: inline-flex;
    align-items: center;
    border-radius: 999px;
    padding: .2rem .55rem;
    font-size: .76rem;
    border: 1px solid rgba(255,255,255,.16);
  }

  .accounts-page .accounts-user-row {
    display: grid;
    grid-template-columns: minmax(220px, 1fr) 150px 150px auto;
    gap: .75rem;
    align-items: center;
    padding: .9rem 0;
    border-bottom: 1px solid rgba(255,255,255,.08);
  }

  .accounts-page .accounts-user-row:last-child {
    border-bottom: 0;
  }

  .accounts-page .accounts-user-row .accounts-cell {
    max-width: none;
    min-width: 0;
  }

  .accounts-page .accounts-event-row {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: .75rem;
    align-items: start;
    padding: .7rem 0;
    border-bottom: 1px solid rgba(255,255,255,.08);
  }

  .accounts-page .accounts-event-row:last-child {
    border-bottom: 0;
  }

  .accounts-page .accounts-registration-row {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(260px, 360px);
    gap: 1rem;
    padding: 1rem 0;
    border-bottom: 1px solid rgba(255,255,255,.08);
  }

  .accounts-page .accounts-registration-row:last-child {
    border-bottom: 0;
  }

  .accounts-page .accounts-registration-actions {
    display: grid;
    gap: .75rem;
  }

  .accounts-page .accounts-request-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: .35rem .9rem;
    margin-top: .75rem;
  }

  .accounts-page .accounts-request-label {
    color: var(--mdb-secondary-color);
    display: block;
    font-size: .72rem;
    line-height: 1.2;
    margin-bottom: .1rem;
    text-transform: uppercase;
  }

  .accounts-page .accounts-request-value {
    overflow-wrap: anywhere;
  }

  .accounts-page .accounts-action-title {
    color: var(--mdb-secondary-color);
    font-size: .78rem;
    font-weight: 700;
    letter-spacing: 0;
    margin-bottom: .75rem;
    text-transform: uppercase;
  }

  .accounts-page .accounts-danger-panel {
    border-color: rgba(255, 56, 96, .45);
    background: rgba(255, 56, 96, .035);
  }

  .accounts-page .accounts-empty-state {
    min-height: 230px;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }

  .accounts-page .accounts-scroll-list {
    max-height: 540px;
    overflow: auto;
    padding-right: .35rem;
  }

  .accounts-page .accounts-scroll-list::-webkit-scrollbar {
    width: 8px;
  }

  .accounts-page .accounts-scroll-list::-webkit-scrollbar-thumb {
    background: rgba(255,255,255,.18);
    border-radius: 999px;
  }

  .accounts-page .accounts-event-actions {
    display: flex;
    flex-wrap: wrap;
    gap: .45rem;
    align-items: center;
  }

  .accounts-page .accounts-event-actions .form-select {
    width: auto;
    min-width: 118px;
  }

  .accounts-page .accounts-management-header {
    display: flex;
    gap: 1rem;
    justify-content: space-between;
    align-items: flex-start;
    border-bottom: 1px solid rgba(255,255,255,.08);
    padding-bottom: 1rem;
    margin-bottom: 1.25rem;
  }

  .accounts-page .accounts-management-meta {
    display: flex;
    flex-wrap: wrap;
    gap: .5rem;
  }

  .accounts-page .accounts-management-tabs .nav-link {
    color: var(--mdb-secondary-color);
  }

  .accounts-page .accounts-management-tabs .nav-link.active {
    background: rgba(255,255,255,.08);
    border-color: rgba(255,255,255,.18);
    color: var(--mdb-body-color);
  }

  .accounts-page .accounts-tab-panel.d-none {
    display: none !important;
  }

  @media (max-width: 991.98px) {
    .accounts-page .accounts-user-row,
    .accounts-page .accounts-event-row,
    .accounts-page .accounts-registration-row {
      grid-template-columns: 1fr;
    }

    .accounts-page .accounts-request-grid {
      grid-template-columns: 1fr;
    }

    .accounts-page .accounts-management-header {
      flex-direction: column;
    }
  }
</style>

<section class="accounts-page">
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1"><cfif VARIABLES.businessAccountsCanAdminAll>Administração de contas<cfelse>Minha conta</cfif></h3>
              <p class="text-muted mb-0">
                <cfif VARIABLES.businessAccountsCanAdminAll>
                  Cadastre empresas, aprove solicitações de acesso e gerencie usuários e eventos vinculados.
                <cfelse>
                  Gerencie os usuários vinculados à sua conta Business e acompanhe os eventos já aprovados.
                </cfif>
              </p>
            </div>
            <cfif VARIABLES.businessAccountsCanAdminAll>
              <div class="text-lg-end">
                <cfoutput><a class="btn btn-warning" href="./?conta_nova=1&busca=#urlEncodedFormat(URL.busca)#">Nova conta</a></cfoutput>
              </div>
            </cfif>
          </div>

          <hr/>

          <div class="accounts-kpis mb-4">
            <div class="accounts-kpi">
              <div class="accounts-kpi-label">Contas</div>
              <div class="accounts-kpi-value"><cfoutput>#LSNumberFormat(VARIABLES.accountsTotal)#</cfoutput></div>
            </div>
            <div class="accounts-kpi">
              <div class="accounts-kpi-label">Ativas</div>
              <div class="accounts-kpi-value"><cfoutput>#LSNumberFormat(VARIABLES.accountsActiveTotal)#</cfoutput></div>
            </div>
            <div class="accounts-kpi">
              <div class="accounts-kpi-label">Pendentes</div>
              <div class="accounts-kpi-value"><cfoutput>#LSNumberFormat(VARIABLES.accountsPendingTotal)#</cfoutput></div>
            </div>
            <cfif VARIABLES.businessAccountsCanAdminAll>
              <div class="accounts-kpi">
                <div class="accounts-kpi-label">Solicitações</div>
                <div class="accounts-kpi-value"><cfoutput>#LSNumberFormat(VARIABLES.accountsRegistrationPendingTotal)#</cfoutput></div>
              </div>
            </cfif>
            <div class="accounts-kpi">
              <div class="accounts-kpi-label">Usuários vinculados</div>
              <div class="accounts-kpi-value"><cfoutput>#LSNumberFormat(VARIABLES.accountsLinkedUsersTotal)#</cfoutput></div>
            </div>
            <div class="accounts-kpi">
              <div class="accounts-kpi-label">Eventos ativos</div>
              <div class="accounts-kpi-value"><cfoutput>#LSNumberFormat(VARIABLES.accountsLinkedEventsTotal)#</cfoutput></div>
            </div>
          </div>

          <cfif len(trim(VARIABLES.accountsNoticeMessage))>
            <div class="alert alert-success" role="alert">
              <cfoutput>#htmlEditFormat(VARIABLES.accountsNoticeMessage)#</cfoutput>
            </div>
          </cfif>

          <cfif NOT VARIABLES.businessAccountsTablesReady>
            <div class="alert alert-warning" role="alert">
              <strong>Estrutura pendente.</strong> Aplique as tabelas de contas, usuários e eventos para liberar o cadastro.
            </div>
          </cfif>

          <cfif VARIABLES.businessAccountsCanAdminAll AND VARIABLES.businessAccountsTablesReady AND NOT VARIABLES.businessAccountRegistrationTableReady>
            <div class="alert alert-warning" role="alert">
              <strong>Estrutura pendente.</strong> Aplique a tabela de solicitações para revisar cadastros externos.
            </div>
          </cfif>

          <cfif len(trim(VARIABLES.accountsSaveErrorMessage)) AND VARIABLES.businessAccountsTablesReady>
            <div class="alert alert-danger" role="alert">
              <cfoutput>#htmlEditFormat(VARIABLES.accountsSaveErrorMessage)#</cfoutput>
            </div>
          </cfif>

          <cfif len(trim(VARIABLES.accountsUserSaveErrorMessage))>
            <div class="alert alert-danger" role="alert">
              <cfoutput>#htmlEditFormat(VARIABLES.accountsUserSaveErrorMessage)#</cfoutput>
            </div>
          </cfif>

          <cfif len(trim(VARIABLES.accountsEventSaveErrorMessage))>
            <div class="alert alert-danger" role="alert">
              <cfoutput>#htmlEditFormat(VARIABLES.accountsEventSaveErrorMessage)#</cfoutput>
            </div>
          </cfif>

          <cfif len(trim(VARIABLES.accountsRegistrationSaveErrorMessage))>
            <div class="alert alert-danger" role="alert">
              <cfoutput>#htmlEditFormat(VARIABLES.accountsRegistrationSaveErrorMessage)#</cfoutput>
            </div>
          </cfif>

          <cfif len(trim(VARIABLES.accountsVoucherSaveErrorMessage))>
            <div class="alert alert-danger" role="alert">
              <cfoutput>#htmlEditFormat(VARIABLES.accountsVoucherSaveErrorMessage)#</cfoutput>
            </div>
          </cfif>

          <cfif VARIABLES.businessAccountsCanAdminAll>
            <div class="accounts-panel p-3 mb-4">
              <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                <div>
                  <h5 class="mb-1">Solicitações de acesso</h5>
                  <div class="text-muted small">
                    <cfoutput>#LSNumberFormat(VARIABLES.accountsRegistrationPendingTotal)# pendentes de #LSNumberFormat(VARIABLES.accountsRegistrationTotal)# solicitações</cfoutput>
                  </div>
                </div>
                <a class="btn btn-sm btn-outline-warning align-self-start" href="/cadastro/" target="_blank">Abrir cadastro público</a>
              </div>

              <cfif NOT VARIABLES.businessAccountRegistrationTableReady>
                <div class="text-muted py-3">A fila será exibida depois que a estrutura de solicitações for aplicada.</div>
              <cfelseif qBusinessAccountRegistrationRequests.recordcount>
                <cfoutput query="qBusinessAccountRegistrationRequests">
                  <div class="accounts-registration-row">
                    <div class="accounts-cell">
                      <div class="d-flex flex-wrap align-items-center gap-2 mb-2">
                        <span class="accounts-status">## #qBusinessAccountRegistrationRequests.id_solicitacao#</span>
                        <span class="accounts-status">#htmlEditFormat(qBusinessAccountRegistrationRequests.tipo_prestador)#</span>
                        <span class="accounts-status">#htmlEditFormat(qBusinessAccountRegistrationRequests.tipo_titular)#</span>
                        <cfif len(trim(qBusinessAccountRegistrationRequests.voucher_codigo))>
                          <span class="accounts-status">Voucher #htmlEditFormat(qBusinessAccountRegistrationRequests.voucher_codigo)#</span>
                        </cfif>
                      </div>
                      <div class="fw-bold fs-6">#htmlEditFormat(qBusinessAccountRegistrationRequests.nome_empresa)#</div>
                      <div class="accounts-request-grid small">
                        <div>
                          <span class="accounts-request-label">Documento</span>
                          <span class="accounts-request-value">#htmlEditFormat(qBusinessAccountRegistrationRequests.documento)#</span>
                        </div>
                        <div>
                          <span class="accounts-request-label">Responsável</span>
                          <span class="accounts-request-value">#htmlEditFormat(qBusinessAccountRegistrationRequests.nome_responsavel)#</span>
                        </div>
                        <div>
                          <span class="accounts-request-label">E-mail</span>
                          <span class="accounts-request-value">#htmlEditFormat(qBusinessAccountRegistrationRequests.email_responsavel)#</span>
                        </div>
                        <cfif len(trim(qBusinessAccountRegistrationRequests.telefone_responsavel))>
                          <div>
                            <span class="accounts-request-label">Telefone</span>
                            <span class="accounts-request-value">#htmlEditFormat(qBusinessAccountRegistrationRequests.telefone_responsavel)#</span>
                          </div>
                        </cfif>
                        <cfif len(trim(qBusinessAccountRegistrationRequests.cidade)) OR len(trim(qBusinessAccountRegistrationRequests.estado))>
                          <div>
                            <span class="accounts-request-label">Local</span>
                            <span class="accounts-request-value">#htmlEditFormat(qBusinessAccountRegistrationRequests.cidade)#<cfif len(trim(qBusinessAccountRegistrationRequests.estado))>/#htmlEditFormat(qBusinessAccountRegistrationRequests.estado)#</cfif></span>
                          </div>
                        </cfif>
                        <cfif len(trim(qBusinessAccountRegistrationRequests.site))>
                          <cfset VARIABLES.accountRegistrationSiteUrl = trim(qBusinessAccountRegistrationRequests.site)/>
                          <cfif NOT reFindNoCase("^https?://", VARIABLES.accountRegistrationSiteUrl)>
                            <cfset VARIABLES.accountRegistrationSiteUrl = "https://" & VARIABLES.accountRegistrationSiteUrl/>
                          </cfif>
                          <div>
                            <span class="accounts-request-label">Site</span>
                            <span class="accounts-request-value"><a href="#htmlEditFormat(VARIABLES.accountRegistrationSiteUrl)#" target="_blank" rel="noopener">#htmlEditFormat(qBusinessAccountRegistrationRequests.site)#</a></span>
                          </div>
                        </cfif>
                        <cfif len(trim(qBusinessAccountRegistrationRequests.voucher_codigo))>
                          <div>
                            <span class="accounts-request-label">Voucher</span>
                            <span class="accounts-request-value">#htmlEditFormat(qBusinessAccountRegistrationRequests.voucher_codigo)#<cfif len(trim(qBusinessAccountRegistrationRequests.voucher_credito))> - #LSCurrencyFormat(qBusinessAccountRegistrationRequests.voucher_credito)#</cfif></span>
                          </div>
                        </cfif>
                      </div>
                      <cfif len(trim(qBusinessAccountRegistrationRequests.mensagem))>
                        <div class="small mt-3">
                          <span class="accounts-request-label">Mensagem</span>
                          #htmlEditFormat(qBusinessAccountRegistrationRequests.mensagem)#
                        </div>
                      </cfif>
                      <div class="small text-muted mt-2">Criada em #dateTimeFormat(qBusinessAccountRegistrationRequests.data_criacao, "dd/mm/yyyy HH:nn")#</div>
                    </div>

                    <div class="accounts-registration-actions">
                      <form method="post" action="./" class="accounts-panel p-3">
                        <div class="accounts-action-title">Aprovação</div>
                        <input type="hidden" name="account_registration_action" value="aprovar"/>
                        <input type="hidden" name="id_solicitacao" value="#qBusinessAccountRegistrationRequests.id_solicitacao#"/>

                        <label class="form-label small">Associar a uma conta existente</label>
                        <select class="form-select form-select-sm mb-2" name="id_conta_existente">
                          <option value="">Criar nova conta</option>
                          <cfloop query="qBusinessAccountRegistrationAccountOptions">
                            <option value="#qBusinessAccountRegistrationAccountOptions.id_conta#">## #qBusinessAccountRegistrationAccountOptions.id_conta# - #htmlEditFormat(qBusinessAccountRegistrationAccountOptions.nome_conta)# - #htmlEditFormat(qBusinessAccountRegistrationAccountOptions.documento)# (#htmlEditFormat(qBusinessAccountRegistrationAccountOptions.status)#)</option>
                          </cfloop>
                        </select>

                        <label class="form-label small">Nota da aprovação</label>
                        <textarea class="form-control form-control-sm mb-2" name="observacao_revisor" rows="2"></textarea>

                        <button class="btn btn-sm btn-warning w-100" type="submit">Aprovar</button>
                      </form>

                      <form method="post" action="./" class="accounts-panel accounts-danger-panel p-3" onsubmit="return confirm('Recusar esta solicitação?');">
                        <div class="accounts-action-title">Recusa</div>
                        <input type="hidden" name="account_registration_action" value="recusar"/>
                        <input type="hidden" name="id_solicitacao" value="#qBusinessAccountRegistrationRequests.id_solicitacao#"/>

                        <label class="form-label small">Motivo da recusa</label>
                        <textarea class="form-control form-control-sm mb-2" name="observacao_revisor" rows="2"></textarea>

                        <button class="btn btn-sm btn-outline-danger w-100" type="submit">Recusar</button>
                      </form>
                    </div>
                  </div>
                </cfoutput>
              <cfelse>
                <div class="text-muted py-3">Nenhuma solicitação pendente.</div>
              </cfif>
            </div>
          </cfif>

          <cfif VARIABLES.businessAccountsCanAdminAll OR qBusinessAccountList.recordcount GT 1 OR len(trim(URL.busca)) GT 0>
            <cfoutput>
              <form method="get" action="./" class="mb-4">
                <div class="row g-3 align-items-end">
                  <div class="col-12 col-lg-9">
                    <label class="form-label">Buscar conta</label>
                    <input class="form-control" type="text" name="busca" value="#htmlEditFormat(URL.busca)#" placeholder="Nome, titular, documento ou e-mail"/>
                  </div>
                  <div class="col-12 col-lg-3">
                    <button class="btn btn-outline-warning w-100" type="submit">Buscar</button>
                  </div>
                </div>
              </form>
            </cfoutput>
          </cfif>

          <cfif VARIABLES.accountsShowForm AND VARIABLES.businessAccountsTablesReady>
            <div class="accounts-panel p-4 mb-4">
              <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                <div>
                  <h5 class="mb-1"><cfif len(VARIABLES.accountFormId)>Editar conta<cfelse>Nova conta</cfif></h5>
                  <p class="text-muted small mb-0">A conta representa a empresa titular do acesso Business.</p>
                </div>
                <cfoutput>
                  <a class="btn btn-sm btn-outline-secondary" href="./?<cfif len(VARIABLES.accountFormId)>conta_id=#urlEncodedFormat(VARIABLES.accountFormId)#&</cfif>busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage#<cfif len(VARIABLES.accountFormId)>##conta-gerenciamento</cfif>">Fechar</a>
                </cfoutput>
              </div>

              <cfoutput>
                <form method="post" action="./?<cfif len(VARIABLES.accountFormId)>conta_id=#urlEncodedFormat(VARIABLES.accountFormId)#&editar_conta=1&</cfif>busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage#<cfif len(VARIABLES.accountFormId)>##conta-gerenciamento</cfif>">
                  <input type="hidden" name="account_action" value="salvar"/>
                  <input type="hidden" name="id_conta" value="#htmlEditFormat(VARIABLES.accountFormId)#"/>

                  <div class="row g-3">
                    <div class="col-12 col-lg-6">
                      <label class="form-label">Nome da conta</label>
                      <input class="form-control" type="text" name="nome_conta" value="#htmlEditFormat(VARIABLES.accountFormNome)#" maxlength="160" required/>
                    </div>

                    <div class="col-12 col-lg-3">
                      <label class="form-label">Titular</label>
                      <select class="form-select" name="tipo_titular" required>
              </cfoutput>
                        <cfloop list="#VARIABLES.accountTipoTitularList#" item="accountTipoOption">
                          <cfoutput><option value="#accountTipoOption#" <cfif VARIABLES.accountFormTipoTitular EQ accountTipoOption>selected</cfif>>#accountTipoOption#</option></cfoutput>
                        </cfloop>
              <cfoutput>
                      </select>
                    </div>

                    <div class="col-12 col-lg-3">
                      <label class="form-label">Status</label>
                      <select class="form-select" name="status" required>
              </cfoutput>
                        <cfloop list="#VARIABLES.accountStatusList#" item="accountStatusOption">
                          <cfoutput><option value="#accountStatusOption#" <cfif VARIABLES.accountFormStatus EQ accountStatusOption>selected</cfif>>#accountStatusOption#</option></cfoutput>
                        </cfloop>
              <cfoutput>
                      </select>
                    </div>

                    <div class="col-12 col-lg-4">
                      <label class="form-label">Documento</label>
                      <input class="form-control" type="text" name="documento" value="#htmlEditFormat(VARIABLES.accountFormDocumento)#" maxlength="20" required/>
                    </div>

                    <div class="col-12 col-lg-8">
                      <label class="form-label">Nome do titular</label>
                      <input class="form-control" type="text" name="nome_titular" value="#htmlEditFormat(VARIABLES.accountFormNomeTitular)#" maxlength="200" required/>
                    </div>

                    <div class="col-12 col-lg-6">
                      <label class="form-label">E-mail principal</label>
                      <input class="form-control" type="email" name="email_principal" value="#htmlEditFormat(VARIABLES.accountFormEmail)#" maxlength="255"/>
                    </div>

                    <div class="col-12 col-lg-6">
                      <label class="form-label">Telefone principal</label>
                      <input class="form-control" type="text" name="telefone_principal" value="#htmlEditFormat(VARIABLES.accountFormTelefone)#" maxlength="30"/>
                    </div>

                    <div class="col-12 d-flex flex-column flex-lg-row gap-2 justify-content-between">
                      <div>
                        <button type="submit" class="btn btn-warning">Salvar conta</button>
                        <a class="btn btn-outline-secondary" href="./?<cfif len(VARIABLES.accountFormId)>conta_id=#urlEncodedFormat(VARIABLES.accountFormId)#&</cfif>busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage#<cfif len(VARIABLES.accountFormId)>##conta-gerenciamento</cfif>">Cancelar</a>
                      </div>
                    </div>
                  </div>
                </form>
              </cfoutput>

              <cfif len(VARIABLES.accountFormId)>
                <cfoutput>
                  <form method="post" action="./" class="mt-3" onsubmit="return confirm('Excluir esta conta? Os vínculos de usuários também serão removidos.');">
                    <input type="hidden" name="account_action" value="excluir"/>
                    <input type="hidden" name="id_conta" value="#htmlEditFormat(VARIABLES.accountFormId)#"/>
                    <button type="submit" class="btn btn-outline-danger btn-sm">Excluir conta</button>
                  </form>
                </cfoutput>
              </cfif>
            </div>
          </cfif>

          <div class="row g-4">
            <div class="col-12">
              <div class="accounts-panel p-3">
                <div class="d-flex justify-content-between align-items-center mb-3">
                  <div>
                    <h5 class="mb-1"><cfif VARIABLES.businessAccountsCanAdminAll>Contas cadastradas<cfelse>Contas da empresa</cfif></h5>
                    <div class="small text-muted"><cfoutput>#LSNumberFormat(VARIABLES.accountsFilteredTotal)# contas encontradas</cfoutput></div>
                  </div>
                  <div class="small text-muted"><cfoutput>Página #VARIABLES.accountsPage# de #VARIABLES.accountsTotalPages#</cfoutput></div>
                </div>

                <div class="table-responsive">
                  <table class="table table-sm accounts-table align-middle mb-0">
                    <thead>
                      <tr>
                        <th>Conta</th>
                        <th>Documento</th>
                        <th>Status</th>
                        <th>Usuários</th>
                        <th>Eventos</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfif qBusinessAccountList.recordcount>
                        <cfoutput query="qBusinessAccountList">
                          <tr <cfif qBusinessAccountEdit.recordcount AND qBusinessAccountList.id_conta EQ qBusinessAccountEdit.id_conta>class="table-active"</cfif>>
                            <td class="accounts-cell">
                              <div class="fw-bold">#htmlEditFormat(qBusinessAccountList.nome_conta)#</div>
                              <div class="small text-muted">#htmlEditFormat(qBusinessAccountList.nome_titular)#</div>
                              <cfif len(trim(qBusinessAccountList.email_principal))>
                                <div class="small text-muted">#htmlEditFormat(qBusinessAccountList.email_principal)#</div>
                              </cfif>
                            </td>
                            <td>
                              <div>#htmlEditFormat(qBusinessAccountList.documento)#</div>
                              <div class="small text-muted">#htmlEditFormat(qBusinessAccountList.tipo_titular)#</div>
                            </td>
                            <td><span class="accounts-status">#htmlEditFormat(qBusinessAccountList.status)#</span></td>
                            <td>
                              <div>#LSNumberFormat(qBusinessAccountList.total_usuarios)#</div>
                              <div class="small text-muted">#LSNumberFormat(qBusinessAccountList.usuarios_ativos)# ativos</div>
                            </td>
                            <td>
                              <div>#LSNumberFormat(qBusinessAccountList.total_eventos)#</div>
                              <div class="small text-muted">#LSNumberFormat(qBusinessAccountList.eventos_ativos)# ativos</div>
                            </td>
                            <td class="text-end">
                              <a class="btn btn-sm btn-outline-warning" href="./?conta_id=#qBusinessAccountList.id_conta#&busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage###conta-gerenciamento">Gerenciar</a>
                            </td>
                          </tr>
                        </cfoutput>
                      <cfelse>
                        <tr>
                          <td colspan="6" class="text-muted py-4">Nenhuma conta encontrada.</td>
                        </tr>
                      </cfif>
                    </tbody>
                  </table>
                </div>

                <cfif VARIABLES.accountsTotalPages GT 1>
                  <div class="d-flex justify-content-between align-items-center mt-3">
                    <cfoutput>
                      <a class="btn btn-sm btn-outline-secondary <cfif VARIABLES.accountsPage LTE 1>disabled</cfif>" href="./?pagina=#max(1, VARIABLES.accountsPage - 1)#&busca=#urlEncodedFormat(URL.busca)#">Anterior</a>
                      <a class="btn btn-sm btn-outline-secondary <cfif VARIABLES.accountsPage GTE VARIABLES.accountsTotalPages>disabled</cfif>" href="./?pagina=#min(VARIABLES.accountsTotalPages, VARIABLES.accountsPage + 1)#&busca=#urlEncodedFormat(URL.busca)#">Próxima</a>
                    </cfoutput>
                  </div>
                </cfif>
              </div>
            </div>

            <div class="col-12">
              <div class="accounts-panel p-3" id="conta-gerenciamento">
                <cfif qBusinessAccountEdit.recordcount>
                  <div class="accounts-management-header">
                    <div>
                      <div class="accounts-action-title mb-1">Conta selecionada</div>
                      <h4 class="mb-2"><cfoutput>#htmlEditFormat(qBusinessAccountEdit.nome_conta)#</cfoutput></h4>
                      <div class="accounts-management-meta small text-muted">
                        <cfoutput>
                          <span>Documento: #htmlEditFormat(qBusinessAccountEdit.documento)#</span>
                          <span>Titular: #htmlEditFormat(qBusinessAccountEdit.nome_titular)#</span>
                          <span>Status: #htmlEditFormat(qBusinessAccountEdit.status)#</span>
                          <span>#LSNumberFormat(qBusinessAccountUsers.recordcount)# usuários</span>
                          <span>#LSNumberFormat(qBusinessAccountEvents.recordcount)# eventos</span>
                        </cfoutput>
                      </div>
                    </div>
                    <div class="d-flex flex-wrap gap-2 justify-content-end">
                      <cfif VARIABLES.businessAccountsCanAdminAll>
                        <cfoutput><a class="btn btn-sm btn-outline-warning" href="./?conta_id=#qBusinessAccountEdit.id_conta#&editar_conta=1&busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage###conta-gerenciamento">Editar dados</a></cfoutput>
                      </cfif>
                      <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage#">Fechar conta</a></cfoutput>
                    </div>
                  </div>

                  <cfoutput>
                    <ul class="nav nav-tabs accounts-management-tabs mb-4">
                      <li class="nav-item">
                        <a class="nav-link <cfif VARIABLES.accountManagementTab EQ 'usuarios'>active</cfif>" href="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=usuarios&busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage###conta-gerenciamento">
                          Usuários (#LSNumberFormat(qBusinessAccountUsers.recordcount)#)
                        </a>
                      </li>
                      <cfif VARIABLES.businessAccountsCanAdminAll>
                        <li class="nav-item">
                          <a class="nav-link <cfif VARIABLES.accountManagementTab EQ 'vouchers'>active</cfif>" href="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=vouchers&busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage###conta-gerenciamento">
                            Vouchers (#LSNumberFormat(qBusinessAccountVouchers.recordcount)#)
                          </a>
                        </li>
                      </cfif>
                      <li class="nav-item">
                        <a class="nav-link <cfif VARIABLES.accountManagementTab EQ 'eventos'>active</cfif>" href="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=eventos&busca=#urlEncodedFormat(URL.busca)#&pagina=#VARIABLES.accountsPage###conta-gerenciamento">
                          Eventos (#LSNumberFormat(qBusinessAccountEvents.recordcount)#)
                        </a>
                      </li>
                    </ul>
                  </cfoutput>

                  <div class="accounts-tab-panel <cfif VARIABLES.accountManagementTab NEQ 'usuarios'>d-none</cfif>">
                  <div class="mb-3">
                    <h5 class="mb-1">Usuários da conta</h5>
                    <div class="text-muted small">
                      <cfoutput>#htmlEditFormat(qBusinessAccountEdit.nome_conta)# - #LSNumberFormat(qBusinessAccountUsers.recordcount)# usuários vinculados</cfoutput>
                    </div>
                  </div>

                  <cfif VARIABLES.businessAccountsCanManageUsers>
                    <cfoutput>
                      <form method="post" action="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=usuarios##conta-gerenciamento" class="accounts-panel p-3 mb-3">
                        <input type="hidden" name="account_user_action" value="convidar"/>
                        <input type="hidden" name="id_conta" value="#qBusinessAccountEdit.id_conta#"/>
                        <div class="row g-3">
                          <div class="col-12">
                            <label class="form-label">Nome</label>
                            <input class="form-control" type="text" name="nome_usuario" maxlength="256" required/>
                          </div>
                          <div class="col-12">
                            <label class="form-label">E-mail Google</label>
                            <input class="form-control" type="email" name="email_usuario" maxlength="256" required/>
                          </div>
                          <div class="col-12 col-lg-7">
                            <label class="form-label">Papel</label>
                            <select class="form-select" name="papel">
                    </cfoutput>
                              <cfloop list="#VARIABLES.accountUserAssignablePapelList#" item="accountPapelOption">
                                <cfoutput><option value="#accountPapelOption#" <cfif accountPapelOption EQ "OPERADOR">selected</cfif>>#accountPapelOption#</option></cfoutput>
                              </cfloop>
                    <cfoutput>
                            </select>
                          </div>
                          <div class="col-12 col-lg-5 d-flex align-items-end">
                            <button class="btn btn-warning w-100" type="submit">Adicionar</button>
                          </div>
                        </div>
                      </form>

                      <form method="get" action="./##conta-gerenciamento" class="mb-3">
                        <input type="hidden" name="conta_id" value="#qBusinessAccountEdit.id_conta#"/>
                        <input type="hidden" name="busca" value="#htmlEditFormat(URL.busca)#"/>
                        <input type="hidden" name="tab" value="usuarios"/>
                        <div class="row g-2 align-items-end">
                          <div class="col-12 col-lg-8">
                            <label class="form-label">Buscar usuário existente</label>
                            <input class="form-control" type="text" name="user_busca" value="#htmlEditFormat(URL.user_busca)#" placeholder="Nome, e-mail ou ID"/>
                          </div>
                          <div class="col-12 col-lg-4">
                            <button class="btn btn-outline-warning w-100" type="submit">Buscar</button>
                          </div>
                        </div>
                      </form>
                    </cfoutput>

                    <cfif len(trim(URL.user_busca))>
                      <cfif qBusinessAccountUserSearch.recordcount>
                        <cfoutput>
                          <form method="post" action="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=usuarios&user_busca=#urlEncodedFormat(URL.user_busca)###conta-gerenciamento" class="accounts-panel p-3 mb-3">
                            <input type="hidden" name="account_user_action" value="salvar"/>
                            <input type="hidden" name="id_conta" value="#qBusinessAccountEdit.id_conta#"/>
                            <div class="row g-3">
                              <div class="col-12">
                                <label class="form-label">Usuário encontrado</label>
                                <select class="form-select" name="id_usuario" required>
                        </cfoutput>
                                  <cfoutput query="qBusinessAccountUserSearch">
                                    <option value="#qBusinessAccountUserSearch.id#">
                                      ## #qBusinessAccountUserSearch.id# - #htmlEditFormat(qBusinessAccountUserSearch.name)# - #htmlEditFormat(qBusinessAccountUserSearch.email)#<cfif len(trim(qBusinessAccountUserSearch.status))> - vínculo atual: #qBusinessAccountUserSearch.papel#/#qBusinessAccountUserSearch.status#</cfif>
                                    </option>
                                  </cfoutput>
                        <cfoutput>
                                </select>
                              </div>
                              <div class="col-12 col-lg-6">
                                <label class="form-label">Papel</label>
                                <select class="form-select" name="papel">
                        </cfoutput>
                                  <cfloop list="#VARIABLES.accountUserAssignablePapelList#" item="accountPapelOption">
                                    <cfoutput><option value="#accountPapelOption#" <cfif accountPapelOption EQ "OPERADOR">selected</cfif>>#accountPapelOption#</option></cfoutput>
                                  </cfloop>
                        <cfoutput>
                                </select>
                              </div>
                              <div class="col-12 col-lg-6">
                                <label class="form-label">Status</label>
                                <select class="form-select" name="status">
                        </cfoutput>
                                  <cfloop list="#VARIABLES.accountUserStatusList#" item="accountUserStatusOption">
                                    <cfoutput><option value="#accountUserStatusOption#" <cfif accountUserStatusOption EQ "ATIVO">selected</cfif>>#accountUserStatusOption#</option></cfoutput>
                                  </cfloop>
                        <cfoutput>
                                </select>
                              </div>
                              <div class="col-12">
                                <button class="btn btn-warning w-100" type="submit">Vincular usuário</button>
                              </div>
                            </div>
                          </form>
                        </cfoutput>
                      <cfelse>
                        <div class="alert alert-warning" role="alert">Nenhum usuário encontrado para esta busca.</div>
                      </cfif>
                    </cfif>
                  <cfelse>
                    <div class="alert alert-info" role="alert">Seu acesso permite consultar os usuários desta conta.</div>
                  </cfif>

                  <div>
                    <cfif qBusinessAccountUsers.recordcount>
                      <cfoutput query="qBusinessAccountUsers">
                        <cfif VARIABLES.businessAccountsCanManageUsers AND (VARIABLES.businessAccountsCanAdminAll OR qBusinessAccountUsers.papel NEQ "OWNER")>
                          <form method="post" action="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=usuarios##conta-gerenciamento" class="accounts-user-row">
                            <input type="hidden" name="account_user_action" value="salvar"/>
                            <input type="hidden" name="id_conta" value="#qBusinessAccountEdit.id_conta#"/>
                            <input type="hidden" name="id_usuario" value="#qBusinessAccountUsers.id_usuario#"/>

                            <div class="accounts-cell">
                              <div class="fw-bold">#htmlEditFormat(qBusinessAccountUsers.name)#</div>
                              <div class="small text-muted">## #qBusinessAccountUsers.id_usuario# - #htmlEditFormat(qBusinessAccountUsers.email)#</div>
                              <div class="small text-muted">
                                <cfif qBusinessAccountUsers.is_admin>ADMIN</cfif><cfif qBusinessAccountUsers.is_admin AND qBusinessAccountUsers.is_partner> / </cfif><cfif qBusinessAccountUsers.is_partner>PARTNER</cfif>
                              </div>
                            </div>

                            <div>
                              <label class="form-label small">Papel</label>
                              <select class="form-select form-select-sm" name="papel">
                                <cfloop list="#VARIABLES.accountUserAssignablePapelList#" item="accountPapelOption">
                                  <option value="#accountPapelOption#" <cfif qBusinessAccountUsers.papel EQ accountPapelOption>selected</cfif>>#accountPapelOption#</option>
                                </cfloop>
                              </select>
                            </div>

                            <div>
                              <label class="form-label small">Status</label>
                              <select class="form-select form-select-sm" name="status">
                                <cfloop list="#VARIABLES.accountUserStatusList#" item="accountUserStatusOption">
                                  <option value="#accountUserStatusOption#" <cfif qBusinessAccountUsers.status EQ accountUserStatusOption>selected</cfif>>#accountUserStatusOption#</option>
                                </cfloop>
                              </select>
                            </div>

                            <div class="d-flex gap-2">
                              <button class="btn btn-sm btn-outline-warning" type="submit">Salvar</button>
                              <a class="btn btn-sm btn-outline-danger" href="./?account_user_action=remover&conta_id=#qBusinessAccountEdit.id_conta#&tab=usuarios&id_usuario=#qBusinessAccountUsers.id_usuario###conta-gerenciamento" onclick="return confirm('Remover este vínculo?');">Remover</a>
                            </div>
                          </form>
                        <cfelse>
                          <div class="accounts-user-row">
                            <div class="accounts-cell">
                              <div class="fw-bold">#htmlEditFormat(qBusinessAccountUsers.name)#</div>
                              <div class="small text-muted">## #qBusinessAccountUsers.id_usuario# - #htmlEditFormat(qBusinessAccountUsers.email)#</div>
                            </div>
                            <div>
                              <span class="accounts-status">#htmlEditFormat(qBusinessAccountUsers.papel)#</span>
                            </div>
                            <div>
                              <span class="accounts-status">#htmlEditFormat(qBusinessAccountUsers.status)#</span>
                            </div>
                          </div>
                        </cfif>
                      </cfoutput>
                    <cfelse>
                      <div class="text-muted py-3">Nenhum usuário vinculado a esta conta.</div>
                    </cfif>
                  </div>
                  </div>

                  <cfif VARIABLES.businessAccountsCanAdminAll>
                    <div class="accounts-tab-panel <cfif VARIABLES.accountManagementTab NEQ 'vouchers'>d-none</cfif>">

                    <div class="mb-3">
                      <h5 class="mb-1">Vouchers de ads</h5>
                      <div class="text-muted small">
                        Códigos de crédito vinculados a esta conta. Quem resgatar o código será associado à conta.
                      </div>
                    </div>

                    <cfif NOT VARIABLES.businessAccountVoucherColumnsReady>
                      <div class="alert alert-warning" role="alert">
                        A estrutura de vouchers Business ainda depende do SQL <code>_codex/sql/2026-06-14_tb_ad_vouchers_contas.sql</code>.
                      </div>
                    <cfelse>
                      <cfoutput>
                        <form method="post" action="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=vouchers##conta-gerenciamento" class="accounts-panel p-3 mb-3">
                          <input type="hidden" name="account_voucher_action" value="salvar"/>
                          <input type="hidden" name="id_conta" value="#qBusinessAccountEdit.id_conta#"/>
                          <div class="row g-3">
                            <div class="col-12 col-lg-5">
                              <label class="form-label">Código</label>
                              <input class="form-control" type="text" name="codigo" maxlength="80" placeholder="Gerar automaticamente"/>
                            </div>
                            <div class="col-12 col-lg-3">
                              <label class="form-label">Crédito</label>
                              <input class="form-control" type="number" name="credito" min="1" step="0.01" value="500.00" required/>
                            </div>
                            <div class="col-12 col-lg-4">
                              <label class="form-label">Validade</label>
                              <input class="form-control" type="date" name="data_expiracao"/>
                            </div>
                            <div class="col-12 col-lg-5">
                              <label class="form-label">Papel no resgate</label>
                              <select class="form-select" name="papel_resgate">
                                <option value="OWNER" selected>OWNER</option>
                                <option value="ADMIN">ADMIN</option>
                                <option value="OPERADOR">OPERADOR</option>
                                <option value="VISUALIZADOR">VISUALIZADOR</option>
                              </select>
                            </div>
                            <div class="col-12 col-lg-7">
                              <label class="form-label">Observação</label>
                              <input class="form-control" type="text" name="observacao" maxlength="500"/>
                            </div>
                            <div class="col-12">
                              <button class="btn btn-warning w-100" type="submit">Criar voucher</button>
                            </div>
                          </div>
                        </form>
                      </cfoutput>

                      <cfif qBusinessAccountVouchers.recordcount>
                        <div class="table-responsive">
                          <table class="table table-sm accounts-table align-middle mb-0">
                            <thead>
                              <tr>
                                <th>Código</th>
                                <th>Crédito</th>
                                <th>Status</th>
                                <th>Resgate</th>
                                <th></th>
                              </tr>
                            </thead>
                            <tbody>
                              <cfoutput query="qBusinessAccountVouchers">
                                <tr>
                                  <td class="accounts-cell">
                                    <div class="fw-bold">#htmlEditFormat(qBusinessAccountVouchers.codigo)#</div>
                                    <cfif len(trim(qBusinessAccountVouchers.observacao))>
                                      <div class="small text-muted">#htmlEditFormat(qBusinessAccountVouchers.observacao)#</div>
                                    </cfif>
                                  </td>
                                  <td>
                                    <div>#LSCurrencyFormat(qBusinessAccountVouchers.credito)#</div>
                                    <div class="small text-muted">saldo #LSCurrencyFormat(qBusinessAccountVouchers.credito_disponivel)#</div>
                                  </td>
                                  <td>
                                    <cfif qBusinessAccountVouchers.status EQ 1>
                                      <span class="accounts-status">Disponível</span>
                                    <cfelseif qBusinessAccountVouchers.status EQ 2>
                                      <span class="accounts-status">Resgatado</span>
                                    <cfelse>
                                      <span class="accounts-status">Inativo</span>
                                    </cfif>
                                    <cfif len(trim(qBusinessAccountVouchers.data_expiracao))>
                                      <div class="small text-muted">até #dateFormat(qBusinessAccountVouchers.data_expiracao, "dd/mm/yyyy")#</div>
                                    </cfif>
                                  </td>
                                  <td class="accounts-cell">
                                    <cfif len(trim(qBusinessAccountVouchers.id_usuario_resgate))>
                                      <div>#htmlEditFormat(qBusinessAccountVouchers.usuario_resgate_nome)#</div>
                                      <div class="small text-muted">#htmlEditFormat(qBusinessAccountVouchers.usuario_resgate_email)#</div>
                                      <cfif len(trim(qBusinessAccountVouchers.data_resgate))>
                                        <div class="small text-muted">#dateTimeFormat(qBusinessAccountVouchers.data_resgate, "dd/mm/yyyy HH:nn")#</div>
                                      </cfif>
                                    <cfelse>
                                      <span class="text-muted">Aguardando resgate</span>
                                    </cfif>
                                  </td>
                                  <td class="text-end">
                                    <cfif NOT len(trim(qBusinessAccountVouchers.id_usuario_resgate))>
                                      <cfif qBusinessAccountVouchers.status EQ 1>
                                        <a class="btn btn-sm btn-outline-danger" href="./?account_voucher_action=cancelar&conta_id=#qBusinessAccountEdit.id_conta#&tab=vouchers&id_ad_voucher=#qBusinessAccountVouchers.id_ad_voucher###conta-gerenciamento" onclick="return confirm('Cancelar este voucher?');">Cancelar</a>
                                      <cfelseif qBusinessAccountVouchers.status EQ 3>
                                        <a class="btn btn-sm btn-outline-warning" href="./?account_voucher_action=reativar&conta_id=#qBusinessAccountEdit.id_conta#&tab=vouchers&id_ad_voucher=#qBusinessAccountVouchers.id_ad_voucher###conta-gerenciamento">Reativar</a>
                                      </cfif>
                                    </cfif>
                                  </td>
                                </tr>
                              </cfoutput>
                            </tbody>
                          </table>
                        </div>
                      <cfelse>
                        <div class="text-muted py-3">Nenhum voucher criado para esta conta.</div>
                      </cfif>
                    </cfif>
                    </div>
                  </cfif>

                  <div class="accounts-tab-panel <cfif VARIABLES.accountManagementTab NEQ 'eventos'>d-none</cfif>">

                  <div class="mb-3">
                    <h5 class="mb-1">Eventos da conta</h5>
                    <div class="text-muted small">
                      <cfoutput>#LSNumberFormat(qBusinessAccountEvents.recordcount)# eventos vinculados</cfoutput>
                    </div>
                  </div>

                  <cfif VARIABLES.businessAccountsCanManageEvents>
                    <cfoutput>
                      <form method="get" action="./##conta-gerenciamento" class="mb-3">
                        <input type="hidden" name="conta_id" value="#qBusinessAccountEdit.id_conta#"/>
                        <input type="hidden" name="busca" value="#htmlEditFormat(URL.busca)#"/>
                        <input type="hidden" name="user_busca" value="#htmlEditFormat(URL.user_busca)#"/>
                        <input type="hidden" name="tab" value="eventos"/>
                        <div class="row g-2 align-items-end">
                          <div class="col-12 col-lg-8">
                            <label class="form-label">Buscar evento</label>
                            <input class="form-control" type="text" name="evento_busca" value="#htmlEditFormat(URL.evento_busca)#" placeholder="Nome, tag, cidade ou ID"/>
                          </div>
                          <div class="col-12 col-lg-4">
                            <button class="btn btn-outline-warning w-100" type="submit">Buscar</button>
                          </div>
                        </div>
                      </form>
                    </cfoutput>

                    <cfif len(trim(URL.evento_busca))>
                      <cfif qBusinessAccountEventSearch.recordcount>
                        <cfoutput>
                          <form method="post" action="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=eventos&evento_busca=#urlEncodedFormat(URL.evento_busca)###conta-gerenciamento" class="accounts-panel p-3 mb-3">
                            <input type="hidden" name="account_event_action" value="salvar"/>
                            <input type="hidden" name="id_conta" value="#qBusinessAccountEdit.id_conta#"/>
                            <div class="row g-3">
                              <div class="col-12">
                                <label class="form-label">Evento encontrado</label>
                                <select class="form-select" name="id_evento" required>
                        </cfoutput>
                                  <cfoutput query="qBusinessAccountEventSearch">
                                    <option value="#qBusinessAccountEventSearch.id_evento#">
                                      ## #qBusinessAccountEventSearch.id_evento# - #htmlEditFormat(qBusinessAccountEventSearch.nome_evento)#<cfif len(trim(qBusinessAccountEventSearch.tag))> - #htmlEditFormat(qBusinessAccountEventSearch.tag)#</cfif><cfif len(trim(qBusinessAccountEventSearch.status))> - vínculo atual: #qBusinessAccountEventSearch.status#</cfif>
                                    </option>
                                  </cfoutput>
                        <cfoutput>
                                </select>
                              </div>
                              <div class="col-12 col-lg-6">
                                <label class="form-label">Status</label>
                                <select class="form-select" name="status">
                        </cfoutput>
                                  <cfloop list="#VARIABLES.accountEventStatusList#" item="accountEventStatusOption">
                                    <cfoutput><option value="#accountEventStatusOption#" <cfif accountEventStatusOption EQ "ATIVO">selected</cfif>>#accountEventStatusOption#</option></cfoutput>
                                  </cfloop>
                        <cfoutput>
                                </select>
                              </div>
                              <div class="col-12 col-lg-6 d-flex align-items-end">
                                <button class="btn btn-warning w-100" type="submit">Vincular evento</button>
                              </div>
                            </div>
                          </form>
                        </cfoutput>
                      <cfelse>
                        <div class="alert alert-warning" role="alert">Nenhum evento encontrado para esta busca.</div>
                      </cfif>
                    </cfif>
                  <cfelse>
                    <div class="alert alert-info" role="alert">
                      Para incluir um evento nesta conta, use a tela de Eventos e envie uma solicitação de vínculo.
                    </div>
                  </cfif>

                  <div>
                    <cfif qBusinessAccountEvents.recordcount>
                      <div class="accounts-scroll-list">
                        <cfoutput query="qBusinessAccountEvents">
                          <cfif VARIABLES.businessAccountsCanManageEvents>
                            <form method="post" action="./?conta_id=#qBusinessAccountEdit.id_conta#&tab=eventos##conta-gerenciamento" class="accounts-event-row">
                              <input type="hidden" name="account_event_action" value="salvar"/>
                              <input type="hidden" name="id_conta" value="#qBusinessAccountEdit.id_conta#"/>
                              <input type="hidden" name="id_evento" value="#qBusinessAccountEvents.id_evento#"/>

                              <div class="accounts-cell">
                                <div class="fw-bold">#htmlEditFormat(qBusinessAccountEvents.nome_evento)#</div>
                                <div class="small text-muted">
                                  ## #qBusinessAccountEvents.id_evento#<cfif len(trim(qBusinessAccountEvents.tag))> - #htmlEditFormat(qBusinessAccountEvents.tag)#</cfif>
                                </div>
                                <div class="small text-muted">
                                  <cfif isDate(qBusinessAccountEvents.data_inicial)>#dateFormat(qBusinessAccountEvents.data_inicial, "dd/mm/yyyy")#</cfif><cfif len(trim(qBusinessAccountEvents.cidade))> - #htmlEditFormat(qBusinessAccountEvents.cidade)#</cfif><cfif len(trim(qBusinessAccountEvents.estado))>/#htmlEditFormat(qBusinessAccountEvents.estado)#</cfif>
                                </div>
                              </div>

                              <div class="accounts-event-actions">
                                <select class="form-select form-select-sm" name="status" aria-label="Status do vínculo do evento">
                                  <cfloop list="#VARIABLES.accountEventStatusList#" item="accountEventStatusOption">
                                    <option value="#accountEventStatusOption#" <cfif qBusinessAccountEvents.status EQ accountEventStatusOption>selected</cfif>>#accountEventStatusOption#</option>
                                  </cfloop>
                                </select>
                                <button class="btn btn-sm btn-outline-warning" type="submit">Salvar</button>
                                <a class="btn btn-sm btn-outline-danger" href="./?account_event_action=remover&conta_id=#qBusinessAccountEdit.id_conta#&tab=eventos&id_evento=#qBusinessAccountEvents.id_evento###conta-gerenciamento" onclick="return confirm('Remover este vínculo de evento?');">Remover</a>
                              </div>
                            </form>
                          <cfelse>
                            <div class="accounts-event-row">
                              <div class="accounts-cell">
                                <div class="fw-bold">#htmlEditFormat(qBusinessAccountEvents.nome_evento)#</div>
                                <div class="small text-muted">
                                  ## #qBusinessAccountEvents.id_evento#<cfif len(trim(qBusinessAccountEvents.tag))> - #htmlEditFormat(qBusinessAccountEvents.tag)#</cfif>
                                </div>
                                <div class="small text-muted">
                                  <cfif isDate(qBusinessAccountEvents.data_inicial)>#dateFormat(qBusinessAccountEvents.data_inicial, "dd/mm/yyyy")#</cfif><cfif len(trim(qBusinessAccountEvents.cidade))> - #htmlEditFormat(qBusinessAccountEvents.cidade)#</cfif><cfif len(trim(qBusinessAccountEvents.estado))>/#htmlEditFormat(qBusinessAccountEvents.estado)#</cfif>
                                </div>
                              </div>
                              <div>
                                <span class="accounts-status">#htmlEditFormat(qBusinessAccountEvents.status)#</span>
                              </div>
                            </div>
                          </cfif>
                        </cfoutput>
                      </div>
                    <cfelse>
                      <div class="text-muted py-3">Nenhum evento vinculado a esta conta.</div>
                    </cfif>
                  </div>
                  </div>
                <cfelse>
                  <div class="accounts-empty-state">
                    <h5 class="mb-2">Selecione uma conta</h5>
                    <p class="text-muted mb-3">Abra uma conta da lista para gerenciar usuários, eventos vinculados e permissões de acesso.</p>
                    <cfif VARIABLES.businessAccountsCanAdminAll>
                      <div>
                        <cfoutput><a class="btn btn-sm btn-outline-warning" href="./?conta_nova=1&busca=#urlEncodedFormat(URL.busca)#">Criar nova conta</a></cfoutput>
                      </div>
                    </cfif>
                  </div>
                </cfif>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  </div>
</section>
