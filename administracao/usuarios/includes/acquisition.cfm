<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"><cfabort></cfif>
<link rel="stylesheet" href="/administracao/usuarios/assets/acquisition.css?v=20261023-1">
<section class="user-acquisition p-3 p-lg-4 mb-4" data-user-acquisition data-days="<cfoutput>#VARIABLES.userAcquisitionDays#</cfoutput>" aria-labelledby="user-acquisition-title">
  <div class="user-acquisition-header">
    <div><h4 class="h5 mb-1" id="user-acquisition-title">Aquisição de novos usuários</h4><p class="small text-muted mb-0">Novos cadastros por dia · visão geral, independente dos filtros da lista</p></div>
    <div class="user-acquisition-periods" role="group" aria-label="Período de aquisição">
      <cfloop list="7,30,90,365" index="VARIABLES.userAcquisitionOption"><cfoutput><a role="button" data-acquisition-period="#VARIABLES.userAcquisitionOption#" aria-pressed="#VARIABLES.userAcquisitionDays EQ val(VARIABLES.userAcquisitionOption) ? 'true' : 'false'#" class="<cfif VARIABLES.userAcquisitionDays EQ val(VARIABLES.userAcquisitionOption)>is-selected</cfif>" href="?aquisicao_dias=#VARIABLES.userAcquisitionOption#&amp;pagina=#VARIABLES.userManagerPage#&amp;busca=#encodeForURL(VARIABLES.userManagerSearch)#&amp;status=#VARIABLES.userManagerStatus#&amp;papel=#VARIABLES.userManagerRole#">#VARIABLES.userAcquisitionOption# dias</a></cfoutput></cfloop>
    </div>
  </div>
  <cfif VARIABLES.userAcquisitionReady>
    <cfset VARIABLES.userAcquisitionSummary=VARIABLES.userAcquisition.summary>
    <cfoutput>
    <div class="user-acquisition-summary">
      <div><span class="small text-muted">Novos no período</span><strong class="acq-value" data-acquisition-total>#LSNumberFormat(VARIABLES.userAcquisitionSummary.total)#</strong></div>
      <div><span class="small text-muted">Média por dia</span><strong class="acq-value" data-acquisition-average>#numberFormat(VARIABLES.userAcquisitionSummary.average,'0.0')#</strong></div>
      <div><span class="small text-muted">Pico diário</span><strong class="acq-value" data-acquisition-peak>#LSNumberFormat(VARIABLES.userAcquisitionSummary.peak)#</strong><span class="small text-muted" data-acquisition-peak-day><cfif len(VARIABLES.userAcquisitionSummary.peak_day)>#dateFormat(VARIABLES.userAcquisitionSummary.peak_day,'dd/mm/yyyy')#<cfelse>Sem cadastros</cfif></span></div>
    </div>
    <p class="small text-muted mb-1" data-acquisition-range aria-live="polite">#dateFormat(VARIABLES.userAcquisitionSummary.first_day,'dd/mm/yyyy')# a #dateFormat(VARIABLES.userAcquisitionSummary.last_day,'dd/mm/yyyy')# · hoje parcial</p>
    </cfoutput>
    <div class="user-acquisition-plot" data-acquisition-plot tabindex="0" role="img" aria-label="Cadastros diários. Use as setas para consultar cada dia; Home e End vão ao início e ao fim.">
      <svg aria-hidden="true"></svg><div class="user-acquisition-tooltip" data-acquisition-tooltip role="tooltip" hidden></div>
    </div>
    <span class="visually-hidden" aria-live="polite" data-acquisition-announcement></span>
    <p class="small text-muted" data-acquisition-empty <cfif VARIABLES.userAcquisitionSummary.total NEQ 0>hidden</cfif>>Nenhum cadastro no período.</p>
    <p class="small text-warning" data-acquisition-error hidden>Não foi possível desenhar o gráfico. Consulte os valores diários abaixo.</p>
    <noscript><p class="small text-muted">Consulte os valores diários abaixo. Os links de período continuam disponíveis.</p></noscript>
    <details class="user-acquisition-details"><summary>Valores diários e critérios da métrica</summary>
      <p class="mt-2 mb-1">Uma conta por data de cadastro, incluindo inativas e excluídas logicamente. Perfis/páginas não são novos usuários. Contas removidas definitivamente ou mescladas não permanecem neste histórico. A média inclui todos os dias do intervalo, inclusive hoje parcial.</p>
      <p class="mb-0">Horário de Brasília · atualizado em <cfoutput>#encodeForHTML(VARIABLES.userAcquisition.updated_at)#</cfoutput>.</p>
      <div class="user-acquisition-data" tabindex="0" role="region" aria-label="Valores diários de aquisição"><table class="table table-sm mb-0"><caption class="visually-hidden">Cadastros por dia no período selecionado</caption><thead><tr><th scope="col">Data</th><th scope="col" class="text-end">Novos usuários</th></tr></thead><tbody data-acquisition-table-body>
        <cfloop from="#max(1,arrayLen(VARIABLES.userAcquisition.rows)-VARIABLES.userAcquisitionDays+1)#" to="#arrayLen(VARIABLES.userAcquisition.rows)#" index="VARIABLES.userAcquisitionIndex"><cfset VARIABLES.userAcquisitionRow=VARIABLES.userAcquisition.rows[VARIABLES.userAcquisitionIndex]><cfoutput><tr><th scope="row">#dateFormat(VARIABLES.userAcquisitionRow.day,'dd/mm/yyyy')#</th><td>#LSNumberFormat(VARIABLES.userAcquisitionRow.count)#</td></tr></cfoutput></cfloop>
      </tbody></table></div>
    </details>
    <script type="application/json" data-acquisition-data><cfoutput>#serializeJSON(VARIABLES.userAcquisition.rows)#</cfoutput></script>
    <script src="/administracao/usuarios/assets/acquisition.js?v=20261023-1" defer></script>
  <cfelse>
    <p class="small text-warning mt-3 mb-0" role="status">As métricas de aquisição estão temporariamente indisponíveis. A gestão de usuários continua disponível.</p>
  </cfif>
</section>
