<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- WIDGETS --->

<section class="mb-4">

  <div class="row gx-xl-3">

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-bell fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Notificações</p>
              <h4 class="mb-0">
                <cfoutput>#LSNumberFormat(qNotificaCount.total, "9,999,999")#</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-hand-pointer fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Clicks</p>
              <h4 class="mb-0">
                <cfoutput>#LSNumberFormat(qNotificaCountClicks.total, "9,999,999")# (#LSNumberFormat((qNotificaCountClicks.total*100)/qNotificaCount.total, "9.99")#%)</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-dollar-sign fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Conversão</p>
              <h4 class="mb-0">
                <cfoutput>#lsCurrencyFormat(qNotificaCountConversoes.valor_total)# (#qNotificaCountConversoes.total#)</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>

</section>

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <div class="d-flex flex-wrap gap-2 mb-4">
            <a class="btn btn-warning <cfif VARIABLES.template EQ "/notificacoes/">active</cfif>" href="/notificacoes/">Histórico de Notificações</a>
            <a class="btn btn-outline-secondary <cfif VARIABLES.template EQ "/notificacoes/templates/">active</cfif>" href="/notificacoes/templates/">Templates</a>
            <a class="btn btn-outline-secondary <cfif VARIABLES.template EQ "/notificacoes/envio/">active</cfif>" href="/notificacoes/envio/">Envio</a>
          </div>

          <div class="row">
            <div class="col">
                <h3>Histórico de Notificações</h3>
            </div>
            <div class="col text-end">
                <!---a href="fila.cfm" target="_blank"><button class="btn btn-outline-danger">Enviar Fila</button></a--->
            </div>
          </div>

          <hr/>

          <form method="get" action="./" class="mb-4">
            <input type="hidden" name="pagina" value="1"/>

            <div class="row g-3">
              <div class="col-12 col-xl-4">
                <label class="form-label small text-uppercase text-muted fw-bold">Busca</label>
                <input class="form-control" type="text" name="busca" value="<cfoutput>#htmlEditFormat(VARIABLES.notificaBusca)#</cfoutput>" placeholder="ID do usuário, ID da notificação, nome, e-mail, link ou conteúdo"/>
              </div>

              <div class="col-12 col-md-6 col-xl-2">
                <label class="form-label small text-uppercase text-muted fw-bold">Template</label>
                <input class="form-control" type="number" name="template_id" value="<cfoutput>#htmlEditFormat(VARIABLES.notificaTemplateId)#</cfoutput>" step="1" inputmode="numeric"/>
              </div>

              <div class="col-12 col-md-6 col-xl-2">
                <label class="form-label small text-uppercase text-muted fw-bold">Campanha</label>
                <select class="form-select" name="campanha">
                  <option value="" <cfif VARIABLES.notificaCampanha EQ "">selected</cfif>>Todas</option>
                  <cfoutput query="qNotificaCampanhas">
                    <option value="#htmlEditFormat(qNotificaCampanhas.campaign_name)#" <cfif VARIABLES.notificaCampanha EQ qNotificaCampanhas.campaign_name>selected</cfif>>#htmlEditFormat(qNotificaCampanhas.campaign_name)#</option>
                  </cfoutput>
                </select>
              </div>

              <div class="col-12 col-md-6 col-xl-2">
                <label class="form-label small text-uppercase text-muted fw-bold">Status</label>
                <select class="form-select" name="leitura">
                  <option value="" <cfif VARIABLES.notificaLeitura EQ "">selected</cfif>>Todas</option>
                  <option value="lidas" <cfif VARIABLES.notificaLeitura EQ "lidas">selected</cfif>>Lidas</option>
                  <option value="nao_lidas" <cfif VARIABLES.notificaLeitura EQ "nao_lidas">selected</cfif>>Não lidas</option>
                  <option value="ativas" <cfif VARIABLES.notificaLeitura EQ "ativas">selected</cfif>>Ativas</option>
                  <option value="expiradas" <cfif VARIABLES.notificaLeitura EQ "expiradas">selected</cfif>>Expiradas</option>
                </select>
              </div>

              <div class="col-12 col-md-6 col-xl-2">
                <label class="form-label small text-uppercase text-muted fw-bold">Publicadas a partir de</label>
                <input class="form-control" type="date" name="data_publicacao_inicial" value="<cfoutput>#htmlEditFormat(VARIABLES.notificaDataPublicacaoInicial)#</cfoutput>"/>
              </div>

              <div class="col-12 col-md-6 col-xl-2">
                <label class="form-label small text-uppercase text-muted fw-bold">Publicadas até</label>
                <input class="form-control" type="date" name="data_publicacao_final" value="<cfoutput>#htmlEditFormat(VARIABLES.notificaDataPublicacaoFinal)#</cfoutput>"/>
              </div>
            </div>

            <div class="d-flex flex-wrap gap-2 justify-content-end mt-3">
              <a class="btn btn-outline-secondary" href="/notificacoes/">Limpar filtros</a>
              <button type="submit" class="btn btn-warning">Filtrar histórico</button>
            </div>
          </form>

          <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-center gap-3 mb-3">
            <div class="text-muted small">
              <cfoutput>#LSNumberFormat(qNotificaHistoricoCount.total)#</cfoutput> notificações encontradas
            </div>
            <div class="d-flex flex-wrap align-items-center gap-2">
              <div class="text-muted small">
                <cfoutput>Página #VARIABLES.notificaPage# de #VARIABLES.notificaTotalPages#</cfoutput>
              </div>
              <cfif isDefined("qPerfil") AND qPerfil.recordcount AND qPerfil.is_admin AND qNotificaHistoricoCount.total>
                <form method="post" action="./?pagina=<cfoutput>#VARIABLES.notificaPage#&busca=#urlEncodedFormat(VARIABLES.notificaBusca)#&template_id=#urlEncodedFormat(VARIABLES.notificaTemplateId)#&campanha=#urlEncodedFormat(VARIABLES.notificaCampanha)#&leitura=#urlEncodedFormat(VARIABLES.notificaLeitura)#&data_publicacao_inicial=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoInicial)#&data_publicacao_final=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoFinal)#</cfoutput>" class="d-flex flex-wrap gap-2">
                  <button type="submit" name="history_action" value="desativar_filtradas" class="btn btn-sm btn-outline-warning" onclick="return confirm('Tem certeza que deseja desativar todas as notificações filtradas?');">Desativar filtradas</button>
                  <button type="submit" name="history_action" value="excluir_filtradas" class="btn btn-sm btn-outline-danger" onclick="return confirm('Tem certeza que deseja excluir todas as notificações filtradas?');">Excluir filtradas</button>
                </form>
              </cfif>
            </div>
          </div>

          <div class="row g-3 mb-4">
            <div class="col-6 col-xl-2">
              <div class="card shadow-0 h-100">
                <div class="card-body p-3">
                  <div class="small text-muted">Enviadas</div>
                  <div class="h5 mb-0"><cfoutput>#LSNumberFormat(qNotificaHistoricoStats.total)#</cfoutput></div>
                </div>
              </div>
            </div>
            <div class="col-6 col-xl-2">
              <div class="card shadow-0 h-100">
                <div class="card-body p-3">
                  <div class="small text-muted">Ativas</div>
                  <div class="h5 mb-0"><cfoutput>#LSNumberFormat(val(qNotificaHistoricoStats.total_ativas))#</cfoutput></div>
                </div>
              </div>
            </div>
            <div class="col-6 col-xl-2">
              <div class="card shadow-0 h-100">
                <div class="card-body p-3">
                  <div class="small text-muted">Inativas</div>
                  <div class="h5 mb-0"><cfoutput>#LSNumberFormat(val(qNotificaHistoricoStats.total_inativas))#</cfoutput></div>
                </div>
              </div>
            </div>
            <div class="col-6 col-xl-2">
              <div class="card shadow-0 h-100">
                <div class="card-body p-3">
                  <div class="small text-muted">Lidas</div>
                  <div class="h5 mb-0"><cfoutput>#LSNumberFormat(val(qNotificaHistoricoStats.total_lidas))#</cfoutput></div>
                </div>
              </div>
            </div>
            <div class="col-6 col-xl-2">
              <div class="card shadow-0 h-100">
                <div class="card-body p-3">
                  <div class="small text-muted">Não lidas</div>
                  <div class="h5 mb-0"><cfoutput>#LSNumberFormat(val(qNotificaHistoricoStats.total_nao_lidas))#</cfoutput></div>
                </div>
              </div>
            </div>
          </div>

          <div class="table-responsive">
            <table class="table table-sm table-striped table-hover align-middle">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Usuário</th>
                  <th>Campanha</th>
                  <th>Conteúdo</th>
                  <th>Link</th>
                  <th>Publicação</th>
                  <th>Status</th>
                  <th>Ações</th>
                </tr>
              </thead>
              <tbody>
                <cfif qNotificaHistorico.recordcount>
                  <cfoutput query="qNotificaHistorico">
                    <tr>
                      <td>
                        <div class="fw-semibold">#id_notifica#</div>
                        <div class="small text-muted">Template <cfif len(trim(id_notifica_template))>#id_notifica_template#<cfelse>sem template</cfif></div>
                      </td>
                      <td style="max-width: 220px;">
                        <div class="fw-semibold">#htmlEditFormat(name)#</div>
                        <div class="small text-muted">#htmlEditFormat(email)#</div>
                        <div class="small text-muted">Usuário #id_usuario#</div>
                      </td>
                      <td style="max-width: 180px;">
                        <cfif len(trim(campanha_template))>
                          #htmlEditFormat(campanha_template)#
                        <cfelse>
                          <span class="text-muted">Sem campanha</span>
                        </cfif>
                      </td>
                      <td style="max-width: 340px;">
                        <cfif len(trim(conteudo_notifica))>
                          <div class="small">#conteudo_notifica#</div>
                        <cfelse>
                          <span class="text-muted">Sem conteúdo</span>
                        </cfif>
                      </td>
                      <td style="max-width: 220px;">
                        <cfif len(trim(link))>
                          <a href="#htmlEditFormat(link)#" target="_blank" rel="noopener noreferrer">#htmlEditFormat(link)#</a>
                        <cfelse>
                          <span class="text-muted">Sem link</span>
                        </cfif>
                      </td>
                      <td>
                        <div>#LSDateTimeFormat(data_publicacao, "dd/mm/yyyy HH:nn")#</div>
                        <div class="small text-muted">
                          <cfif isDate(data_expiracao)>
                            Expira em #LSDateTimeFormat(data_expiracao, "dd/mm/yyyy HH:nn")#
                          <cfelse>
                            Sem expiração
                          </cfif>
                        </div>
                      </td>
                      <td>
                        <cfif isDate(data_leitura)>
                          <span class="badge badge-success">Lida</span>
                        <cfelse>
                          <span class="badge badge-secondary">Não lida</span>
                        </cfif>
                        <cfif NOT isDate(data_expiracao) OR data_expiracao GTE now()>
                          <span class="badge badge-warning text-dark">Ativa</span>
                        <cfelse>
                          <span class="badge badge-dark">Expirada</span>
                        </cfif>
                      </td>
                      <td>
                        <div class="d-flex flex-wrap gap-2">
                          <a class="btn btn-sm btn-outline-warning" href="./?acao=desativar&id_notifica=#id_notifica#&pagina=#VARIABLES.notificaPage#&busca=#urlEncodedFormat(VARIABLES.notificaBusca)#&template_id=#urlEncodedFormat(VARIABLES.notificaTemplateId)#&campanha=#urlEncodedFormat(VARIABLES.notificaCampanha)#&leitura=#urlEncodedFormat(VARIABLES.notificaLeitura)#&data_publicacao_inicial=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoInicial)#&data_publicacao_final=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoFinal)#" onclick="return confirm('Tem certeza que deseja desativar esta notificação?');">Desativar</a>
                          <a class="btn btn-sm btn-outline-danger" href="./?acao=excluir&id_notifica=#id_notifica#&pagina=#VARIABLES.notificaPage#&busca=#urlEncodedFormat(VARIABLES.notificaBusca)#&template_id=#urlEncodedFormat(VARIABLES.notificaTemplateId)#&campanha=#urlEncodedFormat(VARIABLES.notificaCampanha)#&leitura=#urlEncodedFormat(VARIABLES.notificaLeitura)#&data_publicacao_inicial=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoInicial)#&data_publicacao_final=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoFinal)#" onclick="return confirm('Tem certeza que deseja excluir esta notificação?');">Excluir</a>
                        </div>
                      </td>
                    </tr>
                  </cfoutput>
                <cfelse>
                  <tr>
                    <td colspan="8" class="text-center text-muted py-4">Nenhuma notificação encontrada com os filtros atuais.</td>
                  </tr>
                </cfif>
              </tbody>
            </table>
          </div>

          <cfif VARIABLES.notificaTotalPages GT 1>
            <div class="d-flex flex-wrap gap-2 justify-content-end mt-3">
              <cfif VARIABLES.notificaPage GT 1>
                <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.notificaPage - 1#&busca=#urlEncodedFormat(VARIABLES.notificaBusca)#&template_id=#urlEncodedFormat(VARIABLES.notificaTemplateId)#&campanha=#urlEncodedFormat(VARIABLES.notificaCampanha)#&leitura=#urlEncodedFormat(VARIABLES.notificaLeitura)#&data_publicacao_inicial=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoInicial)#&data_publicacao_final=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoFinal)#">Anterior</a></cfoutput>
              </cfif>
              <cfif VARIABLES.notificaPage LT VARIABLES.notificaTotalPages>
                <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.notificaPage + 1#&busca=#urlEncodedFormat(VARIABLES.notificaBusca)#&template_id=#urlEncodedFormat(VARIABLES.notificaTemplateId)#&campanha=#urlEncodedFormat(VARIABLES.notificaCampanha)#&leitura=#urlEncodedFormat(VARIABLES.notificaLeitura)#&data_publicacao_inicial=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoInicial)#&data_publicacao_final=#urlEncodedFormat(VARIABLES.notificaDataPublicacaoFinal)#">Próxima</a></cfoutput>
              </cfif>
            </div>
          </cfif>

        </div>

      </div>

    </div>

  </div>

</section>
