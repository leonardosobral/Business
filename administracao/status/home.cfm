<cfscript>
function statusJson(value) {
    if (isNull(arguments.value)) {
        return "";
    }

    return serializeJSON(arguments.value);
}

function statusSimpleValue(value) {
    if (isNull(arguments.value)) {
        return "-";
    }

    if (isSimpleValue(arguments.value)) {
        if (isDate(arguments.value)) {
            return lsDateFormat(arguments.value, "dd/mm/yyyy") & " " & lsTimeFormat(arguments.value, "HH:mm:ss");
        }

        if (len(trim(arguments.value & ""))) {
            return trim(arguments.value & "");
        }

        return "-";
    }

    if (isArray(arguments.value)) {
        return arrayLen(arguments.value) & " item(ns)";
    }

    if (isStruct(arguments.value)) {
        return structCount(arguments.value) & " campo(s)";
    }

    return "-";
}

statusOverallClass = VARIABLES.uptimeStatus.down GT 0 ? "danger" : (VARIABLES.uptimeStatus.warning GT 0 ? "warning" : "success");
statusOverallLabel = VARIABLES.uptimeStatus.down GT 0 ? "Atenção necessária" : (VARIABLES.uptimeStatus.warning GT 0 ? "Instabilidade detectada" : "Todos online");
</cfscript>

<style>
  .status-page .status-card {
    border: 1px solid rgba(255,255,255,.1);
    border-radius: 14px;
    background: rgba(255,255,255,.025);
  }

  .status-page .status-kpi {
    min-height: 118px;
  }

  .status-page .status-json {
    background: rgba(0,0,0,.28);
    border: 1px solid rgba(255,255,255,.08);
    border-radius: 10px;
    color: rgba(255,255,255,.78);
    max-height: 360px;
    overflow: auto;
    padding: 1rem;
    white-space: pre-wrap;
    word-break: break-word;
  }

  .status-page .status-monitor-url {
    max-width: 460px;
  }
</style>

