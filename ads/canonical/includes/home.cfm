<cfset VARIABLES.adsV1FormCampaignId = ""/>
<cfset VARIABLES.adsV1FormEventId = 0/>
<cfset VARIABLES.adsV1FormName = ""/>
<cfset VARIABLES.adsV1FormCpcRaw = "1.00"/>
<cfset VARIABLES.adsV1FormBudgetTotalRaw = "100.00"/>
<cfset VARIABLES.adsV1FormBudgetDailyRaw = ""/>
<cfset VARIABLES.adsV1FormStartsDisplay = dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn")/>
<cfset VARIABLES.adsV1FormEndsDisplay = dateTimeFormat(dateAdd("d", 30, now()), "yyyy-mm-dd'T'HH:nn")/>
<cfset VARIABLES.adsV1FormDevice = "ALL"/>
<cfset VARIABLES.adsV1FormCountry = "BR"/>
<cfset VARIABLES.adsV1FormRegion = ""/>
<cfset VARIABLES.adsV1FormPlacementKeys = ["rr-home-upcoming-native"] />
<cfset VARIABLES.adsV1CampaignEditable = true/>

<cfif FORM.ads_v1_action EQ "save_campaign" AND len(VARIABLES.adsV1Error)>
    <cfset VARIABLES.adsV1FormCampaignId = structKeyExists(FORM, "campaign_id") ? trim(FORM.campaign_id & "") : ""/>
    <cfset VARIABLES.adsV1FormEventId = structKeyExists(FORM, "core_event_id") AND isNumeric(FORM.core_event_id) ? val(FORM.core_event_id) : 0/>
    <cfset VARIABLES.adsV1FormName = structKeyExists(FORM, "name") ? trim(FORM.name & "") : ""/>
    <cfset VARIABLES.adsV1FormCpcRaw = structKeyExists(FORM, "cpc_bid") ? trim(FORM.cpc_bid & "") : ""/>
    <cfset VARIABLES.adsV1FormBudgetTotalRaw = structKeyExists(FORM, "budget_total") ? trim(FORM.budget_total & "") : ""/>
    <cfset VARIABLES.adsV1FormBudgetDailyRaw = structKeyExists(FORM, "budget_daily") ? trim(FORM.budget_daily & "") : ""/>
    <cfset VARIABLES.adsV1FormStartsDisplay = structKeyExists(FORM, "starts_at") ? trim(FORM.starts_at & "") : ""/>
    <cfset VARIABLES.adsV1FormEndsDisplay = structKeyExists(FORM, "ends_at") ? trim(FORM.ends_at & "") : ""/>
    <cfset VARIABLES.adsV1FormDevice = structKeyExists(FORM, "target_device_class") ? uCase(trim(FORM.target_device_class & "")) : "ALL"/>
    <cfset VARIABLES.adsV1FormCountry = structKeyExists(FORM, "target_country_code") ? uCase(trim(FORM.target_country_code & "")) : "BR"/>
    <cfset VARIABLES.adsV1FormRegion = structKeyExists(FORM, "target_region_code") ? uCase(trim(FORM.target_region_code & "")) : ""/>
    <cfset VARIABLES.adsV1FormPlacementKeys = structKeyExists(FORM, "placement_keys") ? adsV1FormList(FORM.placement_keys) : []/>
