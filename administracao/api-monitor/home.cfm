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

function apiMonitorTrafficLabel(required string classification) {
    if (arguments.classification EQ "authenticated") {
        return "Autenticado";
    }

    if (arguments.classification EQ "publicSurface") {
        return "Público";
    }

    if (arguments.classification EQ "rejected") {
        return "Rejeitado";
    }

    return "Probe";
}

function apiMonitorTrafficClass(required string classification) {
    if (arguments.classification EQ "authenticated") {
        return "authenticated";
    }

    if (arguments.classification EQ "publicSurface") {
        return "public";
    }

    if (arguments.classification EQ "rejected") {
        return "rejected";
    }

    return "probe";
}

apiMonitorSnapshotCompatible = structKeyExists(VARIABLES.apiMonitorSnapshot, "schemaVersion")
    AND val(VARIABLES.apiMonitorSnapshot.schemaVersion) EQ 2
    AND structKeyExists(VARIABLES.apiMonitorSnapshot, "traffic")
    AND isStruct(VARIABLES.apiMonitorSnapshot.traffic)
    AND structKeyExists(VARIABLES.apiMonitorSnapshot.traffic, "authenticated")
    AND structKeyExists(VARIABLES.apiMonitorSnapshot.traffic, "publicSurface")
    AND structKeyExists(VARIABLES.apiMonitorSnapshot.traffic, "rejected")
    AND structKeyExists(VARIABLES.apiMonitorSnapshot.traffic, "probe");
apiMonitorDisplayError = structKeyExists(VARIABLES.apiMonitorSnapshot, "error")
    ? trim(VARIABLES.apiMonitorSnapshot.error & "")
    : "";
apiMonitorDisplayHint = "Verifique a existência do arquivo e a permissão de leitura do usuário do ColdFusion.";
apiMonitorAuthenticated = {};
apiMonitorPublicSurface = {};
apiMonitorRejected = {};
apiMonitorProbe = {};
apiMonitorTrafficRows = [];