<section class="status-page py-5">
  <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-end gap-3 mb-4">
    <div>
      <div class="text-warning text-uppercase small fw-bold">Administração</div>
      <h1 class="h3 mb-1">Status dos Sites</h1>
      <p class="text-muted mb-0">Monitoramento via UptimeRobot com resumo operacional e payload completo retornado pela API.</p>
    </div>
    <div class="d-flex flex-wrap gap-2">
      <a class="btn btn-outline-light btn-sm" href="/?resetApp">Recarregar configuração</a>
      <a class="btn btn-warning btn-sm" href="/administracao/status/?uptime_refresh=1">Atualizar status</a>
    </div>
  </div>

  <cfif NOT VARIABLES.uptimeStatus.configured>
    <div class="alert alert-info">
      Configure a chave read-only do UptimeRobot em <code>UPTIMEROBOT_API_KEY</code> ou <code>config/business.local.cfm</code>.
      <cfif isDefined("URL.uptime_debug") AND val(URL.uptime_debug) EQ 1>
        <hr>
        <div class="small font-monospace">
          <cfoutput>
            configSource=#htmlEditFormat(VARIABLES.uptimeStatus.configSource)#<br>
            configPath=#htmlEditFormat(VARIABLES.uptimeStatus.configPath)#<br>
            configFileExists=#yesNoFormat(VARIABLES.uptimeStatus.configFileExists)#<br>
            applicationHasKey=#yesNoFormat(structKeyExists(APPLICATION, "uptimeRobot") AND structKeyExists(APPLICATION.uptimeRobot, "apiKey") AND len(trim(APPLICATION.uptimeRobot.apiKey)) GT 0)#<br>
            error=#htmlEditFormat(VARIABLES.uptimeStatus.error)#
          </cfoutput>
        </div>
      </cfif>
    </div>
  <cfelse>
    <cfif len(trim(VARIABLES.uptimeStatus.error))>
      <div class="alert alert-warning">
        <strong>Status indisponível.</strong> <cfoutput>#htmlEditFormat(VARIABLES.uptimeStatus.error)#</cfoutput>
      </div>
    </cfif>

    <div class="row g-3 mb-4">
      <div class="col-6 col-xl-2">
        <div class="status-card status-kpi p-3">
          <small class="text-muted d-block">Monitores</small>
          <strong class="fs-2"><cfoutput>#LSNumberFormat(VARIABLES.uptimeStatus.total, "9,999")#</cfoutput></strong>
          <div class="small text-muted">HTTP <cfoutput>#htmlEditFormat(VARIABLES.uptimeStatus.apiHttpStatus)#</cfoutput></div>
        </div>
      </div>
      <div class="col-6 col-xl-2">
        <div class="status-card status-kpi p-3 border border-success border-opacity-25">
          <small class="text-muted d-block">Online</small>
          <strong class="fs-2 text-success"><cfoutput>#LSNumberFormat(VARIABLES.uptimeStatus.up, "9,999")#</cfoutput></strong>
          <div class="small text-muted">operando</div>
        </div>
      </div>
      <div class="col-6 col-xl-2">
        <div class="status-card status-kpi p-3 border border-warning border-opacity-25">
          <small class="text-muted d-block">Instáveis</small>
          <strong class="fs-2 text-warning"><cfoutput>#LSNumberFormat(VARIABLES.uptimeStatus.warning, "9,999")#</cfoutput></strong>
          <div class="small text-muted">em verificação</div>
        </div>
      </div>
      <div class="col-6 col-xl-2">
        <div class="status-card status-kpi p-3 border border-danger border-opacity-25">
          <small class="text-muted d-block">Offline</small>
          <strong class="fs-2 text-danger"><cfoutput>#LSNumberFormat(VARIABLES.uptimeStatus.down, "9,999")#</cfoutput></strong>
          <div class="small text-muted">atenção</div>
        </div>
      </div>
      <div class="col-6 col-xl-2">
        <div class="status-card status-kpi p-3">
          <small class="text-muted d-block">Uptime médio</small>
          <strong class="fs-2"><cfoutput>#numberFormat(VARIABLES.uptimeStatus.averageUptime, "99.99")#%</cfoutput></strong>
          <div class="small text-muted">all time</div>
        </div>
      </div>
      <div class="col-6 col-xl-2">
        <div class="status-card status-kpi p-3">
          <small class="text-muted d-block">Resposta média</small>
          <strong class="fs-2"><cfoutput>#numberFormat(VARIABLES.uptimeStatus.averageResponseTime, "9")#ms</cfoutput></strong>
          <div class="small text-muted">
            <cfif isDate(VARIABLES.uptimeStatus.fetchedAt)>
              <cfoutput>#lsDateFormat(VARIABLES.uptimeStatus.fetchedAt, "dd/mm")# #lsTimeFormat(VARIABLES.uptimeStatus.fetchedAt, "HH:mm")#</cfoutput>
            <cfelse>
              -
            </cfif>
          </div>
        </div>
      </div>
    </div>

    <div class="row g-4">
      <div class="col-12">
        <div class="status-card p-3 p-lg-4">
          <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-start gap-2 mb-3">
            <div>
              <h2 class="h5 mb-1">Monitores</h2>
              <div class="text-muted small">Tabela com campos operacionais normalizados e detalhes brutos de cada monitor.</div>
            </div>
            <cfoutput><span class="badge badge-#statusOverallClass#">#htmlEditFormat(statusOverallLabel)#</span></cfoutput>
          </div>

          <cfif arrayLen(VARIABLES.uptimeStatus.monitors)>
            <div class="table-responsive">
              <table class="table table-sm align-middle business-table">
                <thead>
                  <tr>
                    <th>Monitor</th>
                    <th>Status</th>
                    <th class="text-end">Uptime</th>
                    <th class="text-end">Resposta</th>
                    <th>Último evento</th>
                    <th>Detalhes da API</th>
                  </tr>
                </thead>
                <tbody>
                  <cfloop array="#VARIABLES.uptimeStatus.monitors#" index="statusMonitor">
                    <cfoutput>
                      <tr>
                        <td>
                          <strong>#htmlEditFormat(statusMonitor.name)#</strong>
                          <cfif len(trim(statusMonitor.url))>
                            <small class="text-muted d-block text-truncate status-monitor-url">#htmlEditFormat(statusMonitor.url)#</small>
                          </cfif>
                        </td>
                        <td><span class="badge badge-#statusMonitor.statusClass#">#statusMonitor.statusLabel#</span></td>
                        <td class="text-end">#statusMonitor.uptime GT 0 ? numberFormat(statusMonitor.uptime, "99.99") & "%" : "-"#</td>
                        <td class="text-end">#statusMonitor.responseTime GT 0 ? numberFormat(statusMonitor.responseTime, "9") & "ms" : "-"#</td>
                        <td>
                          <cfif len(trim(statusMonitor.incident))>
                            #htmlEditFormat(statusMonitor.incident)#
                            <cfif isDate(statusMonitor.incidentAt)>
                              <small class="text-muted d-block">#lsDateFormat(statusMonitor.incidentAt, "dd/mm/yyyy")# #lsTimeFormat(statusMonitor.incidentAt, "HH:mm")#</small>
                            </cfif>
                          <cfelse>
                            <span class="text-muted">-</span>
                          </cfif>
                        </td>
                        <td style="min-width: 260px;">
                          <cfif structKeyExists(statusMonitor, "raw") AND isStruct(statusMonitor.raw)>
                            <details>
                              <summary class="text-warning" role="button">Ver payload</summary>
                              <pre class="status-json mt-2 mb-0">#htmlEditFormat(statusJson(statusMonitor.raw))#</pre>
                            </details>
                          <cfelse>
                            <span class="text-muted">-</span>
                          </cfif>
                        </td>
                      </tr>
                    </cfoutput>
                  </cfloop>
                </tbody>
              </table>
            </div>
          <cfelse>
            <p class="text-muted mb-0">Nenhum monitor foi retornado pela API.</p>
          </cfif>
        </div>
      </div>

      <div class="col-12 col-xl-5">
        <div class="status-card p-3 p-lg-4 h-100">
          <h2 class="h5 mb-3">Metadados do Retorno</h2>
          <div class="table-responsive">
            <table class="table table-sm align-middle mb-0">
              <tbody>
                <tr>
                  <th>Fonte de configuração</th>
                  <td><cfoutput>#htmlEditFormat(VARIABLES.uptimeStatus.configSource)#</cfoutput></td>
                </tr>
                <tr>
                  <th>API URL</th>
                  <td><cfoutput>#structKeyExists(APPLICATION, "uptimeRobot") ? htmlEditFormat(APPLICATION.uptimeRobot.apiUrl) : "-"#</cfoutput></td>
                </tr>
                <tr>
                  <th>Cache</th>
                  <td><cfoutput>#structKeyExists(APPLICATION, "uptimeRobot") ? LSNumberFormat(APPLICATION.uptimeRobot.cacheSeconds) & "s" : "-"#</cfoutput></td>
                </tr>
                <tr>
                  <th>Timeout</th>
                  <td><cfoutput>#structKeyExists(APPLICATION, "uptimeRobot") ? LSNumberFormat(APPLICATION.uptimeRobot.timeoutSeconds) & "s" : "-"#</cfoutput></td>
                </tr>
                <tr>
                  <th>Atualizado em</th>
                  <td>
                    <cfif isDate(VARIABLES.uptimeStatus.fetchedAt)>
                      <cfoutput>#lsDateFormat(VARIABLES.uptimeStatus.fetchedAt, "dd/mm/yyyy")# #lsTimeFormat(VARIABLES.uptimeStatus.fetchedAt, "HH:mm:ss")#</cfoutput>
                    <cfelse>
                      -
                    </cfif>
                  </td>
                </tr>
                <cfif structKeyExists(VARIABLES.uptimeStatus, "rawPayload") AND isStruct(VARIABLES.uptimeStatus.rawPayload)>
                  <cfloop collection="#VARIABLES.uptimeStatus.rawPayload#" item="payloadKey">
                    <cfif payloadKey NEQ "monitors">
                      <tr>
                        <th><cfoutput>#htmlEditFormat(payloadKey)#</cfoutput></th>
                        <td><cfoutput>#htmlEditFormat(statusSimpleValue(VARIABLES.uptimeStatus.rawPayload[payloadKey]))#</cfoutput></td>
                      </tr>
                    </cfif>
                  </cfloop>
                </cfif>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="col-12 col-xl-7">
        <div class="status-card p-3 p-lg-4 h-100">
          <h2 class="h5 mb-3">Payload Completo da API</h2>
          <cfif structKeyExists(VARIABLES.uptimeStatus, "rawPayload") AND isStruct(VARIABLES.uptimeStatus.rawPayload) AND structCount(VARIABLES.uptimeStatus.rawPayload)>
            <pre class="status-json mb-0"><cfoutput>#htmlEditFormat(statusJson(VARIABLES.uptimeStatus.rawPayload))#</cfoutput></pre>
          <cfelse>
            <p class="text-muted mb-0">O payload bruto ainda não está disponível no cache atual. Use “Atualizar status”.</p>
          </cfif>
        </div>
      </div>
    </div>
  </cfif>
</section>
