<style>
    .ads-legacy-summary {
        min-height: 110px;
    }

    .ads-legacy-table {
        font-size: .82rem;
        min-width: 940px;
    }

    .ads-legacy-table th,
    .ads-legacy-table td {
        vertical-align: middle;
    }
</style>

<section class="mb-4">
    <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-end gap-3">
        <div>
            <div class="text-warning fw-bold text-uppercase small">Consulta administrativa</div>
            <h1 class="h3 mb-1">Historico anterior de publicidade</h1>
            <p class="text-muted mb-0">Visao compacta e estritamente somente leitura das campanhas armazenadas nas tabelas anteriores.</p>
        </div>
        <a class="btn btn-sm btn-outline-warning" href="/ads/">Voltar para Publicidade</a>
    </div>
</section>

<cfif NOT VARIABLES.adsLegacyReady>
    <div class="alert alert-warning">
        <cfoutput>#htmlEditFormat(VARIABLES.adsLegacyError)#</cfoutput>
    </div>
<cfelse>
    <cfif qAdsLegacySummary.recordcount>
        <section class="row row-cols-1 row-cols-sm-2 row-cols-xl-4 g-3 mb-4">
            <div class="col"><div class="card ads-legacy-summary h-100"><div class="card-body"><div class="small text-muted">Campanhas</div><div class="h3 mb-0"><cfoutput>#numberFormat(qAdsLegacySummary.campaigns_total, "9,999")#</cfoutput></div><div class="small text-muted"><cfoutput>#numberFormat(qAdsLegacySummary.campaigns_active, "9,999")# ativas</cfoutput></div></div></div></div>
            <div class="col"><div class="card ads-legacy-summary h-100"><div class="card-body"><div class="small text-muted">Visualizacoes</div><div class="h3 mb-0"><cfoutput>#numberFormat(qAdsLegacySummary.views_total, "9,999,999")#</cfoutput></div><div class="small text-muted">historico consolidado</div></div></div></div>
            <div class="col"><div class="card ads-legacy-summary h-100"><div class="card-body"><div class="small text-muted">Cliques</div><div class="h3 mb-0"><cfoutput>#numberFormat(qAdsLegacySummary.clicks_total, "9,999,999")#</cfoutput></div><div class="small text-muted">historico consolidado</div></div></div></div>
            <div class="col"><div class="card ads-legacy-summary h-100"><div class="card-body"><div class="small text-muted">Custo</div><div class="h3 mb-0"><cfoutput>#lsCurrencyFormat(qAdsLegacySummary.cost_total)#</cfoutput></div><div class="small text-muted">consumo historico</div></div></div></div>
        </section>
    </cfif>

    <section class="card shadow-0 mb-4">
        <div class="card-body p-3 p-lg-4">
            <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                <div>
                    <h2 class="h5 mb-1">Campanhas anteriores</h2>
                    <p class="text-muted mb-0">A consulta mostra no maximo as 100 campanhas mais recentes e nao oferece controles de alteracao.</p>
                </div>
                <cfif len(VARIABLES.adsLegacyRealUserName)>
                    <span class="small text-muted"><cfoutput>#htmlEditFormat(VARIABLES.adsLegacyRealUserName)#</cfoutput></span>
                </cfif>
            </div>

            <cfif qAdsLegacyCampaigns.recordcount>
                <div class="table-responsive">
                    <table class="table table-sm table-hover ads-legacy-table mb-0">
                        <thead>
                            <tr><th>Evento</th><th>Contas</th><th>Status</th><th>Periodo</th><th class="text-end">CPC</th><th class="text-end">Views</th><th class="text-end">Cliques</th><th class="text-end">Custo</th></tr>
                        </thead>
                        <tbody>
                            <cfoutput query="qAdsLegacyCampaigns">
                                <cfset VARIABLES.adsLegacyStatusLabel = "Status " & qAdsLegacyCampaigns.status/>
                                <cfif qAdsLegacyCampaigns.status LT 3><cfset VARIABLES.adsLegacyStatusLabel = "Ativa"/></cfif>
                                <cfif qAdsLegacyCampaigns.status EQ 3><cfset VARIABLES.adsLegacyStatusLabel = "Pausada"/></cfif>
                                <cfif qAdsLegacyCampaigns.status EQ 4><cfset VARIABLES.adsLegacyStatusLabel = "Arquivada"/></cfif>
                                <tr>
                                    <td><strong>#htmlEditFormat(qAdsLegacyCampaigns.nome_evento)#</strong><div class="small text-muted">#htmlEditFormat(qAdsLegacyCampaigns.cidade)#<cfif len(trim(qAdsLegacyCampaigns.estado))>/#htmlEditFormat(qAdsLegacyCampaigns.estado)#</cfif></div></td>
                                    <td>#htmlEditFormat(qAdsLegacyCampaigns.contas)#</td>
                                    <td>#htmlEditFormat(VARIABLES.adsLegacyStatusLabel)#</td>
                                    <td><cfif isDate(qAdsLegacyCampaigns.inicio_ad)>#lsDateFormat(qAdsLegacyCampaigns.inicio_ad, "dd/mm/yyyy")#<cfelse>-</cfif> a <cfif isDate(qAdsLegacyCampaigns.final_ad)>#lsDateFormat(qAdsLegacyCampaigns.final_ad, "dd/mm/yyyy")#<cfelse>-</cfif></td>
                                    <td class="text-end">#lsCurrencyFormat(qAdsLegacyCampaigns.cpc_max)#</td>
                                    <td class="text-end">#numberFormat(qAdsLegacyCampaigns.views, "9,999,999")#</td>
                                    <td class="text-end">#numberFormat(qAdsLegacyCampaigns.clicks, "9,999,999")#</td>
                                    <td class="text-end">#lsCurrencyFormat(qAdsLegacyCampaigns.cost_total)#</td>
                                </tr>
                            </cfoutput>
                        </tbody>
                    </table>
                </div>
            <cfelse>
                <p class="text-muted mb-0">Nenhuma campanha anterior encontrada.</p>
            </cfif>
        </div>
    </section>
</cfif>
