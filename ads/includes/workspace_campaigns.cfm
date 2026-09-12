<cfif VARIABLES.adsV1WorkspaceView EQ "campaigns">
  <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-3">
    <div class="ads-status-tabs" aria-label="Filtrar campanhas">
      <a class="<cfif VARIABLES.adsV1CampaignFilter EQ 'ongoing'>active</cfif>" href="./?view=campaigns&amp;status=ongoing">Em andamento <span class="badge badge-secondary"><cfoutput>#VARIABLES.adsV1OngoingCount#</cfoutput></span></a>
      <a class="<cfif VARIABLES.adsV1CampaignFilter EQ 'draft'>active</cfif>" href="./?view=campaigns&amp;status=draft">Rascunhos <span class="badge badge-secondary"><cfoutput>#VARIABLES.adsV1DraftCount#</cfoutput></span></a>
      <a class="<cfif VARIABLES.adsV1CampaignFilter EQ 'ended'>active</cfif>" href="./?view=campaigns&amp;status=ended">Finalizadas <span class="badge badge-secondary"><cfoutput>#VARIABLES.adsV1EndedCount#</cfoutput></span></a>
    </div>
    <cfif VARIABLES.adsAccessCanManageCampaign><a class="btn btn-outline-info" href="./?view=campaigns&amp;mode=new#campaign-form">Nova campanha</a></cfif>
  </div>
</cfif>

