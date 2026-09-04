<cfset VARIABLES.adsV1PerformanceIsAdmin = isDefined("VARIABLES.adsV1PerformanceContext")
    AND VARIABLES.adsV1PerformanceContext EQ "admin"/>
<cfset VARIABLES.adsV1PerformanceIsCampaign = isDefined("VARIABLES.adsV1PerformanceContext")
    AND VARIABLES.adsV1PerformanceContext EQ "campaign"/>
<cfif VARIABLES.adsV1PerformanceIsCampaign>
    <cfset VARIABLES.adsV1PerformanceDaily = qAdsV1CampaignPerformanceDaily/>
    <cfset VARIABLES.adsV1PerformanceComparison = qAdsV1CampaignPerformanceComparison/>
    <cfset VARIABLES.adsV1PerformanceView = "campaign-detail"/>
    <cfset VARIABLES.adsV1PerformanceTitle = "Desempenho da campanha"/>
    <cfset VARIABLES.adsV1PerformanceSubtitle = "Acompanhe somente os resultados deste anúncio, sem misturar com as outras campanhas da conta."/>
<cfelseif VARIABLES.adsV1PerformanceIsAdmin>
    <cfset VARIABLES.adsV1PerformanceDaily = qAdsV1AdminPerformanceDaily/>
    <cfset VARIABLES.adsV1PerformanceComparison = qAdsV1AdminPerformanceComparison/>
    <cfset VARIABLES.adsV1PerformanceView = "admin"/>
    <cfset VARIABLES.adsV1PerformanceTitle = "Performance global dos anúncios"/>
    <cfset VARIABLES.adsV1PerformanceSubtitle = "Resultado diário das campanhas de evento em todas as contas."/>
<cfelse>
    <cfset VARIABLES.adsV1PerformanceDaily = qAdsV1AccountPerformanceDaily/>
    <cfset VARIABLES.adsV1PerformanceComparison = qAdsV1AccountPerformanceComparison/>
    <cfset VARIABLES.adsV1PerformanceView = "overview"/>
    <cfset VARIABLES.adsV1PerformanceTitle = "Performance da publicidade"/>
    <cfset VARIABLES.adsV1PerformanceSubtitle = "Veja o alcance dos seus eventos e quanto cada resultado está custando."/>
</cfif>

<cfset VARIABLES.adsV1PerformanceImpressions = 0/>
<cfset VARIABLES.adsV1PerformanceClicks = 0/>
<cfset VARIABLES.adsV1PerformanceBillableClicks = 0/>
<cfset VARIABLES.adsV1PerformanceConversions = 0/>
<cfset VARIABLES.adsV1PerformanceCost = 0/>
<cfset VARIABLES.adsV1PerformanceRows = []/>

<cfloop from="1" to="#VARIABLES.adsV1PerformanceDaily.recordcount#" index="VARIABLES.adsV1PerformanceRowIndex">
    <cfset VARIABLES.adsV1PerformanceImpressions += val(VARIABLES.adsV1PerformanceDaily.impressions[VARIABLES.adsV1PerformanceRowIndex])/>
    <cfset VARIABLES.adsV1PerformanceClicks += val(VARIABLES.adsV1PerformanceDaily.clicks[VARIABLES.adsV1PerformanceRowIndex])/>
    <cfset VARIABLES.adsV1PerformanceBillableClicks += val(VARIABLES.adsV1PerformanceDaily.billable_clicks[VARIABLES.adsV1PerformanceRowIndex])/>
    <cfset VARIABLES.adsV1PerformanceConversions += val(VARIABLES.adsV1PerformanceDaily.conversions[VARIABLES.adsV1PerformanceRowIndex])/>
    <cfset VARIABLES.adsV1PerformanceCost += val(VARIABLES.adsV1PerformanceDaily.cost[VARIABLES.adsV1PerformanceRowIndex])/>
    <cfset arrayAppend(VARIABLES.adsV1PerformanceRows, {
        "date" = dateFormat(VARIABLES.adsV1PerformanceDaily.metric_date[VARIABLES.adsV1PerformanceRowIndex], "yyyy-mm-dd"),
        "impressions" = val(VARIABLES.adsV1PerformanceDaily.impressions[VARIABLES.adsV1PerformanceRowIndex]),
        "clicks" = val(VARIABLES.adsV1PerformanceDaily.clicks[VARIABLES.adsV1PerformanceRowIndex]),
        "billableClicks" = val(VARIABLES.adsV1PerformanceDaily.billable_clicks[VARIABLES.adsV1PerformanceRowIndex]),
        "cost" = val(VARIABLES.adsV1PerformanceDaily.cost[VARIABLES.adsV1PerformanceRowIndex])
    })/>
