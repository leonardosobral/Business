<cfif VARIABLES.adsAccessCanReviewCampaign>
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
        <div class="table-responsive">
          <table class="table align-middle mb-0">
            <thead><tr><th>Campanha</th><th>Conta e evento</th><th>Segmentação</th><th>Investimento</th><th>Resultados</th><th>Período</th></tr></thead>
            <tbody>
              <cfoutput query="qAdsV1AdminOperationalCampaigns">
                <cfset VARIABLES.adsV1AdminOperationalStatus = uCase(trim(campaign_status & ""))/>
                <tr>
                  <td>
                    <div class="d-flex flex-wrap align-items-center gap-2 mb-1">
                      <strong>#htmlEditFormat(campaign_name)#</strong>
                      <span class="badge <cfif VARIABLES.adsV1AdminOperationalStatus EQ 'ACTIVE'>badge-success<cfelse>badge-warning</cfif>">#htmlEditFormat(adsV1CampaignStatusLabel(campaign_status))#</span>
                    </div>
                    <div class="small text-muted">CPC · ID #htmlEditFormat(campaign_id)#</div>
                  </td>
                  <td><strong>#htmlEditFormat(account_name)#</strong><div class="small text-muted">#htmlEditFormat(event_name)#<cfif len(trim(event_city & "")) OR len(trim(event_state & ""))> · #htmlEditFormat(event_city)#/#htmlEditFormat(event_state)#</cfif></div></td>
                  <td><strong><cfif len(trim(target_region_code & ""))>#htmlEditFormat(target_region_code)#<cfelse>Brasil</cfif></strong><div class="small text-muted"><cfif uCase(trim(target_device_class & "")) EQ "MOBILE">Celular<cfelseif uCase(trim(target_device_class & "")) EQ "DESKTOP">Desktop<cfelse>Todos os dispositivos</cfif></div><div class="small text-muted">#htmlEditFormat(adsV1PlacementSummary(placement_keys))#</div></td>
                  <td><strong>#lsCurrencyFormat(spent_total)# de #lsCurrencyFormat(budget_total)#</strong><div class="small text-muted">Lance #lsCurrencyFormat(cpc_bid)# por clique<cfif isNumeric(budget_daily) AND val(budget_daily) GT 0> · limite #lsCurrencyFormat(budget_daily)#/dia</cfif></div></td>
                  <td><strong>#lsNumberFormat(viewable_impression_count, "9,999,999")# impressões</strong><div class="small text-muted">#lsNumberFormat(valid_click_count, "9,999,999")# cliques · #lsNumberFormat(served_count, "9,999,999")# entregas</div></td>
                  <td><strong><cfif isDate(starts_at)>#lsDateFormat(starts_at, "dd/mm/yyyy")#<cfelse>-</cfif> a <cfif isDate(ends_at)>#lsDateFormat(ends_at, "dd/mm/yyyy")#<cfelse>-</cfif></strong><div class="small text-muted"><cfif isDate(reviewed_at)>Aprovada em #lsDateFormat(reviewed_at, "dd/mm/yyyy")#<cfelse>Aprovada</cfif></div></td>
                </tr>
              </cfoutput>
            </tbody>
          </table>
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
