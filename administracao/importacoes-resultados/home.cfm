<cfscript>
function resultImportProcessingMeta(required string statusValue) {
    var normalized = lCase(trim(arguments.statusValue));
    var statuses = {
        pendente = { label = "Pendente", className = "warning" },
        processando = { label = "Processando", className = "info" },
        processado = { label = "Processado", className = "success" },
        falhou = { label = "Falhou", className = "danger" },
        cancelado = { label = "Cancelado", className = "secondary" }
    };

    return structKeyExists(statuses, normalized)
        ? statuses[normalized]
        : { label = len(normalized) ? normalized : "Desconhecido", className = "secondary" };
}

function resultImportPublicationMeta(required string statusValue) {
    var normalized = lCase(trim(arguments.statusValue));
    var statuses = {
        extraoficial = { label = "Extraoficial", className = "warning" },
        final = { label = "Final", className = "success" },
        atualizacao = { label = "Atualização", className = "info" }
    };

    return structKeyExists(statuses, normalized)
        ? statuses[normalized]
        : { label = len(normalized) ? normalized : "Desconhecido", className = "secondary" };
}

function resultImportQueueUrl(struct changes = {}) {
    var values = {
        busca = VARIABLES.resultImportSearch,
        status = VARIABLES.resultImportStatus,
        publicacao = VARIABLES.resultImportPublicationStatus,
        timer = VARIABLES.resultImportTimer,
        cliente = VARIABLES.resultImportClient,
        periodo = VARIABLES.resultImportPeriodDays,
        pagina = VARIABLES.resultImportPage,
        id = VARIABLES.resultImportSelectedId
    };
    var orderedKeys = ["busca", "status", "publicacao", "timer", "cliente", "periodo", "pagina", "id"];
    var keyValue = "";
    var pairs = [];

    structAppend(values, arguments.changes, true);

    for (keyValue in orderedKeys) {
        if (len(trim(values[keyValue] & ""))) {
            arrayAppend(pairs, keyValue & "=" & encodeForURL(values[keyValue] & ""));
        }
    }

    return "./?" & arrayToList(pairs, "&");
}

function resultImportDateTime(any value = "") {
    if (isNull(arguments.value) || !isDate(arguments.value)) {
        return "-";
    }

    return lsDateFormat(arguments.value, "dd/mm/yyyy") & " " & lsTimeFormat(arguments.value, "HH:mm:ss");
}

resultImportPeriodLabel = VARIABLES.resultImportPeriodDays GT 0
    ? "Últimos " & VARIABLES.resultImportPeriodDays & " dias"
    : "Todo o período";
</cfscript>

<style>
  .result-import-page .result-import-id,
  .result-import-page .result-import-url {
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .result-import-page .result-import-detail-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
    gap: .75rem 1rem;
  }

  .result-import-page .result-import-detail-item {
    min-width: 0;
  }

  .result-import-page .result-import-detail-label {
    color: var(--business-ui-muted);
    display: block;
    font-size: .72rem;
    font-weight: 700;
    margin-bottom: .15rem;
    text-transform: uppercase;
  }

  .result-import-page .result-import-event-cell {
    min-width: 220px;
    max-width: 380px;
  }

  .result-import-page .result-import-client-cell {
    min-width: 150px;
  }

  .result-import-page .result-import-date-cell {
    min-width: 138px;
  }

  .result-import-page .result-import-error {
    border-left: 3px solid var(--mdb-danger);
    background: rgba(220, 76, 100, .08);
    padding: .75rem;
  }

  @media (max-width: 767.98px) {
    .result-import-page .business-page-body {
      padding: .75rem;
    }

    .result-import-page .result-import-detail-grid {
      grid-template-columns: 1fr;
    }
  }
</style>

