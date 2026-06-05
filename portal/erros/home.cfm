<cfinclude template="../includes/error_log_backend.cfm"/>

<cfset VARIABLES.errorLogBaseQuery = "dias=#urlEncodedFormat(VARIABLES.errorLogDays)#&item=#urlEncodedFormat(VARIABLES.errorLogItem)#&limite=#urlEncodedFormat(VARIABLES.errorLogSampleLimit)#"/>
<cfif len(VARIABLES.errorLogSite)>
  <cfset VARIABLES.errorLogBaseQuery = VARIABLES.errorLogBaseQuery & "&site=#urlEncodedFormat(VARIABLES.errorLogSite)#"/>
</cfif>
<cfif len(VARIABLES.errorLogTerm)>
  <cfset VARIABLES.errorLogBaseQuery = VARIABLES.errorLogBaseQuery & "&termo=#urlEncodedFormat(VARIABLES.errorLogTerm)#"/>
</cfif>

<style>
  .error-log-page .error-filter,
  .error-log-page .error-metric,
  .error-log-page .error-panel {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 8px;
    background: rgba(255, 255, 255, .03);
  }

  .error-log-page .error-filter,
  .error-log-page .error-panel {
    padding: 1rem;
  }

  .error-log-page .error-metric {
    height: 100%;
    padding: 1rem;
  }

  .error-log-page .error-metric-label {
    color: var(--mdb-secondary-color);
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .04em;
    text-transform: uppercase;
  }

  .error-log-page .error-table {
    min-width: 1120px;
  }

  .error-log-page .error-table th,
  .error-log-page .error-table td {
    vertical-align: middle;
  }

  .error-log-page .error-text-cell {
    max-width: 420px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .error-log-page .error-pre {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 8px;
    background: rgba(0, 0, 0, .2);
    color: var(--mdb-body-color);
    font-size: .78rem;
    max-height: 460px;
    overflow: auto;
    padding: .9rem;
    white-space: pre-wrap;
  }

  .error-log-page .error-badges {
    display: flex;
    flex-wrap: wrap;
    gap: .35rem;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body error-log-page">

          <div class="d-flex flex-column flex-xl-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Erros</h3>
              <p class="text-muted mb-0">Monitore uma amostra recente da <strong>tb_log</strong>, priorizando registros com cara de erro para identificar URLs, origens e padrões recorrentes.</p>
            </div>
            <div class="text-xl-end">
              <div class="small text-muted">Amostra maxima</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.errorLogSampleLimit, "9,999")# logs</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o monitor de erros do Portal.
            </div>
          <cfelseif NOT VARIABLES.errorLogTablesReady>
            <div class="alert alert-warning mb-0">
              A tabela <strong>tb_log</strong> ainda nao foi encontrada neste ambiente.
            </div>
          <cfelse>
            <form class="error-filter mb-4" method="get" action="./">
              <div class="row g-3 align-items-end">
                <div class="col-md-2">
                  <label class="form-label">Periodo</label>
                  <select class="form-select" name="dias">
                    <option value="1"<cfif VARIABLES.errorLogDays EQ 1> selected</cfif>>1 dia</option>
                    <option value="7"<cfif VARIABLES.errorLogDays EQ 7> selected</cfif>>7 dias</option>
                    <option value="30"<cfif VARIABLES.errorLogDays EQ 30> selected</cfif>>30 dias</option>
                    <option value="90"<cfif VARIABLES.errorLogDays EQ 90> selected</cfif>>90 dias</option>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Tipo</label>
                  <select class="form-select" name="item">
                    <option value="erro"<cfif VARIABLES.errorLogItem EQ "erro"> selected</cfif>>Erro</option>
                    <option value="404"<cfif VARIABLES.errorLogItem EQ "404"> selected</cfif>>404</option>
                    <option value="busca"<cfif VARIABLES.errorLogItem EQ "busca"> selected</cfif>>Busca</option>
                    <option value="evento"<cfif VARIABLES.errorLogItem EQ "evento"> selected</cfif>>Evento</option>
                    <option value="todos"<cfif VARIABLES.errorLogItem EQ "todos"> selected</cfif>>Todos</option>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Site</label>
                  <select class="form-select" name="site">
                    <option value="">Todos</option>
                    <option value="RR"<cfif VARIABLES.errorLogSite EQ "RR"> selected</cfif>>RR</option>
                    <option value="OR"<cfif VARIABLES.errorLogSite EQ "OR"> selected</cfif>>OR</option>
                    <option value="CT"<cfif VARIABLES.errorLogSite EQ "CT"> selected</cfif>>CT</option>
                  </select>
                </div>

                <div class="col-md-2">
                  <label class="form-label">Amostra</label>
                  <select class="form-select" name="limite">
                    <option value="100"<cfif VARIABLES.errorLogSampleLimit EQ 100> selected</cfif>>100</option>
                    <option value="500"<cfif VARIABLES.errorLogSampleLimit EQ 500> selected</cfif>>500</option>
                    <option value="1000"<cfif VARIABLES.errorLogSampleLimit EQ 1000> selected</cfif>>1000</option>
                  </select>
                </div>

                <div class="col-md-3">
                  <label class="form-label">Termo</label>
                  <input type="search" class="form-control" name="termo" value="<cfoutput>#htmlEditFormat(VARIABLES.errorLogTerm)#</cfoutput>" placeholder="URL, IP, mensagem ou agente"/>
                </div>

                <div class="col-md-1">
                  <button type="submit" class="btn btn-warning w-100">Filtrar</button>
                </div>
              </div>
            </form>

            <div class="alert alert-info">
              A busca textual roda sobre a amostra carregada, nao sobre a tabela inteira. Para investigacao profunda, use filtros mais fechados antes de aumentar a amostra.
            </div>

            <div class="row g-3 mb-4">
              <div class="col-sm-6 col-xl-2">
                <div class="error-metric">
                  <div class="error-metric-label mb-1">Logs na amostra</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.errorLogStats.total, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="error-metric">
                  <div class="error-metric-label mb-1">Erros</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.errorLogStats.erros, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="error-metric">
                  <div class="error-metric-label mb-1">404</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.errorLogStats.notFound, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="error-metric">
                  <div class="error-metric-label mb-1">Bots</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.errorLogStats.bots, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="error-metric">
                  <div class="error-metric-label mb-1">Sites</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.errorLogStats.sites, "9,999,999")#</cfoutput></div>
                </div>
              </div>
              <div class="col-sm-6 col-xl-2">
                <div class="error-metric">
                  <div class="error-metric-label mb-1">Origens</div>
                  <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.errorLogStats.origens, "9,999,999")#</cfoutput></div>
                </div>
              </div>
            </div>

            <cfif len(trim(URL.log_id))>
              <cfif qErrorLogDetail.recordcount>
                <div class="error-panel mb-4">
                  <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                    <div>
                      <h5 class="mb-1"><cfoutput>Detalhe do log ###qErrorLogDetail.id_log#</cfoutput></h5>
                      <div class="text-muted small">
                        <cfoutput>#errorLogFormatDateTime(qErrorLogDetail.log_timestamp)# - #htmlEditFormat(qErrorLogDetail.site)# - #htmlEditFormat(qErrorLogDetail.classificacao)#</cfoutput>
                      </div>
                    </div>
                    <cfoutput><a class="btn btn-sm btn-outline-light" href="./?#VARIABLES.errorLogBaseQuery#">Fechar detalhe</a></cfoutput>
                  </div>

                  <div class="row g-3 mb-3">
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-1">Tipo</div>
                      <cfoutput>
                        <span class="badge badge-secondary">#htmlEditFormat(errorLogItemLabel(qErrorLogDetail.log_item))#</span>
                        <cfif qErrorLogDetail.parece_bot><span class="badge badge-warning">bot</span></cfif>
                      </cfoutput>
                    </div>
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-1">Origem</div>
                      <div class="error-text-cell"><cfoutput>#htmlEditFormat(qErrorLogDetail.log_user)#</cfoutput></div>
                    </div>
                    <div class="col-lg-4">
                      <div class="small text-muted text-uppercase fw-semibold mb-1">URL detectada</div>
                      <div class="error-text-cell">
                        <cfif len(trim(qErrorLogDetail.url_detectada))>
                          <cfoutput>#htmlEditFormat(qErrorLogDetail.url_detectada)#</cfoutput>
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                      </div>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-lg-6">
                      <div class="small text-muted text-uppercase fw-semibold mb-2">Resumo limpo</div>
                      <pre class="error-pre mb-0"><cfoutput>#htmlEditFormat(errorLogShortText(qErrorLogDetail.log_preview, 4000))#</cfoutput></pre>
                    </div>
                    <div class="col-lg-6">
                      <div class="small text-muted text-uppercase fw-semibold mb-2">Trecho bruto</div>
                      <pre class="error-pre mb-0"><cfoutput>#htmlEditFormat(left(qErrorLogDetail.log_item_id & "", 12000))#<cfif len(qErrorLogDetail.log_item_id & "") GT 12000>

