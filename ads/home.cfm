<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- WIDGETS --->

<cfset VARIABLES.adsViewsTotal = val(qAdCountViews.total)/>
<cfset VARIABLES.adsClicksTotal = val(qAdCountClicks.total)/>
<cfset VARIABLES.adsClickRate = VARIABLES.adsViewsTotal GT 0 ? (VARIABLES.adsClicksTotal * 100 / VARIABLES.adsViewsTotal) : 0/>
<cfset VARIABLES.adsCampaignsTotal = qEventosAds.recordcount + qEventosAdsPausados.recordcount + qEventosAdsFinalizados.recordcount/>
<cfset VARIABLES.adsHasCampaigns = VARIABLES.adsCampaignsTotal GT 0/>
<cfset VARIABLES.adsCreditAnchor = (VARIABLES.adsVoucherColumnsReady AND qAdCreditVouchers.recordcount) ? "##credito-ads" : "##turbinar-evento"/>
<cfif VARIABLES.adsVoucherColumnsReady AND qAdAvailableVouchers.recordcount>
  <cfset VARIABLES.adsCreditAnchor = "##voucher-ads"/>
</cfif>
<cfset VARIABLES.adsPeriodViews = 0/>
<cfset VARIABLES.adsPeriodClicks = 0/>
<cfset VARIABLES.adsPeriodCost = 0/>
<cfset VARIABLES.adsChartMax = 1/>
<cfset VARIABLES.adsViewsTrend = 0/>
<cfset VARIABLES.adsClicksTrend = 0/>
<cfset VARIABLES.adsCostTrend = 0/>
<cfset VARIABLES.adsViewsTrendSign = ""/>
<cfset VARIABLES.adsClicksTrendSign = ""/>
<cfset VARIABLES.adsCostTrendSign = ""/>
<cfset VARIABLES.adsDailySpend = 0/>
<cfset VARIABLES.adsCreditRunwayDays = 0/>
<cfset VARIABLES.adsConversionsTotal = 0/>
<cfset VARIABLES.adsConversionRate = 0/>
<cfloop query="qAdMetricasDia">
  <cfset VARIABLES.adsPeriodViews = VARIABLES.adsPeriodViews + val(qAdMetricasDia.views)/>
  <cfset VARIABLES.adsPeriodClicks = VARIABLES.adsPeriodClicks + val(qAdMetricasDia.clicks)/>
  <cfset VARIABLES.adsPeriodCost = VARIABLES.adsPeriodCost + val(qAdMetricasDia.custo)/>
  <cfif val(qAdMetricasDia.views) GT VARIABLES.adsChartMax>
    <cfset VARIABLES.adsChartMax = val(qAdMetricasDia.views)/>
  </cfif>
  <cfif val(qAdMetricasDia.clicks) GT VARIABLES.adsChartMax>
    <cfset VARIABLES.adsChartMax = val(qAdMetricasDia.clicks)/>
  </cfif>
</cfloop>
<cfset VARIABLES.adsPeriodClickRate = VARIABLES.adsPeriodViews GT 0 ? (VARIABLES.adsPeriodClicks * 100 / VARIABLES.adsPeriodViews) : 0/>
<cfif qAdMetricasComparativo.recordcount>
  <cfset VARIABLES.adsViewsTrend = val(qAdMetricasComparativo.views_anterior) GT 0 ? ((val(qAdMetricasComparativo.views_atual) - val(qAdMetricasComparativo.views_anterior)) * 100 / val(qAdMetricasComparativo.views_anterior)) : (val(qAdMetricasComparativo.views_atual) GT 0 ? 100 : 0)/>
  <cfset VARIABLES.adsClicksTrend = val(qAdMetricasComparativo.clicks_anterior) GT 0 ? ((val(qAdMetricasComparativo.clicks_atual) - val(qAdMetricasComparativo.clicks_anterior)) * 100 / val(qAdMetricasComparativo.clicks_anterior)) : (val(qAdMetricasComparativo.clicks_atual) GT 0 ? 100 : 0)/>
  <cfset VARIABLES.adsCostTrend = val(qAdMetricasComparativo.custo_anterior) GT 0 ? ((val(qAdMetricasComparativo.custo_atual) - val(qAdMetricasComparativo.custo_anterior)) * 100 / val(qAdMetricasComparativo.custo_anterior)) : (val(qAdMetricasComparativo.custo_atual) GT 0 ? 100 : 0)/>
</cfif>
<cfif VARIABLES.adsViewsTrend GTE 0><cfset VARIABLES.adsViewsTrendSign = "+"/></cfif>
<cfif VARIABLES.adsClicksTrend GTE 0><cfset VARIABLES.adsClicksTrendSign = "+"/></cfif>
<cfif VARIABLES.adsCostTrend GTE 0><cfset VARIABLES.adsCostTrendSign = "+"/></cfif>
<cfif VARIABLES.adsPeriodoDias GT 0>
  <cfset VARIABLES.adsDailySpend = VARIABLES.adsPeriodCost / VARIABLES.adsPeriodoDias/>
</cfif>
<cfif VARIABLES.adsDailySpend GT 0 AND VARIABLES.adsCreditBalance GT 0>
  <cfset VARIABLES.adsCreditRunwayDays = ceiling(VARIABLES.adsCreditBalance / VARIABLES.adsDailySpend)/>
</cfif>
<cfif VARIABLES.adsConversionLogReady AND qAdConversionSummary.recordcount>
  <cfset VARIABLES.adsConversionsTotal = val(qAdConversionSummary.conversoes_periodo)/>
  <cfif VARIABLES.adsPeriodClicks GT 0>
    <cfset VARIABLES.adsConversionRate = VARIABLES.adsConversionsTotal * 100 / VARIABLES.adsPeriodClicks/>
  </cfif>
</cfif>

