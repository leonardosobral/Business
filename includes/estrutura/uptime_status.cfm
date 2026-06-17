<cfinclude template="../backend/uptime_status.cfm"/>

<cfif VARIABLES.uptimeStatus.configured>
    <section class="col-12">
        <div class="card shadow-0 overflow-hidden">
            <div class="card-header bg-black bg-opacity-25 d-flex flex-wrap gap-2 justify-content-between align-items-center">
                <div>
                    <h5 class="mb-0">Uptime Server Status</h5>
                    <small class="text-muted">
                        <cfif VARIABLES.uptimeStatus.loaded AND isDate(VARIABLES.uptimeStatus.fetchedAt)>
                            Atualizado em <cfoutput>#lsDateFormat(VARIABLES.uptimeStatus.fetchedAt, "dd/mm/yyyy")# #lsTimeFormat(VARIABLES.uptimeStatus.fetchedAt, "HH:mm")#</cfoutput>
                        <cfelse>
                            Monitoramento externo
                        </cfif>
                    </small>
                </div>
                <cfif VARIABLES.uptimeStatus.loaded>
                    <cfoutput>
                        <span class="badge badge-#VARIABLES.uptimeStatus.down GT 0 ? 'danger' : (VARIABLES.uptimeStatus.warning GT 0 ? 'warning' : 'success')#">
                            #VARIABLES.uptimeStatus.down GT 0 ? 'Atenção necessária' : (VARIABLES.uptimeStatus.warning GT 0 ? 'Instabilidade detectada' : 'Todos online')#
                        </span>
                    </cfoutput>
                </cfif>
            </div>

            <div class="card-body">
                <cfif len(trim(VARIABLES.uptimeStatus.error))>
                    <div class="alert alert-warning mb-0">
                        <strong>Status indisponível.</strong> <cfoutput>#htmlEditFormat(VARIABLES.uptimeStatus.error)#</cfoutput>
                    </div>
                <cfelseif VARIABLES.uptimeStatus.loaded>
                    <div class="row g-3 mb-4">
                        <div class="col-6 col-lg-2">
                            <div class="border rounded-4 p-3 h-100">
                                <small class="text-muted d-block">Monitores</small>
                                <strong class="fs-3"><cfoutput>#numberFormat(VARIABLES.uptimeStatus.total, "9")#</cfoutput></strong>
                            </div>
                        </div>
                        <div class="col-6 col-lg-2">
                            <div class="border border-success rounded-4 p-3 h-100">
                                <small class="text-muted d-block">Online</small>
                                <strong class="fs-3 text-success"><cfoutput>#numberFormat(VARIABLES.uptimeStatus.up, "9")#</cfoutput></strong>
                            </div>
                        </div>
                        <div class="col-6 col-lg-2">
                            <div class="border border-warning rounded-4 p-3 h-100">
                                <small class="text-muted d-block">Instáveis</small>
                                <strong class="fs-3 text-warning"><cfoutput>#numberFormat(VARIABLES.uptimeStatus.warning, "9")#</cfoutput></strong>
                            </div>
                        </div>
                        <div class="col-6 col-lg-2">
                            <div class="border border-danger rounded-4 p-3 h-100">
                                <small class="text-muted d-block">Offline</small>
                                <strong class="fs-3 text-danger"><cfoutput>#numberFormat(VARIABLES.uptimeStatus.down, "9")#</cfoutput></strong>
                            </div>
                        </div>
                        <div class="col-6 col-lg-2">
                            <div class="border rounded-4 p-3 h-100">
                                <small class="text-muted d-block">Uptime médio</small>
                                <strong class="fs-3"><cfoutput>#numberFormat(VARIABLES.uptimeStatus.averageUptime, "99.99")#%</cfoutput></strong>
                            </div>
                        </div>
                        <div class="col-6 col-lg-2">
                            <div class="border rounded-4 p-3 h-100">
                                <small class="text-muted d-block">Resposta média</small>
                                <strong class="fs-3"><cfoutput>#numberFormat(VARIABLES.uptimeStatus.averageResponseTime, "9")#ms</cfoutput></strong>
                            </div>
                        </div>
                    </div>

                    <div class="table-responsive">
                        <table class="table table-sm align-middle mb-0">
                            <thead>
                                <tr>
                                    <th>Monitor</th>
                                    <th>Status</th>
                                    <th class="text-end">Uptime</th>
                                    <th class="text-end">Resposta</th>
                                    <th>Último evento</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop array="#VARIABLES.uptimeStatus.monitors#" index="uptimeMonitorView">
                                    <cfoutput>
                                        <tr>
                                            <td>
                                                <strong>#htmlEditFormat(uptimeMonitorView.name)#</strong>
                                                <cfif len(trim(uptimeMonitorView.url))>
                                                    <small class="text-muted d-block text-truncate" style="max-width: 420px;">#htmlEditFormat(uptimeMonitorView.url)#</small>
                                                </cfif>
                                            </td>
                                            <td>
                                                <span class="badge badge-#uptimeMonitorView.statusClass#">#uptimeMonitorView.statusLabel#</span>
                                            </td>
                                            <td class="text-end">#uptimeMonitorView.uptime GT 0 ? numberFormat(uptimeMonitorView.uptime, "99.99") & "%" : "-"#</td>
                                            <td class="text-end">#uptimeMonitorView.responseTime GT 0 ? numberFormat(uptimeMonitorView.responseTime, "9") & "ms" : "-"#</td>
                                            <td>
                                                <cfif len(trim(uptimeMonitorView.incident))>
                                                    #htmlEditFormat(uptimeMonitorView.incident)#
                                                    <cfif isDate(uptimeMonitorView.incidentAt)>
                                                        <small class="text-muted d-block">#lsDateFormat(uptimeMonitorView.incidentAt, "dd/mm/yyyy")# #lsTimeFormat(uptimeMonitorView.incidentAt, "HH:mm")#</small>
                                                    </cfif>
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
                    <div class="alert alert-info mb-0">
                        O status dos servidores ainda não foi carregado.
                    </div>
                </cfif>
            </div>
        </div>
    </section>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND qPerfil.is_admin>
    <section class="col-12">
        <div class="alert alert-info">
            Configure a chave read-only do UptimeRobot em <code>UPTIMEROBOT_API_KEY</code> ou <code>config/business.local.cfm</code> para exibir o Server Status.
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
    </section>
</cfif>
