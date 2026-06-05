<cfinclude template="../includes/event_analytics_backend.cfm"/>

<cfset VARIABLES.eventAnalyticsBaseQuery = "dias=#urlEncodedFormat(VARIABLES.eventAnalyticsDays)#&limite=#urlEncodedFormat(VARIABLES.eventAnalyticsSampleLimit)#&bot=#urlEncodedFormat(VARIABLES.eventAnalyticsBotFilter)#"/>
<cfif len(VARIABLES.eventAnalyticsSite)>
  <cfset VARIABLES.eventAnalyticsBaseQuery = VARIABLES.eventAnalyticsBaseQuery & "&site=#urlEncodedFormat(VARIABLES.eventAnalyticsSite)#"/>
</cfif>
<cfif len(VARIABLES.eventAnalyticsTerm)>
  <cfset VARIABLES.eventAnalyticsBaseQuery = VARIABLES.eventAnalyticsBaseQuery & "&termo=#urlEncodedFormat(VARIABLES.eventAnalyticsTerm)#"/>
</cfif>

<style>
  .event-analytics-page .analytics-filter,
  .event-analytics-page .analytics-metric,
  .event-analytics-page .analytics-panel {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 8px;
    background: rgba(255, 255, 255, .03);
  }

  .event-analytics-page .analytics-filter,
  .event-analytics-page .analytics-panel {
    padding: 1rem;
  }

  .event-analytics-page .analytics-metric {
    height: 100%;
    padding: 1rem;
  }

  .event-analytics-page .analytics-metric-label {
    color: var(--mdb-secondary-color);
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .04em;
    text-transform: uppercase;
  }

  .event-analytics-page .analytics-table {
    min-width: 1120px;
  }

  .event-analytics-page .analytics-table th,
  .event-analytics-page .analytics-table td {
    vertical-align: middle;
  }

  .event-analytics-page .analytics-text-cell {
    max-width: 420px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .event-analytics-page .analytics-badges {
    display: flex;
    flex-wrap: wrap;
    gap: .35rem;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body event-analytics-page">

          <div class="d-flex flex-column flex-xl-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Eventos visitados</h3>
              <p class="text-muted mb-0">Analise carregamentos de paginas de evento a partir da <strong>tb_log</strong>, usando <strong>log_item = evento</strong>.</p>
            </div>
            <div class="text-xl-end">
              <div class="small text-muted">Amostra maxima</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventAnalyticsSampleLimit, "9,999")# logs</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o analytics de eventos do Portal.
            </div>
          <cfelseif NOT VARIABLES.eventAnalyticsTablesReady>
            <div class="alert alert-warning mb-0">
              As tabelas <strong>tb_log</strong> e <strong>tb_evento_corridas</strong> precisam existir neste ambiente.
            </div>
          <cfelse>
            <form class="analytics-filter mb-4" method="get" action="./">
              <div class="row g-3 align-items-end">
                <div class="col-md-2">
                  <label class="form-label">Periodo</label>
                  <select class="form-select" name="dias">
                    <option value="1"<cfif VARIABLES.eventAnalyticsDays EQ 1> selected</cfif>>1 dia</option>
                    <option value="7"<cfif VARIABLES.eventAnalyticsDays EQ 7> selected</cfif>>7 dias</option>
                    <option value="30"<cfif VARIABLES.eventAnalyticsDays EQ 30> selected</cfif>>30 dias</option>
                    <option value="90"<cfif VARIABLES.eventAnalyticsDays EQ 90> selected</cfif>>90 dias</option>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Site</label>
                  <select class="form-select" name="site">
                    <option value="">Todos</option>
                    <option value="RR"<cfif VARIABLES.eventAnalyticsSite EQ "RR"> selected</cfif>>RR</option>
                    <option value="OR"<cfif VARIABLES.eventAnalyticsSite EQ "OR"> selected</cfif>>OR</option>
                    <option value="CT"<cfif VARIABLES.eventAnalyticsSite EQ "CT"> selected</cfif>>CT</option>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Bots</label>
                  <select class="form-select" name="bot">
                    <option value="todos"<cfif VARIABLES.eventAnalyticsBotFilter EQ "todos"> selected</cfif>>Todos</option>
                    <option value="nao"<cfif VARIABLES.eventAnalyticsBotFilter EQ "nao"> selected</cfif>>Sem bots</option>
                    <option value="sim"<cfif VARIABLES.eventAnalyticsBotFilter EQ "sim"> selected</cfif>>So bots</option>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Amostra</label>
                  <select class="form-select" name="limite">
                    <option value="500"<cfif VARIABLES.eventAnalyticsSampleLimit EQ 500> selected</cfif>>500</option>
                    <option value="1000"<cfif VARIABLES.eventAnalyticsSampleLimit EQ 1000> selected</cfif>>1000</option>
                    <option value="3000"<cfif VARIABLES.eventAnalyticsSampleLimit EQ 3000> selected</cfif>>3000</option>
                  </select>
                </div>

                <div class="col-md-3">
                  <label class="form-label">Termo</label>
                  <input type="search" class="form-control" name="termo" value="<cfoutput>#htmlEditFormat(VARIABLES.eventAnalyticsTerm)#</cfoutput>" placeholder="Evento, tag, cidade, estado, IP ou agente"/>
                </div>

                <div class="col-md-1">
                  <button type="submit" class="btn btn-warning w-100">Filtrar</button>
                </div>
              </div>
            </form>

            <div class="alert alert-info">
              Os numeros sao calculados sobre a amostra recente da <strong>tb_log</strong>. O fluxo usa a sequencia de eventos por origem textual (<code>log_user</code>), entao e uma aproximacao, nao uma sessao web real.
            </div>

            <div class="row g-3 mb-4">
              <div class="col-sm-6 col-xl-2">
                <div class="analytics-metric">
                  <div class="analytics-metric-label mb-1">Pageviews</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventAnalyticsStats.pageviews, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="analytics-metric">
                  <div class="analytics-metric-label mb-1">Eventos</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventAnalyticsStats.eventos, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="analytics-metric">
                  <div class="analytics-metric-label mb-1">Origens</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventAnalyticsStats.origens, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="analytics-metric">
                  <div class="analytics-metric-label mb-1">Bots</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventAnalyticsStats.bots, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="analytics-metric">
                  <div class="analytics-metric-label mb-1">Mobile</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventAnalyticsStats.mobile, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="analytics-metric">
                  <div class="analytics-metric-label mb-1">Sem cadastro</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventAnalyticsStats.semCadastro, "9,999,999")#</cfoutput></div>
                </div>
              </div>
            </div>

            <cfif VARIABLES.eventAnalyticsEventId GT 0>
              <div class="analytics-panel mb-4">
                <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                  <div>
                    <h5 class="mb-1">
                      <cfif qEventAnalyticsDetailEvent.recordcount>
                        <cfoutput>#htmlEditFormat(qEventAnalyticsDetailEvent.nome_evento)#</cfoutput>
                      <cfelse>
                        <cfoutput>Evento ###VARIABLES.eventAnalyticsEventId#</cfoutput>
                      </cfif>
                    </h5>
                    <div class="text-muted small">
                      <cfif qEventAnalyticsDetailEvent.recordcount>
                        <cfoutput>
                          #qEventAnalyticsDetailEvent.id_evento# -
                          #htmlEditFormat(qEventAnalyticsDetailEvent.cidade)#/#htmlEditFormat(qEventAnalyticsDetailEvent.estado)# -
                          #dateFormat(qEventAnalyticsDetailEvent.data_inicial, "dd/mm/yyyy")#
                        </cfoutput>
                      <cfelse>
                        Cadastro do evento nao localizado.
                      </cfif>
                    </div>
                  </div>
                  <cfoutput><a class="btn btn-sm btn-outline-light" href="./?#VARIABLES.eventAnalyticsBaseQuery#">Fechar detalhe</a></cfoutput>
                </div>

                <cfif qEventAnalyticsDetailStats.recordcount>
                  <div class="row g-3 mb-3">
                    <div class="col-sm-6 col-xl-2"><div class="analytics-metric"><div class="analytics-metric-label mb-1">Views</div><div class="h5 mb-0"><cfoutput>#LSNumberFormat(qEventAnalyticsDetailStats.views, "9,999,999")#</cfoutput></div></div></div>
                    <div class="col-sm-6 col-xl-2"><div class="analytics-metric"><div class="analytics-metric-label mb-1">Origens</div><div class="h5 mb-0"><cfoutput>#LSNumberFormat(qEventAnalyticsDetailStats.origens, "9,999,999")#</cfoutput></div></div></div>
                    <div class="col-sm-6 col-xl-2"><div class="analytics-metric"><div class="analytics-metric-label mb-1">Bots</div><div class="h5 mb-0"><cfoutput>#LSNumberFormat(qEventAnalyticsDetailStats.bots, "9,999,999")#</cfoutput></div></div></div>
                    <div class="col-sm-6 col-xl-2"><div class="analytics-metric"><div class="analytics-metric-label mb-1">Mobile</div><div class="h5 mb-0"><cfoutput>#LSNumberFormat(qEventAnalyticsDetailStats.mobile, "9,999,999")#</cfoutput></div></div></div>
                    <div class="col-sm-6 col-xl-2"><div class="analytics-metric"><div class="analytics-metric-label mb-1">Primeiro</div><div class="small mb-0"><cfoutput>#eventAnalyticsFormatDateTime(qEventAnalyticsDetailStats.primeiro_acesso)#</cfoutput></div></div></div>
                    <div class="col-sm-6 col-xl-2"><div class="analytics-metric"><div class="analytics-metric-label mb-1">Ultimo</div><div class="small mb-0"><cfoutput>#eventAnalyticsFormatDateTime(qEventAnalyticsDetailStats.ultimo_acesso)#</cfoutput></div></div></div>
                  </div>
                </cfif>

                <cfif qEventAnalyticsDetailRecent.recordcount>
                  <div class="table-responsive">
                    <table class="table table-sm table-striped table-hover analytics-table mb-0">
                      <thead>
                        <tr>
                          <th>Data</th>
                          <th>Origem</th>
                          <th>Site</th>
                          <th>Dispositivo</th>
                          <th>Navegador</th>
                          <th>User agent</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventAnalyticsDetailRecent">
                          <tr>
                            <td>#eventAnalyticsFormatDateTime(qEventAnalyticsDetailRecent.log_timestamp)#</td>
                            <td>#htmlEditFormat(qEventAnalyticsDetailRecent.log_user)#</td>
                            <td><span class="badge badge-secondary">#htmlEditFormat(qEventAnalyticsDetailRecent.site)#</span></td>
                            <td>#htmlEditFormat(qEventAnalyticsDetailRecent.dispositivo)#</td>
                            <td>#htmlEditFormat(qEventAnalyticsDetailRecent.navegador)#</td>
                            <td class="analytics-text-cell">#htmlEditFormat(eventAnalyticsShortText(qEventAnalyticsDetailRecent.log_user_agent, 180))#</td>
                          </tr>
                        </cfoutput>
                      </tbody>
                    </table>
                  </div>
                </cfif>
              </div>
            </cfif>

            <div class="analytics-panel mb-4">
              <h5 class="mb-3">Eventos mais visitados</h5>
              <cfif qEventAnalyticsTopEvents.recordcount>
                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover analytics-table mb-0">
                    <thead>
                      <tr>
                        <th>Evento</th>
                        <th>Cidade</th>
                        <th>Data</th>
                        <th>Views</th>
                        <th>Origens</th>
                        <th>Bots</th>
                        <th>Ultimo</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qEventAnalyticsTopEvents">
                        <tr>
                          <td class="analytics-text-cell">
                            <strong>#htmlEditFormat(qEventAnalyticsTopEvents.evento_nome)#</strong>
                            <div class="small text-muted">###qEventAnalyticsTopEvents.id_evento# <cfif len(trim(qEventAnalyticsTopEvents.evento_tag))>- #htmlEditFormat(qEventAnalyticsTopEvents.evento_tag)#</cfif></div>
                          </td>
                          <td>#htmlEditFormat(qEventAnalyticsTopEvents.cidade)#<cfif len(trim(qEventAnalyticsTopEvents.estado))>/#htmlEditFormat(qEventAnalyticsTopEvents.estado)#</cfif></td>
                          <td><cfif isDate(qEventAnalyticsTopEvents.data_inicial)>#dateFormat(qEventAnalyticsTopEvents.data_inicial, "dd/mm/yyyy")#</cfif></td>
                          <td>#LSNumberFormat(qEventAnalyticsTopEvents.views, "9,999,999")#</td>
                          <td>#LSNumberFormat(qEventAnalyticsTopEvents.origens, "9,999,999")#</td>
                          <td>#LSNumberFormat(qEventAnalyticsTopEvents.bots, "9,999,999")#</td>
                          <td>#eventAnalyticsFormatDateTime(qEventAnalyticsTopEvents.ultimo_acesso)#</td>
                          <td>
                            <cfif len(trim(qEventAnalyticsTopEvents.id_evento & ""))>
                              <a class="btn btn-sm btn-outline-light" href="./?#VARIABLES.eventAnalyticsBaseQuery#&evento_id=#qEventAnalyticsTopEvents.id_evento#">Detalhe</a>
                            </cfif>
                          </td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              <cfelse>
                <div class="text-muted">Nenhum evento encontrado nos filtros atuais.</div>
              </cfif>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-4">
                <div class="analytics-panel h-100">
                  <h5 class="mb-3">Cidades</h5>
                  <cfif qEventAnalyticsByCity.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead><tr><th>Cidade</th><th>Views</th><th>Eventos</th></tr></thead>
                        <tbody>
                          <cfoutput query="qEventAnalyticsByCity">
                            <tr>
                              <td>#htmlEditFormat(qEventAnalyticsByCity.cidade)#<cfif len(trim(qEventAnalyticsByCity.estado))>/#htmlEditFormat(qEventAnalyticsByCity.estado)#</cfif></td>
                              <td>#LSNumberFormat(qEventAnalyticsByCity.views, "9,999,999")#</td>
                              <td>#LSNumberFormat(qEventAnalyticsByCity.eventos, "9,999,999")#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse><div class="text-muted">Sem cidades.</div></cfif>
                </div>
              </div>

              <div class="col-xl-4">
                <div class="analytics-panel h-100">
                  <h5 class="mb-3">Dispositivos</h5>
                  <cfif qEventAnalyticsByDevice.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead><tr><th>Dispositivo</th><th>Views</th><th>Eventos</th><th>Origens</th></tr></thead>
                        <tbody>
                          <cfoutput query="qEventAnalyticsByDevice">
                            <tr>
                              <td>#htmlEditFormat(qEventAnalyticsByDevice.dispositivo)#</td>
                              <td>#LSNumberFormat(qEventAnalyticsByDevice.views, "9,999,999")#</td>
                              <td>#LSNumberFormat(qEventAnalyticsByDevice.eventos, "9,999,999")#</td>
                              <td>#LSNumberFormat(qEventAnalyticsByDevice.origens, "9,999,999")#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse><div class="text-muted">Sem dispositivos.</div></cfif>
                </div>
              </div>

              <div class="col-xl-4">
                <div class="analytics-panel h-100">
                  <h5 class="mb-3">Sites</h5>
                  <cfif qEventAnalyticsBySite.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead><tr><th>Site</th><th>Views</th><th>Eventos</th><th>Bots</th></tr></thead>
                        <tbody>
                          <cfoutput query="qEventAnalyticsBySite">
                            <tr>
                              <td><span class="badge badge-secondary">#htmlEditFormat(qEventAnalyticsBySite.site)#</span></td>
                              <td>#LSNumberFormat(qEventAnalyticsBySite.views, "9,999,999")#</td>
                              <td>#LSNumberFormat(qEventAnalyticsBySite.eventos, "9,999,999")#</td>
                              <td>#LSNumberFormat(qEventAnalyticsBySite.bots, "9,999,999")#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse><div class="text-muted">Sem sites.</div></cfif>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="analytics-panel h-100">
                  <h5 class="mb-3">Fluxo aproximado entre eventos</h5>
                  <cfif qEventAnalyticsFlow.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover analytics-table mb-0">
                        <thead><tr><th>De</th><th>Para</th><th>Transições</th><th>Origens</th></tr></thead>
                        <tbody>
                          <cfoutput query="qEventAnalyticsFlow">
                            <tr>
                              <td class="analytics-text-cell">#htmlEditFormat(qEventAnalyticsFlow.evento_anterior_nome)#</td>
                              <td class="analytics-text-cell">#htmlEditFormat(qEventAnalyticsFlow.evento_atual_nome)#</td>
                              <td>#LSNumberFormat(qEventAnalyticsFlow.transicoes, "9,999,999")#</td>
                              <td>#LSNumberFormat(qEventAnalyticsFlow.origens, "9,999,999")#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem transicoes suficientes na amostra.</div>
                  </cfif>
                </div>
              </div>

              <div class="col-xl-6">
                <div class="analytics-panel h-100">
                  <h5 class="mb-3">Top origens</h5>
                  <cfif qEventAnalyticsOrigins.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover analytics-table mb-0">
                        <thead><tr><th>Origem</th><th>Views</th><th>Eventos</th><th>Ultimo agente</th></tr></thead>
                        <tbody>
                          <cfoutput query="qEventAnalyticsOrigins">
                            <tr>
                              <td>#htmlEditFormat(qEventAnalyticsOrigins.log_user)#</td>
                              <td>#LSNumberFormat(qEventAnalyticsOrigins.views, "9,999,999")#</td>
                              <td>#LSNumberFormat(qEventAnalyticsOrigins.eventos, "9,999,999")#</td>
                              <td class="analytics-text-cell">#htmlEditFormat(eventAnalyticsShortText(qEventAnalyticsOrigins.ultimo_user_agent, 160))#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem origens para listar.</div>
                  </cfif>
                </div>
              </div>
            </div>

            <div class="analytics-panel mb-4">
              <h5 class="mb-3">Volume por hora</h5>
              <cfif qEventAnalyticsByHour.recordcount>
                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover mb-0">
                    <thead><tr><th>Hora</th><th>Views</th><th>Eventos</th><th>Bots</th></tr></thead>
                    <tbody>
                      <cfoutput query="qEventAnalyticsByHour">
                        <tr>
                          <td>#dateTimeFormat(qEventAnalyticsByHour.hora, "dd/mm HH:nn")#</td>
                          <td>#LSNumberFormat(qEventAnalyticsByHour.views, "9,999,999")#</td>
                          <td>#LSNumberFormat(qEventAnalyticsByHour.eventos, "9,999,999")#</td>
                          <td>#LSNumberFormat(qEventAnalyticsByHour.bots, "9,999,999")#</td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              <cfelse>
                <div class="text-muted">Sem volume por hora.</div>
              </cfif>
            </div>

            <div class="analytics-panel">
              <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                <div>
                  <h5 class="mb-1">Ultimos acessos a eventos</h5>
                  <div class="text-muted small"><cfoutput>Exibindo ate #VARIABLES.eventAnalyticsDisplayLimit# registros da amostra filtrada</cfoutput></div>
                </div>
                <a class="btn btn-outline-light btn-sm" href="./">Voltar ao padrao</a>
              </div>

              <cfif qEventAnalyticsRecent.recordcount>
                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover analytics-table mb-0">
                    <thead>
                      <tr>
                        <th>Data</th>
                        <th>Evento</th>
                        <th>Site</th>
                        <th>Origem</th>
                        <th>Dispositivo</th>
                        <th>Navegador</th>
                        <th>User agent</th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qEventAnalyticsRecent">
                        <tr>
                          <td>#eventAnalyticsFormatDateTime(qEventAnalyticsRecent.log_timestamp)#</td>
                          <td class="analytics-text-cell">
                            <strong>#htmlEditFormat(qEventAnalyticsRecent.evento_nome)#</strong>
                            <div class="small text-muted">###qEventAnalyticsRecent.id_evento# <cfif len(trim(qEventAnalyticsRecent.cidade))>- #htmlEditFormat(qEventAnalyticsRecent.cidade)#/#htmlEditFormat(qEventAnalyticsRecent.estado)#</cfif></div>
                          </td>
                          <td><span class="badge badge-secondary">#htmlEditFormat(qEventAnalyticsRecent.site)#</span></td>
                          <td>#htmlEditFormat(qEventAnalyticsRecent.log_user)#</td>
                          <td>
                            #htmlEditFormat(qEventAnalyticsRecent.dispositivo)#
                            <cfif qEventAnalyticsRecent.parece_bot><span class="badge badge-warning ms-1">bot</span></cfif>
                          </td>
                          <td>#htmlEditFormat(qEventAnalyticsRecent.navegador)#</td>
                          <td class="analytics-text-cell">#htmlEditFormat(eventAnalyticsShortText(qEventAnalyticsRecent.log_user_agent, 180))#</td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              <cfelse>
                <div class="text-muted">Nenhum acesso encontrado para os filtros atuais.</div>
              </cfif>
            </div>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