if (apiMonitorSnapshotCompatible) {
    apiMonitorAuthenticated = VARIABLES.apiMonitorSnapshot.traffic.authenticated;
    apiMonitorPublicSurface = VARIABLES.apiMonitorSnapshot.traffic.publicSurface;
    apiMonitorRejected = VARIABLES.apiMonitorSnapshot.traffic.rejected;
    apiMonitorProbe = VARIABLES.apiMonitorSnapshot.traffic.probe;
    apiMonitorTrafficRows = [
        { key = "authenticated", data = apiMonitorAuthenticated },
        { key = "publicSurface", data = apiMonitorPublicSurface },
        { key = "rejected", data = apiMonitorRejected },
        { key = "probe", data = apiMonitorProbe }
    ];
} else {
    apiMonitorDisplayError = "Os arquivos do monitor estão em versões diferentes.";
    apiMonitorDisplayHint = "Suba juntos o serviço, o backend e a view do monitor e atualize novamente.";
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
    display: flex;
    height: 12px;
    overflow: hidden;
  }

  .api-monitor-page .api-monitor-timeline-segment {
    height: 100%;
    min-width: 2px;
  }

  .api-monitor-page .api-monitor-authenticated {
    background: #42c78a;
  }

  .api-monitor-page .api-monitor-public {
    background: #58a9d6;
  }

  .api-monitor-page .api-monitor-rejected {
    background: #f4b120;
  }

  .api-monitor-page .api-monitor-probe {
    background: #dc6464;
  }

  .api-monitor-page .api-monitor-legend {
    align-items: center;
    color: var(--api-monitor-muted);
    display: flex;
    flex-wrap: wrap;
    font-size: .76rem;
    gap: .45rem 1rem;
  }

  .api-monitor-page .api-monitor-legend-item,
  .api-monitor-page .api-monitor-kind {
    align-items: center;
    display: inline-flex;
    gap: .4rem;
  }

  .api-monitor-page .api-monitor-legend-item::before,
  .api-monitor-page .api-monitor-kind::before {
    background: currentColor;
    border-radius: 50%;
    content: "";
    flex: 0 0 7px;
    height: 7px;
    width: 7px;
  }

  .api-monitor-page .api-monitor-kind-authenticated {
    color: #42c78a;
  }

  .api-monitor-page .api-monitor-kind-public {
    color: #58a9d6;
  }

  .api-monitor-page .api-monitor-kind-rejected {
    color: #f4b120;
  }

  .api-monitor-page .api-monitor-kind-probe {
    color: #dc6464;
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

  <cfif len(apiMonitorDisplayError)>
    <div class="alert alert-warning">
      <strong>Telemetria indisponível.</strong>
      <cfoutput>#htmlEditFormat(apiMonitorDisplayError)#</cfoutput>
      <div class="small mt-2"><cfoutput>#htmlEditFormat(apiMonitorDisplayHint)#</cfoutput></div>
    </div>
  <cfelse>
    <cfif structKeyExists(VARIABLES.apiMonitorSnapshot, "skippedFiles")
        AND arrayLen(VARIABLES.apiMonitorSnapshot.skippedFiles)>
      <div class="alert alert-warning">
        <strong>Telemetria parcial.</strong>
        Um arquivo rotacionado nao pôde ser lido; os dados abaixo usam somente os arquivos acessíveis.
        <cfloop array="#VARIABLES.apiMonitorSnapshot.skippedFiles#" index="apiMonitorSkippedFile">
          <div class="small mt-2">
            <cfoutput>#htmlEditFormat(apiMonitorSkippedFile.path)# (#htmlEditFormat(apiMonitorSkippedFile.error)#)</cfoutput>
          </div>
        </cfloop>
      </div>
    </cfif>

    <div class="api-monitor-metrics mb-4">
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Tráfego total</span>
        <div class="api-monitor-value"><cfoutput>#LSNumberFormat(VARIABLES.apiMonitorSnapshot.totals.requests, "9,999")#</cfoutput></div>
        <small class="text-muted">
          <cfoutput>pico #LSNumberFormat(VARIABLES.apiMonitorSnapshot.totals.peakRequestsPerMinute, "9,999")#/min</cfoutput>
        </small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">API autenticada</span>
        <div class="api-monitor-value"><cfoutput>#LSNumberFormat(apiMonitorAuthenticated.total, "9,999")#</cfoutput></div>
        <small class="text-muted">
          <cfoutput>#VARIABLES.apiMonitorSnapshot.totals.uniqueClients# clientes identificados</cfoutput>
        </small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Sucesso autenticado</span>
        <div class="api-monitor-value text-success">
          <cfif apiMonitorAuthenticated.total GT 0>
            <cfoutput>#numberFormat(apiMonitorPercent(apiMonitorAuthenticated.success, apiMonitorAuthenticated.total), "9.9")#%</cfoutput>
          <cfelse>
            -
          </cfif>
        </div>
        <small class="text-muted"><cfoutput>#apiMonitorAuthenticated.success# respostas 2xx</cfoutput></small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Rejeições protegidas</span>
        <div class="api-monitor-value text-warning"><cfoutput>#LSNumberFormat(apiMonitorRejected.total, "9,999")#</cfoutput></div>
        <small class="text-muted">rotas da API sem acesso</small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Probes detectados</span>
        <div class="api-monitor-value <cfif apiMonitorProbe.total GT 0>text-danger</cfif>"><cfoutput>#LSNumberFormat(apiMonitorProbe.total, "9,999")#</cfoutput></div>
        <small class="text-muted">fora do contrato da API</small>
      </div>
      <div class="api-monitor-metric">
        <span class="api-monitor-label">Latência autenticada p95</span>
        <div class="api-monitor-value"><cfoutput>#apiMonitorDuration(apiMonitorAuthenticated.p95DurationMs)#</cfoutput></div>
        <small class="text-muted">
          <cfoutput>#apiMonitorAuthenticated.serverErrors# falhas 5xx; média #apiMonitorDuration(apiMonitorAuthenticated.averageDurationMs)#</cfoutput>
        </small>
      </div>
    </div>

    <div class="row g-4 mb-4">
      <div class="col-12 col-xl-7">
        <section class="api-monitor-section h-100">
          <div class="d-flex justify-content-between align-items-baseline gap-3 mb-3">
            <h2 class="h5 mb-0">Volume por hora</h2>
            <span class="small text-muted"><cfoutput>#VARIABLES.apiMonitorSnapshot.totals.uniqueIps# IPs anonimizados</cfoutput></span>
          </div>
          <div class="api-monitor-legend mb-3" aria-label="Classificação do tráfego">
            <span class="api-monitor-kind api-monitor-kind-authenticated">Autenticado</span>
            <span class="api-monitor-kind api-monitor-kind-public">Público</span>
            <span class="api-monitor-kind api-monitor-kind-rejected">Rejeitado</span>
            <span class="api-monitor-kind api-monitor-kind-probe">Probe</span>
          </div>

          <cfif arrayLen(VARIABLES.apiMonitorSnapshot.timeline)>
            <div class="api-monitor-timeline">
              <cfloop array="#VARIABLES.apiMonitorSnapshot.timeline#" index="apiMonitorTimelineItem">
                <cfoutput>
                  <div class="api-monitor-timeline-row">
                    <span class="small text-muted">#htmlEditFormat(apiMonitorTimelineItem.label)#</span>
                    <div class="api-monitor-timeline-track" title="#apiMonitorTimelineItem.total# requisições">
                      <cfif apiMonitorTimelineItem.authenticated GT 0>
                        <div class="api-monitor-timeline-segment api-monitor-authenticated"
                             style="width:#numberFormat((apiMonitorTimelineItem.authenticated / apiMonitorMaxTimeline) * 100, '9.99')#%"></div>
                      </cfif>
                      <cfif apiMonitorTimelineItem.publicSurface GT 0>
                        <div class="api-monitor-timeline-segment api-monitor-public"
                             style="width:#numberFormat((apiMonitorTimelineItem.publicSurface / apiMonitorMaxTimeline) * 100, '9.99')#%"></div>
                      </cfif>
                      <cfif apiMonitorTimelineItem.rejected GT 0>
                        <div class="api-monitor-timeline-segment api-monitor-rejected"
                             style="width:#numberFormat((apiMonitorTimelineItem.rejected / apiMonitorMaxTimeline) * 100, '9.99')#%"></div>
                      </cfif>
                      <cfif apiMonitorTimelineItem.probe GT 0>
                        <div class="api-monitor-timeline-segment api-monitor-probe"
                             style="width:#numberFormat((apiMonitorTimelineItem.probe / apiMonitorMaxTimeline) * 100, '9.99')#%"></div>
                      </cfif>
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
          <h2 class="h5 mb-3">Classificação do tráfego</h2>
          <div class="table-responsive">
            <table class="table table-sm align-middle mb-0 api-monitor-table">
              <thead>
                <tr><th>Classe</th><th class="text-end">Req.</th><th class="text-end">2xx</th><th class="text-end">4xx</th></tr>
              </thead>
              <tbody>
                <cfloop array="#apiMonitorTrafficRows#" index="apiMonitorTrafficRow">
                  <cfoutput>
                    <tr title="#htmlEditFormat(apiMonitorTrafficRow.data.description)#">
                      <th>
                        <span class="api-monitor-kind api-monitor-kind-#apiMonitorTrafficClass(apiMonitorTrafficRow.key)#">
                          #apiMonitorTrafficLabel(apiMonitorTrafficRow.key)#
                        </span>
                      </th>
                      <td class="text-end">#apiMonitorTrafficRow.data.total#</td>
                      <td class="text-end">#apiMonitorTrafficRow.data.success#</td>
                      <td class="text-end">#apiMonitorTrafficRow.data.clientErrors#</td>
                    </tr>
                  </cfoutput>
                </cfloop>
              </tbody>
            </table>
          </div>
          <div class="api-monitor-source mt-2">
            <cfoutput>
              #VARIABLES.apiMonitorSnapshot.totals.unauthorized# respostas 401,
              #VARIABLES.apiMonitorSnapshot.totals.forbidden# respostas 403,
              #VARIABLES.apiMonitorSnapshot.totals.notFound# respostas 404 e
              #VARIABLES.apiMonitorSnapshot.totals.rateLimited# respostas 429.
            </cfoutput>
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
                <tr><th>Cliente</th><th class="text-end">Req.</th><th class="text-end">2xx</th><th class="text-end">4xx</th><th class="text-end">Média</th></tr>
              </thead>
              <tbody>
                <cfif arrayLen(VARIABLES.apiMonitorSnapshot.clients)>
                  <cfloop array="#VARIABLES.apiMonitorSnapshot.clients#" index="apiMonitorClient">
                    <cfoutput>
                      <tr>
                        <td><code>#htmlEditFormat(apiMonitorClient.label)#</code></td>
                        <td class="text-end">#apiMonitorClient.total#</td>
                        <td class="text-end">#apiMonitorClient.success#</td>
                        <td class="text-end">#apiMonitorClient.clientErrors#</td>
                        <td class="text-end">#apiMonitorDuration(apiMonitorClient.averageDurationMs)#</td>
                      </tr>
                    </cfoutput>
                  </cfloop>
                <cfelse>
                  <tr><td colspan="5" class="text-muted">Nenhum cliente autenticado nesta janela.</td></tr>
                </cfif>
              </tbody>
            </table>
          </div>
        </section>
      </div>

      <div class="col-12 col-xl-7">
        <section class="api-monitor-section">
          <h2 class="h5 mb-3">Rotas autenticadas</h2>
          <div class="table-responsive">
            <table class="table table-sm align-middle api-monitor-table">
              <thead>
                <tr><th>Rota</th><th class="text-end">Req.</th><th class="text-end">4xx</th><th class="text-end">5xx</th><th class="text-end">Média</th></tr>
              </thead>
              <tbody>
                <cfif arrayLen(VARIABLES.apiMonitorSnapshot.authenticatedRoutes)>
                  <cfloop array="#VARIABLES.apiMonitorSnapshot.authenticatedRoutes#" index="apiMonitorRoute">
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
                <cfelse>
                  <tr><td colspan="5" class="text-muted">Nenhuma rota autenticada nesta janela.</td></tr>
                </cfif>
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>

    <div class="row g-4 mb-4">
      <div class="col-12 col-xl-5">
        <section class="api-monitor-section h-100">
          <h2 class="h5 mb-3">Rotas fora do contrato</h2>
          <div class="table-responsive">
            <table class="table table-sm align-middle api-monitor-table">
              <thead>
                <tr><th>Rota sondada</th><th class="text-end">Req.</th><th class="text-end">2xx</th><th class="text-end">3xx</th><th class="text-end">4xx</th><th class="text-end">5xx</th></tr>
              </thead>
              <tbody>
                <cfif arrayLen(VARIABLES.apiMonitorSnapshot.probeRoutes)>
                  <cfloop array="#VARIABLES.apiMonitorSnapshot.probeRoutes#" index="apiMonitorProbeRoute">
                    <cfoutput>
                      <tr>
                        <td class="api-monitor-route"><code>#htmlEditFormat(apiMonitorProbeRoute.label)#</code></td>
                        <td class="text-end">#apiMonitorProbeRoute.total#</td>
                        <td class="text-end">#apiMonitorProbeRoute.success#</td>
                        <td class="text-end">#apiMonitorProbeRoute.redirects#</td>
                        <td class="text-end">#apiMonitorProbeRoute.clientErrors#</td>
                        <td class="text-end">#apiMonitorProbeRoute.serverErrors#</td>
                      </tr>
                    </cfoutput>
                  </cfloop>
                <cfelse>
                  <tr><td colspan="6" class="text-muted">Nenhum probe detectado nesta janela.</td></tr>
                </cfif>
              </tbody>
            </table>
          </div>
        </section>
      </div>

      <div class="col-12 col-xl-7">
        <section class="api-monitor-section h-100">
          <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-baseline gap-2 mb-3">
            <h2 class="h5 mb-0">Sinais de abuso</h2>
            <span class="small text-muted">IP exibido somente como hash SHA-256 parcial</span>
          </div>

          <cfif arrayLen(VARIABLES.apiMonitorSnapshot.abuseSignals)>
            <div class="table-responsive">
              <table class="table table-sm align-middle api-monitor-table">
                <thead>
                  <tr><th>IP hash</th><th class="text-end">Score</th><th class="text-end">Req.</th><th class="text-end">Probes</th><th class="text-end">401</th><th class="text-end">403</th><th class="text-end">404</th><th class="text-end">429</th></tr>
                </thead>
                <tbody>
                  <cfloop array="#VARIABLES.apiMonitorSnapshot.abuseSignals#" index="apiMonitorAbuse">
                    <cfoutput>
                      <tr>
                        <td><code>#htmlEditFormat(apiMonitorAbuse.label)#</code></td>
                        <td class="text-end fw-bold #apiMonitorAbuse.score GTE 100 ? 'text-danger' : 'text-warning'#">#apiMonitorAbuse.score#</td>
                        <td class="text-end">#apiMonitorAbuse.total#</td>
                        <td class="text-end">#apiMonitorAbuse.probe#</td>
                        <td class="text-end">#apiMonitorAbuse.unauthorized#</td>
                        <td class="text-end">#apiMonitorAbuse.forbidden#</td>
                        <td class="text-end">#apiMonitorAbuse.notFound#</td>
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
      </div>
    </div>

    <section class="api-monitor-section">
      <h2 class="h5 mb-3">Respostas de erro recentes</h2>
      <div class="table-responsive">
        <table class="table table-sm align-middle api-monitor-table">
          <thead>
            <tr><th>Horário</th><th>Classe</th><th>Status</th><th>Rota</th><th>Cliente</th><th>Erro</th><th>IP hash</th><th class="text-end">Tempo</th></tr>
          </thead>
          <tbody>
            <cfloop array="#VARIABLES.apiMonitorSnapshot.recentErrors#" index="apiMonitorError">
              <cfoutput>
                <tr>
                  <td class="text-nowrap">#dateFormat(apiMonitorError.eventAt, "dd/mm")# #timeFormat(apiMonitorError.eventAt, "HH:nn:ss")#</td>
                  <td>
                    <span class="api-monitor-kind api-monitor-kind-#apiMonitorTrafficClass(apiMonitorError.classification)#">
                      #apiMonitorTrafficLabel(apiMonitorError.classification)#
                    </span>
                  </td>
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