<cfelseif qAdsV1SelectedCampaign.recordcount>
    <cfset VARIABLES.adsV1FormCampaignId = qAdsV1SelectedCampaign.campaign_id & ""/>
    <cfset VARIABLES.adsV1FormEventId = val(qAdsV1SelectedCampaign.core_event_id)/>
    <cfset VARIABLES.adsV1FormName = qAdsV1SelectedCampaign.name & ""/>
    <cfset VARIABLES.adsV1FormCpcRaw = numberFormat(qAdsV1SelectedCampaign.cpc_bid, "0.00")/>
    <cfset VARIABLES.adsV1FormBudgetTotalRaw = numberFormat(qAdsV1SelectedCampaign.budget_total, "0.00")/>
    <cfset VARIABLES.adsV1FormBudgetDailyRaw = len(trim(qAdsV1SelectedCampaign.budget_daily & "")) ? numberFormat(qAdsV1SelectedCampaign.budget_daily, "0.00") : ""/>
    <cfset VARIABLES.adsV1FormStartsDisplay = isDate(qAdsV1SelectedCampaign.starts_at) ? dateTimeFormat(qAdsV1SelectedCampaign.starts_at, "yyyy-mm-dd'T'HH:nn") : ""/>
    <cfset VARIABLES.adsV1FormEndsDisplay = isDate(qAdsV1SelectedCampaign.ends_at) ? dateTimeFormat(qAdsV1SelectedCampaign.ends_at, "yyyy-mm-dd'T'HH:nn") : ""/>
    <cfset VARIABLES.adsV1FormDevice = qAdsV1SelectedCampaign.target_device_class & ""/>
    <cfset VARIABLES.adsV1FormCountry = trim(qAdsV1SelectedCampaign.target_country_code & "")/>
    <cfset VARIABLES.adsV1FormRegion = trim(qAdsV1SelectedCampaign.target_region_code & "")/>
    <cfset VARIABLES.adsV1FormPlacementKeys = len(trim(qAdsV1SelectedCampaign.placement_keys & "")) ? listToArray(qAdsV1SelectedCampaign.placement_keys & "") : []/>
    <cfset VARIABLES.adsV1CampaignEditable = listFind("DRAFT,PAUSED", qAdsV1SelectedCampaign.status) GT 0/>
</cfif>

