<cfinclude template="../includes/send_backend.cfm"/>

<style>
  .notification-nav {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
  }

  .notification-send-grid {
    row-gap: 1rem;
  }

  .notification-send-card,
  .notification-send-template-card,
  .notification-send-preview-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
    background: rgba(255,255,255,0.025);
  }

  .notification-send-field-card {
    background: rgba(255,255,255,0.025);
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: 1rem;
    padding: 1rem;
    height: 100%;
  }

  .notification-send-field-card .form-label {
    font-size: 0.82rem;
    font-weight: 700;
    letter-spacing: 0.02em;
    text-transform: uppercase;
    color: rgba(255,255,255,0.7);
  }

  .notification-send-template-preview {
    display: grid;
    gap: 0.9rem;
  }

  .notification-send-template-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.6rem;
    padding: 0.9rem 1rem;
    border-radius: 1rem;
    border: 1px dashed rgba(245, 196, 81, 0.25);
    background: rgba(245, 196, 81, 0.08);
    color: #f5c451;
  }

  .notification-send-template-badge i {
    font-size: 1.35rem;
  }

  .notification-send-template-content {
    padding: 1rem 1.1rem;
    border-radius: 1rem;
    background: rgba(255,255,255,0.04);
    border: 1px solid rgba(255,255,255,0.08);
    line-height: 1.45;
  }

  .notification-send-template-content p:last-child {
    margin-bottom: 0;
  }

  .notification-send-recipient-table td,
  .notification-send-recipient-table th {
    vertical-align: middle;
  }

  .notification-send-recipient-cell {
    max-width: 320px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .notification-send-filter-chip {
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    padding: 0.45rem 0.7rem;
    border-radius: 999px;
    background: rgba(255,255,255,0.06);
    border: 1px solid rgba(255,255,255,0.08);
    font-size: 0.82rem;
  }
</style>

<cfset VARIABLES.notificationTemplateCurrentCampaign = ""/>
<cfset VARIABLES.notificationTemplateCurrentContent = ""/>
<cfset VARIABLES.notificationTemplateCurrentIcon = ""/>
<cfset VARIABLES.notificationTemplateCurrentLink = ""/>

<cfif qNotificationSendTemplateCurrent.recordcount>
  <cfif len(trim(VARIABLES.notificationSendTemplateCampaignColumn))>
    <cfset VARIABLES.notificationTemplateCurrentCampaign = qNotificationSendTemplateCurrent[VARIABLES.notificationSendTemplateCampaignColumn][1]/>
  </cfif>
  <cfif len(trim(VARIABLES.notificationSendTemplateContentColumn))>
    <cfset VARIABLES.notificationTemplateCurrentContent = qNotificationSendTemplateCurrent[VARIABLES.notificationSendTemplateContentColumn][1]/>
  </cfif>
  <cfif len(trim(VARIABLES.notificationSendTemplateIconColumn))>
    <cfset VARIABLES.notificationTemplateCurrentIcon = qNotificationSendTemplateCurrent[VARIABLES.notificationSendTemplateIconColumn][1]/>
  </cfif>
  <cfif len(trim(VARIABLES.notificationSendTemplateLinkColumn))>
    <cfset VARIABLES.notificationTemplateCurrentLink = qNotificationSendTemplateCurrent[VARIABLES.notificationSendTemplateLinkColumn][1]/>
  </cfif>
</cfif>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Notificações - Envio</h3>
              <p class="text-muted mb-0">Selecione um template existente, filtre os destinatários reais do portal e publique a notificação na fila interna.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Destinatários encontrados</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qNotificationSendRecipientsCount.total)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <div class="notification-nav mb-4">
            <a class="btn btn-outline-secondary <cfif VARIABLES.template EQ "/notificacoes/">active</cfif>" href="/notificacoes/">Histórico de Notificações</a>
            <a class="btn btn-outline-secondary <cfif VARIABLES.template EQ "/notificacoes/templates/">active</cfif>" href="/notificacoes/templates/">Templates</a>
            <a class="btn btn-warning <cfif VARIABLES.template EQ "/notificacoes/envio/">active</cfif>" href="/notificacoes/envio/">Envio</a>
          </div>

          <cfif VARIABLES.notificationSendStatus EQ "enviado">
            <div class="alert alert-success">
              <cfoutput>#LSNumberFormat(VARIABLES.notificationSendTotalSent)#</cfoutput> notificações foram preparadas com sucesso na fila.
            </div>
            <cfif VARIABLES.notificationSendPushStatus EQ "sent">
              <div class="alert alert-info">
                <cfoutput>
                  Push aceito para #LSNumberFormat(VARIABLES.notificationSendPushNotifications)# notificações, com #LSNumberFormat(VARIABLES.notificationSendPushDeliveries)# entrega(s) aceita(s) em #LSNumberFormat(VARIABLES.notificationSendPushSubscriptions)# subscription(s).
                </cfoutput>
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "no_active_subscriptions">
              <div class="alert alert-secondary">
                As notificações web foram salvas, mas nenhum destinatário deste recorte tinha Push ativo no PWA neste ambiente.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "push_disabled">
              <div class="alert alert-secondary">
                As notificações web foram salvas, mas o Push do PWA não está habilitado neste ambiente do Road Runners.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "scheduled">
              <div class="alert alert-secondary">
                As notificações web foram agendadas com sucesso. O Push não foi disparado agora porque a publicação está programada para uma data futura.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "invalid_signature">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o Road Runners recusou a autenticação do disparo Push.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "expired_signature">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas a assinatura usada no disparo Push expirou antes da validação.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "invalid_payload">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o payload enviado ao Road Runners foi recusado.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "internal_error">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o Road Runners retornou erro interno ao processar o Push.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "http_401">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o endpoint de Push respondeu HTTP 401.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "http_404">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o endpoint de Push não foi encontrado no Road Runners.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "http_500">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o endpoint de Push retornou HTTP 500.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "local_dispatch_failed">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas nem a ponte HTTP nem o envio direto local conseguiram confirmar o Push.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "local_vapid_401">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o envio Push local foi rejeitado com HTTP 401. Isso normalmente indica problema nas chaves VAPID configuradas no Business para este ambiente.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "local_vapid_403">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o envio Push local foi rejeitado com HTTP 403. A subscription ativa foi tratada como inválida e desativada; agora é importante recriá-la no beta antes de testar novamente.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "local_subscription_404">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas as subscriptions Push encontradas responderam HTTP 404 e foram tratadas como inválidas.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "local_subscription_410">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas as subscriptions Push encontradas responderam HTTP 410 e foram desativadas por expiração ou revogação.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "local_push_unconfigured">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o ambiente do Business não tem as chaves VAPID configuradas para tentar o envio Push local.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "dispatch_failed">
              <div class="alert alert-warning">
                As notificações web foram salvas, mas o disparo do Push não retornou confirmação do Road Runners.
              </div>
            <cfelseif VARIABLES.notificationSendPushStatus EQ "not_configured">
              <div class="alert alert-secondary">
                As notificações web foram salvas, mas a ponte de Push ainda não está configurada neste ambiente.
              </div>
            </cfif>
          <cfelseif VARIABLES.notificationSendStatus EQ "sem_destinatarios">
            <div class="alert alert-warning">Nenhum destinatário foi encontrado com os filtros atuais.</div>
          <cfelseif VARIABLES.notificationSendStatus EQ "template_invalido">
            <div class="alert alert-danger">Selecione um template válido antes de enviar.</div>
          <cfelseif VARIABLES.notificationSendStatus EQ "publicacao_invalida">
            <div class="alert alert-danger">A data de publicação informada é inválida.</div>
          <cfelseif VARIABLES.notificationSendStatus EQ "expiracao_invalida">
            <div class="alert alert-danger">A data de expiração informada é inválida.</div>
          </cfif>

          <div class="notification-send-card p-4 mb-4">
            <form method="get" action="./">
              <input type="hidden" name="pagina" value="<cfoutput>#VARIABLES.notificationSendPage#</cfoutput>"/>

              <div class="row notification-send-grid">
                <div class="col-12 col-xl-4">
                  <div class="notification-send-field-card">
                    <label class="form-label">Template</label>
                    <select class="form-select" name="template_id">
                      <option value="">Selecione um template</option>
                      <cfoutput query="qNotificationSendTemplates">
                        <cfset VARIABLES.notificationTemplateOptionLabel = "Template ##" & qNotificationSendTemplates[VARIABLES.notificationSendTemplatePk][qNotificationSendTemplates.currentRow]/>
                        <cfif len(trim(VARIABLES.notificationSendTemplateCampaignColumn)) AND len(trim(qNotificationSendTemplates[VARIABLES.notificationSendTemplateCampaignColumn][qNotificationSendTemplates.currentRow]))>
                          <cfset VARIABLES.notificationTemplateOptionLabel = qNotificationSendTemplates[VARIABLES.notificationSendTemplateCampaignColumn][qNotificationSendTemplates.currentRow]/>
                        </cfif>
                        <option value="#htmlEditFormat(qNotificationSendTemplates[VARIABLES.notificationSendTemplatePk][qNotificationSendTemplates.currentRow])#" <cfif VARIABLES.notificationSendTemplateId EQ qNotificationSendTemplates[VARIABLES.notificationSendTemplatePk][qNotificationSendTemplates.currentRow]>selected</cfif>>#htmlEditFormat(VARIABLES.notificationTemplateOptionLabel)#</option>
                      </cfoutput>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-2">
                  <div class="notification-send-field-card">
                    <label class="form-label">ID do Usuário</label>
                    <input class="form-control" type="number" name="user_id" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendUserId)#</cfoutput>" step="1" inputmode="numeric"/>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Data de Publicação</label>
                    <input class="form-control" type="datetime-local" name="data_publicacao" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendPublicacao)#</cfoutput>" step="60"/>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Expiração em Dias</label>
                    <input class="form-control" type="number" name="dias_expiracao" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendDiasExpiracao)#</cfoutput>" step="1" min="0" inputmode="numeric"/>
                    <div class="small text-muted mt-2">
                      <cfif VARIABLES.notificationSendPublicationIsValid AND VARIABLES.notificationSendExpirationIsValid>
                        <cfoutput>Expira em #LSDateTimeFormat(VARIABLES.notificationSendExpirationDate, "dd/mm/yyyy HH:nn")#</cfoutput>
                      <cfelse>
                        Informe um número de dias válido.
                      </cfif>
                    </div>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Administrador</label>
                    <select class="form-select" name="admin">
                      <option value="" <cfif VARIABLES.notificationSendAdmin EQ "">selected</cfif>>Todos</option>
                      <option value="true" <cfif VARIABLES.notificationSendAdmin EQ "true">selected</cfif>>Sim</option>
                      <option value="false" <cfif VARIABLES.notificationSendAdmin EQ "false">selected</cfif>>Não</option>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Conta vinculada no Strava</label>
                    <select class="form-select" name="strava">
                      <option value="" <cfif VARIABLES.notificationSendStrava EQ "">selected</cfif>>Todos</option>
                      <option value="true" <cfif VARIABLES.notificationSendStrava EQ "true">selected</cfif>>Sim</option>
                      <option value="false" <cfif VARIABLES.notificationSendStrava EQ "false">selected</cfif>>Não</option>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Inscrito em desafio</label>
                    <select class="form-select" name="desafio">
                      <option value="" <cfif VARIABLES.notificationSendDesafio EQ "">selected</cfif>>Todos</option>
                      <option value="true" <cfif VARIABLES.notificationSendDesafio EQ "true">selected</cfif>>Sim</option>
                      <option value="false" <cfif VARIABLES.notificationSendDesafio EQ "false">selected</cfif>>Não</option>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Informou assessoria</label>
                    <select class="form-select" name="assessoria">
                      <option value="" <cfif VARIABLES.notificationSendAssessoria EQ "">selected</cfif>>Todos</option>
                      <option value="true" <cfif VARIABLES.notificationSendAssessoria EQ "true">selected</cfif>>Sim</option>
                      <option value="false" <cfif VARIABLES.notificationSendAssessoria EQ "false">selected</cfif>>Não</option>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Desenvolvedor</label>
                    <select class="form-select" name="dev">
                      <option value="" <cfif VARIABLES.notificationSendDev EQ "">selected</cfif>>Todos</option>
                      <option value="true" <cfif VARIABLES.notificationSendDev EQ "true">selected</cfif>>Sim</option>
                      <option value="false" <cfif VARIABLES.notificationSendDev EQ "false">selected</cfif>>Não</option>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Parceiro</label>
                    <select class="form-select" name="partner">
                      <option value="" <cfif VARIABLES.notificationSendPartner EQ "">selected</cfif>>Todos</option>
                      <option value="true" <cfif VARIABLES.notificationSendPartner EQ "true">selected</cfif>>Sim</option>
                      <option value="false" <cfif VARIABLES.notificationSendPartner EQ "false">selected</cfif>>Não</option>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Gênero</label>
                    <select class="form-select" name="genero">
                      <option value="" <cfif VARIABLES.notificationSendGenero EQ "">selected</cfif>>Todos</option>
                      <option value="M" <cfif VARIABLES.notificationSendGenero EQ "M">selected</cfif>>Homem</option>
                      <option value="F" <cfif VARIABLES.notificationSendGenero EQ "F">selected</cfif>>Mulher</option>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Registro na CBAT</label>
                    <select class="form-select" name="cbat">
                      <option value="" <cfif VARIABLES.notificationSendCBAT EQ "">selected</cfif>>Todos</option>
                      <option value="true" <cfif VARIABLES.notificationSendCBAT EQ "true">selected</cfif>>Sim</option>
                      <option value="false" <cfif VARIABLES.notificationSendCBAT EQ "false">selected</cfif>>Não</option>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">País</label>
                    <select class="form-select" name="pais">
                      <option value="" <cfif VARIABLES.notificationSendPais EQ "">selected</cfif>>Todos</option>
                      <cfoutput query="qNotificationSendCountries">
                        <option value="#htmlEditFormat(qNotificationSendCountries.pais)#" <cfif VARIABLES.notificationSendPais EQ qNotificationSendCountries.pais>selected</cfif>>#htmlEditFormat(qNotificationSendCountries.nome_pais)#</option>
                      </cfoutput>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Estado</label>
                    <select class="form-select" name="estado">
                      <option value="" <cfif VARIABLES.notificationSendEstado EQ "">selected</cfif>>Todos</option>
                      <cfoutput query="qNotificationSendStates">
                        <option value="#htmlEditFormat(qNotificationSendStates.estado)#" <cfif VARIABLES.notificationSendEstado EQ qNotificationSendStates.estado>selected</cfif>>#htmlEditFormat(qNotificationSendStates.estado)#</option>
                      </cfoutput>
                    </select>
                  </div>
                </div>

                <div class="col-12 col-md-6 col-xl-3">
                  <div class="notification-send-field-card">
                    <label class="form-label">Página verificada</label>
                    <select class="form-select" name="verificado">
                      <option value="" <cfif VARIABLES.notificationSendVerificado EQ "">selected</cfif>>Todos</option>
                      <option value="true" <cfif VARIABLES.notificationSendVerificado EQ "true">selected</cfif>>Sim</option>
                      <option value="false" <cfif VARIABLES.notificationSendVerificado EQ "false">selected</cfif>>Não</option>
                    </select>
                  </div>
                </div>
              </div>

              <div class="d-flex flex-wrap gap-2 justify-content-end mt-4">
                <a class="btn btn-outline-secondary" href="/notificacoes/envio/">Limpar filtros</a>
                <button type="submit" class="btn btn-warning">Atualizar lista</button>
              </div>
            </form>
          </div>

          <cfif len(trim(VARIABLES.notificationSendTemplateId)) OR len(trim(VARIABLES.notificationSendUserId)) OR len(trim(VARIABLES.notificationSendAdmin)) OR len(trim(VARIABLES.notificationSendStrava)) OR len(trim(VARIABLES.notificationSendDesafio)) OR len(trim(VARIABLES.notificationSendAssessoria)) OR len(trim(VARIABLES.notificationSendDev)) OR len(trim(VARIABLES.notificationSendPartner)) OR len(trim(VARIABLES.notificationSendGenero)) OR len(trim(VARIABLES.notificationSendCBAT)) OR len(trim(VARIABLES.notificationSendPais)) OR len(trim(VARIABLES.notificationSendEstado)) OR len(trim(VARIABLES.notificationSendVerificado))>
            <div class="d-flex flex-wrap gap-2 mb-4">
              <cfif len(trim(VARIABLES.notificationSendTemplateId))><span class="notification-send-filter-chip">Template: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendTemplateId)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendUserId))><span class="notification-send-filter-chip">Usuário: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendUserId)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendAdmin))><span class="notification-send-filter-chip">Admin: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendAdmin)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendStrava))><span class="notification-send-filter-chip">Strava: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendStrava)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendDesafio))><span class="notification-send-filter-chip">Desafio: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendDesafio)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendAssessoria))><span class="notification-send-filter-chip">Assessoria: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendAssessoria)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendDev))><span class="notification-send-filter-chip">Dev: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendDev)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendPartner))><span class="notification-send-filter-chip">Parceiro: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendPartner)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendGenero))><span class="notification-send-filter-chip">Gênero: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendGenero)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendCBAT))><span class="notification-send-filter-chip">CBAT: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendCBAT)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendPais))><span class="notification-send-filter-chip">País: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendPais)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendEstado))><span class="notification-send-filter-chip">Estado: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendEstado)#</cfoutput></span></cfif>
              <cfif len(trim(VARIABLES.notificationSendVerificado))><span class="notification-send-filter-chip">Verificado: <cfoutput>#htmlEditFormat(VARIABLES.notificationSendVerificado)#</cfoutput></span></cfif>
            </div>
          </cfif>

          <div class="row g-4">
            <div class="col-12 col-xl-4">
              <div class="notification-send-template-card p-4 h-100">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                  <div>
                    <h5 class="mb-1">Template selecionado</h5>
                    <p class="text-muted small mb-0">A notificação enviada herda o template escolhido e é gravada na fila interna da `tb_notifica`.</p>
                  </div>
                </div>

                <cfif qNotificationSendTemplateCurrent.recordcount>
                  <div class="notification-send-template-preview">
                    <div class="notification-send-template-badge">
                      <i class="<cfif len(trim(VARIABLES.notificationTemplateCurrentIcon))>#htmlEditFormat(VARIABLES.notificationTemplateCurrentIcon)#<cfelse>fa-solid fa-bell</cfif>"></i>
                      <div>
                        <div class="fw-semibold"><cfoutput>#htmlEditFormat(len(trim(VARIABLES.notificationTemplateCurrentCampaign)) ? VARIABLES.notificationTemplateCurrentCampaign : ("Template ##" & VARIABLES.notificationSendTemplateId))#</cfoutput></div>
                        <cfif len(trim(VARIABLES.notificationTemplateCurrentLink))>
                          <div class="small opacity-75"><cfoutput>#htmlEditFormat(VARIABLES.notificationTemplateCurrentLink)#</cfoutput></div>
                        </cfif>
                      </div>
                    </div>

                    <cfif len(trim(VARIABLES.notificationTemplateCurrentContent))>
                      <div class="notification-send-template-content"><cfoutput>#VARIABLES.notificationTemplateCurrentContent#</cfoutput></div>
                    <cfelse>
                      <div class="notification-send-template-content text-muted">Este template não possui conteúdo textual identificado automaticamente.</div>
                    </cfif>

                    <form method="post" action="./?pagina=<cfoutput>#VARIABLES.notificationSendPage#</cfoutput>">
                      <input type="hidden" name="notification_send_action" value="enviar"/>
                      <input type="hidden" name="notification_send_template_id" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendTemplateId)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_user_id" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendUserId)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_admin" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendAdmin)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_strava" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendStrava)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_desafio" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendDesafio)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_assessoria" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendAssessoria)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_dev" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendDev)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_partner" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendPartner)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_genero" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendGenero)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_cbat" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendCBAT)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_pais" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendPais)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_estado" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendEstado)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_verificado" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendVerificado)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_data_publicacao" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendPublicacao)#</cfoutput>"/>
                      <input type="hidden" name="notification_send_dias_expiracao" value="<cfoutput>#htmlEditFormat(VARIABLES.notificationSendDiasExpiracao)#</cfoutput>"/>

                      <div class="small text-muted mb-3">Destinatários atuais: <cfoutput>#LSNumberFormat(qNotificationSendRecipientsCount.total)#</cfoutput></div>
                      <button type="submit" class="btn btn-warning w-100" onclick="return confirm('Confirma o envio desta notificação para os destinatários filtrados?');">Enviar notificação</button>
                    </form>
                  </div>
                <cfelse>
                  <div class="alert alert-secondary mb-0">Selecione um template para visualizar a prévia e liberar o envio.</div>
                </cfif>
              </div>
            </div>

            <div class="col-12 col-xl-8">
              <div class="notification-send-preview-card p-4 h-100">
                <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                  <div>
                    <h5 class="mb-1">Prévia de destinatários</h5>
                    <p class="text-muted small mb-0">A tabela abaixo mostra uma amostra dos primeiros 100 usuários alcançados pelos filtros atuais.</p>
                  </div>
                  <div class="text-lg-end">
                    <div class="small text-muted">Amostra carregada</div>
                    <div class="h5 mb-0"><cfoutput>#LSNumberFormat(qNotificationSendRecipientsPreview.recordcount)#</cfoutput></div>
                  </div>
                </div>

                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover notification-send-recipient-table mb-0">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Usuário</th>
                        <th>Perfil</th>
                        <th>Local</th>
                        <th>Página</th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfif qNotificationSendRecipientsPreview.recordcount>
                        <cfoutput query="qNotificationSendRecipientsPreview">
                          <tr>
                            <td>#id#</td>
                            <td class="notification-send-recipient-cell">
                              <div class="fw-semibold">#htmlEditFormat(name)#</div>
                              <div class="small text-muted">#htmlEditFormat(email)#</div>
                            </td>
                            <td class="notification-send-recipient-cell">
                              <div class="d-flex flex-wrap gap-1">
                                <cfif is_admin><span class="badge badge-warning text-dark">Admin</span></cfif>
                                <cfif is_dev><span class="badge badge-info">Dev</span></cfif>
                                <cfif is_partner><span class="badge badge-success">Parceiro</span></cfif>
                                <cfif len(trim(strava_code)) OR isNumeric(strava_id)><span class="badge bg-strava">Strava</span></cfif>
                                <cfif inscrito_desafio><span class="badge badge-primary">Desafio</span></cfif>
                                <cfif len(trim(assessoria))><span class="badge badge-secondary">Assessoria</span></cfif>
                                <cfif len(trim(cbat))><span class="badge badge-light text-dark">CBAT</span></cfif>
                                <cfif genero EQ "M"><span class="badge badge-dark">Homem</span></cfif>
                                <cfif genero EQ "F"><span class="badge badge-dark">Mulher</span></cfif>
                              </div>
                            </td>
                            <td>
                              <div>#htmlEditFormat(pais)#</div>
                              <div class="small text-muted">#htmlEditFormat(estado)#</div>
                            </td>
                            <td class="notification-send-recipient-cell">
                              <cfif len(trim(tag))>
                                <a class="link-warning" href="https://roadrunners.run/atleta/#htmlEditFormat(tag)#/" target="_blank" rel="noopener noreferrer">#htmlEditFormat(pagina_nome)#</a>
                              <cfelse>
                                #htmlEditFormat(pagina_nome)#
                              </cfif>
                              <div class="small text-muted">
                                <cfif len(trim(id_pagina))>ID #id_pagina#</cfif>
                                <cfif len(trim(tag))> | #htmlEditFormat(tag)#</cfif>
                              </div>
                              <cfif verificado><div class="small text-success">Verificada</div></cfif>
                            </td>
                          </tr>
                        </cfoutput>
                      <cfelse>
                        <tr>
                          <td colspan="5" class="text-center text-muted py-4">Nenhum usuário encontrado com os filtros atuais.</td>
                        </tr>
                      </cfif>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  </div>
</section>