<div class="row g-4 mb-4">
  <div class="col-12">
    <section class="card shadow-0 h-100">
      <div class="card-body p-3 p-lg-4">
        <div class="d-flex justify-content-between align-items-center gap-3 mb-3">
          <div><div class="ads-v1-eyebrow">Campanhas</div><h2 class="h5 mb-0"><cfif VARIABLES.adsV1WorkspaceView EQ 'overview'>Campanhas em andamento<cfelseif VARIABLES.adsV1CampaignFilter EQ 'draft'>Rascunhos<cfelseif VARIABLES.adsV1CampaignFilter EQ 'ended'>Campanhas finalizadas<cfelse>Campanhas em andamento</cfif></h2></div>
          <cfif VARIABLES.adsV1WorkspaceView EQ "overview"><a href="./?view=campaigns" class="btn btn-sm btn-outline-info">Ver todas</a></cfif>
        </div>

        <cfif qAdsV1Campaigns.recordcount>
          <div class="table-responsive">
            <table class="table table-hover ads-campaign-table <cfif VARIABLES.adsV1WorkspaceView EQ 'overview'>ads-campaign-table--overview<cfelse>ads-campaign-table--management</cfif> mb-0">
              <thead>
                <cfif VARIABLES.adsV1WorkspaceView EQ "overview">
                  <tr><th>Campanha</th><th>Status</th><th>Investimento</th><th>Resultados</th></tr>
                <cfelseif VARIABLES.adsV1WorkspaceView EQ "campaigns">
                  <tr><th>Campanha</th><th>Status</th><th>Investimento</th><th>Resultados</th><th class="text-end">Ações</th></tr>
                </cfif>
              </thead>
              <tbody>
                <cfset VARIABLES.adsV1CampaignRowsShown = 0/>
                <cfloop query="qAdsV1Campaigns">
                  <cfset VARIABLES.adsV1RowStatus = uCase(qAdsV1Campaigns.status & "")/>
                  <cfset VARIABLES.adsV1RowReviewStatus = uCase(trim(qAdsV1Campaigns.review_status & ""))/>
                  <cfset VARIABLES.adsV1ShowCampaignRow = VARIABLES.adsV1WorkspaceView EQ "overview"
                    ? listFind("ACTIVE,PAUSED", VARIABLES.adsV1RowStatus) GT 0
                    : (VARIABLES.adsV1CampaignFilter EQ "ongoing"
                      ? listFind("ACTIVE,PAUSED", VARIABLES.adsV1RowStatus) GT 0
                      : (VARIABLES.adsV1CampaignFilter EQ "draft" ? VARIABLES.adsV1RowStatus EQ "DRAFT" : VARIABLES.adsV1RowStatus EQ "ENDED"))/>
                  <cfif VARIABLES.adsV1ShowCampaignRow>
                    <cfset VARIABLES.adsV1CampaignRowsShown++/>
                    <cfset VARIABLES.adsV1BudgetProgress = val(qAdsV1Campaigns.budget_total) GT 0 ? min(100, max(0, (val(qAdsV1Campaigns.spent_total) / val(qAdsV1Campaigns.budget_total)) * 100)) : 0/>
                    <cfset VARIABLES.adsV1RowCtr = val(qAdsV1Campaigns.viewable_impression_count) GT 0 ? val(qAdsV1Campaigns.valid_click_count) * 100 / val(qAdsV1Campaigns.viewable_impression_count) : 0/>
                    <cfset VARIABLES.adsV1RowAverageCpc = val(qAdsV1Campaigns.billable_click_count) GT 0 ? val(qAdsV1Campaigns.cost) / val(qAdsV1Campaigns.billable_click_count) : 0/>
                    <cfoutput>
                      <tr>
                        <td><div class="d-flex align-items-start gap-2"><div class="ads-campaign-mark"><i class="fas fa-bullhorn" aria-hidden="true"></i></div><div class="min-w-0"><a class="text-body text-decoration-none ads-campaign-title" href="./?view=campaign-detail&amp;campaign=#urlEncodedFormat(qAdsV1Campaigns.campaign_id)#"><strong>#htmlEditFormat(qAdsV1Campaigns.name)#</strong></a><div class="small text-muted ads-campaign-event">#htmlEditFormat(qAdsV1Campaigns.nome_evento)#</div><div class="small text-muted">#htmlEditFormat(adsV1PlacementCountSummary(qAdsV1Campaigns.placement_keys))#</div><cfif VARIABLES.adsV1WorkspaceView EQ "overview"><a class="ads-campaign-performance-link" href="./?view=campaign-detail&amp;campaign=#urlEncodedFormat(qAdsV1Campaigns.campaign_id)#">Ver desempenho <i class="fas fa-arrow-right ms-1" aria-hidden="true"></i></a></cfif></div></div></td>
                        <td>
                          <span class="badge <cfif VARIABLES.adsV1RowStatus EQ 'ACTIVE'>badge-success<cfelseif VARIABLES.adsV1RowStatus EQ 'PAUSED'>badge-warning<cfelseif VARIABLES.adsV1RowStatus EQ 'ENDED'>badge-danger<cfelse>badge-secondary</cfif>">#htmlEditFormat(adsV1CampaignStatusLabel(VARIABLES.adsV1RowStatus))#</span>
                          <cfif VARIABLES.adsV1RowReviewStatus EQ "WAITING_PREREQUISITES">
                            <div class="mt-2"><span class="badge badge-warning">Aguardando pré-requisitos</span></div>
                            <div class="small text-muted mt-1">A campanha está preparada e será enviada à RunnerHub quando a conta e o evento forem aprovados.</div>
                          <cfelseif VARIABLES.adsV1RowReviewStatus EQ "PENDING_REVIEW">
                            <div class="mt-2"><span class="badge badge-info">Em análise pela RunnerHub</span></div>
                            <div class="small text-muted mt-1">Nenhum anúncio entra no ar antes da aprovação.</div>
                          <cfelseif VARIABLES.adsV1RowReviewStatus EQ "CHANGES_REQUESTED">
                            <div class="mt-2"><span class="badge badge-danger">Ajustes solicitados</span></div>
                            <cfif len(trim(qAdsV1Campaigns.review_reason & ""))><div class="small text-danger mt-1">#htmlEditFormat(qAdsV1Campaigns.review_reason)#</div></cfif>
                          <cfelseif VARIABLES.adsV1RowReviewStatus EQ "APPROVED">
                            <div class="mt-2"><span class="badge badge-success">Aprovada pela RunnerHub</span></div>
                          <cfelseif VARIABLES.adsV1RowReviewStatus EQ "CANCELED">
                            <div class="mt-2"><span class="badge badge-secondary">Análise cancelada</span></div>
                          </cfif>
                          <cfif VARIABLES.adsV1RowStatus EQ "ACTIVE" AND VARIABLES.adsV1Summary.balance LT qAdsV1Campaigns.cpc_bid><div class="small text-warning mt-1">Saldo insuficiente</div></cfif>
                        </td>
                        <td class="ads-campaign-investment"><div>#lsCurrencyFormat(qAdsV1Campaigns.spent_total)# de #lsCurrencyFormat(qAdsV1Campaigns.budget_total)#</div><div class="ads-budget-progress mt-2"><span style="width:#numberFormat(VARIABLES.adsV1BudgetProgress, '0')#%"></span></div></td>
                        <td><div class="ads-campaign-result-grid<cfif VARIABLES.adsV1WorkspaceView EQ 'campaigns'> ads-campaign-result-grid--management</cfif>">
                          <span><small>Impressões</small><strong>#lsNumberFormat(qAdsV1Campaigns.viewable_impression_count, "9,999,999")#</strong></span>
                          <span><small>Cliques</small><strong>#lsNumberFormat(qAdsV1Campaigns.valid_click_count, "9,999,999")#</strong></span>
                          <span><small>CTR</small><strong>#lsNumberFormat(VARIABLES.adsV1RowCtr, "9.99")#%</strong></span>
                          <span><small>CPC médio</small><strong>#lsCurrencyFormat(VARIABLES.adsV1RowAverageCpc)#</strong></span>
                        </div></td>
                        <cfif VARIABLES.adsV1WorkspaceView EQ "campaigns">
                          <td class="text-end"><div class="ads-campaign-actions">
                          <a class="btn btn-sm btn-outline-info" href="./?view=campaign-detail&amp;campaign=#urlEncodedFormat(qAdsV1Campaigns.campaign_id)#" title="Ver desempenho da campanha"><i class="fas fa-chart-line me-1" aria-hidden="true"></i>Desempenho</a>
                          <cfif VARIABLES.adsAccessCanManageCampaign>
                            <cfif VARIABLES.adsV1RowStatus EQ "DRAFT"
                              AND (NOT len(VARIABLES.adsV1RowReviewStatus) OR listFind("CHANGES_REQUESTED,CANCELED", VARIABLES.adsV1RowReviewStatus))>
                              <form method="post" action="./?view=campaigns">
                                <input type="hidden" name="ads_v1_action" value="submit_campaign_review"/>
                                <input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/>
                                <input type="hidden" name="campaign_id" value="#htmlEditFormat(qAdsV1Campaigns.campaign_id)#"/>
                                <button class="btn btn-sm btn-info w-100" type="submit"><cfif VARIABLES.adsV1RowReviewStatus EQ "CHANGES_REQUESTED">Reenviar<cfelse>Enviar</cfif> para análise</button>
                              </form>
                            </cfif>
                            <details class="ads-row-actions text-start"><summary class="btn btn-sm btn-outline-info">Gerenciar</summary><div class="ads-row-actions-panel">
                              <cfif VARIABLES.adsV1RowStatus EQ "DRAFT"
                                AND listFind("PENDING_REVIEW,WAITING_PREREQUISITES", VARIABLES.adsV1RowReviewStatus)>
                                <form method="post" action="./?view=campaigns">
                                  <input type="hidden" name="ads_v1_action" value="prepare_campaign_edit"/>
                                  <input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/>
                                  <input type="hidden" name="campaign_id" value="#htmlEditFormat(qAdsV1Campaigns.campaign_id)#"/>
                                  <p class="small text-warning mb-2">Ao editar, a campanha sai da fila de análise. Depois, você pode reenviar ou salvar como rascunho.</p>
                                  <button class="btn btn-sm btn-outline-light w-100" type="submit">Editar</button>
                                </form>
                              </cfif>
                              <cfif VARIABLES.adsV1RowReviewStatus EQ "APPROVED"
                                AND listFind("ACTIVE,PAUSED", VARIABLES.adsV1RowStatus)>
                                <form method="post" action="./?view=campaigns">
                                  <input type="hidden" name="ads_v1_action" value="prepare_campaign_edit"/>
                                  <input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/>
                                  <input type="hidden" name="campaign_id" value="#htmlEditFormat(qAdsV1Campaigns.campaign_id)#"/>
                                  <p class="small text-warning mb-2">Ao editar, a campanha ficará fora do ar até uma nova aprovação.</p>
                                  <button class="btn btn-sm btn-outline-warning w-100" type="submit" onclick="return confirm('A campanha ficará fora do ar até a RunnerHub aprovar novamente. Deseja continuar?')"><cfif VARIABLES.adsV1RowStatus EQ "ACTIVE">Pausar e editar<cfelse>Editar e reenviar</cfif></button>
                                </form>
                              </cfif>
                              <cfif listFind("DRAFT,PAUSED", VARIABLES.adsV1RowStatus)
                                AND NOT listFind("WAITING_PREREQUISITES,PENDING_REVIEW,APPROVED", VARIABLES.adsV1RowReviewStatus)>
                                <a class="btn btn-sm btn-outline-light" href="./?view=campaigns&amp;campaign=#urlEncodedFormat(qAdsV1Campaigns.campaign_id)###campaign-form">Editar</a>
                              </cfif>
                              <cfif VARIABLES.adsV1RowStatus EQ "ACTIVE"><form method="post" action="./?view=campaigns"><input type="hidden" name="ads_v1_action" value="change_campaign_status"/><input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/><input type="hidden" name="campaign_id" value="#htmlEditFormat(qAdsV1Campaigns.campaign_id)#"/><input type="hidden" name="target_status" value="PAUSED"/><input type="hidden" name="reason" value="Pausa manual pelo Business"/><button class="btn btn-sm btn-warning w-100" type="submit">Pausar</button></form></cfif>
                              <cfif listFind("DRAFT,ACTIVE,PAUSED", VARIABLES.adsV1RowStatus)><form method="post" action="./?view=campaigns"><input type="hidden" name="ads_v1_action" value="change_campaign_status"/><input type="hidden" name="ads_v1_csrf" value="#htmlEditFormat(VARIABLES.adsV1Csrf)#"/><input type="hidden" name="campaign_id" value="#htmlEditFormat(qAdsV1Campaigns.campaign_id)#"/><input type="hidden" name="target_status" value="ENDED"/><input class="form-control form-control-sm" type="text" name="reason" minlength="5" maxlength="500" required placeholder="Motivo para finalizar"/><button class="btn btn-sm btn-outline-danger w-100" type="submit">Finalizar campanha</button></form></cfif>
                            </div></details>
                          </cfif>
                          </div></td>
                        </cfif>
                      </tr>
                    </cfoutput>
                    <cfif VARIABLES.adsV1WorkspaceView EQ "overview" AND VARIABLES.adsV1CampaignRowsShown GTE 3><cfbreak/></cfif>
                  </cfif>
                </cfloop>
                <cfif NOT VARIABLES.adsV1CampaignRowsShown><tr><td colspan="<cfif VARIABLES.adsV1WorkspaceView EQ 'campaigns'>5<cfelse>4</cfif>" class="text-center text-muted py-4">Nenhuma campanha nesta categoria.</td></tr></cfif>
              </tbody>
            </table>
          </div>
        <cfelse><div class="alert alert-info mb-0">Esta conta ainda não possui campanhas.</div></cfif>
      </div>
    </section>
  </div>
