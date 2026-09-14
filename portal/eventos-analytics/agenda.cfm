<!--- Included by home.cfm after its authorized agenda reader succeeds. --->
<cfinclude template="../../includes/backend/require_admin.cfm">
<style>
.event-interest .ei-agenda-kpis{grid-template-columns:repeat(3,minmax(0,1fr))}
@media(max-width:767px){.event-interest .ei-agenda-kpis{grid-template-columns:1fr 1fr}.event-interest .ei-agenda-kpis .ei-kpi:first-child{grid-column:1/-1}}
</style>
<cfoutput>
<div class="ei-note ei-muted">Agenda consultada em #encodeForHTML(ei.meta.until)# · Brasília · Atualização em até 1 minuto.</div>
<cfif len(VARIABLES.eiFilters.evento_id)><div class="ei-panel mt-3 mb-2">Agenda da prova ###encodeForHTML(VARIABLES.eiFilters.evento_id)# <a class="ms-3" href="#encodeForHTMLAttribute(eventInterestUrl({evento_id='',p=1}))#">Voltar a todas as provas</a></div></cfif>
<div class="ei-kpis ei-agenda-kpis">
  <div class="ei-kpi"><span class="ei-muted">Provas com interesse</span><strong class="ei-value" data-metric="agenda-events">#eventInterestNumber(ei.summary.events)#</strong><small class="ei-muted">Hoje e futuras, com pelo menos 1 atleta na agenda</small></div>
  <div class="ei-kpi"><span class="ei-muted">Atletas com provas salvas</span><strong class="ei-value" data-metric="agenda-athletes">#eventInterestNumber(ei.summary.athletes)#</strong><small class="ei-muted">Cada atleta conta uma vez neste recorte</small></div>
  <div class="ei-kpi"><span class="ei-muted">Provas para revisar</span><strong class="ei-value" data-metric="agenda-gaps">#eventInterestNumber(ei.summary.gaps)#</strong><small class="ei-muted">Com interesse em agenda e campos faltando</small></div>
</div>
<div class="ei-panel">
  <h2 class="h5">Provas futuras mais salvas</h2>
  <p class="ei-note ei-muted">Atletas que mantêm a prova na agenda, unificando os tipos de interesse sem duplicar pessoas. Inclui provas de hoje e em andamento, ativas e não canceladas. Ordem: mais atletas, depois data da prova.</p>
  <p class="ei-note ei-muted">Agenda é o saldo atual do ecossistema, não inscrições pagas nem novas inclusões no período. Período e tráfego filtram somente os acessos no Road Runners: #encodeForHTML(ei.meta.since)# a #encodeForHTML(ei.meta.until)# · Brasília · Hoje é parcial.</p>
  <cfif arrayLen(ei.ranking)>
  <div class="ei-scroll" tabindex="0" aria-label="Tabela de provas salvas; role horizontalmente em telas pequenas">
    <table class="ei-table"><thead><tr><th>Prova</th><th class="ei-num">Agenda atual</th><th class="ei-num">Aberturas · #ei.meta.days# dias</th><th class="ei-num">Visitantes · #ei.meta.days# dias</th><th>Revisar</th></tr></thead><tbody>
    <cfloop array="#ei.ranking#" index="eiRow"><tr>
      <td class="ei-title"><cfif len(eiRow.tag)><a href="https://roadrunners.run/evento/#encodeForURL(eiRow.tag)#/" target="_blank" rel="noopener"><strong>#encodeForHTML(eiRow.event_name)#</strong></a><cfelse><strong>#encodeForHTML(eiRow.event_name)#</strong></cfif><div class="ei-note ei-muted">#encodeForHTML(eiRow.city)#<cfif len(eiRow.uf)> / #encodeForHTML(eiRow.uf)#</cfif> · #encodeForHTML(eiRow.event_date)#</div><a class="ei-note" href="#encodeForHTMLAttribute(eventInterestUrl({evento_id=eiRow.content_id,p=1,aba='ranking'}))#">Ver acessos →</a></td>
      <td class="ei-num"><strong>#eventInterestNumber(eiRow.athletes)# atletas na agenda</strong></td>
      <td class="ei-num">#eventInterestNumber(eiRow.pageviews)#<cfif eiRow.pageviews EQ 0><div class="ei-note ei-muted">Sem aberturas medidas</div></cfif></td>
      <td class="ei-num">#eventInterestNumber(eiRow.visitors)#</td>
      <td style="min-width:160px"><cfif arrayLen(eiRow.missing_fields)><div class="ei-note ei-warn">#encodeForHTML(arrayToList(eiRow.missing_fields,', '))#</div><a class="ei-note" href="/admin/?periodo=#eiRow.event_year#&amp;id_evento=#encodeForURL(eiRow.content_id)#">Revisar cadastro →</a><cfelse><span class="ei-note ei-muted">Sem pendências nos campos verificados</span></cfif></td>
    </tr></cfloop></tbody></table>
  </div>
  <cfelse><p class="ei-muted mb-0">Nenhuma prova futura com atletas na agenda encontrada para estes filtros.</p></cfif>
  <div class="ei-pagination ei-note"><span class="ei-muted">#eventInterestNumber(ei.summary.events)# provas · até 50 por página · página #VARIABLES.eiFilters.p#</span><div><cfif val(VARIABLES.eiFilters.p) GT 1><a class="btn btn-sm btn-outline-light me-2" href="#encodeForHTMLAttribute(eventInterestUrl({p=val(VARIABLES.eiFilters.p)-1}))#">Anterior</a></cfif><cfif val(VARIABLES.eiFilters.p)*50 LT ei.summary.events><a class="btn btn-sm btn-outline-light" href="#encodeForHTMLAttribute(eventInterestUrl({p=val(VARIABLES.eiFilters.p)+1}))#">Próxima</a></cfif></div></div>
</div>
</cfoutput>