</cfloop>

<cfset VARIABLES.adsV1PerformanceCtr = VARIABLES.adsV1PerformanceImpressions GT 0
    ? VARIABLES.adsV1PerformanceClicks * 100 / VARIABLES.adsV1PerformanceImpressions
    : 0/>
<cfset VARIABLES.adsV1PerformanceAverageCpc = VARIABLES.adsV1PerformanceBillableClicks GT 0
    ? VARIABLES.adsV1PerformanceCost / VARIABLES.adsV1PerformanceBillableClicks
    : 0/>
<cfset VARIABLES.adsV1PerformanceImpressionsTrend = 0/>
<cfset VARIABLES.adsV1PerformanceClicksTrend = 0/>
<cfset VARIABLES.adsV1PerformanceCostTrend = 0/>

<cfif VARIABLES.adsV1PerformanceComparison.recordcount>
    <cfset VARIABLES.adsV1PreviousImpressions = val(VARIABLES.adsV1PerformanceComparison.previous_impressions[1])/>
    <cfset VARIABLES.adsV1PreviousClicks = val(VARIABLES.adsV1PerformanceComparison.previous_clicks[1])/>
    <cfset VARIABLES.adsV1PreviousCost = val(VARIABLES.adsV1PerformanceComparison.previous_cost[1])/>
    <cfset VARIABLES.adsV1PerformanceImpressionsTrend = VARIABLES.adsV1PreviousImpressions GT 0
        ? (val(VARIABLES.adsV1PerformanceComparison.current_impressions[1]) - VARIABLES.adsV1PreviousImpressions) * 100 / VARIABLES.adsV1PreviousImpressions
        : (val(VARIABLES.adsV1PerformanceComparison.current_impressions[1]) GT 0 ? 100 : 0)/>
    <cfset VARIABLES.adsV1PerformanceClicksTrend = VARIABLES.adsV1PreviousClicks GT 0
        ? (val(VARIABLES.adsV1PerformanceComparison.current_clicks[1]) - VARIABLES.adsV1PreviousClicks) * 100 / VARIABLES.adsV1PreviousClicks
        : (val(VARIABLES.adsV1PerformanceComparison.current_clicks[1]) GT 0 ? 100 : 0)/>
    <cfset VARIABLES.adsV1PerformanceCostTrend = VARIABLES.adsV1PreviousCost GT 0
        ? (val(VARIABLES.adsV1PerformanceComparison.current_cost[1]) - VARIABLES.adsV1PreviousCost) * 100 / VARIABLES.adsV1PreviousCost
        : (val(VARIABLES.adsV1PerformanceComparison.current_cost[1]) GT 0 ? 100 : 0)/>
</cfif>

<cfset VARIABLES.adsV1PerformanceChartId = "ads-performance-chart-" & VARIABLES.adsV1PerformanceContext/>
<cfset VARIABLES.adsV1PerformanceDataId = "ads-performance-data-" & VARIABLES.adsV1PerformanceContext/>
<cfset VARIABLES.adsV1PerformanceCampaignQuery = NOT VARIABLES.adsV1PerformanceIsAdmin
    AND NOT VARIABLES.adsV1PerformanceIsCampaign
    AND len(VARIABLES.adsV1PerformanceCampaignId)
    ? "&amp;ads_campaign=" & urlEncodedFormat(VARIABLES.adsV1PerformanceCampaignId)
    : ""/>

