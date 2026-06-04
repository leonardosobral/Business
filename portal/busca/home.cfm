<cfinclude template="../includes/search_backend.cfm"/>

<cfset VARIABLES.searchLogBaseQuery = "dias=#urlEncodedFormat(VARIABLES.searchLogDays)#"/>
<cfif len(VARIABLES.searchLogAmbiente)>
  <cfset VARIABLES.searchLogBaseQuery = VARIABLES.searchLogBaseQuery & "&ambiente=#urlEncodedFormat(VARIABLES.searchLogAmbiente)#"/>
</cfif>
<cfif len(VARIABLES.searchLogTerm)>
  <cfset VARIABLES.searchLogBaseQuery = VARIABLES.searchLogBaseQuery & "&termo=#urlEncodedFormat(VARIABLES.searchLogTerm)#"/>
</cfif>

<style>
  .search-log-page .search-filter {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 8px;
    background: rgba(255, 255, 255, .03);
    padding: 1rem;
  }

  .search-log-page .search-metric {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 8px;
    background: rgba(255, 255, 255, .03);
    height: 100%;
    padding: 1rem;
  }

  .search-log-page .search-metric-label {
    color: var(--mdb-secondary-color);
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .04em;
    text-transform: uppercase;
  }

  .search-log-page .search-panel {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 8px;
    background: rgba(255, 255, 255, .03);
    padding: 1rem;
  }

  .search-log-page .search-table {
    min-width: 980px;
  }

  .search-log-page .search-table th,
  .search-log-page .search-table td {
    vertical-align: middle;
  }

  .search-log-page .search-term-cell {
    max-width: 360px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .search-log-page .search-json {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 8px;
    background: rgba(0, 0, 0, .18);
    color: var(--mdb-body-color);
    font-size: .78rem;
    max-height: 320px;
    overflow: auto;
    padding: .8rem;
    white-space: pre-wrap;
  }

  .search-log-page .search-badge-list {
    display: flex;
    flex-wrap: wrap;
    gap: .35rem;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body search-log-page">

          <div class="d-flex flex-column flex-xl-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Busca do site</h3>
              <p class="text-muted mb-0">Acompanhe volume, termos, filtros interpretados, buscas sem resultado e falhas da busca inteligente do Road Runners.</p>
            </div>
            <div class="text-xl-end">
              <div class="small text-muted">Janela analisada</div>
              <div class="h4 mb-0"><cfoutput>#VARIABLES.searchLogDays# dias</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar as estatisticas da busca do site.
            </div>
          <cfelseif NOT VARIABLES.searchLogTablesReady>
            <div class="alert alert-warning mb-0">
              A tabela <strong>tb_busca_log</strong> ainda nao foi encontrada neste ambiente.
            </div>
          <cfelse>
            <form class="search-filter mb-4" method="get" action="./">
              <div class="row g-3 align-items-end">
                <div class="col-md-2">
                  <label class="form-label">Periodo</label>
                  <select class="form-select" name="dias">
                    <option value="7"<cfif VARIABLES.searchLogDays EQ 7> selected</cfif>>7 dias</option>
                    <option value="30"<cfif VARIABLES.searchLogDays EQ 30> selected</cfif>>30 dias</option>
                    <option value="90"<cfif VARIABLES.searchLogDays EQ 90> selected</cfif>>90 dias</option>
                    <option value="365"<cfif VARIABLES.searchLogDays EQ 365> selected</cfif>>365 dias</option>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Ambiente</label>
                  <select class="form-select" name="ambiente">
                    <option value="">Todos</option>
                    <option value="prod"<cfif VARIABLES.searchLogAmbiente EQ "prod"> selected</cfif>>Prod</option>
                    <option value="beta"<cfif VARIABLES.searchLogAmbiente EQ "beta"> selected</cfif>>Beta</option>
                    <option value="dev"<cfif VARIABLES.searchLogAmbiente EQ "dev"> selected</cfif>>Dev</option>
                  </select>
                </div>

                <div class="col-md-5">
                  <label class="form-label">Termo</label>
                  <input type="search" class="form-control" name="termo" value="<cfoutput>#htmlEditFormat(VARIABLES.searchLogTerm)#</cfoutput>" placeholder="Buscar por termo digitado"/>
                </div>

                <div class="col-md-3">
                  <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-warning flex-fill">Filtrar</button>
                    <a class="btn btn-outline-light" href="./">Limpar</a>
                  </div>
                </div>
              </div>
            </form>

            <div class="row g-3 mb-4">
              <div class="col-sm-6 col-xl-2">
                <div class="search-metric">
                  <div class="search-metric-label mb-1">Buscas</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.searchLogStats.totalBuscas, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="search-metric">
                  <div class="search-metric-label mb-1">Modo IA</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.searchLogStats.buscasIa, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="search-metric">
                  <div class="search-metric-label mb-1">Chamadas reais</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.searchLogStats.chamadasIa, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="search-metric">
                  <div class="search-metric-label mb-1">Fallbacks</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.searchLogFallbackRate, "9.99")#%</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="search-metric">
                  <div class="search-metric-label mb-1">Erros</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.searchLogStats.erros, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="search-metric">
                  <div class="search-metric-label mb-1">Execucoes</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.searchLogStats.execucoes, "9,999,999")#</cfoutput></div>
                </div>
              </div>
            </div>

            <cfif len(trim(URL.busca_id))>
              <cfif qSearchLogDetailParent.recordcount>
                <div class="search-panel mb-4">
                  <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                    <div>
                      <h5 class="mb-1"><cfoutput>Detalhe da busca ###qSearchLogDetailParent.id_busca_log#</cfoutput></h5>
                      <div class="text-muted small">
                        <cfoutput>
                          #searchLogFormatDateTime(qSearchLogDetailParent.log_timestamp)# -
                          #htmlEditFormat(qSearchLogDetailParent.ambiente)# -
                          #htmlEditFormat(qSearchLogDetailParent.modelo)#
                        </cfoutput>
                      </div>
                    </div>
                    <cfoutput><a class="btn btn-sm btn-outline-light" href="./?#VARIABLES.searchLogBaseQuery#">Fechar detalhe</a></cfoutput>
                  </div>

                  <div class="row g-3 mb-3">
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-1">Termo original</div>
                      <div class="search-term-cell"><cfoutput>#htmlEditFormat(qSearchLogDetailParent.termo_original)#</cfoutput></div>
                    </div>
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-1">Usuario</div>
                      <cfoutput>
                        <div>#htmlEditFormat(len(trim(qSearchLogDetailParent.usuario_nome)) ? qSearchLogDetailParent.usuario_nome : "Usuario " & qSearchLogDetailParent.id_usuario)#</div>
                        <div class="small text-muted">#htmlEditFormat(qSearchLogDetailParent.usuario_email)#</div>
                      </cfoutput>
                    </div>
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-1">Flags</div>
                      <div class="search-badge-list">
                        <cfoutput>
                          <span class="badge badge-secondary">#htmlEditFormat(qSearchLogDetailParent.busca_modo)#</span>
                          <span class="badge badge-secondary">#htmlEditFormat(qSearchLogDetailParent.tipo_termo)#</span>
                          <cfif qSearchLogDetailParent.usou_ia><span class="badge badge-info">usou IA</span></cfif>
                          <cfif qSearchLogDetailParent.fallback_usado><span class="badge badge-warning">fallback</span></cfif>
                          <cfif len(trim(qSearchLogDetailParent.erro))><span class="badge badge-danger">erro</span></cfif>
                        </cfoutput>
                      </div>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-2">Filtros</div>
                      <pre class="search-json mb-0"><cfoutput>#htmlEditFormat(searchLogShortText(qSearchLogDetailParent.filtros_json, 1400))#</cfoutput></pre>
                    </div>
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-2">IA</div>
                      <pre class="search-json mb-0"><cfoutput>#htmlEditFormat(searchLogShortText(qSearchLogDetailParent.ia_json, 1400))#</cfoutput></pre>
                    </div>
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-2">Payload</div>
                      <pre class="search-json mb-0"><cfoutput>#htmlEditFormat(searchLogShortText(qSearchLogDetailParent.payload_json, 1400))#</cfoutput></pre>
                    </div>
                  </div>

                  <cfif qSearchLogDetailChildren.recordcount>
                    <hr/>
                    <h6 class="mb-3">Execucoes por aba</h6>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover search-table mb-0">
                        <thead>
                          <tr>
                            <th>ID</th>
                            <th>Aba</th>
                            <th>Modo</th>
                            <th>Contagens</th>
                            <th>IA</th>
                            <th>Payload</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qSearchLogDetailChildren">
                            <tr>
                              <td>#qSearchLogDetailChildren.id_busca_log#</td>
                              <td>#htmlEditFormat(searchLogScopeLabel(qSearchLogDetailChildren.busca_scope))#</td>
                              <td>#htmlEditFormat(qSearchLogDetailChildren.busca_modo)#</td>
                              <td class="search-term-cell"><code>#htmlEditFormat(searchLogShortText(qSearchLogDetailChildren.contagens_json, 220))#</code></td>
                              <td class="search-term-cell"><code>#htmlEditFormat(searchLogShortText(qSearchLogDetailChildren.ia_json, 220))#</code></td>
                              <td class="search-term-cell"><code>#htmlEditFormat(searchLogShortText(qSearchLogDetailChildren.payload_json, 260))#</code></td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  </cfif>
                </div>
              <cfelse>
                <div class="alert alert-warning">
                  Busca nao encontrada para o ID informado.
                </div>
              </cfif>
            </cfif>

            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="search-panel h-100">
                  <h5 class="mb-3">Volume por dia</h5>
                  <cfif qSearchLogDaily.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Dia</th>
                            <th>Buscas</th>
                            <th>IA</th>
                            <th>Fallbacks</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qSearchLogDaily">
                            <tr>
                              <td>#dateFormat(qSearchLogDaily.dia, "dd/mm/yyyy")#</td>
                              <td>#LSNumberFormat(qSearchLogDaily.total_buscas, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogDaily.buscas_ia, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogDaily.fallbacks, "9,999,999")#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem buscas no periodo selecionado.</div>
                  </cfif>
                </div>
              </div>

              <div class="col-xl-6">
                <div class="search-panel h-100">
                  <h5 class="mb-3">Resultados por aba</h5>
                  <cfif qSearchLogScopes.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Aba</th>
                            <th>Execucoes</th>
                            <th>Total</th>
                            <th>Eventos</th>
                            <th>Resultados</th>
                            <th>Atletas</th>
                            <th>Noticias</th>
                            <th>Videos</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qSearchLogScopes">
                            <tr>
                              <td>#htmlEditFormat(searchLogScopeLabel(qSearchLogScopes.busca_scope))#</td>
                              <td>#LSNumberFormat(qSearchLogScopes.execucoes, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogScopes.total_resultados, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogScopes.eventos, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogScopes.resultados, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogScopes.atletas, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogScopes.noticias, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogScopes.videos, "9,999,999")#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem execucoes registradas no periodo.</div>
                  </cfif>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="search-panel h-100">
                  <h5 class="mb-3">Termos mais buscados</h5>
                  <cfif qSearchLogTopTerms.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Termo</th>
                            <th>Buscas</th>
                            <th>IA</th>
                            <th>Fallbacks</th>
                            <th>Ultima</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qSearchLogTopTerms">
                            <tr>
                              <td class="search-term-cell">#htmlEditFormat(qSearchLogTopTerms.termo)#</td>
                              <td>#LSNumberFormat(qSearchLogTopTerms.buscas, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogTopTerms.buscas_ia, "9,999,999")#</td>
                              <td>#LSNumberFormat(qSearchLogTopTerms.fallbacks, "9,999,999")#</td>
                              <td>#searchLogFormatDateTime(qSearchLogTopTerms.ultima_busca)#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem termos para listar.</div>
                  </cfif>
                </div>
              </div>

              <div class="col-xl-6">
                <div class="search-panel h-100">
                  <h5 class="mb-3">Filtros interpretados</h5>
                  <cfif qSearchLogTopFilters.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Filtro</th>
                            <th>Valor</th>
                            <th>Buscas</th>
                            <th>Ultima</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qSearchLogTopFilters">
                            <tr>
                              <td>#htmlEditFormat(qSearchLogTopFilters.tipo)#</td>
                              <td class="search-term-cell">#htmlEditFormat(qSearchLogTopFilters.valor)#</td>
                              <td>#LSNumberFormat(qSearchLogTopFilters.buscas, "9,999,999")#</td>
                              <td>#searchLogFormatDateTime(qSearchLogTopFilters.ultima_busca)#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem filtros interpretados no periodo.</div>
                  </cfif>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="search-panel h-100">
                  <h5 class="mb-3">Buscas sem resultado</h5>
                  <cfif qSearchLogZeroResults.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Data</th>
                            <th>Termo</th>
                            <th>Total</th>
                            <th></th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qSearchLogZeroResults">
                            <tr>
                              <td>#searchLogFormatDateTime(qSearchLogZeroResults.log_timestamp)#</td>
                              <td class="search-term-cell">#htmlEditFormat(qSearchLogZeroResults.termo_original)#</td>
                              <td>#LSNumberFormat(qSearchLogZeroResults.total_resultados, "9,999,999")#</td>
                              <td><a class="btn btn-sm btn-outline-light" href="./?#VARIABLES.searchLogBaseQuery#&busca_id=#qSearchLogZeroResults.id_busca_log#">Ver</a></td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Nenhuma busca sem resultado encontrada nessa janela.</div>
                  </cfif>
                </div>
              </div>

              <div class="col-xl-6">
                <div class="search-panel h-100">
                  <h5 class="mb-3">Falhas e fallbacks</h5>
                  <cfif qSearchLogFailures.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Data</th>
                            <th>Termo</th>
                            <th>Motivo</th>
                            <th></th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qSearchLogFailures">
                            <tr>
                              <td>#searchLogFormatDateTime(qSearchLogFailures.log_timestamp)#</td>
                              <td class="search-term-cell">#htmlEditFormat(qSearchLogFailures.termo_original)#</td>
                              <td class="search-term-cell">
                                <cfif len(trim(qSearchLogFailures.fallback_motivo))>
                                  #htmlEditFormat(qSearchLogFailures.fallback_motivo)#
                                <cfelseif len(trim(qSearchLogFailures.erro))>
                                  #htmlEditFormat(searchLogShortText(qSearchLogFailures.erro, 120))#
                                <cfelse>
                                  #htmlEditFormat(qSearchLogFailures.http_status)#
                                </cfif>
                              </td>
                              <td><a class="btn btn-sm btn-outline-light" href="./?#VARIABLES.searchLogBaseQuery#&busca_id=#qSearchLogFailures.id_busca_log#">Ver</a></td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Nenhuma falha ou fallback encontrado nessa janela.</div>
                  </cfif>
                </div>
              </div>
            </div>

            <div class="search-panel mb-4">
              <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                <div>
                  <h5 class="mb-1">Ultimas buscas</h5>
                  <div class="text-muted small"><cfoutput>#LSNumberFormat(VARIABLES.searchLogTotalRows, "9,999,999")# registros encontrados</cfoutput></div>
                </div>
                <div class="text-lg-end text-muted small">
                  <cfoutput>Pagina #VARIABLES.searchLogPage# de #VARIABLES.searchLogTotalPages#</cfoutput>
                </div>
              </div>

              <cfif qSearchLogRecent.recordcount>
                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover search-table">
                    <thead>
                      <tr>
                        <th>Data</th>
                        <th>Termo</th>
                        <th>Tipo</th>
                        <th>Usuario</th>
                        <th>Ambiente</th>
                        <th>Resultados</th>
                        <th>Flags</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qSearchLogRecent">
                        <tr>
                          <td>#searchLogFormatDateTime(qSearchLogRecent.log_timestamp)#</td>
                          <td class="search-term-cell">
                            <strong>#htmlEditFormat(qSearchLogRecent.termo_original)#</strong>
                            <cfif len(trim(qSearchLogRecent.termo_livre))>
                              <div class="small text-muted">Livre: #htmlEditFormat(qSearchLogRecent.termo_livre)#</div>
                            </cfif>
                          </td>
                          <td>
                            <div>#htmlEditFormat(qSearchLogRecent.busca_tipo)#</div>
                            <div class="small text-muted">#htmlEditFormat(qSearchLogRecent.tipo_termo)#</div>
                          </td>
                          <td class="search-term-cell">
                            <cfif len(trim(qSearchLogRecent.usuario_nome))>
                              #htmlEditFormat(qSearchLogRecent.usuario_nome)#
                              <div class="small text-muted">#htmlEditFormat(qSearchLogRecent.usuario_email)#</div>
                            <cfelseif len(trim(qSearchLogRecent.id_usuario))>
                              Usuario #qSearchLogRecent.id_usuario#
                            <cfelse>
                              <span class="text-muted">-</span>
                            </cfif>
                          </td>
                          <td>
                            <span class="badge badge-secondary">#htmlEditFormat(qSearchLogRecent.ambiente)#</span>
                            <div class="small text-muted">#htmlEditFormat(qSearchLogRecent.site)#</div>
                          </td>
                          <td>
                            <div class="search-badge-list">
                              <span class="badge badge-info">Total #LSNumberFormat(qSearchLogRecent.total_resultados, "9,999,999")#</span>
                              <span class="badge badge-secondary">E #LSNumberFormat(qSearchLogRecent.eventos, "9,999,999")#</span>
                              <span class="badge badge-secondary">R #LSNumberFormat(qSearchLogRecent.resultados, "9,999,999")#</span>
                              <span class="badge badge-secondary">A #LSNumberFormat(qSearchLogRecent.atletas, "9,999,999")#</span>
                              <span class="badge badge-secondary">N #LSNumberFormat(qSearchLogRecent.noticias, "9,999,999")#</span>
                              <span class="badge badge-secondary">V #LSNumberFormat(qSearchLogRecent.videos, "9,999,999")#</span>
                            </div>
                          </td>
                          <td>
                            <div class="search-badge-list">
                              <span class="badge badge-secondary">#htmlEditFormat(qSearchLogRecent.busca_modo)#</span>
                              <cfif qSearchLogRecent.usou_ia><span class="badge badge-info">IA</span></cfif>
                              <cfif qSearchLogRecent.fallback_usado><span class="badge badge-warning">fallback</span></cfif>
                              <cfif len(trim(qSearchLogRecent.erro))><span class="badge badge-danger">erro</span></cfif>
                            </div>
                          </td>
                          <td><a class="btn btn-sm btn-outline-light" href="./?#VARIABLES.searchLogBaseQuery#&pagina=#VARIABLES.searchLogPage#&busca_id=#qSearchLogRecent.id_busca_log#">Detalhe</a></td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>

                <cfif VARIABLES.searchLogTotalPages GT 1>
                  <nav aria-label="Paginacao de buscas">
                    <ul class="pagination pagination-sm justify-content-center flex-wrap mb-0">
                      <cfoutput>
                        <li class="page-item <cfif VARIABLES.searchLogPage LTE 1>disabled</cfif>">
                          <a class="page-link" href="./?#VARIABLES.searchLogBaseQuery#&pagina=#max(1, VARIABLES.searchLogPage - 1)#">Anterior</a>
                        </li>
                      </cfoutput>

                      <cfloop from="#max(1, VARIABLES.searchLogPage - 3)#" to="#min(VARIABLES.searchLogTotalPages, VARIABLES.searchLogPage + 3)#" index="searchLogPageIndex">
                        <cfoutput>
                          <li class="page-item <cfif searchLogPageIndex EQ VARIABLES.searchLogPage>active</cfif>">
                            <a class="page-link" href="./?#VARIABLES.searchLogBaseQuery#&pagina=#searchLogPageIndex#">#searchLogPageIndex#</a>
                          </li>
                        </cfoutput>
                      </cfloop>

                      <cfoutput>
                        <li class="page-item <cfif VARIABLES.searchLogPage GTE VARIABLES.searchLogTotalPages>disabled</cfif>">
                          <a class="page-link" href="./?#VARIABLES.searchLogBaseQuery#&pagina=#min(VARIABLES.searchLogTotalPages, VARIABLES.searchLogPage + 1)#">Proxima</a>
                        </li>
                      </cfoutput>
                    </ul>
                  </nav>
                </cfif>
              <cfelse>
                <div class="text-muted">Nenhuma busca encontrada para os filtros atuais.</div>
              </cfif>
            </div>

            <div class="search-panel">
              <h5 class="mb-3">Usuarios que mais usam a busca</h5>
              <cfif qSearchLogUsers.recordcount>
                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover mb-0">
                    <thead>
                      <tr>
                        <th>Usuario</th>
                        <th>Buscas</th>
                        <th>IA</th>
                        <th>Ultima</th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qSearchLogUsers">
                        <tr>
                          <td class="search-term-cell">
                            <cfif len(trim(qSearchLogUsers.usuario_nome))>
                              #htmlEditFormat(qSearchLogUsers.usuario_nome)#
                              <div class="small text-muted">#htmlEditFormat(qSearchLogUsers.usuario_email)#</div>
                            <cfelse>
                              Usuario #qSearchLogUsers.id_usuario#
                            </cfif>
                          </td>
                          <td>#LSNumberFormat(qSearchLogUsers.buscas, "9,999,999")#</td>
                          <td>#LSNumberFormat(qSearchLogUsers.buscas_ia, "9,999,999")#</td>
                          <td>#searchLogFormatDateTime(qSearchLogUsers.ultima_busca)#</td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              <cfelse>
                <div class="text-muted">Sem usuarios associados as buscas desse periodo.</div>
              </cfif>
            </div>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
