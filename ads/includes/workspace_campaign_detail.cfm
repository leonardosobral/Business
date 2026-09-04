<cfif NOT qAdsV1SelectedCampaign.recordcount>
  <section class="card shadow-0 mb-4">
    <div class="card-body p-4 text-center">
      <div class="ads-v1-eyebrow mb-2">Campanha não encontrada</div>
      <h1 class="h4">Não foi possível abrir este desempenho</h1>
      <p class="text-muted">A campanha não existe ou não pertence à conta ativa.</p>
      <a class="btn btn-outline-info" href="./?view=campaigns"><i class="fas fa-arrow-left me-2" aria-hidden="true"></i>Voltar para campanhas</a>
    </div>
  </section>
<cfelse>
  <cfset VARIABLES.adsV1DetailStatus = uCase(trim(qAdsV1SelectedCampaign.status & ""))/>
  <cfset VARIABLES.adsV1DetailReviewStatus = uCase(trim(qAdsV1SelectedCampaign.review_status & ""))/>
  <cfset VARIABLES.adsV1DetailBudget = val(qAdsV1SelectedCampaign.budget_total)/>
  <cfset VARIABLES.adsV1DetailSpent = val(qAdsV1SelectedCampaign.spent_total)/>
  <cfset VARIABLES.adsV1DetailRemaining = max(0, VARIABLES.adsV1DetailBudget - VARIABLES.adsV1DetailSpent)/>
  <cfset VARIABLES.adsV1DetailProgress = VARIABLES.adsV1DetailBudget GT 0
    ? min(100, max(0, VARIABLES.adsV1DetailSpent * 100 / VARIABLES.adsV1DetailBudget))
    : 0/>
  <cfset VARIABLES.adsV1DetailDevice = uCase(trim(qAdsV1SelectedCampaign.target_device_class & ""))/>
  <cfset VARIABLES.adsV1DetailDeviceLabel = VARIABLES.adsV1DetailDevice EQ "MOBILE"
    ? "Celulares"
    : (VARIABLES.adsV1DetailDevice EQ "DESKTOP" ? "Computadores" : "Todos os dispositivos")/>

  <section class="card shadow-0 mb-4 ads-performance-card">
    <div class="card-body p-3 p-lg-4">
      <a class="btn btn-sm btn-outline-light mb-4" href="./?view=campaigns"><i class="fas fa-arrow-left me-2" aria-hidden="true"></i>Voltar para campanhas</a>
      <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-start gap-3">
        <div>
          <div class="ads-v1-eyebrow mb-2">Campanha de evento</div>
          <h1 class="h3 mb-2"><cfoutput>#htmlEditFormat(qAdsV1SelectedCampaign.name)#</cfoutput></h1>
          <p class="text-muted mb-0">
            <strong class="text-body"><cfoutput>#htmlEditFormat(qAdsV1SelectedCampaign.event_name)#</cfoutput></strong>
            <cfif len(trim(qAdsV1SelectedCampaign.event_city & "")) OR len(trim(qAdsV1SelectedCampaign.event_state & ""))>
              · <cfoutput>#htmlEditFormat(trim(qAdsV1SelectedCampaign.event_city & ""))#<cfif len(trim(qAdsV1SelectedCampaign.event_state & ""))>/#htmlEditFormat(qAdsV1SelectedCampaign.event_state)#</cfif></cfoutput>
            </cfif>
          </p>
        </div>
        <div class="d-flex flex-wrap gap-2">
          <span class="badge <cfif VARIABLES.adsV1DetailStatus EQ 'ACTIVE'>badge-success<cfelseif VARIABLES.adsV1DetailStatus EQ 'PAUSED'>badge-warning<cfelseif VARIABLES.adsV1DetailStatus EQ 'ENDED'>badge-danger<cfelse>badge-secondary</cfif>"><cfoutput>#htmlEditFormat(adsV1CampaignStatusLabel(VARIABLES.adsV1DetailStatus))#</cfoutput></span>
          <cfif VARIABLES.adsV1DetailReviewStatus EQ "APPROVED"><span class="badge badge-success">Aprovada pela RunnerHub</span>
          <cfelseif VARIABLES.adsV1DetailReviewStatus EQ "PENDING_REVIEW"><span class="badge badge-info">Em análise</span>
          <cfelseif VARIABLES.adsV1DetailReviewStatus EQ "WAITING_PREREQUISITES"><span class="badge badge-warning">Aguardando pré-requisitos</span>
          <cfelseif VARIABLES.adsV1DetailReviewStatus EQ "CHANGES_REQUESTED"><span class="badge badge-danger">Ajustes solicitados</span></cfif>
        </div>
      </div>
    </div>
  </section>

  <cfset VARIABLES.adsV1PerformanceContext = "campaign"/>
  <cfinclude template="workspace_performance.cfm"/>

  <div class="row g-4 mb-4">
    <div class="col-xl-6">
      <section class="card shadow-0 h-100">
        <div class="card-body p-3 p-lg-4">
          <div class="ads-v1-eyebrow mb-2">Investimento</div>
          <h2 class="h5 mb-4">Orçamento e período</h2>
          <div class="row g-4">
            <div class="col-sm-6"><div class="text-muted small">Orçamento total</div><strong class="h5"><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1DetailBudget)#</cfoutput></strong></div>
            <div class="col-sm-6"><div class="text-muted small">Orçamento restante</div><strong class="h5"><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1DetailRemaining)#</cfoutput></strong></div>
            <div class="col-sm-6"><div class="text-muted small">Investido até agora</div><strong><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1DetailSpent)#</cfoutput></strong></div>
            <div class="col-sm-6"><div class="text-muted small">Lance máximo por clique</div><strong><cfoutput>#lsCurrencyFormat(qAdsV1SelectedCampaign.cpc_bid)#</cfoutput></strong></div>
            <cfif len(trim(qAdsV1SelectedCampaign.budget_daily & ""))><div class="col-sm-6"><div class="text-muted small">Limite diário</div><strong><cfoutput>#lsCurrencyFormat(qAdsV1SelectedCampaign.budget_daily)#</cfoutput></strong></div></cfif>
          </div>
          <div class="ads-budget-progress mt-4 w-100"><span style="width:<cfoutput>#numberFormat(VARIABLES.adsV1DetailProgress, '0')#</cfoutput>%"></span></div>
          <div class="d-flex flex-column flex-sm-row justify-content-between gap-2 small text-muted mt-3">
            <span>Início: <strong class="text-body"><cfif isDate(qAdsV1SelectedCampaign.starts_at)><cfoutput>#lsDateFormat(qAdsV1SelectedCampaign.starts_at, "dd/mm/yyyy")#</cfoutput><cfelse>Não informado</cfif></strong></span>
            <span>Fim: <strong class="text-body"><cfif isDate(qAdsV1SelectedCampaign.ends_at)><cfoutput>#lsDateFormat(qAdsV1SelectedCampaign.ends_at, "dd/mm/yyyy")#</cfoutput><cfelse>Não informado</cfif></strong></span>
          </div>
        </div>
      </section>
    </div>

    <div class="col-xl-6">
      <section class="card shadow-0 h-100">
        <div class="card-body p-3 p-lg-4">
          <div class="ads-v1-eyebrow mb-2">Configuração</div>
          <h2 class="h5 mb-4">Segmentação e exibição</h2>
          <div class="row g-4 mb-4">
            <div class="col-sm-4"><div class="text-muted small">País</div><strong><cfoutput>#htmlEditFormat(qAdsV1SelectedCampaign.target_country_code)#</cfoutput></strong></div>
            <div class="col-sm-4"><div class="text-muted small">Estado ou região</div><strong><cfoutput>#len(trim(qAdsV1SelectedCampaign.target_region_code & "")) ? htmlEditFormat(qAdsV1SelectedCampaign.target_region_code) : "Todo o Brasil"#</cfoutput></strong></div>
            <div class="col-sm-4"><div class="text-muted small">Dispositivos</div><strong><cfoutput>#htmlEditFormat(VARIABLES.adsV1DetailDeviceLabel)#</cfoutput></strong></div>
          </div>
          <div class="text-muted small mb-2">Locais de exibição</div>
          <div class="p-3 rounded bg-body-tertiary"><strong><cfoutput>#htmlEditFormat(adsV1PlacementSummary(qAdsV1SelectedCampaign.placement_keys))#</cfoutput></strong></div>
          <cfif len(trim(qAdsV1SelectedCampaign.destination_url & ""))>
            <a class="btn btn-sm btn-outline-info mt-4" href="<cfoutput>#htmlEditFormat(qAdsV1SelectedCampaign.destination_url)#</cfoutput>" target="_blank" rel="noopener">Ver página anunciada <i class="fas fa-external-link-alt ms-1" aria-hidden="true"></i></a>
          </cfif>
        </div>
      </section>
    </div>
  </div>

  <section class="card shadow-0 mb-4">
    <div class="card-body p-3 p-lg-4">
      <div class="ads-v1-eyebrow mb-2">Linha do tempo</div>
      <h2 class="h5 mb-3">Histórico da campanha</h2>
      <cfif qAdsV1CampaignStatusHistory.recordcount>
        <div>
          <cfloop query="qAdsV1CampaignStatusHistory">
            <div class="ads-activity-row">
              <div>
                <strong><cfoutput>#htmlEditFormat(adsV1CampaignStatusLabel(qAdsV1CampaignStatusHistory.to_status))#</cfoutput></strong>
                <div class="small text-muted"><cfoutput>#htmlEditFormat(qAdsV1CampaignStatusHistory.reason)#</cfoutput></div>
                <cfif len(trim(qAdsV1CampaignStatusHistory.changed_by_name & ""))><div class="small text-muted">Por <cfoutput>#htmlEditFormat(qAdsV1CampaignStatusHistory.changed_by_name)#</cfoutput></div></cfif>
              </div>
              <div class="small text-muted text-end"><cfif isDate(qAdsV1CampaignStatusHistory.changed_at)><cfoutput>#lsDateFormat(qAdsV1CampaignStatusHistory.changed_at, "dd/mm/yyyy")#<br/>#lsTimeFormat(qAdsV1CampaignStatusHistory.changed_at, "HH:nn")#</cfoutput></cfif></div>
            </div>
          </cfloop>
        </div>
      <cfelse>
        <div class="text-muted py-4 text-center">Ainda não há mudanças registradas para esta campanha.</div>
      </cfif>
    </div>
  </section>
</cfif>