<section class="card shadow-0 ads-performance-card mb-4">
    <div class="card-body p-3 p-lg-4">
        <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
            <div>
                <div class="ads-v1-eyebrow">Resultados</div>
                <h2 class="h4 mb-1"><cfoutput>#htmlEditFormat(VARIABLES.adsV1PerformanceTitle)#</cfoutput></h2>
                <p class="text-muted mb-0"><cfoutput>#htmlEditFormat(VARIABLES.adsV1PerformanceSubtitle)#</cfoutput></p>
                <cfif NOT VARIABLES.adsV1PerformanceIsAdmin AND NOT VARIABLES.adsV1PerformanceIsCampaign AND len(VARIABLES.adsV1PerformanceCampaignName)>
                    <div class="ads-performance-selection mt-2"><i class="fas fa-filter me-1" aria-hidden="true"></i>Campanha selecionada: <strong><cfoutput>#htmlEditFormat(VARIABLES.adsV1PerformanceCampaignName)#</cfoutput></strong></div>
                </cfif>
            </div>
            <div class="ads-performance-controls">
                <cfif NOT VARIABLES.adsV1PerformanceIsAdmin AND NOT VARIABLES.adsV1PerformanceIsCampaign>
                    <form class="ads-performance-campaign-filter" method="get" action="./">
                        <input type="hidden" name="view" value="overview"/>
                        <input type="hidden" name="ads_period" value="<cfoutput>#VARIABLES.adsV1PerformanceDays#</cfoutput>"/>
                        <label for="ads-performance-campaign">Campanha</label>
                        <div class="input-group input-group-sm">
                            <select class="form-select" id="ads-performance-campaign" name="ads_campaign">
                                <option value="">Todas as campanhas</option>
                                <cfoutput query="qAdsV1Campaigns"><option value="#htmlEditFormat(qAdsV1Campaigns.campaign_id)#"<cfif compareNoCase(qAdsV1Campaigns.campaign_id & "", VARIABLES.adsV1PerformanceCampaignId) EQ 0> selected</cfif>>#htmlEditFormat(qAdsV1Campaigns.name)#</option></cfoutput>
                            </select>
                            <button class="btn btn-outline-info" type="submit">Filtrar</button>
                        </div>
                    </form>
                </cfif>
                <div class="btn-group btn-group-sm" role="group" aria-label="Período do gráfico">
                    <cfif VARIABLES.adsV1PerformanceIsCampaign>
                        <a class="btn <cfif VARIABLES.adsV1PerformanceDays EQ 7>btn-info<cfelse>btn-outline-info</cfif>" href="./?view=campaign-detail&amp;campaign=<cfoutput>#urlEncodedFormat(VARIABLES.adsV1SelectedCampaignId)#</cfoutput>&amp;ads_period=7">Últimos 7 dias</a>
                        <a class="btn <cfif VARIABLES.adsV1PerformanceDays EQ 30>btn-info<cfelse>btn-outline-info</cfif>" href="./?view=campaign-detail&amp;campaign=<cfoutput>#urlEncodedFormat(VARIABLES.adsV1SelectedCampaignId)#</cfoutput>&amp;ads_period=30">Últimos 30 dias</a>
                    <cfelse>
                        <a class="btn <cfif VARIABLES.adsV1PerformanceDays EQ 7>btn-info<cfelse>btn-outline-info</cfif>" href="./?view=<cfoutput>#VARIABLES.adsV1PerformanceView#</cfoutput>&amp;ads_period=7<cfoutput>#VARIABLES.adsV1PerformanceCampaignQuery#</cfoutput>">Últimos 7 dias</a>
                        <a class="btn <cfif VARIABLES.adsV1PerformanceDays EQ 30>btn-info<cfelse>btn-outline-info</cfif>" href="./?view=<cfoutput>#VARIABLES.adsV1PerformanceView#</cfoutput>&amp;ads_period=30<cfoutput>#VARIABLES.adsV1PerformanceCampaignQuery#</cfoutput>">Últimos 30 dias</a>
                    </cfif>
                </div>
            </div>
        </div>

        <div class="ads-performance-kpis mb-4">
            <div class="ads-performance-kpi">
                <span>Impressões</span>
                <strong><cfoutput>#lsNumberFormat(VARIABLES.adsV1PerformanceImpressions, "9,999,999")#</cfoutput></strong>
                <small>vezes em que os anúncios apareceram</small>
            </div>
            <div class="ads-performance-kpi">
                <span>Cliques</span>
                <strong><cfoutput>#lsNumberFormat(VARIABLES.adsV1PerformanceClicks, "9,999,999")#</cfoutput></strong>
                <small>visitas geradas para os eventos</small>
            </div>
            <div class="ads-performance-kpi">
                <span>Taxa de cliques (CTR)</span>
                <strong><cfoutput>#lsNumberFormat(VARIABLES.adsV1PerformanceCtr, "9.99")#%</cfoutput></strong>
                <small>percentual de impressões que virou clique</small>
            </div>
            <div class="ads-performance-kpi">
                <span>Investimento</span>
                <strong><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1PerformanceCost)#</cfoutput></strong>
                <small>valor consumido no período</small>
            </div>
            <div class="ads-performance-kpi">
                <span>CPC médio real</span>
                <strong><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1PerformanceAverageCpc)#</cfoutput></strong>
                <small>custo médio de cada clique cobrado</small>
            </div>
        </div>

        <div class="ads-performance-trends mb-3" aria-label="Comparação com o período anterior">
            <span>Comparado aos <cfoutput>#VARIABLES.adsV1PerformanceDays#</cfoutput> dias anteriores:</span>
            <strong class="<cfif VARIABLES.adsV1PerformanceImpressionsTrend GTE 0>text-success<cfelse>text-danger</cfif>">Impressões <cfif VARIABLES.adsV1PerformanceImpressionsTrend GT 0>+</cfif><cfoutput>#lsNumberFormat(VARIABLES.adsV1PerformanceImpressionsTrend, "9.9")#%</cfoutput></strong>
            <strong class="<cfif VARIABLES.adsV1PerformanceClicksTrend GTE 0>text-success<cfelse>text-danger</cfif>">Cliques <cfif VARIABLES.adsV1PerformanceClicksTrend GT 0>+</cfif><cfoutput>#lsNumberFormat(VARIABLES.adsV1PerformanceClicksTrend, "9.9")#%</cfoutput></strong>
            <strong class="<cfif VARIABLES.adsV1PerformanceCostTrend LTE 0>text-success<cfelse>text-warning</cfif>">Investimento <cfif VARIABLES.adsV1PerformanceCostTrend GT 0>+</cfif><cfoutput>#lsNumberFormat(VARIABLES.adsV1PerformanceCostTrend, "9.9")#%</cfoutput></strong>
        </div>

        <cfif VARIABLES.adsV1PerformanceImpressions GT 0 OR VARIABLES.adsV1PerformanceClicks GT 0 OR VARIABLES.adsV1PerformanceCost GT 0>
            <div class="ads-performance-chart-wrap">
                <canvas id="<cfoutput>#VARIABLES.adsV1PerformanceChartId#</cfoutput>" data-ads-performance-chart data-source-id="<cfoutput>#VARIABLES.adsV1PerformanceDataId#</cfoutput>" aria-label="Gráfico diário de impressões, cliques e investimento" role="img"></canvas>
            </div>
            <script type="application/json" id="<cfoutput>#VARIABLES.adsV1PerformanceDataId#</cfoutput>"><cfoutput>#serializeJSON(VARIABLES.adsV1PerformanceRows)#</cfoutput></script>
        <cfelse>
            <div class="ads-performance-empty text-center">
                <i class="fas fa-chart-line mb-3" aria-hidden="true"></i>
                <h3 class="h6 mb-2">O gráfico começa com as primeiras exibições</h3>
                <p class="text-muted mb-0">Assim que uma campanha aprovada for veiculada, você verá aqui a evolução diária do alcance, dos cliques e do investimento.</p>
            </div>
        </cfif>
    </div>
</section>
