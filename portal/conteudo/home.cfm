<cfinclude template="../includes/event_content_kpi_backend.cfm"/>

<style>
  .event-content-page .content-filter,
  .event-content-page .content-metric,
  .event-content-page .content-panel {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 8px;
    background: rgba(255, 255, 255, .03);
  }

  .event-content-page .content-filter,
  .event-content-page .content-panel {
    padding: 1rem;
  }

  .event-content-page .content-metric {
    height: 100%;
    padding: 1rem;
  }

  .event-content-page .content-metric-label {
    color: var(--mdb-secondary-color);
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .04em;
    text-transform: uppercase;
  }

  .event-content-page .content-table {
    min-width: 1160px;
  }

  .event-content-page .content-table th,
  .event-content-page .content-table td {
    vertical-align: middle;
  }

  .event-content-page .content-text-cell {
    max-width: 430px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .event-content-page .content-badges {
    display: flex;
    flex-wrap: wrap;
    gap: .35rem;
  }

  .event-content-page .content-progress {
    height: 6px;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body event-content-page">

          <div class="d-flex flex-column flex-xl-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Conteudo das provas</h3>
              <p class="text-muted mb-0">KPIs de completude para saber quais provas precisam de conteudo, inscricao, categorias, organizador e dados basicos.</p>
            </div>
            <div class="text-xl-end">
              <div class="small text-muted">Ano monitorado</div>
              <div class="h4 mb-0"><cfoutput>#VARIABLES.eventContentKpiYear#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar os KPIs de conteudo do Portal.
            </div>
          <cfelseif NOT VARIABLES.eventContentKpiTablesReady>
            <div class="alert alert-warning mb-0">
              A tabela <strong>tb_evento_corridas</strong> precisa existir neste ambiente.
            </div>
          <cfelse>
            <form class="content-filter mb-4" method="get" action="./">
              <div class="row g-3 align-items-end">
                <div class="col-md-1">
                  <label class="form-label">Ano</label>
                  <select class="form-select" name="ano">
                    <cfloop from="#VARIABLES.eventContentKpiCurrentYear + 2#" to="#VARIABLES.eventContentKpiCurrentYear - 2#" index="yearOption" step="-1">
                      <cfoutput><option value="#yearOption#"<cfif VARIABLES.eventContentKpiYear EQ yearOption> selected</cfif>>#yearOption#</option></cfoutput>
                    </cfloop>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Recorte</label>
                  <select class="form-select" name="recorte">
                    <option value="futuros"<cfif VARIABLES.eventContentKpiRecorte EQ "futuros"> selected</cfif>>Pro frente</option>
                    <option value="ano"<cfif VARIABLES.eventContentKpiRecorte EQ "ano"> selected</cfif>>Ano inteiro</option>
                    <option value="passados"<cfif VARIABLES.eventContentKpiRecorte EQ "passados"> selected</cfif>>Ja passaram</option>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Situacao</label>
                  <select class="form-select" name="situacao">
                    <option value="ativos"<cfif VARIABLES.eventContentKpiSituacao EQ "ativos"> selected</cfif>>Ativos</option>
                    <option value="todos"<cfif VARIABLES.eventContentKpiSituacao EQ "todos"> selected</cfif>>Todos</option>
                    <option value="inativos"<cfif VARIABLES.eventContentKpiSituacao EQ "inativos"> selected</cfif>>Inativos</option>
                  </select>
                </div>

                <div class="col-md-1">
                  <label class="form-label">UF</label>
                  <select class="form-select" name="estado">
                    <option value="">Todas</option>
                    <cfoutput query="qEventContentKpiStates">
                      <option value="#htmlEditFormat(qEventContentKpiStates.estado)#"<cfif VARIABLES.eventContentKpiEstado EQ qEventContentKpiStates.estado> selected</cfif>>#htmlEditFormat(qEventContentKpiStates.estado)#</option>
                    </cfoutput>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Falta na fila</label>
                  <select class="form-select" name="falta">
                    <option value="incompletos"<cfif VARIABLES.eventContentKpiMissingFilter EQ "incompletos"> selected</cfif>>Qualquer campo</option>
                    <option value="descricao"<cfif VARIABLES.eventContentKpiMissingFilter EQ "descricao"> selected</cfif>>Descricao</option>
                    <option value="inscricao"<cfif VARIABLES.eventContentKpiMissingFilter EQ "inscricao"> selected</cfif>>Link inscricao</option>
                    <option value="categorias"<cfif VARIABLES.eventContentKpiMissingFilter EQ "categorias"> selected</cfif>>Categorias</option>
                    <option value="organizador"<cfif VARIABLES.eventContentKpiMissingFilter EQ "organizador"> selected</cfif>>Organizador</option>
                    <option value="local"<cfif VARIABLES.eventContentKpiMissingFilter EQ "local"> selected</cfif>>Local</option>
                    <option value="endereco"<cfif VARIABLES.eventContentKpiMissingFilter EQ "endereco"> selected</cfif>>Endereco</option>
                    <option value="imagem"<cfif VARIABLES.eventContentKpiMissingFilter EQ "imagem"> selected</cfif>>Imagem</option>
                    <option value="todos"<cfif VARIABLES.eventContentKpiMissingFilter EQ "todos"> selected</cfif>>Todas as provas</option>
                  </select>
                </div>

                <div class="col-md-3">
                  <label class="form-label">Busca</label>
                  <input type="search" class="form-control" name="busca" value="<cfoutput>#htmlEditFormat(VARIABLES.eventContentKpiSearch)#</cfoutput>" placeholder="Evento, tag, cidade ou organizador"/>
                </div>

                <div class="col-md-1">
                  <button type="submit" class="btn btn-warning w-100">Filtrar</button>
                </div>
              </div>
            </form>

            <div class="row g-3 mb-4">
              <div class="col-sm-6 col-xl-2">
                <div class="content-metric">
                  <div class="content-metric-label mb-1">Provas</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventContentKpiStats.total, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="content-metric">
                  <div class="content-metric-label mb-1">Completude media</div>
                  <div class="h4 mb-0"><cfoutput>#numberFormat(VARIABLES.eventContentKpiStats.completudeMedia, "9.9")#%</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="content-metric">
                  <div class="content-metric-label mb-1">Completas</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventContentKpiStats.completos, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="content-metric">
                  <div class="content-metric-label mb-1">Incompletas</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventContentKpiStats.incompletos, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="content-metric">
                  <div class="content-metric-label mb-1">Criticas</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventContentKpiStats.criticos, "9,999,999")#</cfoutput></div>
                  <div class="small text-muted">3+ campos faltando</div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="content-metric">
                  <div class="content-metric-label mb-1">Proximos 30 dias</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.eventContentKpiStats.proximos30, "9,999,999")#</cfoutput></div>
                  <div class="small text-muted">incompletas</div>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-5">
                <div class="content-panel h-100">
                  <h5 class="mb-3">Cobertura por campo</h5>
                  <cfif qEventContentKpiFieldsSorted.recordcount>
                    <cfoutput query="qEventContentKpiFieldsSorted">
                      <div class="mb-3">
                        <div class="d-flex justify-content-between gap-3 mb-1">
                          <div>#htmlEditFormat(qEventContentKpiFieldsSorted.campo)#</div>
                          <div class="text-end">
                            <strong>#numberFormat(qEventContentKpiFieldsSorted.percentual, "9.9")#%</strong>
                            <span class="text-muted small">#LSNumberFormat(qEventContentKpiFieldsSorted.total_ok, "9,999")#/#LSNumberFormat(VARIABLES.eventContentKpiStats.total, "9,999")#</span>
                          </div>
                        </div>
                        <div class="progress content-progress">
                          <div class="progress-bar bg-warning" role="progressbar" style="width: #min(100, qEventContentKpiFieldsSorted.percentual)#%"></div>
                        </div>
                        <div class="small text-muted mt-1">Faltando: #LSNumberFormat(qEventContentKpiFieldsSorted.total_missing, "9,999")#</div>
                      </div>
                    </cfoutput>
                  <cfelse>
                    <div class="text-muted">Nenhuma prova encontrada no recorte.</div>
                  </cfif>
                </div>
              </div>

              <div class="col-xl-3">
                <div class="content-panel h-100">
                  <h5 class="mb-3">Por UF</h5>
                  <cfif qEventContentKpiByStateSorted.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped mb-0">
                        <thead>
                          <tr>
                            <th>UF</th>
                            <th>Total</th>
                            <th>Incomp.</th>
                            <th>Media</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qEventContentKpiByStateSorted">
                            <tr>
                              <td>#htmlEditFormat(qEventContentKpiByStateSorted.estado)#</td>
                              <td>#LSNumberFormat(qEventContentKpiByStateSorted.total, "9,999")#</td>
                              <td>#LSNumberFormat(qEventContentKpiByStateSorted.incompletos, "9,999")#</td>
                              <td>#numberFormat(qEventContentKpiByStateSorted.completude_media, "9.9")#%</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem dados por UF.</div>
                  </cfif>
                </div>
              </div>

              <div class="col-xl-4">
                <div class="content-panel h-100">
                  <h5 class="mb-3">Por mes</h5>
                  <cfif qEventContentKpiByMonthSorted.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped mb-0">
                        <thead>
                          <tr>
                            <th>Mes</th>
                            <th>Total</th>
                            <th>Incompletas</th>
                            <th>Media</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qEventContentKpiByMonthSorted">
                            <tr>
                              <td>#htmlEditFormat(qEventContentKpiByMonthSorted.mes)#</td>
                              <td>#LSNumberFormat(qEventContentKpiByMonthSorted.total, "9,999")#</td>
                              <td>#LSNumberFormat(qEventContentKpiByMonthSorted.incompletos, "9,999")#</td>
                              <td>#numberFormat(qEventContentKpiByMonthSorted.completude_media, "9.9")#%</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem dados por mes.</div>
                  </cfif>
                </div>
              </div>
            </div>

            <div class="content-panel">
              <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                <div>
                  <h5 class="mb-1">Fila de ataque</h5>
                  <div class="text-muted small"><cfoutput>#LSNumberFormat(VARIABLES.eventContentKpiAttackTotal, "9,999")# provas no filtro; exibindo ate #qEventContentKpiAttack.recordcount#</cfoutput></div>
                </div>
              </div>

              <cfif qEventContentKpiAttack.recordcount>
                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover content-table mb-0">
                    <thead>
                      <tr>
                        <th>Data</th>
                        <th>Prova</th>
                        <th>Local</th>
                        <th>Score</th>
                        <th>Faltando</th>
                        <th>Organizador</th>
                        <th>Acoes</th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qEventContentKpiAttack">
                        <tr>
                          <td nowrap>
                            #eventContentKpiFormatDate(qEventContentKpiAttack.data_inicial)#
                            <div class="small text-muted">
                              <cfif val(qEventContentKpiAttack.dias_ate_evento) GTE 0>
                                em #LSNumberFormat(qEventContentKpiAttack.dias_ate_evento, "9,999")# dias
                              <cfelse>
                                passou ha #LSNumberFormat(abs(qEventContentKpiAttack.dias_ate_evento), "9,999")# dias
                              </cfif>
                            </div>
                          </td>
                          <td class="content-text-cell">
                            <strong>#htmlEditFormat(qEventContentKpiAttack.nome_evento)#</strong>
                            <div class="small text-muted">ID #qEventContentKpiAttack.id_evento# <cfif len(trim(qEventContentKpiAttack.status_evento))>- #htmlEditFormat(qEventContentKpiAttack.status_evento)#</cfif></div>
                          </td>
                          <td>#htmlEditFormat(qEventContentKpiAttack.cidade)#<cfif len(trim(qEventContentKpiAttack.estado))>/#htmlEditFormat(qEventContentKpiAttack.estado)#</cfif></td>
                          <td nowrap>
                            <strong>#numberFormat(qEventContentKpiAttack.completude, "9.9")#%</strong>
                            <div class="small text-muted">#qEventContentKpiAttack.required_count#/#VARIABLES.eventContentKpiRequiredFields# campos</div>
                          </td>
                          <td class="content-text-cell">
                            <cfif len(trim(qEventContentKpiAttack.faltando))>
                              <div class="content-badges">
                                <cfloop list="#qEventContentKpiAttack.faltando#" index="missingLabel" delimiters=",">
                                  <span class="badge badge-warning">#htmlEditFormat(trim(missingLabel))#</span>
                                </cfloop>
                              </div>
                            <cfelse>
                              <span class="badge badge-success">Completo</span>
                            </cfif>
                          </td>
                          <td class="content-text-cell">#htmlEditFormat(eventContentKpiShortText(qEventContentKpiAttack.organizador_label, 120))#</td>
                          <td nowrap>
                            <a class="btn btn-sm btn-outline-light" href="/admin/?periodo=#VARIABLES.eventContentKpiYear#&id_evento=#qEventContentKpiAttack.id_evento#">Editar</a>
                            <cfif len(trim(qEventContentKpiAttack.tag))>
                              <a class="btn btn-sm btn-outline-light" target="processar" href="https://roadrunners.run/evento/#qEventContentKpiAttack.tag#/">Ver</a>
                            </cfif>
                            <a class="btn btn-sm btn-outline-light" target="processar" href="https://google.com.br/search?q=#urlEncodedFormat(qEventContentKpiAttack.nome_evento)#">Google</a>
                          </td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              <cfelse>
                <div class="text-muted">Nenhuma prova encontrada para a fila selecionada.</div>
              </cfif>
            </div>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