<section class="mb-4">
  <style>
    .ads-page-hero {
      align-items: flex-end;
      display: flex;
      justify-content: space-between;
      gap: 1rem;
      margin-bottom: 1rem;
    }

    .ads-page-eyebrow {
      color: #f4b120;
      font-size: .8rem;
      font-weight: 700;
      text-transform: uppercase;
    }

    .ads-summary-card {
      min-height: 126px;
    }

    .ads-summary-icon {
      align-items: center;
      background: rgba(244, 177, 32, .14);
      border-radius: .45rem;
      color: #f4b120;
      display: inline-flex;
      height: 42px;
      justify-content: center;
      width: 42px;
    }

    .ads-summary-value {
      font-size: 1.45rem;
      font-weight: 700;
      line-height: 1.1;
    }

    .ads-summary-detail {
      border-top: 1px solid rgba(255,255,255,.08);
      display: grid;
      gap: .25rem;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      margin-top: .85rem;
      padding-top: .65rem;
    }

    .ads-summary-detail-item strong {
      display: block;
      font-size: .95rem;
    }

    .ads-campaign-table {
      font-size: .86rem;
      min-width: 920px;
    }

    .ads-campaign-table th,
    .ads-campaign-table td {
      vertical-align: middle;
      white-space: nowrap;
    }

    .ads-campaign-actions {
      min-width: 72px;
      width: 72px;
    }

    .ads-campaign-event {
      max-width: 360px;
      min-width: 260px;
      white-space: normal !important;
    }

    .ads-campaign-event-title {
      display: block;
      font-weight: 700;
      line-height: 1.2;
    }

    .ads-campaign-event-date {
      color: var(--mdb-secondary-color);
      display: block;
      font-size: .78rem;
      margin-top: .15rem;
    }

    .ads-chart-card {
      min-height: 285px;
    }

    .ads-voucher-card {
      border: 1px solid rgba(244, 177, 32, .35);
    }

    .ads-voucher-list {
      display: grid;
      gap: .75rem;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    }

    .ads-voucher-option {
      background: rgba(255,255,255,.04);
      border: 1px solid rgba(255,255,255,.1);
      border-radius: .45rem;
      padding: .85rem;
    }

    .ads-onboarding-card {
      border: 1px solid rgba(244, 177, 32, .24);
    }

    .ads-onboarding-steps {
      display: grid;
      gap: .85rem;
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }

    .ads-onboarding-step {
      background: rgba(255,255,255,.04);
      border: 1px solid rgba(255,255,255,.09);
      border-radius: .5rem;
      display: flex;
      flex-direction: column;
      min-height: 210px;
      padding: 1rem;
    }

    .ads-onboarding-number {
      align-items: center;
      background: #f4b120;
      border-radius: 999px;
      color: #111;
      display: inline-flex;
      font-weight: 800;
      height: 30px;
      justify-content: center;
      margin-bottom: .75rem;
      width: 30px;
    }

    .ads-onboarding-action {
      margin-top: auto;
      padding-top: 1rem;
    }

    .ads-period-switch {
      display: inline-flex;
      gap: .4rem;
    }

    .ads-period-switch a {
      border: 1px solid rgba(255,255,255,.22);
      border-radius: .35rem;
      color: var(--mdb-secondary-color);
      font-size: .8rem;
      font-weight: 700;
      padding: .35rem .65rem;
    }

    .ads-period-switch a.active {
      border-color: #f4b120;
      color: #f4b120;
    }

    .ads-chart {
      align-items: end;
      display: grid;
      gap: .35rem;
      grid-template-columns: repeat(<cfoutput>#qAdMetricasDia.recordcount#</cfoutput>, minmax(10px, 1fr));
      min-height: 155px;
      padding-top: 1rem;
    }

    .ads-chart-day {
      align-items: end;
      display: flex;
      gap: .15rem;
      height: 155px;
      justify-content: center;
      min-width: 0;
    }

    .ads-chart-bar {
      border-radius: .25rem .25rem 0 0;
      min-height: 3px;
      width: 42%;
    }

    .ads-chart-bar-views {
      background: rgba(244, 177, 32, .75);
    }

    .ads-chart-bar-clicks {
      background: rgba(127, 214, 230, .8);
    }

    .ads-chart-labels {
      color: var(--mdb-secondary-color);
      display: grid;
      font-size: .72rem;
      gap: .35rem;
      grid-template-columns: repeat(<cfoutput>#qAdMetricasDia.recordcount#</cfoutput>, minmax(10px, 1fr));
      margin-top: .4rem;
    }

    .ads-chart-labels span {
      overflow: hidden;
      text-align: center;
      text-overflow: clip;
      white-space: nowrap;
    }

    .ads-insight-list {
      display: grid;
      gap: .75rem;
    }

    .ads-insight-item {
      background: rgba(255,255,255,.04);
      border: 1px solid rgba(255,255,255,.08);
      border-radius: .45rem;
      padding: .75rem;
    }

    .ads-trend-grid {
      display: grid;
      gap: .5rem;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      margin-top: .75rem;
    }

    .ads-trend-item {
      border: 1px solid rgba(255,255,255,.08);
      border-radius: .4rem;
      padding: .55rem .65rem;
    }

    .ads-trend-value {
      font-size: .9rem;
      font-weight: 700;
    }

    .ads-trend-positive {
      color: #63d17c;
    }

    .ads-trend-negative {
      color: #ff7a8a;
    }

    .ads-action-panel {
      align-items: center;
      background: rgba(255,255,255,.04);
      border: 1px solid rgba(255,255,255,.08);
      border-radius: .5rem;
      display: flex;
      gap: 1rem;
      justify-content: space-between;
      padding: 1rem;
    }

    .ads-action-metrics {
      display: grid;
      gap: .75rem;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      min-width: min(100%, 420px);
    }

    .ads-action-metric {
      border-left: 1px solid rgba(255,255,255,.12);
      padding-left: .75rem;
    }

    .ads-action-metric strong {
      display: block;
      font-size: 1.05rem;
    }

    @media (max-width: 991.98px) {
      .ads-page-hero {
        align-items: stretch;
        flex-direction: column;
      }

      .ads-action-panel {
        align-items: stretch;
        flex-direction: column;
      }

      .ads-action-metrics {
        grid-template-columns: 1fr;
      }

      .ads-trend-grid {
        grid-template-columns: 1fr;
      }

      .ads-onboarding-steps {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 1399.98px) {
      .ads-summary-value {
        font-size: 1.25rem;
      }

      .ads-campaign-table {
        font-size: .82rem;
        min-width: 840px;
      }

      .ads-campaign-event {
        max-width: 300px;
        min-width: 230px;
      }

      .ads-col-rank {
        display: none;
      }
    }
  </style>

  <div class="ads-page-hero">
    <div>
      <div class="ads-page-eyebrow">Marketing</div>
      <h3 class="mb-1">Turbinados</h3>
      <p class="text-muted mb-0">Destaque seus eventos na busca e nas areas de divulgacao do RoadRunners.run.</p>
    </div>
    <div class="d-flex flex-wrap gap-2">
      <cfif VARIABLES.adsHasCampaigns>
        <a class="btn btn-warning" href="/ads/?nova=1#turbinar-evento"><i class="fas fa-rocket me-2"></i>Turbinar evento</a>
      <cfelse>
        <a class="btn btn-warning" href="#primeiro-turbinado"><i class="fas fa-rocket me-2"></i>Comecar</a>
      </cfif>
      <cfoutput><a class="btn btn-outline-warning" href="#VARIABLES.adsCreditAnchor#"><i class="fas fa-ticket me-2"></i>Ver credito</a></cfoutput>
    </div>
  </div>

  <cfif VARIABLES.adsHasCampaigns>
  <div class="row row-cols-1 row-cols-md-2 row-cols-xl-4 g-3">
    <div class="col">
      <div class="card shadow-0 ads-summary-card h-100">
        <div class="card-body p-3">
          <div class="d-flex align-items-start">
            <div class="ads-summary-icon"><i class="fas fa-chart-line"></i></div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Performance</p>
              <div class="ads-summary-value"><cfoutput>#lsNumberFormat(VARIABLES.adsClickRate, "9.99")#%</cfoutput></div>
              <div class="small text-muted">taxa de click</div>
            </div>
          </div>
          <div class="ads-summary-detail">
            <div class="ads-summary-detail-item">
              <span class="small text-muted">Views</span>
              <strong><cfoutput>#LSNumberFormat(VARIABLES.adsViewsTotal, "9,999,999")#</cfoutput></strong>
            </div>
            <div class="ads-summary-detail-item">
              <span class="small text-muted">Clicks</span>
              <strong><cfoutput>#LSNumberFormat(VARIABLES.adsClicksTotal, "9,999,999")#</cfoutput></strong>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col">
      <div class="card shadow-0 ads-summary-card h-100">
        <div class="card-body p-3">
          <div class="d-flex align-items-start">
            <div class="ads-summary-icon"><i class="fas fa-dollar-sign"></i></div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Investimento</p>
              <div class="ads-summary-value"><cfoutput>#lsCurrencyFormat(qAdValorTotal.total)#</cfoutput></div>
              <div class="small text-muted">custo consumido</div>
            </div>
          </div>
          <div class="ads-summary-detail">
            <div class="ads-summary-detail-item">
              <span class="small text-muted">CPC medio</span>
              <strong><cfoutput>#lsCurrencyFormat(qAdValorMedio.total)#</cfoutput></strong>
            </div>
            <div class="ads-summary-detail-item">
              <span class="small text-muted">Conversao</span>
              <strong>
                <cfif VARIABLES.adsConversionLogReady>
                  <cfoutput>#lsNumberFormat(VARIABLES.adsConversionRate, "9.99")#%</cfoutput>
                <cfelse>
                  em breve
                </cfif>
              </strong>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col">
      <div class="card shadow-0 ads-summary-card h-100">
        <div class="card-body p-3">
          <div class="d-flex align-items-start">
            <div class="ads-summary-icon"><i class="fas fa-ticket"></i></div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Credito Ads</p>
              <div class="ads-summary-value">
                <cfif VARIABLES.adsVoucherColumnsReady AND qAdVoucherCredit.recordcount>
                  <cfoutput>#lsCurrencyFormat(VARIABLES.adsCreditBalance)#</cfoutput>
                <cfelse>
                  -
                </cfif>
              </div>
              <div class="small text-muted">saldo disponivel</div>
            </div>
          </div>
          <div class="ads-summary-detail">
            <div class="ads-summary-detail-item">
              <span class="small text-muted">Usado</span>
              <strong><cfoutput>#lsCurrencyFormat(VARIABLES.adsCreditSpent)#</cfoutput></strong>
            </div>
            <div class="ads-summary-detail-item">
              <span class="small text-muted">Total</span>
              <strong><cfoutput>#lsCurrencyFormat(VARIABLES.adsCreditTotal)#</cfoutput></strong>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col">
      <div class="card shadow-0 ads-summary-card h-100">
        <div class="card-body p-3">
          <div class="d-flex align-items-start">
            <div class="ads-summary-icon"><i class="fas fa-rocket"></i></div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Campanhas</p>
              <div class="ads-summary-value"><cfoutput>#LSNumberFormat(VARIABLES.adsCampaignsTotal, "9,999")#</cfoutput></div>
              <div class="small text-muted">turbinados cadastrados</div>
            </div>
          </div>
          <div class="ads-summary-detail">
            <div class="ads-summary-detail-item">
              <span class="small text-muted">Ativos</span>
              <strong><cfoutput>#qEventosAds.recordcount#</cfoutput></strong>
            </div>
            <div class="ads-summary-detail-item">
              <span class="small text-muted">Pausados/final.</span>
              <strong><cfoutput>#qEventosAdsPausados.recordcount + qEventosAdsFinalizados.recordcount#</cfoutput></strong>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
  </cfif>
</section>

<cfif VARIABLES.adsVoucherColumnsReady AND (qAdAvailableVouchers.recordcount OR len(trim(VARIABLES.adsVoucherActionMessage)) OR len(trim(VARIABLES.adsVoucherActionError)))>
  <section class="mb-4" id="voucher-ads">
    <div class="card shadow-0 ads-voucher-card">
      <div class="card-body p-3">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
          <div>
            <div class="ads-page-eyebrow">Credito disponivel</div>
            <h5 class="mb-1">Ative voucher de Ads</h5>
            <p class="text-muted mb-0">Use o credito recebido para criar ou manter campanhas de Turbinados.</p>
          </div>
          <form method="post" action="/ads/#voucher-ads" class="d-flex flex-column flex-sm-row gap-2 align-self-lg-start">
            <input type="hidden" name="acao" value="ativar_voucher_ads"/>
            <input class="form-control" type="text" name="voucher_codigo" maxlength="80" placeholder="Codigo do voucher" value="<cfoutput>#htmlEditFormat(FORM.voucher_codigo)#</cfoutput>"/>
            <button class="btn btn-warning" type="submit">Ativar</button>
          </form>
        </div>

        <cfif len(trim(VARIABLES.adsVoucherActionMessage))>
          <div class="alert alert-success py-2">
            <cfoutput>#htmlEditFormat(VARIABLES.adsVoucherActionMessage)#</cfoutput>
          </div>
        </cfif>

        <cfif len(trim(VARIABLES.adsVoucherActionError))>
          <div class="alert alert-danger py-2">
            <cfoutput>#htmlEditFormat(VARIABLES.adsVoucherActionError)#</cfoutput>
          </div>
        </cfif>

        <cfif qAdAvailableVouchers.recordcount>
          <div class="ads-voucher-list">
            <cfoutput query="qAdAvailableVouchers">
              <form method="post" action="/ads/##voucher-ads" class="ads-voucher-option">
                <input type="hidden" name="acao" value="ativar_voucher_ads"/>
                <input type="hidden" name="voucher_codigo" value="#htmlEditFormat(qAdAvailableVouchers.codigo)#"/>
                <div class="d-flex justify-content-between gap-3 mb-2">
                  <div>
                    <div class="fw-bold">#htmlEditFormat(qAdAvailableVouchers.codigo)#</div>
                    <div class="small text-muted">#htmlEditFormat(qAdAvailableVouchers.nome_conta)#</div>
                  </div>
                  <div class="text-end">
                    <div class="fw-bold">#lsCurrencyFormat(qAdAvailableVouchers.credito)#</div>
                    <div class="small text-muted">credito</div>
                  </div>
                </div>
                <cfif len(trim(qAdAvailableVouchers.observacao))>
                  <div class="small text-muted mb-2">#htmlEditFormat(qAdAvailableVouchers.observacao)#</div>
                </cfif>
                <div class="d-flex justify-content-between align-items-center gap-2">
                  <div class="small text-muted">
                    <cfif isDate(qAdAvailableVouchers.data_expiracao)>
                      Valido ate #lsDateFormat(qAdAvailableVouchers.data_expiracao, "dd/mm/yyyy")#
                    <cfelse>
                      Sem validade definida
                    </cfif>
                  </div>
                  <button class="btn btn-sm btn-warning" type="submit">Ativar credito</button>
                </div>
              </form>
            </cfoutput>
          </div>
        </cfif>
      </div>
    </div>
  </section>
</cfif>

<cfif NOT VARIABLES.adsHasCampaigns>
  <section class="mb-4" id="primeiro-turbinado">
    <div class="card shadow-0 ads-onboarding-card">
      <div class="card-body p-3 p-lg-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-4">
          <div>
            <div class="ads-page-eyebrow">Primeiro turbinado</div>
            <h4 class="mb-1">Comece destacando um evento</h4>
            <p class="text-muted mb-0">Siga os passos abaixo para liberar credito, vincular uma prova e criar o primeiro anuncio.</p>
          </div>
          <cfif qAdAvailableVouchers.recordcount>
            <a class="btn btn-warning align-self-lg-start" href="#voucher-ads">Ativar voucher disponivel</a>
          <cfelseif VARIABLES.adsCreditBalance GT 0 AND qAdsEventosPermitidos.recordcount>
            <a class="btn btn-warning align-self-lg-start" href="/ads/?nova=1#turbinar-evento">Turbinar evento</a>
          </cfif>
        </div>

        <div class="ads-onboarding-steps">
          <div class="ads-onboarding-step">
            <span class="ads-onboarding-number">1</span>
            <h5 class="mb-2">Ative credito</h5>
            <p class="text-muted mb-0">Use um voucher recebido ou solicite credito para conseguir iniciar campanhas de Turbinados.</p>
            <div class="ads-onboarding-action">
              <cfif qAdAvailableVouchers.recordcount>
                <a class="btn btn-warning w-100" href="#voucher-ads">Ver voucher</a>
              <cfelseif VARIABLES.adsCreditBalance GT 0>
                <span class="btn btn-outline-success disabled w-100">Credito ativo</span>
              <cfelse>
                <a class="btn btn-outline-warning w-100" href="/assinaturas/">Ver opcoes</a>
              </cfif>
            </div>
          </div>

          <div class="ads-onboarding-step">
            <span class="ads-onboarding-number">2</span>
            <h5 class="mb-2">Vincule a prova</h5>
            <p class="text-muted mb-3">Cole a URL, tag, ID ou nome do evento no RoadRunners. Se ainda nao estiver vinculado, o pedido vai para aprovacao.</p>
            <form method="get" action="/eventos/" class="ads-onboarding-action">
              <cfif VARIABLES.adsRestrictByConta AND isDefined("VARIABLES.businessEffectiveAccountIds") AND listLen(VARIABLES.businessEffectiveAccountIds) EQ 1>
                <input type="hidden" name="id_conta_solicitacao" value="<cfoutput>#htmlEditFormat(listFirst(VARIABLES.businessEffectiveAccountIds))#</cfoutput>"/>
              </cfif>
              <div class="input-group">
                <input class="form-control" type="text" name="evento_referencia" placeholder="https://roadrunners.run/evento/..."/>
                <button class="btn btn-outline-warning" type="submit">Buscar</button>
              </div>
            </form>
          </div>

          <div class="ads-onboarding-step">
            <span class="ads-onboarding-number">3</span>
            <h5 class="mb-2">Turbine o evento</h5>
            <p class="text-muted mb-0">Depois que o evento estiver ativo na conta, defina CPC, limite diario e periodo da campanha.</p>
            <div class="ads-onboarding-action">
              <cfif qAdsEventosPermitidos.recordcount AND (VARIABLES.adsCreditBalance GT 0 OR NOT VARIABLES.adsVoucherColumnsReady)>
                <a class="btn btn-warning w-100" href="/ads/?nova=1#turbinar-evento">Criar campanha</a>
              <cfelseif qAdsEventosPermitidos.recordcount>
                <a class="btn btn-outline-warning w-100" href="#voucher-ads">Ativar credito primeiro</a>
              <cfelse>
                <span class="btn btn-outline-light disabled w-100">Aguardando evento</span>
              </cfif>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</cfif>

<cfif VARIABLES.adsHasCampaigns>
<section class="mb-4">
  <div class="row g-3">
    <div class="col-xl-8">
      <div class="card shadow-0 ads-chart-card h-100">
        <div class="card-body p-3">
          <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
            <div>
              <h5 class="mb-1">Acompanhamento do periodo</h5>
              <p class="text-muted mb-0">Views, clicks e custo dos turbinados.</p>
            </div>
            <div class="ads-period-switch">
              <a href="/ads/?ads_periodo=7" class="<cfif VARIABLES.adsPeriodoDias EQ 7>active</cfif>">7 dias</a>
              <a href="/ads/?ads_periodo=30" class="<cfif VARIABLES.adsPeriodoDias EQ 30>active</cfif>">30 dias</a>
            </div>
          </div>

          <div class="row g-2 mb-2">
            <div class="col-4">
              <div class="small text-muted">Views</div>
              <div class="fw-bold"><cfoutput>#LSNumberFormat(VARIABLES.adsPeriodViews, "9,999,999")#</cfoutput></div>
            </div>
            <div class="col-4">
              <div class="small text-muted">Clicks</div>
              <div class="fw-bold"><cfoutput>#LSNumberFormat(VARIABLES.adsPeriodClicks, "9,999,999")#</cfoutput></div>
            </div>
            <div class="col-4">
              <div class="small text-muted">Taxa</div>
              <div class="fw-bold"><cfoutput>#lsNumberFormat(VARIABLES.adsPeriodClickRate, "9.99")#%</cfoutput></div>
            </div>
          </div>
          <cfif VARIABLES.adsConversionLogReady>
            <div class="alert alert-light py-2 mb-2" role="status">
              <span class="small text-muted">Conversoes no periodo</span>
              <strong class="ms-2"><cfoutput>#LSNumberFormat(VARIABLES.adsConversionsTotal, "9,999")#</cfoutput></strong>
              <span class="small text-muted ms-2">taxa sobre clicks</span>
              <strong class="ms-1"><cfoutput>#lsNumberFormat(VARIABLES.adsConversionRate, "9.99")#%</cfoutput></strong>
            </div>
          <cfelse>
            <div class="alert alert-light py-2 mb-2" role="status">
              <span class="small text-muted">Conversao real sera exibida quando os clicks de inscricao forem instrumentados.</span>
            </div>
          </cfif>

          <div class="ads-trend-grid">
            <div class="ads-trend-item">
              <div class="small text-muted">Views vs periodo anterior</div>
              <div class="ads-trend-value <cfif VARIABLES.adsViewsTrend GTE 0>ads-trend-positive<cfelse>ads-trend-negative</cfif>">
                <cfoutput>#VARIABLES.adsViewsTrendSign##lsNumberFormat(VARIABLES.adsViewsTrend, "9.9")#%</cfoutput>
              </div>
            </div>
            <div class="ads-trend-item">
              <div class="small text-muted">Clicks vs periodo anterior</div>
              <div class="ads-trend-value <cfif VARIABLES.adsClicksTrend GTE 0>ads-trend-positive<cfelse>ads-trend-negative</cfif>">
                <cfoutput>#VARIABLES.adsClicksTrendSign##lsNumberFormat(VARIABLES.adsClicksTrend, "9.9")#%</cfoutput>
              </div>
            </div>
            <div class="ads-trend-item">
              <div class="small text-muted">Custo vs periodo anterior</div>
              <div class="ads-trend-value <cfif VARIABLES.adsCostTrend GTE 0>ads-trend-positive<cfelse>ads-trend-negative</cfif>">
                <cfoutput>#VARIABLES.adsCostTrendSign##lsNumberFormat(VARIABLES.adsCostTrend, "9.9")#%</cfoutput>
              </div>
            </div>
          </div>

          <div class="ads-chart" aria-label="Grafico de views e clicks por dia">
            <cfoutput query="qAdMetricasDia">
              <cfset VARIABLES.adsViewsHeight = round((val(qAdMetricasDia.views) / VARIABLES.adsChartMax) * 100)/>
              <cfset VARIABLES.adsClicksHeight = round((val(qAdMetricasDia.clicks) / VARIABLES.adsChartMax) * 100)/>
              <div class="ads-chart-day" title="#dateFormat(qAdMetricasDia.data_metrica, 'dd/mm')#: #LSNumberFormat(qAdMetricasDia.views, '9,999')# views, #LSNumberFormat(qAdMetricasDia.clicks, '9,999')# clicks">
                <div class="ads-chart-bar ads-chart-bar-views" style="height: #VARIABLES.adsViewsHeight#%;"></div>
                <div class="ads-chart-bar ads-chart-bar-clicks" style="height: #VARIABLES.adsClicksHeight#%;"></div>
              </div>
            </cfoutput>
          </div>
          <div class="ads-chart-labels">
            <cfoutput query="qAdMetricasDia">
              <span><cfif qAdMetricasDia.currentRow EQ 1 OR qAdMetricasDia.currentRow EQ qAdMetricasDia.recordcount OR qAdMetricasDia.currentRow MOD 5 EQ 0>#dateFormat(qAdMetricasDia.data_metrica, "dd/mm")#<cfelse>&nbsp;</cfif></span>
            </cfoutput>
          </div>
          <div class="d-flex gap-3 mt-3 small text-muted">
            <span><i class="fas fa-square me-1" style="color: rgba(244, 177, 32, .75);"></i>Views</span>
            <span><i class="fas fa-square me-1" style="color: rgba(127, 214, 230, .8);"></i>Clicks</span>
            <span>Custo no periodo: <strong class="text-light"><cfoutput>#lsCurrencyFormat(VARIABLES.adsPeriodCost)#</cfoutput></strong></span>
          </div>
        </div>
      </div>
    </div>

    <div class="col-xl-4">
      <div class="card shadow-0 h-100">
        <div class="card-body p-3">
          <h5 class="mb-1">Acoes recomendadas</h5>
          <p class="text-muted mb-3">Proximos passos para melhorar a divulgacao.</p>
          <div class="ads-insight-list">
            <cfif VARIABLES.adsCreditBalance LTE 0 AND VARIABLES.adsVoucherColumnsReady>
              <div class="ads-insight-item">
                <div class="fw-bold">Ative credito para rodar campanhas</div>
                <div class="small text-muted">Resgate um voucher ou solicite credito para criar novos turbinados.</div>
              </div>
            </cfif>
            <cfif VARIABLES.adsCreditRunwayDays GT 0 AND VARIABLES.adsCreditRunwayDays LTE 7>
              <div class="ads-insight-item">
                <div class="fw-bold">Credito acabando</div>
                <div class="small text-muted">
                  <cfoutput>No ritmo atual, o saldo dura cerca de #VARIABLES.adsCreditRunwayDays# dias.</cfoutput>
                </div>
              </div>
            </cfif>
            <cfif qAdsEventosSemCampanha.recordcount>
              <div class="ads-insight-item">
                <div class="fw-bold">Evento proximo sem campanha</div>
                <div class="small text-muted">
                  <cfoutput>#htmlEditFormat(qAdsEventosSemCampanha.nome_evento)#</cfoutput>
                  <cfif isDate(qAdsEventosSemCampanha.data_inicial)>
                    <cfoutput> - #lsDateFormat(qAdsEventosSemCampanha.data_inicial, "dd/mm/yyyy")#</cfoutput>
                  </cfif>
                </div>
                <a class="btn btn-sm btn-outline-warning mt-2" href="/ads/?nova=1#turbinar-evento">Turbinar agora</a>
              </div>
            <cfelseif qAdsEventosPermitidos.recordcount AND qEventosAds.recordcount EQ 0>
              <div class="ads-insight-item">
                <div class="fw-bold">Turbine seu primeiro evento</div>
                <div class="small text-muted">Voce ja tem eventos liberados para campanha nesta conta.</div>
                <a class="btn btn-sm btn-outline-warning mt-2" href="/ads/?nova=1#turbinar-evento">Criar campanha</a>
              </div>
            </cfif>
            <cfif qEventosAds.recordcount GT 0 AND VARIABLES.adsPeriodViews EQ 0>
              <div class="ads-insight-item">
                <div class="fw-bold">Campanha sem views no periodo</div>
                <div class="small text-muted">Confira status, periodo e aprovacao dos turbinados ativos.</div>
              </div>
            </cfif>
            <cfif qEventosAds.recordcount GT 0 AND VARIABLES.adsPeriodClickRate LT 1 AND VARIABLES.adsPeriodViews GT 0>
              <div class="ads-insight-item">
                <div class="fw-bold">Taxa de click baixa</div>
                <div class="small text-muted">Revise o evento destacado e o momento da campanha.</div>
              </div>
            </cfif>
            <cfif qEventosAds.recordcount GT 0 AND VARIABLES.adsPeriodClickRate GTE 2 AND VARIABLES.adsCreditBalance GT 0>
              <div class="ads-insight-item">
                <div class="fw-bold">Campanha com boa resposta</div>
                <div class="small text-muted">A taxa de click esta acima de 2%. Considere manter ou ampliar o limite diario dos melhores eventos.</div>
              </div>
            </cfif>
            <cfif (VARIABLES.adsCreditBalance GT 0 OR NOT VARIABLES.adsVoucherColumnsReady) AND (qEventosAds.recordcount GT 0 OR qAdsEventosPermitidos.recordcount EQ 0) AND NOT (qEventosAds.recordcount GT 0 AND VARIABLES.adsPeriodClickRate LT 1 AND VARIABLES.adsPeriodViews GT 0)>
              <div class="ads-insight-item">
                <div class="fw-bold">Acompanhe diariamente</div>
                <div class="small text-muted">Use a evolucao de views e clicks para decidir quando aumentar ou pausar investimento.</div>
              </div>
            </cfif>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>
</cfif>

<cfif qAdsTopCampaigns.recordcount>
  <section class="mb-4">
    <div class="card shadow-0">
      <div class="card-body p-3">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
          <div>
            <h5 class="mb-1">Campanhas em destaque</h5>
            <p class="text-muted mb-0">Eventos com melhor resposta entre views e clicks.</p>
          </div>
          <a class="btn btn-sm btn-outline-warning align-self-lg-start" href="#ex1">Ver todas</a>
        </div>
        <div class="table-responsive">
          <table class="table table-sm table-hover align-middle mb-0">
            <thead>
              <tr>
                <th>Evento</th>
                <th class="text-end">Views</th>
                <th class="text-end">Clicks</th>
                <th class="text-end">Taxa</th>
                <th class="text-end">Custo</th>
              </tr>
            </thead>
            <tbody>
              <cfoutput query="qAdsTopCampaigns">
                <tr>
                  <td>
                    <div class="fw-bold">#htmlEditFormat(qAdsTopCampaigns.nome_evento)#</div>
                    <div class="small text-muted">
                      <cfif isDate(qAdsTopCampaigns.data_final)>#lsDateFormat(qAdsTopCampaigns.data_final, "dd/mm/yyyy")#</cfif>
                      <cfif len(trim(qAdsTopCampaigns.cidade)) OR len(trim(qAdsTopCampaigns.estado))>
                        - #htmlEditFormat(qAdsTopCampaigns.cidade)#<cfif len(trim(qAdsTopCampaigns.estado))>/#htmlEditFormat(qAdsTopCampaigns.estado)#</cfif>
                      </cfif>
                    </div>
                  </td>
                  <td class="text-end">#LSNumberFormat(qAdsTopCampaigns.views, "9,999,999")#</td>
                  <td class="text-end">#LSNumberFormat(qAdsTopCampaigns.clicks, "9,999,999")#</td>
                  <td class="text-end">#lsNumberFormat(val(qAdsTopCampaigns.views) GT 0 ? val(qAdsTopCampaigns.clicks) * 100 / val(qAdsTopCampaigns.views) : 0, "9.99")#%</td>
                  <td class="text-end">#lsCurrencyFormat(qAdsTopCampaigns.custo_total)#</td>
                </tr>
              </cfoutput>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </section>
</cfif>

<cfif VARIABLES.adsVoucherColumnsReady AND qAdCreditVouchers.recordcount>
  <section class="mb-4" id="credito-ads">
    <div class="card shadow-0">
      <div class="card-body">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
          <div>
            <h5 class="mb-1">Credito de ads</h5>
            <p class="text-muted mb-0">Saldo consolidado dos vouchers resgatados.</p>
          </div>
          <div class="text-lg-end">
            <div class="small text-muted">Saldo disponivel</div>
            <h4 class="mb-0"><cfoutput>#lsCurrencyFormat(VARIABLES.adsCreditBalance)#</cfoutput></h4>
          </div>
        </div>

        <div class="row gx-xl-4">
          <div class="col-12">
            <h6 class="mb-3">Vouchers resgatados</h6>
            <cfif qAdCreditVouchers.recordcount>
              <div class="table-responsive">
                <table class="table table-sm table-striped mb-0">
                  <thead>
                    <tr>
                      <th>Codigo</th>
                      <th class="text-end">Credito inicial</th>
                      <th class="text-end">Saldo</th>
                      <th>Resgate</th>
                    </tr>
                  </thead>
                  <tbody>
                    <cfoutput query="qAdCreditVouchers">
                      <tr>
                        <td>
                          <strong>#htmlEditFormat(qAdCreditVouchers.codigo)#</strong>
                          <cfif len(trim(qAdCreditVouchers.nome_conta))>
                            <div class="small text-muted">#htmlEditFormat(qAdCreditVouchers.nome_conta)#</div>
                          </cfif>
                        </td>
                        <td class="text-end">#lsCurrencyFormat(qAdCreditVouchers.credito)#</td>
                        <td class="text-end">#lsCurrencyFormat(qAdCreditVouchers.credito_disponivel)#</td>
                        <td>
                          <cfif isDate(qAdCreditVouchers.data_resgate)>
                            #lsDateFormat(qAdCreditVouchers.data_resgate, "dd/mm/yyyy")#
                          <cfelse>
                            -
                          </cfif>
                        </td>
                      </tr>
                    </cfoutput>
                  </tbody>
                </table>
              </div>
            <cfelse>
              <div class="alert alert-light mb-0" role="alert">Nenhum voucher resgatado para esta visao.</div>
            </cfif>
          </div>
        </div>
      </div>
    </div>
  </section>
</cfif>

<!--- CONTEUDO --->

<cfif VARIABLES.adsHasCampaigns OR isDefined("URL.nova") OR isDefined("URL.acao") OR isDefined("URL.campanha") OR isDefined("URL.erro")>
<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0" id="turbinar-evento">

        <div class="card-body">

          <div class="bg-light bg-opacity-10 rounded p-3">

            <!--- INCLUIR CAMPANHA --->

            <h3>Turbinar Evento</h3>

            <cfif isDefined("URL.erro") AND URL.erro EQ "sem_credito">
                <div class="alert alert-warning" role="alert">
                    Esta conta nao possui saldo de credito disponivel para criar uma campanha.
                </div>
            <cfelseif isDefined("URL.erro") AND URL.erro EQ "credito_insuficiente">
                <div class="alert alert-warning" role="alert">
                    O limite da campanha ultrapassa o saldo de credito disponivel da conta.
                </div>
            </cfif>

            <cfif VARIABLES.adsCanOperate AND NOT isDefined("URL.acao") AND NOT isDefined("URL.campanha")>

                <cfif VARIABLES.adsRestrictByConta
                    AND (NOT isDefined("qAdsEventosPermitidos") OR NOT qAdsEventosPermitidos.recordcount)>
                    <div class="alert alert-info mb-0" role="alert">
                        Esta conta ainda nao possui eventos ativos liberados para criar campanhas. Solicite o vinculo do evento em <a href="/eventos/">Eventos</a>.
                    </div>
                <cfelseif VARIABLES.adsRestrictByConta
                    AND VARIABLES.adsVoucherColumnsReady
                    AND VARIABLES.adsCreditBalance LTE 0>
                    <div class="alert alert-info mb-0" role="alert">
                        Solicite ou resgate um voucher de credito antes de criar uma campanha.
                    </div>
                <cfelseif isDefined("URL.nova") AND URL.nova EQ "1">
                    <div class="d-flex justify-content-between align-items-start gap-2 mb-3">
                        <div>
                            <p class="text-muted mb-0">Selecione um evento da conta e defina o investimento para coloca-lo em destaque.</p>
                        </div>
                        <a class="btn btn-sm btn-outline-light" href="/ads/#turbinar-evento">Fechar</a>
                    </div>
                    <cfinclude template="includes/form_campanha.cfm"/>
                <cfelse>
                    <div class="ads-action-panel">
                        <div>
                            <h5 class="mb-1">Pronto para turbinar um evento</h5>
                            <p class="text-muted mb-0">Crie uma campanha para destacar uma prova vinculada a esta conta.</p>
                        </div>
                        <div class="ads-action-metrics">
                            <div class="ads-action-metric">
                                <span class="small text-muted">Eventos liberados</span>
                                <strong><cfoutput>#qAdsEventosPermitidos.recordcount#</cfoutput></strong>
                            </div>
                            <div class="ads-action-metric">
                                <span class="small text-muted">Credito</span>
                                <strong><cfoutput>#lsCurrencyFormat(VARIABLES.adsCreditBalance)#</cfoutput></strong>
                            </div>
                            <div class="ads-action-metric">
                                <span class="small text-muted">Ativas</span>
                                <strong><cfoutput>#qEventosAds.recordcount#</cfoutput></strong>
                            </div>
                        </div>
                        <a class="btn btn-warning" href="/ads/?nova=1#turbinar-evento">Nova campanha</a>
                    </div>
                </cfif>

            <cfelseif NOT VARIABLES.adsCanOperate>

                <cfif VARIABLES.adsRestrictByConta AND VARIABLES.adsEventosContaIds EQ "0">
                    <div class="alert alert-info mb-0" role="alert">Sua conta ainda nao possui eventos aprovados para campanhas. Solicite o vinculo do evento em <a href="/eventos/">Eventos</a>.</div>
                <cfelse>
                    <div class="alert alert-info mb-0" role="alert">Seu acesso permite visualizar campanhas desta conta, mas nao criar ou alterar turbinados.</div>
                </cfif>

            </cfif>

          </div>

          <cfif VARIABLES.adsHasCampaigns>

          <hr/>

          <!--- ABAS --->
          <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Ativos (<cfoutput>#qEventosAds.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Pausados (<cfoutput>#qEventosAdsPausados.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Finalizados (<cfoutput>#qEventosAdsFinalizados.recordcount#</cfoutput>)</a>
            </li>
          </ul>

          <!--- CONTEUDO ABAS --->
          <div class="tab-content" id="ex1-content">

            <div class="tab-pane fade show active tableFixHead rounded" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <table class="table table-sm table-striped table-hover ads-campaign-table">
                      <thead>
                        <tr>
                            <th class="ads-campaign-actions"></th>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end ads-col-rank">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">Conv.</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAds">
                            <tr>
                                <td class="ads-campaign-actions">
                                    <cfif VARIABLES.adsCanOperate>
                                    <cfif qEventosAds.status EQ 1><a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=status_campanha&status=2"><icon class="fa fa-thumbs-up"></icon></a></cfif>
                                    <cfif qEventosAds.status GT 1>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=status_campanha&status=3"><icon class="fa fa-pause"></icon></a>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=status_campanha&status=4"><icon class="fa fa-archive"></icon></a>
                                    </cfif>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                    <cfif qEventosAds.status EQ 2 AND isDefined("qPerfil") AND qPerfil.recordcount AND qPerfil.is_admin><a target="_blank" rel="noopener" title="Testar conversao" href="/api/ads/conversion-click.cfm?id_ad_evento=#qEventosAds.id_ad_evento#&tipo=INSCRICAO_CLICK&origem=business"><icon class="fa fa-external-link-alt"></icon></a></cfif>
                                    </cfif>
                                </td>
                                <td class="ads-campaign-event <cfif qEventosAds.data_final LT now()>text-danger</cfif>"><span class="ads-campaign-event-title">#qEventosAds.nome_evento# <cfif qEventosAds.status EQ 1><span class="badge badge-success">em aprovação</span></cfif></span><span class="ads-campaign-event-date">#lsDateFormat(qEventosAds.data_final, "dd/mm/yyyy")#</span></td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAds.qualidade#</td--->
                                <td class="text-end ads-col-rank">#qEventosAds.ad_rank#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAds.views, "9,999,999")#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAds.clicks, "9,999,999")#</td>
                                <td class="text-end">#lsNumberFormat(val(qEventosAds.views) GT 0 ? val(qEventosAds.clicks)*100/val(qEventosAds.views) : 0, "9.99")#%</td>
                                <td class="text-end">#LSNumberFormat(qEventosAds.conversoes, "9,999,999")# <span class="text-muted small">(#lsNumberFormat(val(qEventosAds.clicks) GT 0 ? val(qEventosAds.conversoes)*100/val(qEventosAds.clicks) : 0, "9.99")#%)</span></td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.custo_total)#</td>
                            </tr>
                            <cfif VARIABLES.adsCanOperate AND isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qEventosAds.id_ad_evento>
                                <tr>
                                    <td colspan="10" class="p-3">
                                        <!--- EDITAR CAMPANHA --->
                                        <cfset VARIABLES.campanha = QueryGetRow(qEventosAds, qEventosAds.currentRow)>
                                        <h5 class="mb-3">Editar Campanha</h5>
                                        <a href="./"><h5 class="mb-3 float-end">X</h5></a>
                                        <cfinclude template="includes/form_campanha.cfm"/>
                                    </td>
                                </tr>
                            </cfif>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-2" role="tabpanel" aria-labelledby="ex1-tab-2">

                  <table class="table table-sm table-striped table-hover ads-campaign-table">
                      <thead>
                        <tr>
                            <th class="ads-campaign-actions"></th>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end ads-col-rank">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">Conv.</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAdsPausados">
                            <tr>
                                <td class="ads-campaign-actions"><a href=""><icon class="fa fa-pause"></icon></a> </td>
                                <td class="ads-campaign-event <cfif qEventosAdsPausados.data_final LT now()>text-danger</cfif>"><span class="ads-campaign-event-title">#qEventosAdsPausados.nome_evento#</span><span class="ads-campaign-event-date">#lsDateFormat(qEventosAdsPausados.data_final, "dd/mm/yyyy")#</span></td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAdsPausados.qualidade#</td--->
                                <td class="text-end ads-col-rank">#qEventosAdsPausados.ad_rank#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsPausados.views, "9,999,999")#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsPausados.clicks, "9,999,999")#</td>
                                <td class="text-end">#lsNumberFormat(val(qEventosAdsPausados.views) GT 0 ? val(qEventosAdsPausados.clicks)*100/val(qEventosAdsPausados.views) : 0, "9.99")#%</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsPausados.conversoes, "9,999,999")# <span class="text-muted small">(#lsNumberFormat(val(qEventosAdsPausados.clicks) GT 0 ? val(qEventosAdsPausados.conversoes)*100/val(qEventosAdsPausados.clicks) : 0, "9.99")#%)</span></td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.custo_total)#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

                  <table class="table table-sm table-striped table-hover ads-campaign-table">
                      <thead>
                        <tr>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end ads-col-rank">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">Conv.</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAdsFinalizados">
                            <tr>
                                <td class="ads-campaign-event"><span class="ads-campaign-event-title">#qEventosAdsFinalizados.nome_evento#</span><span class="ads-campaign-event-date">#lsDateFormat(qEventosAdsFinalizados.data_final, "dd/mm/yyyy")#</span></td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAdsFinalizados.qualidade#</td--->
                                <td class="text-end ads-col-rank">#qEventosAdsFinalizados.ad_rank#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsFinalizados.views, "9,999,999")#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsFinalizados.clicks, "9,999,999")#</td>
                                <td class="text-end">#lsNumberFormat(val(qEventosAdsFinalizados.views) GT 0 ? val(qEventosAdsFinalizados.clicks)*100/val(qEventosAdsFinalizados.views) : 0, "9.99")#%</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsFinalizados.conversoes, "9,999,999")# <span class="text-muted small">(#lsNumberFormat(val(qEventosAdsFinalizados.clicks) GT 0 ? val(qEventosAdsFinalizados.conversoes)*100/val(qEventosAdsFinalizados.clicks) : 0, "9.99")#%)</span></td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.custo_total)#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

          </div>

          </cfif>

        </div>

      </div>

    </div>

  </div>

</section>
</cfif>