</div>

<cfif VARIABLES.adsV1WorkspaceView EQ "overview">
  <section class="card shadow-0 mb-4"><div class="card-body p-3 p-lg-4"><div class="d-flex justify-content-between align-items-center mb-2"><div><div class="ads-v1-eyebrow">Conta</div><h2 class="h5 mb-0">Atividade recente</h2></div><a href="./?view=history" class="btn btn-sm btn-outline-info">Ver histórico completo</a></div>
    <cfset VARIABLES.adsV1ActivityCount = 0/>
    <cfif structKeyExists(VARIABLES.adsV1LatestPaidPayment, "amountCents")><cfset VARIABLES.adsV1ActivityCount++/><div class="ads-activity-row"><div><strong>Saldo adicionado por <cfoutput>#uCase(VARIABLES.adsV1LatestPaidPayment.method)#</cfoutput></strong><div class="small text-muted"><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1LatestPaidPayment.amountCents / 100)# confirmados</cfoutput></div></div><div class="small text-muted"><cfif isDate(VARIABLES.adsV1LatestPaidPayment.paidAt)><cfoutput>#lsDateFormat(VARIABLES.adsV1LatestPaidPayment.paidAt, "dd/mm/yyyy")# #lsTimeFormat(VARIABLES.adsV1LatestPaidPayment.paidAt, "HH:nn")#</cfoutput></cfif></div></div></cfif>
    <cfset VARIABLES.adsV1StatusRowsToShow = max(0, 4 - VARIABLES.adsV1ActivityCount)/>
    <cfif VARIABLES.adsV1StatusRowsToShow GT 0><cfloop query="qAdsV1StatusHistory" endrow="#VARIABLES.adsV1StatusRowsToShow#"><div class="ads-activity-row"><div><strong><cfoutput>Campanha "#htmlEditFormat(qAdsV1StatusHistory.campaign_name)#" #lCase(adsV1CampaignStatusLabel(qAdsV1StatusHistory.to_status))#</cfoutput></strong><div class="small text-muted"><cfoutput>#htmlEditFormat(qAdsV1StatusHistory.reason)#</cfoutput></div></div><div class="small text-muted"><cfif isDate(qAdsV1StatusHistory.changed_at)><cfoutput>#lsDateFormat(qAdsV1StatusHistory.changed_at, "dd/mm/yyyy")# #lsTimeFormat(qAdsV1StatusHistory.changed_at, "HH:nn")#</cfoutput></cfif></div></div></cfloop></cfif>
    <cfif NOT VARIABLES.adsV1ActivityCount AND NOT qAdsV1StatusHistory.recordcount><div class="text-muted py-4 text-center">Nenhuma atividade recente.</div></cfif>
  </div></section>
</cfif>
