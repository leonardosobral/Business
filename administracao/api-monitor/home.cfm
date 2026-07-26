<cfscript>
function apiMonitorPercent(required numeric value, required numeric total) {
    return arguments.total GT 0 ? (arguments.value / arguments.total) * 100 : 0;
}

function apiMonitorDuration(required numeric milliseconds) {
    if (arguments.milliseconds GTE 1000) {
        return numberFormat(arguments.milliseconds / 1000, "9.99") & "s";
    }

    return numberFormat(arguments.milliseconds, "9") & "ms";
}

apiMonitorMaxTimeline = 1;
for (apiMonitorTimelineItem in VARIABLES.apiMonitorSnapshot.timeline) {
    apiMonitorMaxTimeline = max(apiMonitorMaxTimeline, apiMonitorTimelineItem.total);
}
</cfscript>

<style>
  .api-monitor-page {
    --api-monitor-border: rgba(255,255,255,.11);
    --api-monitor-muted: rgba(255,255,255,.58);
  }

  .api-monitor-page .api-monitor-metrics {
    border: 1px solid var(--api-monitor-border);
    border-radius: 8px;
    display: grid;
    grid-template-columns: repeat(6, minmax(0, 1fr));
    overflow: hidden;
  }

  .api-monitor-page .api-monitor-metric {
    min-height: 108px;
    padding: 1rem;
  }

  .api-monitor-page .api-monitor-metric + .api-monitor-metric {
    border-left: 1px solid var(--api-monitor-border);
  }

  .api-monitor-page .api-monitor-label {
    color: var(--api-monitor-muted);
    display: block;
    font-size: .72rem;
    font-weight: 700;
    margin-bottom: .35rem;
    text-transform: uppercase;
  }

  .api-monitor-page .api-monitor-value {
    font-size: 1.75rem;
    font-weight: 750;
    line-height: 1.1;
  }

  .api-monitor-page .api-monitor-section {
    border-top: 1px solid var(--api-monitor-border);
    padding-top: 1.25rem;
  }

  .api-monitor-page .api-monitor-timeline {
    display: grid;
    gap: .55rem;
  }

  .api-monitor-page .api-monitor-timeline-row {
    align-items: center;
    display: grid;
    gap: .75rem;
    grid-template-columns: 92px minmax(0, 1fr) 64px;
  }

  .api-monitor-page .api-monitor-timeline-track {
    background: rgba(255,255,255,.055);
    height: 12px;
    overflow: hidden;
  }

  .api-monitor-page .api-monitor-timeline-bar {
    background: #f4b120;
    height: 100%;
    min-width: 2px;
  }

  .api-monitor-page .api-monitor-table {
    font-size: .86rem;
  }

  .api-monitor-page .api-monitor-route {
    max-width: 520px;
    overflow-wrap: anywhere;
  }

  .api-monitor-page .api-monitor-source {
    color: var(--api-monitor-muted);
    font-size: .78rem;
    overflow-wrap: anywhere;
  }

  @media (max-width: 1199.98px) {
    .api-monitor-page .api-monitor-metrics {
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }

    .api-monitor-page .api-monitor-metric:nth-child(4) {
      border-left: 0;
    }

    .api-monitor-page .api-monitor-metric:nth-child(n+4) {
      border-top: 1px solid var(--api-monitor-border);
    }
  }

  @media (max-width: 575.98px) {
    .api-monitor-page .api-monitor-metrics {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .api-monitor-page .api-monitor-metric:nth-child(odd) {
      border-left: 0;
    }

    .api-monitor-page .api-monitor-metric:nth-child(n+3) {
      border-top: 1px solid var(--api-monitor-border);
    }

    .api-monitor-page .api-monitor-timeline-row {
      grid-template-columns: 74px minmax(0, 1fr) 48px;
    }
  }
</style>

<section class="api-monitor-page py-5">
  <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-end gap-3 mb-4">
    <div>
      <div class="text-warning text-uppercase small fw-bold">Administração</div>
      <h1 class="h3 mb-1">Monitor da API</h1>
      <p class="text-muted mb-0">Uso, desempenho, erros e sinais de abuso em <code>api.roadrunners.run</code>.</p>
    </div>

    <div class="d-flex flex-wrap gap-2">
      <div class="btn-group btn-group-sm" role="group" aria-label="Janela do monitor">
        <cfloop list="1,6,24,72" index="apiMonitorHourOption">
          <cfoutput>
            <a class="btn #VARIABLES.apiMonitorHours EQ apiMonitorHourOption ? 'btn-warning' : 'btn-outline-light'#"
               href="./?hours=#apiMonitorHourOption#">#apiMonitorHourOption#h</a>
          </cfoutput>
        </cfloop>
      </div>
      <cfoutput>
        <a class="btn btn-outline-warning btn-sm" href="./?hours=#VARIABLES.apiMonitorHours#&amp;refresh=1">
          <i class="fa-solid fa-rotate me-1"></i>Atualizar
        </a>
      </cfoutput>
    </div>
  </div>

  <cfif len(trim(VARIABLES.apiMonitorSnapshot.error))>
    <div class="alert alert-warning">
      <strong>Telemetria indisponível.</strong>
      <cfoutput>#htmlEditFormat(VARIABLES.apiMonitorSnapshot.error)#</cfoutput>
      <div class="small mt-2">Verifique a existência do arquivo e a permissão de leitura do usuário do ColdFusion.</div>
    </div>
  <cfelse>
    <div class="api-monitor-metrics mb-4">
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Requisições</span>
        <div class="api-monitor-value"><cfoutput>#LSNumberFormat(VARIABLES.apiMonitorSnapshot.totals.requests, "9,999")#</cfoutput></div>
        <small class="text-muted"><cfoutput>#VARIABLES.apiMonitorHours#h analisadas</cfoutput></small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Pico por minuto</span>
        <div class="api-monitor-value"><cfoutput>#LSNumberFormat(VARIABLES.apiMonitorSnapshot.totals.peakRequestsPerMinute, "9,999")#</cfoutput></div>
        <small class="text-muted">volume máximo</small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Sucesso 2xx</span>
        <div class="api-monitor-value text-success"><cfoutput>#numberFormat(apiMonitorPercent(VARIABLES.apiMonitorSnapshot.totals.success, VARIABLES.apiMonitorSnapshot.totals.requests), "9.9")#%</cfoutput></div>
        <small class="text-muted"><cfoutput>#LSNumberFormat(VARIABLES.apiMonitorSnapshot.totals.success, "9,999")# respostas</cfoutput></small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Erros 4xx</span>
        <div class="api-monitor-value text-warning"><cfoutput>#LSNumberFormat(VARIABLES.apiMonitorSnapshot.totals.clientErrors, "9,999")#</cfoutput></div>
        <small class="text-muted"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.unauthorized# não autorizadas</cfoutput></small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Erros 5xx</span>
        <div class="api-monitor-value <cfif VARIABLES.apiMonitorSnapshot.totals.serverErrors GT 0>text-danger</cfif>"><cfoutput>#LSNumberFormat(VARIABLES.apiMonitorSnapshot.totals.serverErrors, "9,999")#</cfoutput></div>
        <small class="text-muted">falhas internas</small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Latência p95</span>
        <div class="api-monitor-value"><cfoutput>#apiMonitorDuration(VARIABLES.apiMonitorSnapshot.totals.p95DurationMs)#</cfoutput></div>
        <small class="text-muted"><cfoutput>média #apiMonitorDuration(VARIABLES.apiMonitorSnapshot.totals.averageDurationMs)#</cfoutput></small>
      </div>
    </div>

    <div class="row g-4 mb-4">
      <div class="col-12 col-xl-7">
        <section class="api-monitor-section h-100">
          <div class="d-flex justify-content-between align-items-baseline gap-3 mb-3">
            <h2 class="h5 mb-0">Volume por hora</h2>
            <span class="small text-muted"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.uniqueIps# IPs anonimizados</cfoutput></span>
          </div>

          <cfif arrayLen(VARIABLES.apiMonitorSnapshot.timeline)>
            <div class="api-monitor-timeline">
              <cfloop array="#VARIABLES.apiMonitorSnapshot.timeline#" index="apiMonitorTimelineItem">
                <cfoutput>
                  <div class="api-monitor-timeline-row">
                    <span class="small text-muted">#htmlEditFormat(apiMonitorTimelineItem.label)#</span>
                    <div class="api-monitor-timeline-track" title="#apiMonitorTimelineItem.total# requisições">
                      <div class="api-monitor-timeline-bar" style="width:#numberFormat((apiMonitorTimelineItem.total / apiMonitorMaxTimeline) * 100, '9.99')#%"></div>
                    </div>
                    <strong class="text-end">#LSNumberFormat(apiMonitorTimelineItem.total, "9,999")#</strong>
                  </div>
                </cfoutput>
              </cfloop>
            </div>
          <cfelse>
            <p class="text-muted mb-0">Nenhuma requisição encontrada na janela escolhida.</p>
          </cfif>
        </section>
      </div>

      <div class="col-12 col-xl-5">
        <section class="api-monitor-section h-100">
          <h2 class="h5 mb-3">Leitura operacional</h2>
          <div class="table-responsive">
            <table class="table table-sm align-middle mb-0 api-monitor-table">
              <tbody>
                <tr><th>Clientes identificados</th><td class="text-end"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.uniqueClients#</cfoutput></td></tr>
                <tr><th>Requisições autenticadas</th><td class="text-end"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.authenticated#</cfoutput></td></tr>
                <tr><th>401</th><td class="text-end"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.unauthorized#</cfoutput></td></tr>
                <tr><th>403</th><td class="text-end"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.forbidden#</cfoutput></td></tr>
                <tr><th>404</th><td class="text-end"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.notFound#</cfoutput></td></tr>
                <tr><th>405</th><td class="text-end"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.methodNotAllowed#</cfoutput></td></tr>
                <tr><th>429</th><td class="text-end"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.rateLimited#</cfoutput></td></tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>

    <div class="row g-4 mb-4">
      <div class="col-12 col-xl-5">
        <section class="api-monitor-section">
          <h2 class="h5 mb-3">Uso por cliente</h2>
          <div class="table-responsive">
            <table class="table table-sm align-middle api-monitor-table">
              <thead>
                <tr><th>Cliente</th><th class="text-end">Req.</th><th class="text-end">4xx</th><th class="text-end">429</th><th class="text-end">Média</th></tr>
              </thead>
              <tbody>
                <cfloop array="#VARIABLES.apiMonitorSnapshot.clients#" index="apiMonitorClient">
                  <cfoutput>
                    <tr>
                      <td><code>#htmlEditFormat(apiMonitorClient.label)#</code></td>
                      <td class="text-end">#apiMonitorClient.total#</td>
                      <td class="text-end">#apiMonitorClient.clientErrors#</td>
                      <td class="text-end">#apiMonitorClient.rateLimited#</td>
                      <td class="text-end">#apiMonitorDuration(apiMonitorClient.averageDurationMs)#</td>
                    </tr>
                  </cfoutput>
                </cfloop>
              </tbody>
            </table>
          </div>
        </section>
      </div>

      <div class="col-12 col-xl-7">
        <section class="api-monitor-section">
          <h2 class="h5 mb-3">Rotas mais usadas</h2>
          <div class="table-responsive">
            <table class="table table-sm align-middle api-monitor-table">
              <thead>
                <tr><th>Rota</th><th class="text-end">Req.</th><th class="text-end">4xx</th><th class="text-end">5xx</th><th class="text-end">Média</th></tr>
              </thead>
              <tbody>
                <cfloop array="#VARIABLES.apiMonitorSnapshot.routes#" index="apiMonitorRoute">
                  <cfoutput>
                    <tr>
                      <td class="api-monitor-route"><code>#htmlEditFormat(apiMonitorRoute.label)#</code></td>
                      <td class="text-end">#apiMonitorRoute.total#</td>
                      <td class="text-end">#apiMonitorRoute.clientErrors#</td>
                      <td class="text-end">#apiMonitorRoute.serverErrors#</td>
                      <td class="text-end">#apiMonitorDuration(apiMonitorRoute.averageDurationMs)#</td>
                    </tr>
                  </cfoutput>
                </cfloop>
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>

    <section class="api-monitor-section mb-4">
      <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-baseline gap-2 mb-3">
        <h2 class="h5 mb-0">Sinais de abuso</h2>
        <span class="small text-muted">IP exibido somente como hash SHA-256 parcial</span>
      </div>

      <cfif arrayLen(VARIABLES.apiMonitorSnapshot.abuseSignals)>
        <div class="table-responsive">
          <table class="table table-sm align-middle api-monitor-table">
            <thead>
              <tr><th>IP hash</th><th class="text-end">Score</th><th class="text-end">Req.</th><th class="text-end">401</th><th class="text-end">403</th><th class="text-end">404</th><th class="text-end">405</th><th class="text-end">429</th></tr>
            </thead>
            <tbody>
              <cfloop array="#VARIABLES.apiMonitorSnapshot.abuseSignals#" index="apiMonitorAbuse">
                <cfoutput>
                  <tr>
                    <td><code>#htmlEditFormat(apiMonitorAbuse.label)#</code></td>
                    <td class="text-end fw-bold #apiMonitorAbuse.score GTE 100 ? 'text-danger' : 'text-warning'#">#apiMonitorAbuse.score#</td>
                    <td class="text-end">#apiMonitorAbuse.total#</td>
                    <td class="text-end">#apiMonitorAbuse.unauthorized#</td>
                    <td class="text-end">#apiMonitorAbuse.forbidden#</td>
                    <td class="text-end">#apiMonitorAbuse.notFound#</td>
                    <td class="text-end">#apiMonitorAbuse.methodNotAllowed#</td>
                    <td class="text-end">#apiMonitorAbuse.rateLimited#</td>
                  </tr>
                </cfoutput>
              </cfloop>
            </tbody>
          </table>
        </div>
      <cfelse>
        <p class="text-muted mb-0">Nenhum padrão acima dos limiares do monitor nesta janela.</p>
      </cfif>
    </section>

    <section class="api-monitor-section">
      <h2 class="h5 mb-3">Erros recentes</h2>
      <div class="table-responsive">
        <table class="table table-sm align-middle api-monitor-table">
          <thead>
            <tr><th>Horário</th><th>Status</th><th>Rota</th><th>Cliente</th><th>Erro</th><th>IP hash</th><th class="text-end">Tempo</th></tr>
          </thead>
          <tbody>
            <cfloop array="#VARIABLES.apiMonitorSnapshot.recentErrors#" index="apiMonitorError">
              <cfoutput>
                <tr>
                  <td class="text-nowrap">#dateFormat(apiMonitorError.eventAt, "dd/mm")# #timeFormat(apiMonitorError.eventAt, "HH:nn:ss")#</td>
                  <td><strong>#apiMonitorError.statusCode#</strong></td>
                  <td class="api-monitor-route"><code>#htmlEditFormat(apiMonitorError.method & " " & apiMonitorError.route)#</code></td>
                  <td><code>#htmlEditFormat(apiMonitorError.clientId)#</code></td>
                  <td>#len(apiMonitorError.errorCode) ? htmlEditFormat(apiMonitorError.errorCode) : "-"#</td>
                  <td><code>#htmlEditFormat(apiMonitorError.ipHash)#</code></td>
                  <td class="text-end">#apiMonitorDuration(apiMonitorError.durationMs)#</td>
                </tr>
              </cfoutput>
            </cfloop>
          </tbody>
        </table>
      </div>
    </section>

    <div class="api-monitor-source mt-4">
      <cfoutput>
        Atualizado em #dateFormat(VARIABLES.apiMonitorSnapshot.fetchedAt, "dd/mm/yyyy")#
        #timeFormat(VARIABLES.apiMonitorSnapshot.fetchedAt, "HH:nn:ss")#;
        #LSNumberFormat(VARIABLES.apiMonitorSnapshot.linesRead, "9,999")# linhas lidas,
        #LSNumberFormat(VARIABLES.apiMonitorSnapshot.parsedLines, "9,999")# dentro da janela,
        #numberFormat(VARIABLES.apiMonitorSnapshot.bytesRead / 1048576, "9.99")# MB processados.
        <cfif VARIABLES.apiMonitorSnapshot.truncated>Leitura limitada à cauda configurada dos arquivos.</cfif>
      </cfoutput>
    </div>
  </cfif>
</section>
