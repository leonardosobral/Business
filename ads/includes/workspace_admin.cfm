<cfif VARIABLES.adsAccessCanReviewCampaign>
  <cfset VARIABLES.adsV1PerformanceContext = "admin"/>
  <cfinclude template="workspace_performance.cfm"/>

  <section class="mb-3 d-flex flex-column flex-md-row justify-content-between align-items-md-end gap-2">
    <div><div class="ads-v1-eyebrow">Uso interno</div><h2 class="h5 mb-1">Campanhas aguardando análise</h2><p class="text-muted mb-0">Cada bloco abaixo representa uma única solicitação, com contexto e decisões agrupados.</p></div>
    <span class="badge badge-info"><cfoutput>#qAdsV1CampaignReviewQueue.recordcount# na fila</cfoutput></span>
  </section>

  <cfif NOT VARIABLES.adsV1ReviewApiReady>
    <div class="alert alert-warning">A fila de revisão ainda não está disponível. Verifique a migração de publicidade.</div>
  <cfelseif NOT qAdsV1CampaignReviewQueue.recordcount>
    <section class="card shadow-0 mb-4"><div class="card-body p-4 text-center"><div class="ads-v1-eyebrow mb-2">Fila concluída</div><h3 class="h5">Nenhuma campanha aguardando decisão</h3><p class="text-muted mb-0">Novas solicitações aparecerão aqui quando concluírem os pré-requisitos.</p></div></section>
  <cfelse>
    <div class="d-flex flex-column gap-4 mb-4">
      <cfloop query="qAdsV1CampaignReviewQueue">
        <cfset VARIABLES.adsV1AdminReviewStatus = uCase(trim(qAdsV1CampaignReviewQueue.review_status & ""))/>
        <article class="card shadow-0 border <cfif VARIABLES.adsV1AdminReviewStatus EQ 'PENDING_REVIEW'>border-info<cfelse>border-warning</cfif>">
          <div class="card-body p-3 p-lg-4">
            <cfoutput>
              <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-start gap-3 pb-3 mb-3 border-bottom">
                <div>
                  <div class="d-flex flex-wrap gap-2 mb-2"><span class="badge badge-secondary">Solicitação ###qAdsV1CampaignReviewQueue.campaign_review_request_id#</span><span class="badge <cfif VARIABLES.adsV1AdminReviewStatus EQ 'PENDING_REVIEW'>badge-info<cfelse>badge-warning</cfif>"><cfif VARIABLES.adsV1AdminReviewStatus EQ "PENDING_REVIEW">Pronta para análise<cfelse>Aguardando pré-requisitos</cfif></span></div>
                  <h3 class="h5 mb-1">#htmlEditFormat(qAdsV1CampaignReviewQueue.campaign_name)#</h3>
                  <p class="text-muted mb-0">#htmlEditFormat(qAdsV1CampaignReviewQueue.account_name)# · #htmlEditFormat(qAdsV1CampaignReviewQueue.event_name)#</p>
                </div>
                <div class="text-lg-end small text-muted"><div>Enviada em</div><strong class="text-body"><cfif isDate(qAdsV1CampaignReviewQueue.submitted_at)>#lsDateFormat(qAdsV1CampaignReviewQueue.submitted_at, "dd/mm/yyyy")# #lsTimeFormat(qAdsV1CampaignReviewQueue.submitted_at, "HH:nn")#<cfelse>-</cfif></strong></div>
              </div>

              <div class="row g-3 mb-4">
                <div class="col-sm-6 col-xl-3"><div class="small text-muted">Conta</div><strong>#htmlEditFormat(qAdsV1CampaignReviewQueue.account_name)#</strong><div class="small">#htmlEditFormat(qAdsV1CampaignReviewQueue.account_status)#</div></div>
                <div class="col-sm-6 col-xl-3"><div class="small text-muted">Evento</div><strong>#htmlEditFormat(qAdsV1CampaignReviewQueue.event_name)#</strong><div class="small">#htmlEditFormat(qAdsV1CampaignReviewQueue.event_city)#/#htmlEditFormat(qAdsV1CampaignReviewQueue.event_state)# · #htmlEditFormat(qAdsV1CampaignReviewQueue.event_link_status)#</div></div>
                <div class="col-sm-6 col-xl-3"><div class="small text-muted">Investimento</div><strong>#lsCurrencyFormat(qAdsV1CampaignReviewQueue.budget_total)#</strong><div class="small">CPC #lsCurrencyFormat(qAdsV1CampaignReviewQueue.cpc_bid)# · saldo #lsCurrencyFormat(qAdsV1CampaignReviewQueue.available_balance)#</div></div>
                <div class="col-sm-6 col-xl-3"><div class="small text-muted">Período</div><strong><cfif isDate(qAdsV1CampaignReviewQueue.starts_at)>#lsDateFormat(qAdsV1CampaignReviewQueue.starts_at, "dd/mm/yyyy")#<cfelse>-</cfif> a <cfif isDate(qAdsV1CampaignReviewQueue.ends_at)>#lsDateFormat(qAdsV1CampaignReviewQueue.ends_at, "dd/mm/yyyy")#<cfelse>-</cfif></strong><div class="small">#htmlEditFormat(adsV1PlacementSummary(qAdsV1CampaignReviewQueue.placement_keys))#</div></div>
              </div>
            </cfoutput>

            <cfif VARIABLES.adsV1AdminReviewStatus EQ "PENDING_REVIEW">
              <div class="row g-3">
                <div class="col-lg-5">
                  <form method="post" action="./?view=admin" class="border rounded p-3 h-100">
                    <input type="hidden" name="ads_v1_action" value="approve_campaign_review"/>
                    <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
                    <input type="hidden" name="campaign_id" value="<cfoutput>#htmlEditFormat(qAdsV1CampaignReviewQueue.campaign_id)#</cfoutput>"/>
                    <input type="hidden" name="campaign_review_request_id" value="<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>"/>
                    <label class="form-label" for="ads-review-approve-<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>">Nota da aprovação <span class="text-muted">(opcional)</span></label>
                    <textarea class="form-control mb-3" id="ads-review-approve-<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>" name="review_reason" maxlength="1000"></textarea>
                    <button class="btn btn-info w-100" type="submit">Aprovar e liberar campanha</button>
                  </form>
                </div>
                <div class="col-lg-7">
                  <div class="border rounded p-3 h-100">
                    <form method="post" action="./?view=admin" class="mb-3">
                      <input type="hidden" name="ads_v1_action" value="request_campaign_changes"/>
                      <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
                      <input type="hidden" name="campaign_id" value="<cfoutput>#htmlEditFormat(qAdsV1CampaignReviewQueue.campaign_id)#</cfoutput>"/>
                      <input type="hidden" name="campaign_review_request_id" value="<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>"/>
                      <label class="form-label" for="ads-review-change-<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>">O que precisa ser ajustado?</label>
                      <textarea class="form-control mb-2" id="ads-review-change-<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>" name="review_reason" minlength="5" maxlength="1000" required></textarea>
                      <button class="btn btn-outline-warning w-100" type="submit">Solicitar ajustes</button>
                    </form>
                    <form method="post" action="./?view=admin" class="d-flex flex-column flex-md-row gap-2">
                      <input type="hidden" name="ads_v1_action" value="cancel_campaign_review"/>
                      <input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/>
                      <input type="hidden" name="campaign_id" value="<cfoutput>#htmlEditFormat(qAdsV1CampaignReviewQueue.campaign_id)#</cfoutput>"/>
                      <input type="hidden" name="campaign_review_request_id" value="<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>"/>
                      <input class="form-control" name="review_reason" minlength="5" maxlength="1000" required placeholder="Motivo do cancelamento"/>
                      <button class="btn btn-outline-danger" type="submit">Cancelar análise</button>
                    </form>
                  </div>
                </div>
              </div>
            <cfelse>
              <div class="alert alert-warning mb-3"><strong>Ainda não pode ser aprovada.</strong> A conta e o evento precisam estar ativos. A solicitação avança automaticamente quando ambos forem liberados.</div>
              <div class="row g-3">
                <div class="col-lg-7"><form method="post" action="./?view=admin"><input type="hidden" name="ads_v1_action" value="request_campaign_changes"/><input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/><input type="hidden" name="campaign_id" value="<cfoutput>#htmlEditFormat(qAdsV1CampaignReviewQueue.campaign_id)#</cfoutput>"/><input type="hidden" name="campaign_review_request_id" value="<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>"/><label class="form-label">Solicitar correção antecipada</label><textarea class="form-control mb-2" name="review_reason" minlength="5" maxlength="1000" required></textarea><button class="btn btn-outline-warning" type="submit">Solicitar ajustes</button></form></div>
                <div class="col-lg-5"><form method="post" action="./?view=admin"><input type="hidden" name="ads_v1_action" value="cancel_campaign_review"/><input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/><input type="hidden" name="campaign_id" value="<cfoutput>#htmlEditFormat(qAdsV1CampaignReviewQueue.campaign_id)#</cfoutput>"/><input type="hidden" name="campaign_review_request_id" value="<cfoutput>#qAdsV1CampaignReviewQueue.campaign_review_request_id#</cfoutput>"/><label class="form-label">Cancelar solicitação</label><input class="form-control mb-2" name="review_reason" minlength="5" maxlength="1000" required/><button class="btn btn-outline-danger" type="submit">Cancelar análise</button></form></div>
              </div>
            </cfif>
          </div>
        </article>
      </cfloop>
    </div>
  </cfif>

  <section class="mt-5 mb-3 d-flex flex-column flex-md-row justify-content-between align-items-md-end gap-2">
    <div><div class="ads-v1-eyebrow">Acompanhamento global</div><h2 class="h5 mb-1">Campanhas em operação</h2><p class="text-muted mb-0">Campanhas aprovadas pela RunnerHub que estão ativas ou pausadas, em todas as contas.</p></div>
    <span class="badge badge-success"><cfoutput>#qAdsV1AdminOperationalCampaigns.recordcount# campanhas</cfoutput></span>
  </section>

  <section class="card shadow-0 mb-4">
    <div class="card-body p-0">
      <cfif NOT VARIABLES.adsV1ReviewApiReady>
        <div class="alert alert-warning m-3">O acompanhamento das campanhas ainda não está disponível.</div>
      <cfelseif NOT qAdsV1AdminOperationalCampaigns.recordcount>
        <div class="p-4 text-center"><h3 class="h6 mb-2">Nenhuma campanha aprovada em operação</h3><p class="text-muted mb-0">Campanhas ativas ou pausadas aparecerão aqui após a aprovação.</p></div>
      <cfelse>
        <style>
          .ads-operation-grid { display: grid; grid-template-columns: minmax(0,2.1fr) minmax(65px,.6fr) minmax(0,1fr) minmax(0,1fr) 124px 118px; gap: 16px; align-items: center; }
          .ads-operation-head { padding: 12px 20px; color: var(--mdb-secondary-color); font-size: .75rem; font-weight: 700; }
          .ads-operation-row { border-top: 1px solid rgba(255,255,255,.12); }
          .ads-operation-row > summary { list-style: none; cursor: pointer; padding: 14px 20px; font-size: .85rem; }
          .ads-operation-row > summary::-webkit-details-marker { display: none; }
          .ads-operation-row > summary:hover { background: rgba(98,199,216,.04); }
          .ads-operation-row > summary:focus-visible { outline: 2px solid #62c7d8; outline-offset: -2px; }
          .ads-operation-grid > span { min-width: 0; }
          .ads-operation-name { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; line-height: 1.35; overflow-wrap: anywhere; }
          .ads-operation-secondary { display: block; color: var(--mdb-secondary-color); font-size: .78rem; margin-top: 3px; }
          .ads-operation-label { display: none; }
          .ads-operation-toggle { border: 1px solid #62c7d8; border-radius: 4px; color: #78d3e1; font-size: .75rem; padding: 7px 8px; text-align: center; white-space: nowrap; }
          .ads-operation-toggle i { margin-left: 5px; }
          .ads-operation-hide, .ads-operation-row[open] .ads-operation-show { display: none; }
          .ads-operation-row[open] .ads-operation-hide { display: inline; }
          .ads-operation-row[open] .ads-operation-toggle i { transform: rotate(180deg); }
          .ads-operation-detail { border-top: 1px solid rgba(255,255,255,.08); background: rgba(0,0,0,.12); padding: 20px; }
          .ads-operation-detail h3 { font-size: .95rem; margin: 0 0 16px; overflow-wrap: anywhere; }
          .ads-operation-facts { display: grid; grid-template-columns: repeat(3,minmax(0,1fr)); gap: 18px 24px; margin: 0; }
          .ads-operation-facts dt { color: var(--mdb-secondary-color); font-size: .72rem; text-transform: uppercase; margin-bottom: 4px; }
          .ads-operation-facts dd { font-size: .84rem; margin: 0; overflow-wrap: anywhere; }
          .ads-operation-id { color: var(--mdb-secondary-color); font-size: .72rem; margin: 18px 0 0; overflow-wrap: anywhere; }
          @media (max-width: 1100px) {
            .ads-operation-head { display: none; }
            .ads-operation-grid { grid-template-columns: minmax(0,2fr) minmax(0,1fr) minmax(0,1fr); gap: 12px 18px; }
            .ads-operation-label { display: block; color: var(--mdb-secondary-color); font-size: .68rem; margin-bottom: 3px; text-transform: uppercase; }
          }
          @media (max-width: 600px) {
            .ads-operation-grid { grid-template-columns: repeat(2,minmax(0,1fr)); }
            .ads-operation-campaign { grid-column: 1 / -1; }
            .ads-operation-toggle { grid-column: 1 / -1; justify-self: end; }
            .ads-operation-facts { grid-template-columns: 1fr; gap: 14px; }
            .ads-operation-row > summary, .ads-operation-detail { padding: 14px; }
          }
        </style>
        <div class="ads-operation-list">
          <div class="ads-operation-grid ads-operation-head" aria-hidden="true"><span>Campanha / conta</span><span>Status</span><span>Investimento</span><span>Resultados</span><span>CTR / CPC médio</span><span>Detalhes</span></div>
          <cfoutput query="qAdsV1AdminOperationalCampaigns">
            <cfset VARIABLES.adsV1AdminOperationalStatus = uCase(trim(campaign_status & ""))/>
            <cfset VARIABLES.adsV1AdminOperationalCtr = val(viewable_impression_count) GT 0 ? val(valid_click_count) * 100 / val(viewable_impression_count) : 0/>
            <cfset VARIABLES.adsV1AdminOperationalCtrLabel = val(viewable_impression_count) GT 0 ? lsNumberFormat(VARIABLES.adsV1AdminOperationalCtr, "9.99") & "%" : "—"/>
            <cfset VARIABLES.adsV1AdminOperationalAverageCpc = val(billable_click_count) GT 0 ? val(cost) / val(billable_click_count) : 0/>
            <cfset VARIABLES.adsV1AdminOperationalPlaces = []/>
            <cfloop list="#placement_keys#" index="VARIABLES.adsV1AdminOperationalPlaceKey">
              <cfset VARIABLES.adsV1AdminOperationalPlaceLabel = adsV1PlacementLabel(VARIABLES.adsV1AdminOperationalPlaceKey)/>
              <cfif NOT arrayFindNoCase(VARIABLES.adsV1AdminOperationalPlaces, VARIABLES.adsV1AdminOperationalPlaceLabel)>
                <cfset arrayAppend(VARIABLES.adsV1AdminOperationalPlaces, VARIABLES.adsV1AdminOperationalPlaceLabel)/>
              </cfif>
            </cfloop>
            <details class="ads-operation-row">
              <summary class="ads-operation-grid">
                <span class="ads-operation-campaign"><strong class="ads-operation-name">#htmlEditFormat(campaign_name)#</strong><span class="ads-operation-secondary">#htmlEditFormat(account_name)#</span></span>
                <span><span class="ads-operation-label">Status</span><span class="badge <cfif VARIABLES.adsV1AdminOperationalStatus EQ 'ACTIVE'>badge-success<cfelse>badge-warning</cfif>">#htmlEditFormat(adsV1CampaignStatusLabel(campaign_status))#</span></span>
                <span><span class="ads-operation-label">Investimento</span><strong>#lsCurrencyFormat(spent_total)#</strong><span class="ads-operation-secondary">de #lsCurrencyFormat(budget_total)#</span></span>
                <span><strong>#lsNumberFormat(viewable_impression_count, "9,999,999")# impressões</strong><span class="ads-operation-secondary">#lsNumberFormat(valid_click_count, "9,999,999")# cliques</span></span>
                <span><strong<cfif val(viewable_impression_count) LTE 0> title="CTR indisponível: ainda não há impressões registradas."</cfif>>CTR #VARIABLES.adsV1AdminOperationalCtrLabel#</strong><span class="ads-operation-secondary">CPC médio #lsCurrencyFormat(VARIABLES.adsV1AdminOperationalAverageCpc)#</span></span>
                <span class="ads-operation-toggle"><span class="ads-operation-show">Ver detalhes</span><span class="ads-operation-hide">Recolher</span><i class="fas fa-chevron-down" aria-hidden="true"></i></span>
              </summary>
              <div class="ads-operation-detail">
                <h3>#htmlEditFormat(campaign_name)#</h3>
                <dl class="ads-operation-facts">
                  <div><dt>Conta e evento</dt><dd><strong>#htmlEditFormat(account_name)#</strong><br/>#htmlEditFormat(event_name)#<br/>#htmlEditFormat(event_city)#<cfif len(trim(event_state & ""))>/#htmlEditFormat(event_state)#</cfif></dd></div>
                  <div><dt>Público</dt><dd><cfif len(trim(target_region_code & ""))>#htmlEditFormat(target_region_code)#<cfelse>Todo o país</cfif> · #htmlEditFormat(target_country_code)#<br/><cfif uCase(trim(target_device_class & "")) EQ "MOBILE">Celular<cfelseif uCase(trim(target_device_class & "")) EQ "DESKTOP">Desktop<cfelse>Todos os dispositivos</cfif></dd></div>
                  <div><dt>Locais de exibição</dt><dd>#htmlEditFormat(arrayToList(VARIABLES.adsV1AdminOperationalPlaces, ", "))#</dd></div>
                  <div><dt>Lance e orçamento</dt><dd>Lance #lsCurrencyFormat(cpc_bid)# por clique<br/>Gasto #lsCurrencyFormat(spent_total)# de #lsCurrencyFormat(budget_total)#<br/><cfif isNumeric(budget_daily) AND val(budget_daily) GT 0>Limite diário: #lsCurrencyFormat(budget_daily)#<cfelse>Sem limite diário definido</cfif></dd></div>
                  <div><dt>Desempenho acumulado</dt><dd>#lsNumberFormat(viewable_impression_count, "9,999,999")# impressões · #lsNumberFormat(valid_click_count, "9,999,999")# cliques<br/>CTR #VARIABLES.adsV1AdminOperationalCtrLabel# · CPC médio #lsCurrencyFormat(VARIABLES.adsV1AdminOperationalAverageCpc)#<br/>#lsNumberFormat(served_count, "9,999,999")# entregas</dd></div>
                  <div><dt>Período e aprovação</dt><dd><cfif isDate(starts_at)>#lsDateFormat(starts_at, "dd/mm/yyyy")# #lsTimeFormat(starts_at, "HH:nn")#<cfelse>Início não informado</cfif><br/>até <cfif isDate(ends_at)>#lsDateFormat(ends_at, "dd/mm/yyyy")# #lsTimeFormat(ends_at, "HH:nn")#<cfelse>data não informada</cfif><br/><cfif isDate(reviewed_at)>Aprovada em #lsDateFormat(reviewed_at, "dd/mm/yyyy")#<cfelse>Aprovada pela RunnerHub</cfif></dd></div>
                </dl>
                <p class="ads-operation-id">CPC · ID #htmlEditFormat(campaign_id)#</p>
              </div>
            </details>
          </cfoutput>
        </div>
      </cfif>
    </div>
  </section>
</cfif>

<cfif VARIABLES.adsAccessCanAdminFinance>
<section class="mb-3"><div class="ads-v1-eyebrow">Uso interno</div><h2 class="h5 mb-1">Administração financeira</h2><p class="text-muted mb-0">Crédito manual, movimentações e correções da conta.</p></section>

<div class="row g-4 mb-4">
  <div class="col-xl-4"><section class="card shadow-0 h-100"><div class="card-body p-3 p-lg-4"><h2 class="h5">Crédito manual</h2><p class="text-muted">Use apenas para ajustes administrativos.</p><form method="post" action="./?view=admin"><input type="hidden" name="ads_v1_action" value="credit_account"/><input type="hidden" name="ads_v1_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1Csrf)#</cfoutput>"/><input type="hidden" name="idempotency_key" value="<cfoutput>#htmlEditFormat(VARIABLES.adsV1CreditIdempotencyKey)#</cfoutput>"/><div class="mb-3"><label class="form-label" for="ads-v1-credit">Valor</label><input class="form-control" id="ads-v1-credit" type="number" name="amount" min="0.01" step="0.01" required/></div><div class="mb-3"><label class="form-label" for="ads-v1-credit-reason">Justificativa</label><textarea class="form-control" id="ads-v1-credit-reason" name="reason" minlength="5" maxlength="500" required></textarea></div><button class="btn btn-info w-100" type="submit">Registrar crédito</button></form></div></section></div>
  <div class="col-xl-8"><section class="card shadow-0 h-100"><div class="card-body p-3 p-lg-4"><h2 class="h5">Movimentações recentes</h2><div class="table-responsive"><table class="table table-sm align-middle mb-0"><thead><tr><th>Data</th><th>Tipo</th><th>Campanha</th><th class="text-end">Valor</th><th class="text-end">Saldo</th></tr></thead><tbody><cfif qAdsV1Ledger.recordcount><cfoutput query="qAdsV1Ledger"><tr><td><cfif isDate(occurred_at)>#lsDateFormat(occurred_at, "dd/mm/yyyy")# #lsTimeFormat(occurred_at, "HH:nn")#<cfelse>-</cfif></td><td>#htmlEditFormat(adsV1LedgerLabel(entry_type, source_type))#</td><td>#htmlEditFormat(campaign_name)#</td><td class="text-end">#lsCurrencyFormat(amount)#</td><td class="text-end">#lsCurrencyFormat(balance_after)#</td></tr></cfoutput><cfelse><tr><td colspan="5" class="text-muted text-center py-4">Nenhuma movimentação.</td></tr></cfif></tbody></table></div></div></section></div>
</div>

<cfif qAdsV1ReversibleDebits.recordcount>
  <section class="card shadow-0 mb-4"><div class="card-body p-3 p-lg-4"><h2 class="h5">Débitos elegíveis para estorno</h2><p class="text-muted">O estorno cria uma movimentação compensatória; nenhum registro é apagado.</p><div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th>Data</th><th>Campanha</th><th>Débito</th><th>Motivo e ação</th></tr></thead><tbody><cfoutput query="qAdsV1ReversibleDebits"><tr><td><cfif isDate(occurred_at)>#lsDateFormat(occurred_at, "dd/mm/yyyy")# #lsTimeFormat(occurred_at, "HH:nn")#<cfelse>-</cfif></td><td>#htmlEditFormat(campaign_name)#</td><td>#lsCurrencyFormat(amount)#</td><td><form method="post" action="./?view=admin" class="d-flex flex-column flex-lg-row gap-2"><input type="hidden" name="ads_v1_action" value="reverse_click_debit"/><input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/><input type="hidden" name="ledger_entry_id" value="#htmlEditFormat(ledger_entry_id)#"/><input type="hidden" name="idempotency_key" value="business:click-reversal:#htmlEditFormat(ledger_entry_id)#:#adsV1NewIdempotencyToken()#"/><input class="form-control form-control-sm" name="reason" minlength="5" maxlength="500" required placeholder="Motivo do estorno"/><button class="btn btn-sm btn-outline-info" type="submit">Estornar</button></form></td></tr></cfoutput></tbody></table></div></div></section>
</cfif>
</cfif>