... trecho truncado na tela ...
</cfif></cfoutput></pre>
                    </div>
                    <div class="col-12">
                      <div class="small text-muted text-uppercase fw-semibold mb-2">User agent</div>
                      <div class="error-text-cell"><cfoutput>#htmlEditFormat(qErrorLogDetail.log_user_agent)#</cfoutput></div>
                    </div>
                  </div>
                </div>
              <cfelse>
                <div class="alert alert-warning">Log nao encontrado para o ID informado.</div>
              </cfif>
            </cfif>

            <div class="row g-4 mb-4">
              <div class="col-xl-4">
                <div class="error-panel h-100">
                  <h5 class="mb-3">Por classificacao</h5>
                  <cfif qErrorLogByClass.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Classe</th>
                            <th>Total</th>
                            <th>Ultimo</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qErrorLogByClass">
                            <tr>
                              <td>#htmlEditFormat(qErrorLogByClass.classificacao)#</td>
                              <td>#LSNumberFormat(qErrorLogByClass.total, "9,999,999")#</td>
                              <td>#errorLogFormatDateTime(qErrorLogByClass.ultimo_log)#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem dados na amostra.</div>
                  </cfif>
                </div>
              </div>

              <div class="col-xl-4">
                <div class="error-panel h-100">
                  <h5 class="mb-3">Por tipo bruto</h5>
                  <cfif qErrorLogByItem.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Tipo</th>
                            <th>Total</th>
                            <th>Ultimo</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qErrorLogByItem">
                            <tr>
                              <td>#htmlEditFormat(errorLogItemLabel(qErrorLogByItem.log_item))#</td>
                              <td>#LSNumberFormat(qErrorLogByItem.total, "9,999,999")#</td>
                              <td>#errorLogFormatDateTime(qErrorLogByItem.ultimo_log)#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem tipos para listar.</div>
                  </cfif>
                </div>
              </div>

              <div class="col-xl-4">
                <div class="error-panel h-100">
                  <h5 class="mb-3">Por hora</h5>
                  <cfif qErrorLogByHour.recordcount>
                    <div class="table-responsive">
                      <table class="table table-sm table-striped table-hover mb-0">
                        <thead>
                          <tr>
                            <th>Hora</th>
                            <th>Total</th>
                            <th>Erro</th>
                            <th>404</th>
                          </tr>
                        </thead>
                        <tbody>
                          <cfoutput query="qErrorLogByHour">
                            <tr>
                              <td>#dateTimeFormat(qErrorLogByHour.hora, "dd/mm HH:nn")#</td>
                              <td>#LSNumberFormat(qErrorLogByHour.total, "9,999,999")#</td>
                              <td>#LSNumberFormat(qErrorLogByHour.erros, "9,999,999")#</td>
                              <td>#LSNumberFormat(qErrorLogByHour.not_found, "9,999,999")#</td>
                            </tr>
                          </cfoutput>
                        </tbody>
                      </table>
                    </div>
                  <cfelse>
                    <div class="text-muted">Sem distribuicao por hora.</div>
                  </cfif>
                </div>
              </div>
            </div>

            <div class="error-panel mb-4">
              <h5 class="mb-3">Assinaturas recorrentes</h5>
              <cfif qErrorLogBySignature.recordcount>
                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover error-table mb-0">
                    <thead>
                      <tr>
                        <th>Classe</th>
                        <th>Assinatura</th>
                        <th>Total</th>
                        <th>Ultimo</th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qErrorLogBySignature">
                        <tr>
                          <td>#htmlEditFormat(qErrorLogBySignature.classificacao)#</td>
                          <td class="error-text-cell">#htmlEditFormat(qErrorLogBySignature.assinatura)#</td>
                          <td>#LSNumberFormat(qErrorLogBySignature.total, "9,999,999")#</td>
                          <td>#errorLogFormatDateTime(qErrorLogBySignature.ultimo_log)#</td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              <cfelse>
                <div class="text-muted">Sem assinaturas para listar.</div>
              </cfif>
            </div>

            <div class="error-panel">
              <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                <div>
                  <h5 class="mb-1">Ultimos logs da amostra</h5>
                  <div class="text-muted small"><cfoutput>Exibindo ate #VARIABLES.errorLogDisplayLimit# registros da amostra filtrada</cfoutput></div>
                </div>
                <a class="btn btn-outline-light btn-sm" href="./">Voltar ao padrao</a>
              </div>

              <cfif qErrorLogRecent.recordcount>
                <div class="table-responsive">
                  <table class="table table-sm table-striped table-hover error-table">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Data</th>
                        <th>Tipo</th>
                        <th>Site</th>
                        <th>URL / resumo</th>
                        <th>Origem</th>
                        <th>Flags</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qErrorLogRecent">
                        <tr>
                          <td>#qErrorLogRecent.id_log#</td>
                          <td>#errorLogFormatDateTime(qErrorLogRecent.log_timestamp)#</td>
                          <td>
                            <div>#htmlEditFormat(qErrorLogRecent.classificacao)#</div>
                            <div class="small text-muted">#htmlEditFormat(errorLogItemLabel(qErrorLogRecent.log_item))#</div>
                          </td>
                          <td><span class="badge badge-secondary">#htmlEditFormat(qErrorLogRecent.site)#</span></td>
                          <td class="error-text-cell">
                            <cfif len(trim(qErrorLogRecent.url_path))>
                              <strong>#htmlEditFormat(qErrorLogRecent.url_path)#</strong>
                              <div class="small text-muted">#htmlEditFormat(errorLogShortText(qErrorLogRecent.log_preview, 180))#</div>
                            <cfelse>
                              #htmlEditFormat(errorLogShortText(qErrorLogRecent.log_preview, 220))#
                            </cfif>
                          </td>
                          <td class="error-text-cell">
                            #htmlEditFormat(errorLogShortText(qErrorLogRecent.log_user, 120))#
                          </td>
                          <td>
                            <div class="error-badges">
                              <cfif qErrorLogRecent.parece_bot><span class="badge badge-warning">bot</span></cfif>
                              <cfif len(trim(qErrorLogRecent.url_detectada))><span class="badge badge-info">url</span></cfif>
                            </div>
                          </td>
                          <td><a class="btn btn-sm btn-outline-light" href="./?#VARIABLES.errorLogBaseQuery#&log_id=#qErrorLogRecent.id_log#">Detalhe</a></td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              <cfelse>
                <div class="text-muted">Nenhum log encontrado para os filtros atuais.</div>
              </cfif>
            </div>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
