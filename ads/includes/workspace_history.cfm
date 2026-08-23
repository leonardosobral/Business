<div class="ads-status-tabs mb-3"><a class="<cfif VARIABLES.adsV1HistoryTab EQ 'campaigns'>active</cfif>" href="./?view=history&amp;history=campaigns">Campanhas</a><a class="<cfif VARIABLES.adsV1HistoryTab EQ 'legacy'>active</cfif>" href="./?view=history&amp;history=legacy">Sistema anterior</a></div>

<cfif VARIABLES.adsV1HistoryTab EQ "campaigns">
  <section class="card shadow-0 mb-4"><div class="card-body p-3 p-lg-4"><div class="ads-v1-eyebrow">Atividade</div><h2 class="h5">Histórico de status</h2><div class="table-responsive"><table class="table table-sm align-middle mb-0"><thead><tr><th>Data</th><th>Campanha</th><th>Alteração</th><th>Operador</th><th>Motivo</th></tr></thead><tbody><cfif qAdsV1StatusHistory.recordcount><cfoutput query="qAdsV1StatusHistory"><tr><td><cfif isDate(changed_at)>#lsDateFormat(changed_at, "dd/mm/yyyy")# #lsTimeFormat(changed_at, "HH:nn")#<cfelse>-</cfif></td><td>#htmlEditFormat(campaign_name)#</td><td>#htmlEditFormat(adsV1CampaignStatusLabel(from_status))# &rarr; #htmlEditFormat(adsV1CampaignStatusLabel(to_status))#</td><td>#htmlEditFormat(changed_by_name)#</td><td>#htmlEditFormat(reason)#</td></tr></cfoutput><cfelse><tr><td colspan="5" class="text-muted text-center py-4">Nenhuma alteração registrada.</td></tr></cfif></tbody></table></div></div></section>
<cfelse>
  <cfinclude template="legacy_history.cfm"/>
</cfif>