<section class="business-page result-import-page py-5">
  <div class="card shadow-0 business-page-card">
    <div class="card-body business-page-body">
      <div class="business-page-header d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
        <div>
          <div class="text-warning text-uppercase small fw-bold">Resultados</div>
          <h1 class="business-page-title mb-1">Fila de importações</h1>
          <p class="text-muted mb-0">Submissões recebidas de cronometradores e seu estado de processamento.</p>
        </div>
        <div class="business-page-actions">
          <cfoutput>
            <a class="btn btn-outline-warning btn-sm" href="#resultImportQueueUrl({ pagina = 1, id = '' })#">
              <i class="fa-solid fa-rotate me-1"></i>Atualizar
            </a>
          </cfoutput>
        </div>
      </div>

      <cfif len(VARIABLES.resultImportError)>
        <div class="alert alert-warning mb-0">
          <strong>Fila indisponível.</strong>
          <cfoutput>#htmlEditFormat(VARIABLES.resultImportError)#</cfoutput>
        </div>
      <cfelse>
        <div class="business-kpi-grid mb-3">
          <cfoutput>
            <a class="business-kpi" href="#resultImportQueueUrl({ status = '', pagina = 1, id = '' })#">
              <small>Recebidas</small>
              <strong class="business-kpi-value d-block">#LSNumberFormat(qResultImportSummary.total, "9,999")#</strong>
              <span class="business-meta">#htmlEditFormat(resultImportPeriodLabel)#</span>
            </a>
            <a class="business-kpi" href="#resultImportQueueUrl({ status = 'pendente', pagina = 1, id = '' })#">
              <small>Pendentes</small>
              <strong class="business-kpi-value d-block text-warning">#LSNumberFormat(qResultImportSummary.pendentes, "9,999")#</strong>
              <span class="business-meta">#qResultImportSummary.pendentes_atrasadas# há mais de 15 min</span>
            </a>
            <a class="business-kpi" href="#resultImportQueueUrl({ status = 'processando', pagina = 1, id = '' })#">
              <small>Processando</small>
              <strong class="business-kpi-value d-block text-info">#LSNumberFormat(qResultImportSummary.processando, "9,999")#</strong>
              <span class="business-meta">em execução</span>
            </a>
            <a class="business-kpi" href="#resultImportQueueUrl({ status = 'processado', pagina = 1, id = '' })#">
              <small>Processadas</small>
              <strong class="business-kpi-value d-block text-success">#LSNumberFormat(qResultImportSummary.processados, "9,999")#</strong>
              <span class="business-meta">#LSNumberFormat(qResultImportSummary.total_resultados, "9,999")# resultados</span>
            </a>
            <a class="business-kpi" href="#resultImportQueueUrl({ status = 'falhou', pagina = 1, id = '' })#">
              <small>Falhas</small>
              <strong class="business-kpi-value d-block text-danger">#LSNumberFormat(qResultImportSummary.falhas, "9,999")#</strong>
              <span class="business-meta">exigem revisão</span>
            </a>
            <a class="business-kpi" href="#resultImportQueueUrl({ status = 'cancelado', pagina = 1, id = '' })#">
              <small>Canceladas</small>
              <strong class="business-kpi-value d-block">#LSNumberFormat(qResultImportSummary.cancelados, "9,999")#</strong>
              <span class="business-meta">fora da fila ativa</span>
            </a>
            <a class="business-kpi" href="#resultImportQueueUrl({ publicacao = 'extraoficial', status = '', pagina = 1, id = '' })#">
              <small>Extraoficiais</small>
              <strong class="business-kpi-value d-block">#LSNumberFormat(qResultImportSummary.extraoficiais, "9,999")#</strong>
              <span class="business-meta">status recebido</span>
            </a>
            <a class="business-kpi" href="#resultImportQueueUrl({ publicacao = 'final', status = '', pagina = 1, id = '' })#">
              <small>Finais</small>
              <strong class="business-kpi-value d-block">#LSNumberFormat(qResultImportSummary.finais, "9,999")#</strong>
              <span class="business-meta">status recebido</span>
            </a>
            <a class="business-kpi" href="#resultImportQueueUrl({ publicacao = 'atualizacao', status = '', pagina = 1, id = '' })#">
              <small>Atualizações</small>
              <strong class="business-kpi-value d-block">#LSNumberFormat(qResultImportSummary.atualizacoes, "9,999")#</strong>
              <span class="business-meta">status recebido</span>
            </a>
          </cfoutput>
        </div>

        <form class="business-filterbar mb-3" method="get" action="./">
          <div class="row g-2 align-items-end">
            <div class="col-12 col-xl-3">
              <label class="form-label small mb-1" for="result-import-search">Busca</label>
              <input class="form-control form-control-sm"
                     id="result-import-search"
                     name="busca"
                     type="search"
                     maxlength="160"
                     value="<cfoutput>#htmlEditFormat(VARIABLES.resultImportSearch)#</cfoutput>"
                     placeholder="Evento, ID, URL ou referência externa"/>
            </div>
            <div class="col-6 col-md-4 col-xl-2">
              <label class="form-label small mb-1" for="result-import-status">Processamento</label>
              <select class="form-select form-select-sm" id="result-import-status" name="status">
                <option value="">Todos</option>
                <cfloop list="pendente,processando,processado,falhou,cancelado" index="resultImportStatusOption">
                  <cfset resultImportStatusMeta = resultImportProcessingMeta(resultImportStatusOption)/>
                  <cfoutput><option value="#resultImportStatusOption#" <cfif VARIABLES.resultImportStatus EQ resultImportStatusOption>selected</cfif>>#resultImportStatusMeta.label#</option></cfoutput>
                </cfloop>
              </select>
            </div>
            <div class="col-6 col-md-4 col-xl-2">
              <label class="form-label small mb-1" for="result-import-publication">Publicação</label>
              <select class="form-select form-select-sm" id="result-import-publication" name="publicacao">
                <option value="">Todos</option>
                <cfloop list="extraoficial,final,atualizacao" index="resultImportPublicationOption">
                  <cfset resultImportPublicationMetaValue = resultImportPublicationMeta(resultImportPublicationOption)/>
                  <cfoutput><option value="#resultImportPublicationOption#" <cfif VARIABLES.resultImportPublicationStatus EQ resultImportPublicationOption>selected</cfif>>#resultImportPublicationMetaValue.label#</option></cfoutput>
                </cfloop>
              </select>
            </div>
            <div class="col-6 col-md-4 col-xl-1">
              <label class="form-label small mb-1" for="result-import-timer">Timer</label>
              <select class="form-select form-select-sm" id="result-import-timer" name="timer">
                <option value="">Todos</option>
                <cfoutput query="qResultImportTimers">
                  <option value="#htmlEditFormat(cod_timer)#" <cfif VARIABLES.resultImportTimer EQ lCase(cod_timer)>selected</cfif>>#htmlEditFormat(cod_timer)#</option>
                </cfoutput>
              </select>
            </div>
            <div class="col-6 col-md-4 col-xl-2">
              <label class="form-label small mb-1" for="result-import-client">Cliente</label>
              <select class="form-select form-select-sm" id="result-import-client" name="cliente">
                <option value="">Todos</option>
                <cfoutput query="qResultImportClients">
                  <option value="#htmlEditFormat(client_id)#" <cfif VARIABLES.resultImportClient EQ lCase(client_id)>selected</cfif>>#htmlEditFormat(client_id)#</option>
                </cfoutput>
              </select>
            </div>
            <div class="col-6 col-md-4 col-xl-1">
              <label class="form-label small mb-1" for="result-import-period">Período</label>
              <select class="form-select form-select-sm" id="result-import-period" name="periodo">
                <option value="1" <cfif VARIABLES.resultImportPeriodDays EQ 1>selected</cfif>>24h</option>
                <option value="7" <cfif VARIABLES.resultImportPeriodDays EQ 7>selected</cfif>>7 dias</option>
                <option value="30" <cfif VARIABLES.resultImportPeriodDays EQ 30>selected</cfif>>30 dias</option>
                <option value="90" <cfif VARIABLES.resultImportPeriodDays EQ 90>selected</cfif>>90 dias</option>
                <option value="0" <cfif VARIABLES.resultImportPeriodDays EQ 0>selected</cfif>>Tudo</option>
              </select>
            </div>
            <div class="col-12 col-md-auto d-flex gap-2">
              <button class="btn btn-warning btn-sm" type="submit">
                <i class="fa-solid fa-filter me-1"></i>Filtrar
              </button>
              <a class="btn btn-outline-light btn-sm" href="./" title="Limpar filtros">
                <i class="fa-solid fa-xmark"></i>
              </a>
            </div>
          </div>
        </form>

        <cfif len(VARIABLES.resultImportDetailError)>
          <div class="alert alert-warning">
            <cfoutput>#htmlEditFormat(VARIABLES.resultImportDetailError)#</cfoutput>
          </div>
        </cfif>

        <cfif qResultImportDetail.recordcount>
          <cfset resultImportDetailProcessing = resultImportProcessingMeta(qResultImportDetail.status_processamento)/>
          <cfset resultImportDetailPublication = resultImportPublicationMeta(qResultImportDetail.status_publicacao)/>
          <div class="business-panel mb-3">
            <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
              <div>
                <div class="d-flex flex-wrap align-items-center gap-2 mb-1">
                  <h2 class="h5 mb-0">Detalhes da submissão</h2>
                  <cfoutput>
                    <span class="badge badge-#resultImportDetailProcessing.className#">#resultImportDetailProcessing.label#</span>
                    <span class="badge badge-#resultImportDetailPublication.className#">#resultImportDetailPublication.label#</span>
                  </cfoutput>
                </div>
                <code class="result-import-id"><cfoutput>#htmlEditFormat(qResultImportDetail.submission_id)#</cfoutput></code>
              </div>
              <cfoutput>
                <a class="btn btn-outline-light btn-sm align-self-start" href="#resultImportQueueUrl({ id = '' })#" title="Fechar detalhes">
                  <i class="fa-solid fa-xmark"></i>
                </a>
              </cfoutput>
            </div>

            <div class="result-import-detail-grid mb-3">
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Recebida em</span>
                <cfoutput>#resultImportDateTime(qResultImportDetail.data_recebimento)#</cfoutput>
              </div>
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Atualizada em</span>
                <cfoutput>#resultImportDateTime(qResultImportDetail.data_atualizacao)#</cfoutput>
              </div>
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Início do processamento</span>
                <cfoutput>#resultImportDateTime(qResultImportDetail.data_inicio)#</cfoutput>
              </div>
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Processada em</span>
                <cfoutput>#resultImportDateTime(qResultImportDetail.data_processamento)#</cfoutput>
              </div>
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Cronometrador</span>
                <code><cfoutput>#htmlEditFormat(qResultImportDetail.cod_timer)#</cfoutput></code>
              </div>
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Cliente da API</span>
                <code><cfoutput>#htmlEditFormat(qResultImportDetail.client_id)#</cfoutput></code>
              </div>
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Tentativas</span>
                <cfoutput>#LSNumberFormat(qResultImportDetail.tentativas, "9,999")#</cfoutput>
              </div>
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Resultados carregados</span>
                <cfif len(trim(qResultImportDetail.total_resultados & ""))>
                  <cfoutput>#LSNumberFormat(qResultImportDetail.total_resultados, "9,999")#</cfoutput>
                <cfelse>
                  -
                </cfif>
              </div>
            </div>

            <div class="row g-3 mb-3">
              <div class="col-12 col-xl-6">
                <span class="result-import-detail-label">Evento associado</span>
                <cfif len(trim(qResultImportDetail.id_evento & ""))>
                  <strong class="d-block"><cfoutput>#htmlEditFormat(qResultImportDetail.nome_evento)#</cfoutput></strong>
                  <span class="text-muted small">
                    <cfoutput>
                      ID #qResultImportDetail.id_evento#
                      <cfif len(trim(qResultImportDetail.event_tag & ""))> · #htmlEditFormat(qResultImportDetail.event_tag)#</cfif>
                      <cfif isDate(qResultImportDetail.event_date)> · #lsDateFormat(qResultImportDetail.event_date, "dd/mm/yyyy")#</cfif>
                      <cfif len(trim(qResultImportDetail.event_city & ""))> · #htmlEditFormat(qResultImportDetail.event_city)#/#htmlEditFormat(qResultImportDetail.event_state)#</cfif>
                    </cfoutput>
                  </span>
                <cfelse>
                  <strong class="d-block text-warning">Ainda sem vínculo</strong>
                  <span class="text-muted small">
                    <cfoutput>
                      <cfif len(trim(qResultImportDetail.id_evento_informado & ""))>ID informado: #qResultImportDetail.id_evento_informado#</cfif>
                      <cfif len(trim(qResultImportDetail.tag_evento_informada & ""))> Tag informada: #htmlEditFormat(qResultImportDetail.tag_evento_informada)#</cfif>
                      <cfif NOT len(trim(qResultImportDetail.id_evento_informado & "")) AND NOT len(trim(qResultImportDetail.tag_evento_informada & ""))>Nenhuma referência interna foi enviada.</cfif>
                    </cfoutput>
                  </span>
                </cfif>
              </div>
              <div class="col-12 col-xl-3">
                <span class="result-import-detail-label">Conta externa</span>
                <cfoutput>#len(trim(qResultImportDetail.external_account_id & "")) ? htmlEditFormat(qResultImportDetail.external_account_id) : "-"#</cfoutput>
              </div>
              <div class="col-12 col-xl-3">
                <span class="result-import-detail-label">Evento externo</span>
                <cfoutput>#len(trim(qResultImportDetail.external_event_id & "")) ? htmlEditFormat(qResultImportDetail.external_event_id) : "-"#</cfoutput>
              </div>
            </div>

            <div class="mb-3">
              <span class="result-import-detail-label">URL dos dados</span>
              <a class="result-import-url d-block" href="<cfoutput>#htmlEditFormat(qResultImportDetail.url_resultado)#</cfoutput>" target="_blank" rel="noopener noreferrer">
                <cfoutput>#htmlEditFormat(qResultImportDetail.url_resultado)#</cfoutput>
              </a>
            </div>
            <div class="mb-3">
              <span class="result-import-detail-label">URL pública do resultado</span>
              <a class="result-import-url d-block" href="<cfoutput>#htmlEditFormat(qResultImportDetail.url_resultado_publica)#</cfoutput>" target="_blank" rel="noopener noreferrer">
                <cfoutput>#htmlEditFormat(qResultImportDetail.url_resultado_publica)#</cfoutput>
              </a>
            </div>

            <div class="result-import-detail-grid">
              <div class="result-import-detail-item">
                <span class="result-import-detail-label">Idempotency-Key</span>
                <code class="result-import-id"><cfoutput>#htmlEditFormat(qResultImportDetail.idempotency_key)#</cfoutput></code>
              </div>
              <cfif len(trim(qResultImportDetail.erro_codigo & "")) OR len(trim(qResultImportDetail.erro_detalhe & ""))>
                <div class="result-import-detail-item result-import-error">
                  <span class="result-import-detail-label">Erro do processamento</span>
                  <strong class="d-block"><cfoutput>#htmlEditFormat(qResultImportDetail.erro_codigo)#</cfoutput></strong>
                  <span><cfoutput>#htmlEditFormat(qResultImportDetail.erro_detalhe)#</cfoutput></span>
                </div>
              </cfif>
            </div>
          </div>
        </cfif>

        <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-end gap-2 mb-2">
          <div>
            <h2 class="h5 mb-1">Submissões</h2>
            <div class="text-muted small">
              <cfoutput>#LSNumberFormat(VARIABLES.resultImportTotal, "9,999")# registro(s) · página #VARIABLES.resultImportPage# de #VARIABLES.resultImportTotalPages#</cfoutput>
            </div>
          </div>
        </div>

        <cfif qResultImports.recordcount>
          <div class="table-responsive">
            <table class="table table-sm align-middle business-table mb-2">
              <thead>
                <tr>
                  <th>Recebida</th>
                  <th>Processamento</th>
                  <th>Publicação</th>
                  <th>Evento</th>
                  <th>Origem</th>
                  <th class="text-end">Resultados</th>
                  <th class="text-end">Ações</th>
                </tr>
              </thead>
              <tbody>
                <cfoutput query="qResultImports">
                  <cfset resultImportRowProcessing = resultImportProcessingMeta(status_processamento)/>
                  <cfset resultImportRowPublication = resultImportPublicationMeta(status_publicacao)/>
                  <tr>
                    <td class="result-import-date-cell">
                      #resultImportDateTime(data_recebimento)#
                      <small class="text-muted d-block">###id_resultado_importacao#</small>
                    </td>
                    <td>
                      <span class="badge badge-#resultImportRowProcessing.className#">#resultImportRowProcessing.label#</span>
                      <small class="text-muted d-block">#tentativas# tentativa(s)</small>
                    </td>
                    <td><span class="badge badge-#resultImportRowPublication.className#">#resultImportRowPublication.label#</span></td>
                    <td class="result-import-event-cell">
                      <cfif len(trim(id_evento & ""))>
                        <strong class="d-block">#htmlEditFormat(nome_evento)#</strong>
                        <small class="text-muted">ID #id_evento#<cfif len(trim(event_tag & ""))> · #htmlEditFormat(event_tag)#</cfif></small>
                      <cfelse>
                        <strong class="d-block text-warning">Sem vínculo</strong>
                        <small class="text-muted">
                          <cfif len(trim(id_evento_informado & ""))>ID informado: #id_evento_informado#</cfif>
                          <cfif len(trim(tag_evento_informada & ""))>#htmlEditFormat(tag_evento_informada)#</cfif>
                          <cfif NOT len(trim(id_evento_informado & "")) AND NOT len(trim(tag_evento_informada & ""))>aguardando identificação</cfif>
                        </small>
                      </cfif>
                    </td>
                    <td class="result-import-client-cell">
                      <code class="d-block">#htmlEditFormat(cod_timer)#</code>
                      <small class="text-muted">#htmlEditFormat(client_id)#</small>
                    </td>
                    <td class="text-end">
                      <cfif len(trim(total_resultados & ""))>#LSNumberFormat(total_resultados, "9,999")#<cfelse>-</cfif>
                    </td>
                    <td class="business-row-actions text-end">
                      <cfif compareNoCase(cod_timer, "racezone") EQ 0 AND listFindNoCase("pendente,falhou", status_processamento)>
                        <a class="btn btn-warning btn-sm"
                           href="/racetag/?submission_id=#encodeForURL(submission_id)#"
                           target="_blank"
                           rel="noopener noreferrer"
                           title="Abrir processamento manual RaceTag Pro"
                           aria-label="Abrir processamento manual RaceTag Pro">
                          <i class="fa-solid fa-gears"></i>
                        </a>
                      </cfif>
                      <a class="btn btn-outline-warning btn-sm"
                         href="#resultImportQueueUrl({ id = submission_id })#"
                         title="Ver detalhes da submissão"
                         aria-label="Ver detalhes da submissão">
                        <i class="fa-solid fa-eye"></i>
                      </a>
                    </td>
                  </tr>
                </cfoutput>
              </tbody>
            </table>
          </div>

          <nav class="d-flex justify-content-between align-items-center gap-2" aria-label="Paginação da fila">
            <cfoutput>
              <a class="btn btn-outline-light btn-sm <cfif VARIABLES.resultImportPage LTE 1>disabled</cfif>"
                 href="#resultImportQueueUrl({ pagina = max(1, VARIABLES.resultImportPage - 1), id = '' })#"
                 <cfif VARIABLES.resultImportPage LTE 1>aria-disabled="true" tabindex="-1"</cfif>>
                <i class="fa-solid fa-chevron-left me-1"></i>Anterior
              </a>
              <span class="small text-muted">#VARIABLES.resultImportPage# / #VARIABLES.resultImportTotalPages#</span>
              <a class="btn btn-outline-light btn-sm <cfif VARIABLES.resultImportPage GTE VARIABLES.resultImportTotalPages>disabled</cfif>"
                 href="#resultImportQueueUrl({ pagina = min(VARIABLES.resultImportTotalPages, VARIABLES.resultImportPage + 1), id = '' })#"
                 <cfif VARIABLES.resultImportPage GTE VARIABLES.resultImportTotalPages>aria-disabled="true" tabindex="-1"</cfif>>
                Próxima<i class="fa-solid fa-chevron-right ms-1"></i>
              </a>
            </cfoutput>
          </nav>
        <cfelse>
          <div class="business-empty-state">
            <strong>Nenhuma submissão encontrada.</strong>
            <span class="text-muted">Ajuste os filtros ou aguarde uma nova chamada do cronometrador.</span>
          </div>
        </cfif>
      </cfif>
    </div>
  </div>
</section>