<style>
  .ads-v1-eyebrow { color: #62c7d8; font-size: .78rem; font-weight: 800; letter-spacing: .05em; text-transform: uppercase; }
  .ads-v1-summary { min-height: 122px; }
  .ads-v1-summary-value { font-size: 1.45rem; font-weight: 750; line-height: 1.15; }
  .ads-v1-table { font-size: .84rem; min-width: 980px; }
  .ads-v1-table th, .ads-v1-table td { vertical-align: middle; }
  .ads-v1-code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .72rem; }
  .ads-v1-actions { display: flex; flex-wrap: wrap; gap: .35rem; min-width: 255px; }
  .ads-v1-actions form { display: inline-flex; }
  .ads-v1-end-form { align-items: center; display: flex; gap: .35rem; margin-top: .45rem; }
  .ads-v1-end-form input { min-width: 210px; }
  .ads-v1-pilot-badge { border: 1px solid rgba(98,199,216,.5); color: #8bd9e6; }
  @media (max-width: 767.98px) {
    .ads-v1-actions { min-width: 220px; }
    .ads-v1-end-form { align-items: stretch; flex-direction: column; }
    .ads-v1-end-form input { min-width: 0; width: 100%; }
  }
</style>

<section class="mb-4">
  <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-end gap-3">
    <div>
      <div class="ads-v1-eyebrow">Marketing · Canonico</div>
      <div class="d-flex flex-wrap align-items-center gap-2">
        <h1 class="h3 mb-0">Ads V1</h1>
        <span class="badge ads-v1-pilot-badge">Piloto administrativo</span>
      </div>
      <p class="text-muted mb-0 mt-2">Campanhas e saldo canonicos, separados do Turbinado legado.</p>
    </div>
    <div class="d-flex flex-wrap gap-2">
      <a class="btn btn-outline-light" href="/ads/"><i class="fa-solid fa-arrow-left me-2"></i>Turbinados legados</a>
      <cfif VARIABLES.adsV1HasAccount AND VARIABLES.adsV1ApiReady>
        <a class="btn btn-info" href="./#campaign-form"><i class="fa-solid fa-plus me-2"></i>Nova campanha</a>
      </cfif>
    </div>
  </div>
</section>

<cfif len(VARIABLES.adsV1Notice)>
  <div class="alert alert-success"><cfoutput>#htmlEditFormat(VARIABLES.adsV1Notice)#</cfoutput></div>
</cfif>
<cfif len(VARIABLES.adsV1Error)>
  <div class="alert alert-danger"><cfoutput>#htmlEditFormat(VARIABLES.adsV1Error)#</cfoutput></div>
</cfif>

<cfif NOT VARIABLES.adsV1ApiReady>
  <section class="card shadow-0 mb-4">
    <div class="card-body p-4">
      <div class="ads-v1-eyebrow mb-2">Readiness</div>
      <h2 class="h5">API Ads V1 indisponivel</h2>
      <p class="text-muted mb-3">As funcoes SQL ou as permissoes do datasource <code>runnerhub</code> nao estao completas. Nenhuma mutacao foi liberada.</p>
      <a class="btn btn-outline-warning" href="/ads/">Continuar no Turbinado legado</a>
    </div>
  </section>
<cfelseif NOT VARIABLES.adsV1HasAccount>
  <section class="card shadow-0 mb-4">
    <div class="card-body p-4">
      <div class="ads-v1-eyebrow mb-2">Conta obrigatoria</div>
      <h2 class="h5">Selecione uma conta no topo</h2>
      <p class="text-muted mb-0">O piloto nunca opera no contexto “todas as contas”. Escolha uma conta no seletor superior e volte a esta pagina.</p>
    </div>
  </section>
<cfelseif NOT VARIABLES.adsV1DataReady>
  <section class="card shadow-0 mb-4">
    <div class="card-body p-4">
      <div class="ads-v1-eyebrow mb-2">Leitura indisponivel</div>
      <h2 class="h5">Nao foi possivel carregar a conta</h2>
      <p class="text-muted mb-0">As operacoes foram bloqueadas nesta requisicao. Recarregue a pagina e consulte o log <code>business_ads_v1</code> se o erro continuar.</p>
    </div>
  </section>
<cfelse>
  <section class="mb-4">
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
      <div>
        <div class="ads-v1-eyebrow">Conta efetiva</div>
        <h2 class="h5 mb-0"><cfoutput>#htmlEditFormat(qAdsV1Account.nome_conta)#</cfoutput></h2>
      </div>
      <span class="badge badge-success">API pronta</span>
    </div>

    <div class="row row-cols-1 row-cols-sm-2 row-cols-xl-4 g-3">
      <div class="col"><div class="card ads-v1-summary h-100"><div class="card-body"><div class="text-muted small mb-2">Saldo Ads V1</div><div class="ads-v1-summary-value"><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1Summary.balance)#</cfoutput></div><div class="small text-muted mt-2">BRL disponivel</div></div></div></div>
      <div class="col"><div class="card ads-v1-summary h-100"><div class="card-body"><div class="text-muted small mb-2">Campanhas</div><div class="ads-v1-summary-value"><cfoutput>#VARIABLES.adsV1Summary.campaigns#</cfoutput></div><div class="small text-muted mt-2"><cfoutput>#VARIABLES.adsV1Summary.active# ativas · #VARIABLES.adsV1Summary.paused# pausadas</cfoutput></div></div></div></div>
      <div class="col"><div class="card ads-v1-summary h-100"><div class="card-body"><div class="text-muted small mb-2">Gasto canonico</div><div class="ads-v1-summary-value"><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1Summary.spent)#</cfoutput></div><div class="small text-muted mt-2">ledger e budget state</div></div></div></div>
      <div class="col"><div class="card ads-v1-summary h-100"><div class="card-body"><div class="text-muted small mb-2">Performance</div><div class="ads-v1-summary-value"><cfoutput>#lsNumberFormat(VARIABLES.adsV1Summary.clicks, "9,999,999")#</cfoutput></div><div class="small text-muted mt-2"><cfoutput>#lsNumberFormat(VARIABLES.adsV1Summary.views, "9,999,999")# views</cfoutput></div></div></div></div>
    </div>
  </section>

  <section class="card shadow-0 mb-4">
    <div class="card-body p-3 p-lg-4">
      <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
        <div>
          <div class="ads-v1-eyebrow">Operacao</div>
          <h2 class="h5 mb-1">Campanhas canonicas</h2>
          <p class="text-muted mb-0">Campanhas ativas participam somente dos spots habilitados na configuracao do RoadRunners.</p>
        </div>
        <a class="btn btn-outline-info align-self-lg-start" href="./#campaign-form">Criar rascunho</a>
      </div>

      <cfif qAdsV1Campaigns.recordcount>
        <div class="table-responsive">
          <table class="table table-hover align-middle ads-v1-table mb-0">
            <thead><tr><th>Campanha</th><th>Status</th><th>CPC</th><th>Orcamento</th><th>Metricas</th><th>Periodo</th><th>Acoes</th></tr></thead>
            <tbody>
              <cfoutput query="qAdsV1Campaigns">
                <tr>
                  <td>
                    <strong>#htmlEditFormat(name)#</strong>
                    <div class="small text-muted">#htmlEditFormat(nome_evento)#</div>
                    <div class="small text-muted">Spots: #htmlEditFormat(replace(placement_keys & "", ",", ", ", "all"))#</div>
                    <div class="ads-v1-code text-muted">#htmlEditFormat(campaign_id)#</div>
                  </td>
                  <td><span class="badge <cfif status EQ 'ACTIVE'>badge-success<cfelseif status EQ 'PAUSED'>badge-warning<cfelseif status EQ 'ENDED'>badge-danger<cfelse>badge-secondary</cfif>">#htmlEditFormat(status)#</span></td>
                  <td>#lsCurrencyFormat(cpc_bid)#</td>
                  <td>
                    <div>#lsCurrencyFormat(spent_total)# / #lsCurrencyFormat(budget_total)#</div>
                    <div class="small text-muted">diario: <cfif len(trim(budget_daily & ''))>#lsCurrencyFormat(budget_daily)#<cfelse>sem limite</cfif></div>
                  </td>
                  <td><div>#lsNumberFormat(viewable_impression_count, "9,999,999")# views</div><div class="small text-muted">#lsNumberFormat(valid_click_count, "9,999,999")# clicks · #lsCurrencyFormat(cost)#</div></td>
                  <td><cfif isDate(starts_at)>#lsDateFormat(starts_at, "dd/mm/yyyy")#<cfelse>-</cfif><br/><span class="small text-muted">ate <cfif isDate(ends_at)>#lsDateFormat(ends_at, "dd/mm/yyyy")#<cfelse>-</cfif></span></td>
                  <td>
                    <div class="ads-v1-actions">
                      <cfif listFind("DRAFT,PAUSED", status)><a class="btn btn-sm btn-outline-light" href="./?campaign=#urlEncodedFormat(campaign_id)###campaign-form">Editar</a></cfif>
                      <cfif listFind("DRAFT,PAUSED", status)>
                        <form method="post" action="./">
                          <input type="hidden" name="ads_v1_action" value="activate_campaign"/>
                          <input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/>
                          <input type="hidden" name="campaign_id" value="#htmlEditFormat(campaign_id)#"/>
                          <input type="hidden" name="reason" value="Ativacao manual pelo Business"/>
                          <button class="btn btn-sm btn-success" type="submit">Ativar<cfif status EQ 'PAUSED'> novamente</cfif></button>
                        </form>
                      </cfif>
                      <cfif status EQ "ACTIVE">
                        <form method="post" action="./">
                          <input type="hidden" name="ads_v1_action" value="change_campaign_status"/>
                          <input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/>
                          <input type="hidden" name="campaign_id" value="#htmlEditFormat(campaign_id)#"/>
                          <input type="hidden" name="target_status" value="PAUSED"/>
                          <input type="hidden" name="reason" value="Pausa manual pelo Business"/>
                          <button class="btn btn-sm btn-warning" type="submit">Pausar</button>
                        </form>
                      </cfif>
                    </div>
                    <cfif listFind("DRAFT,ACTIVE,PAUSED", status)>
                      <form method="post" action="./" class="ads-v1-end-form">
                        <input type="hidden" name="ads_v1_action" value="change_campaign_status"/>
                        <input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/>
                        <input type="hidden" name="campaign_id" value="#htmlEditFormat(campaign_id)#"/>
                        <input type="hidden" name="target_status" value="ENDED"/>
                        <input class="form-control form-control-sm" type="text" name="reason" minlength="5" maxlength="500" required placeholder="Motivo do encerramento"/>
                        <button class="btn btn-sm btn-outline-danger" type="submit">Encerrar</button>
                      </form>
                    </cfif>
                  </td>
                </tr>
              </cfoutput>
            </tbody>
          </table>
        </div>
      <cfelse>
        <div class="alert alert-info mb-0">Esta conta ainda nao possui campanhas canonicas.</div>
      </cfif>
    </div>
  </section>

  <section class="card shadow-0 mb-4" id="campaign-form">
    <div class="card-body p-3 p-lg-4">
      <div class="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-3">
        <div>
          <div class="ads-v1-eyebrow">Configuracao CPC</div>
          <h2 class="h5 mb-1"><cfif len(VARIABLES.adsV1FormCampaignId)>Editar campanha<cfelse>Nova campanha</cfif></h2>
          <p class="text-muted mb-0">Escolha em quais spots nativos do RoadRunners a campanha pode aparecer.</p>
        </div>
        <cfif len(VARIABLES.adsV1FormCampaignId)><a class="btn btn-sm btn-outline-light" href="./#campaign-form">Cancelar edicao</a></cfif>
      </div>

      <cfif NOT VARIABLES.adsV1CampaignEditable>
        <div class="alert alert-warning mb-0">Somente campanhas DRAFT ou PAUSED podem ser editadas.</div>
      <cfelseif NOT qAdsV1Events.recordcount>
        <div class="alert alert-warning mb-0">A conta selecionada nao possui eventos ativos vinculados.</div>
      <cfelseif NOT qAdsV1Placements.recordcount>
        <div class="alert alert-warning mb-0">Nenhum spot nativo Ads V1 esta disponivel para configuracao.</div>
      <cfelse>
        <form method="post" action="./#campaign-form" class="row g-3">
          <input type="hidden" name="ads_v1_action" value="save_campaign"/>
          <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
          <input type="hidden" name="campaign_id" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormCampaignId)#</cfoutput>"/>
          <div class="col-lg-6">
            <label class="form-label" for="ads-v1-event">Evento</label>
            <select class="form-select" id="ads-v1-event" name="core_event_id" required>
              <option value="">Selecione</option>
              <cfoutput query="qAdsV1Events"><option value="#id_evento#" <cfif val(id_evento) EQ VARIABLES.adsV1FormEventId>selected</cfif>>#htmlEditFormat(nome_evento)# · #htmlEditFormat(cidade)#/#htmlEditFormat(estado)#</option></cfoutput>
            </select>
          </div>
          <div class="col-lg-6">
            <label class="form-label" for="ads-v1-name">Nome da campanha</label>
            <input class="form-control" id="ads-v1-name" name="name" minlength="3" maxlength="160" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormName)#</cfoutput>"/>
          </div>
          <div class="col-sm-4">
            <label class="form-label" for="ads-v1-cpc">CPC</label>
            <input class="form-control" id="ads-v1-cpc" type="number" name="cpc_bid" min="0.01" step="0.01" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormCpcRaw)#</cfoutput>"/>
          </div>
          <div class="col-sm-4">
            <label class="form-label" for="ads-v1-total">Orcamento total</label>
            <input class="form-control" id="ads-v1-total" type="number" name="budget_total" min="0.01" step="0.01" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormBudgetTotalRaw)#</cfoutput>"/>
          </div>
          <div class="col-sm-4">
            <label class="form-label" for="ads-v1-daily">Orcamento diario</label>
            <input class="form-control" id="ads-v1-daily" type="number" name="budget_daily" min="0.01" step="0.01" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormBudgetDailyRaw)#</cfoutput>" placeholder="Opcional"/>
          </div>
          <div class="col-md-6">
            <label class="form-label" for="ads-v1-start">Inicio</label>
            <input class="form-control" id="ads-v1-start" type="datetime-local" name="starts_at" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormStartsDisplay)#</cfoutput>"/>
          </div>
          <div class="col-md-6">
            <label class="form-label" for="ads-v1-end">Fim</label>
            <input class="form-control" id="ads-v1-end" type="datetime-local" name="ends_at" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormEndsDisplay)#</cfoutput>"/>
          </div>
          <div class="col-md-4">
            <label class="form-label" for="ads-v1-device">Dispositivo</label>
            <select class="form-select" id="ads-v1-device" name="target_device_class"><option value="ALL" <cfif VARIABLES.adsV1FormDevice EQ "ALL">selected</cfif>>Todos</option><option value="DESKTOP" <cfif VARIABLES.adsV1FormDevice EQ "DESKTOP">selected</cfif>>Desktop</option><option value="MOBILE" <cfif VARIABLES.adsV1FormDevice EQ "MOBILE">selected</cfif>>Mobile</option></select>
          </div>
          <div class="col-md-4">
            <label class="form-label" for="ads-v1-country">Pais</label>
            <input class="form-control" id="ads-v1-country" name="target_country_code" maxlength="2" required value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormCountry)#</cfoutput>"/>
          </div>
          <div class="col-md-4">
            <label class="form-label" for="ads-v1-region">Regiao</label>
            <input class="form-control" id="ads-v1-region" name="target_region_code" maxlength="40" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1FormRegion)#</cfoutput>" placeholder="Opcional, ex.: SC"/>
          </div>
          <div class="col-12">
            <fieldset>
              <legend class="form-label mb-2">Spots de exibicao</legend>
              <p class="small text-muted mb-2">Selecione ao menos um. A mesma campanha pode atender varios pontos sem duplicar saldo ou orcamento.</p>
              <div class="row g-2">
                <cfoutput query="qAdsV1Placements">
                  <div class="col-md-6 col-xl-4">
                    <div class="form-check border rounded p-3 h-100">
                      <input class="form-check-input ms-0 me-2" id="ads-v1-placement-#currentRow#" type="checkbox" name="placement_keys" value="#htmlEditFormat(placement_key)#" <cfif arrayFindNoCase(VARIABLES.adsV1FormPlacementKeys, placement_key)>checked</cfif>/>
                      <label class="form-check-label" for="ads-v1-placement-#currentRow#">
                        <strong>#htmlEditFormat(surface)#</strong>
                        <span class="d-block small text-muted">#htmlEditFormat(placement_key)#</span>
                      </label>
                    </div>
                  </div>
                </cfoutput>
              </div>
            </fieldset>
          </div>
          <div class="col-12 d-flex justify-content-end"><button class="btn btn-info" type="submit">Salvar campanha</button></div>
        </form>
      </cfif>
    </div>
  </section>

  <div class="row g-4 mb-4">
    <div class="col-xl-4">
      <section class="card shadow-0 h-100">
        <div class="card-body p-3 p-lg-4">
          <div class="ads-v1-eyebrow">Financeiro</div>
          <h2 class="h5">Credito manual</h2>
          <p class="text-muted">O credito entra no ledger canonico em BRL.</p>
          <form method="post" action="./">
            <input type="hidden" name="ads_v1_action" value="credit_account"/>
            <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
            <input type="hidden" name="idempotency_key" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1CreditIdempotencyKey)#</cfoutput>"/>
            <div class="mb-3"><label class="form-label" for="ads-v1-credit">Valor</label><input class="form-control" id="ads-v1-credit" type="number" name="amount" min="0.01" step="0.01" required value="<cfif FORM.ads_v1_action EQ 'credit_account' AND structKeyExists(FORM, 'amount')><cfoutput>#htmlEditFormat(FORM.amount)#</cfoutput></cfif>"/></div>
            <div class="mb-3"><label class="form-label" for="ads-v1-credit-reason">Justificativa</label><textarea class="form-control" id="ads-v1-credit-reason" name="reason" minlength="5" maxlength="500" required><cfif FORM.ads_v1_action EQ 'credit_account' AND structKeyExists(FORM, 'reason')><cfoutput>#htmlEditFormat(FORM.reason)#</cfoutput></cfif></textarea></div>
            <button class="btn btn-info w-100" type="submit">Registrar credito</button>
          </form>
        </div>
      </section>
    </div>
    <div class="col-xl-8">
      <section class="card shadow-0 h-100">
        <div class="card-body p-3 p-lg-4">
          <div class="ads-v1-eyebrow">Ledger</div>
          <h2 class="h5">Lancamentos recentes</h2>
          <div class="table-responsive">
            <table class="table table-sm align-middle mb-0"><thead><tr><th>Data</th><th>Tipo</th><th>Campanha</th><th class="text-end">Valor</th><th class="text-end">Saldo</th></tr></thead><tbody>
              <cfif qAdsV1Ledger.recordcount>
                <cfoutput query="qAdsV1Ledger"><tr><td><cfif isDate(occurred_at)>#lsDateFormat(occurred_at, "dd/mm/yyyy")# #lsTimeFormat(occurred_at, "HH:nn")#<cfelse>-</cfif></td><td><span class="badge <cfif entry_type EQ 'CREDIT'>badge-success<cfelseif entry_type EQ 'DEBIT'>badge-danger<cfelse>badge-info</cfif>">#htmlEditFormat(entry_type)# / #htmlEditFormat(source_type)#</span></td><td>#htmlEditFormat(campaign_name)#</td><td class="text-end">#lsCurrencyFormat(amount)#</td><td class="text-end">#lsCurrencyFormat(balance_after)#</td></tr></cfoutput>
              <cfelse><tr><td colspan="5" class="text-muted text-center py-4">Nenhum lancamento canonico.</td></tr></cfif>
            </tbody></table>
          </div>
        </div>
      </section>
    </div>
  </div>

  <cfif qAdsV1ReversibleDebits.recordcount>
    <section class="card shadow-0 mb-4">
      <div class="card-body p-3 p-lg-4">
        <div class="ads-v1-eyebrow">Correcao financeira</div>
        <h2 class="h5">Debitos CPC elegiveis para estorno</h2>
        <p class="text-muted">O estorno cria um lancamento compensatorio; nenhum registro e apagado.</p>
        <div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th>Data</th><th>Campanha</th><th>Debito</th><th>Motivo e acao</th></tr></thead><tbody>
          <cfoutput query="qAdsV1ReversibleDebits">
            <tr><td><cfif isDate(occurred_at)>#lsDateFormat(occurred_at, "dd/mm/yyyy")# #lsTimeFormat(occurred_at, "HH:nn")#<cfelse>-</cfif></td><td>#htmlEditFormat(campaign_name)#<div class="ads-v1-code text-muted">#htmlEditFormat(ledger_entry_id)#</div></td><td>#lsCurrencyFormat(amount)#</td><td><form method="post" action="./" class="d-flex flex-column flex-lg-row gap-2"><input type="hidden" name="ads_v1_action" value="reverse_click_debit"/><input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/><input type="hidden" name="ledger_entry_id" value="#htmlEditFormat(ledger_entry_id)#"/><input type="hidden" name="idempotency_key" value="business:click-reversal:#htmlEditFormat(ledger_entry_id)#:#adsV1NewIdempotencyToken()#"/><input class="form-control form-control-sm" name="reason" minlength="5" maxlength="500" required placeholder="Motivo do estorno"/><button class="btn btn-sm btn-outline-info" type="submit">Estornar</button></form></td></tr>
          </cfoutput>
        </tbody></table></div>
      </div>
    </section>
  </cfif>

  <cfif qAdsV1StatusHistory.recordcount>
    <section class="card shadow-0 mb-4">
      <div class="card-body p-3 p-lg-4">
        <div class="ads-v1-eyebrow">Auditoria</div>
        <h2 class="h5">Historico de status</h2>
        <div class="table-responsive"><table class="table table-sm align-middle mb-0"><thead><tr><th>Data</th><th>Campanha</th><th>Transicao</th><th>Operador</th><th>Motivo</th></tr></thead><tbody>
          <cfoutput query="qAdsV1StatusHistory"><tr><td><cfif isDate(changed_at)>#lsDateFormat(changed_at, "dd/mm/yyyy")# #lsTimeFormat(changed_at, "HH:nn")#<cfelse>-</cfif></td><td>#htmlEditFormat(campaign_name)#</td><td>#htmlEditFormat(from_status)# &rarr; #htmlEditFormat(to_status)#</td><td>#htmlEditFormat(changed_by_name)#</td><td>#htmlEditFormat(reason)#</td></tr></cfoutput>
        </tbody></table></div>
      </div>
    </section>
  </cfif>
</cfif>
