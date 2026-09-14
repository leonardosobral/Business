<cfprocessingdirective pageencoding="utf-8"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../includes/seo_queue_backend.cfm"/>
<cfinclude template="../includes/seo_score_backend.cfm"/>

<style>
  .seo-queue { --seo-border: rgba(255,255,255,.14); }
  .seo-queue .seo-subtitle { max-width: 760px; color: var(--mdb-secondary-color); }
  .seo-queue .seo-run-grid, .seo-queue .seo-detail-grid { display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap: 1rem; }
  .seo-queue .seo-run, .seo-queue .seo-filter, .seo-queue .seo-issue { border: 1px solid var(--seo-border); border-radius: 8px; background: rgba(255,255,255,.025); }
  .seo-queue .seo-run, .seo-queue .seo-filter { padding: 1rem; }
  .seo-queue .seo-run-numbers { display: grid; grid-template-columns: repeat(4,minmax(0,1fr)); gap: .75rem; margin: 1rem 0; }
  .seo-queue .seo-run-numbers dt { font-size: .75rem; font-weight: 400; color: var(--mdb-secondary-color); }
  .seo-queue .seo-run-numbers dd { font-size: 1.3rem; font-weight: 650; margin: .25rem 0 0; }
  .seo-queue .seo-label { display: inline-flex; align-items: center; gap: .35rem; border: 1px solid var(--seo-border); border-radius: 5px; padding: .25rem .5rem; font-size: .75rem; line-height: 1.4; }
  .seo-queue .seo-partial, .seo-queue .seo-priority-p1 { color: #ffda86; background: rgba(255,193,7,.1); border-color: rgba(255,193,7,.3); }
  .seo-queue .seo-complete { color: #a0dfd4; background: rgba(40,167,145,.1); border-color: rgba(40,167,145,.3); }
  .seo-queue .seo-priority-p2 { color: #a9d1ff; background: rgba(95,164,242,.08); }
  .seo-queue .seo-priority-p3, .seo-queue .seo-priority-review { color: #d6d6d6; }
  .seo-queue .seo-filter { display: flex; flex-wrap: wrap; gap: 1rem; align-items: end; }
  .seo-queue .seo-filter-field { flex: 1 1 180px; min-width: 0; }
  .seo-queue .seo-filter .form-label { font-size: .85rem; }
  .seo-queue .seo-filter .btn { min-height: 40px; }
  .seo-queue .seo-issue { padding: 1.15rem 1.25rem; margin-bottom: .75rem; }
  .seo-queue .seo-issue-head { display: flex; justify-content: space-between; align-items: start; gap: 1rem; }
  .seo-queue .seo-issue-heading { min-width: 0; }
  .seo-queue .seo-issue-heading h3 { font-size: 1.05rem; margin: .65rem 0 .4rem; line-height: 1.45; }
  .seo-queue .seo-meta { display: flex; flex-wrap: wrap; gap: .4rem; align-items: center; }
  .seo-queue .seo-state { font-size: .75rem; color: var(--mdb-secondary-color); white-space: nowrap; }
  .seo-queue .seo-issue p { margin-bottom: .6rem; }
  .seo-queue .seo-issue details { border-top: 1px solid var(--seo-border); margin-top: .85rem; padding-top: .6rem; }
  .seo-queue .seo-issue summary { cursor: pointer; color: #ffda86; padding: .25rem 0; font-size: .875rem; width: fit-content; }
  .seo-queue .seo-detail-grid { margin-top: 1rem; }
  .seo-queue .seo-detail-grid dt { font-size: .8rem; color: var(--mdb-secondary-color); margin-bottom: .35rem; }
  .seo-queue .seo-detail-grid dd { margin: 0; font-size: .9rem; overflow-wrap: anywhere; white-space: pre-line; }
  .seo-queue .seo-urls { list-style: none; padding-left: 0; margin: .75rem 0 0; }
  .seo-queue .seo-urls li { margin-top: .4rem; }
  .seo-queue .seo-urls a { color: #b9d8ff; overflow-wrap: anywhere; font-size: .875rem; text-decoration: underline; text-underline-offset: 3px; }
  .seo-queue a:focus-visible, .seo-queue summary:focus-visible { outline: 2px solid #ffda86; outline-offset: 4px; }
  .seo-queue .seo-note { font-size: .8rem; line-height: 1.5; color: var(--mdb-secondary-color); }
  .seo-queue .seo-report { margin-bottom: 2rem; }
  .seo-queue .seo-section-head { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: .75rem; margin-bottom: 1rem; }
  .seo-queue .seo-score-card { padding: 1.25rem; }
  .seo-queue .seo-score-main { display: flex; align-items: center; gap: 1.25rem; padding: 1rem 0; }
  .seo-queue .seo-score-number { display: flex; align-items: baseline; gap: .25rem; flex-shrink: 0; }
  .seo-queue .seo-score-value { font-size: 3rem; line-height: 1; font-weight: 750; letter-spacing: -.05em; color: #f3f5f8; }
  .seo-queue .seo-score-max { font-size: 1rem; color: #aab2bd; }
  .seo-queue .seo-score-copy { min-width: 0; }
  .seo-queue .seo-score-copy strong { font-size: .9rem; }
  .seo-queue .seo-status-totals { display: grid; grid-template-columns: repeat(4,minmax(0,1fr)); gap: .5rem; padding: 0; margin: 0 0 1rem; list-style: none; }
  .seo-queue .seo-status-total { border: 1px solid; border-radius: 6px; padding: .6rem .5rem; }
  .seo-queue .seo-status-total strong { display: block; font-size: 1.15rem; line-height: 1.3; }
  .seo-queue .seo-status-total span { display: block; font-size: .7rem; line-height: 1.4; margin-top: .15rem; }
  .seo-queue .seo-status-pass { --seo-status-color: #94e3b0; --seo-status-bg: rgba(83,199,125,.07); --seo-status-border: rgba(83,199,125,.3); }
  .seo-queue .seo-status-warning { --seo-status-color: #ffda86; --seo-status-bg: rgba(255,193,7,.07); --seo-status-border: rgba(255,193,7,.3); }
  .seo-queue .seo-status-error { --seo-status-color: #ffaaa6; --seo-status-bg: rgba(250,100,100,.08); --seo-status-border: rgba(250,100,100,.34); }
  .seo-queue .seo-status-unknown { --seo-status-color: #bcc3cf; --seo-status-bg: rgba(170,180,195,.06); --seo-status-border: rgba(170,180,195,.25); }
  .seo-queue .seo-status-total, .seo-queue .seo-status-badge { color: var(--seo-status-color); background: var(--seo-status-bg); border-color: var(--seo-status-border); }
  .seo-queue .seo-score-card .seo-run-numbers { border-top: 1px solid var(--seo-border); padding-top: 1rem; }
  .seo-queue .seo-report-note { border-left: 3px solid #7992ac; background: rgba(121,146,172,.06); padding: .8rem 1rem; margin-top: 1rem; }
  .seo-queue .seo-method, .seo-queue .seo-checklist, .seo-queue .seo-history { border: 1px solid var(--seo-border); border-radius: 8px; background: rgba(255,255,255,.02); }
  .seo-queue .seo-method { margin: 1rem 0 1.5rem; padding: 0 1rem; }
  .seo-queue .seo-method > summary { cursor: pointer; padding: .9rem 0; font-size: .9rem; font-weight: 600; }
  .seo-queue .seo-method-body { padding: .1rem 0 1rem; max-width: 960px; }
  .seo-queue .seo-method-body p { margin-bottom: .6rem; font-size: .85rem; }
  .seo-queue .seo-method-body p:last-child { margin-bottom: 0; }
  .seo-queue .seo-checklist-grid, .seo-queue .seo-history-grid { display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); align-items: start; gap: 1rem; }
  .seo-queue .seo-checklist { padding: 1.1rem; min-width: 0; }
  .seo-queue .seo-checklist-heading { display: flex; flex-wrap: wrap; gap: .5rem; justify-content: space-between; align-items: baseline; margin-bottom: 1rem; }
  .seo-queue .seo-check-group + .seo-check-group { margin-top: 1.25rem; }
  .seo-queue .seo-check-group-title { color: var(--seo-status-color); font-size: .75rem; letter-spacing: .04em; text-transform: uppercase; font-weight: 650; margin: 0 0 .55rem; }
  .seo-queue .seo-check { border: 1px solid var(--seo-border); border-left: 3px solid var(--seo-status-border); border-radius: 5px; margin-top: .5rem; background: var(--seo-status-bg); }
  .seo-queue .seo-check > summary { display: flex; align-items: flex-start; gap: .6rem; padding: .85rem .8rem; cursor: pointer; list-style: none; }
  .seo-queue .seo-check > summary::-webkit-details-marker { display: none; }
  .seo-queue .seo-check-icon { flex: 0 0 1rem; color: var(--seo-status-color); font-weight: 700; line-height: 1.5; }
  .seo-queue .seo-check-summary { flex: 1; min-width: 0; }
  .seo-queue .seo-check-summary strong { display: block; font-size: .87rem; font-weight: 600; line-height: 1.5; }
  .seo-queue .seo-check-summary-meta { display: flex; flex-wrap: wrap; align-items: center; gap: .35rem .6rem; margin-top: .3rem; }
  .seo-queue .seo-check-summary-meta span { font-size: .7rem; }
  .seo-queue .seo-check-summary-meta .seo-status-text { color: var(--seo-status-color); font-weight: 600; }
  .seo-queue .seo-check-chevron { color: #b7bfca; font-size: .85rem; line-height: 1.5; transition: transform .15s ease; }
  .seo-queue .seo-check[open] > summary .seo-check-chevron { transform: rotate(90deg); }
  .seo-queue .seo-check[open] > summary { border-bottom: 1px solid var(--seo-border); }
  .seo-queue .seo-check-body { padding: .85rem .9rem; }
  .seo-queue .seo-check-body > p { font-size: .83rem; line-height: 1.55; margin: 0 0 .75rem; }
  .seo-queue .seo-check-counts { display: flex; flex-wrap: wrap; gap: .35rem .75rem; font-size: .75rem; margin: .65rem 0; }
  .seo-queue .seo-check-counts span { color: var(--seo-status-color); }
  .seo-queue .seo-check-cases { margin-top: .85rem; }
  .seo-queue .seo-check-cases strong { font-size: .75rem; color: var(--seo-status-color); }
  .seo-queue .seo-check-cases .seo-urls { margin-top: .3rem; }
  .seo-queue .seo-check-cases .seo-urls a { font-size: .75rem; line-height: 1.5; }
  .seo-queue .seo-history-grid { margin-top: 1rem; }
  .seo-queue .seo-history { padding: 1rem; min-width: 0; }
  .seo-queue .seo-history .table { margin: .75rem 0; --mdb-table-bg: transparent; }
  .seo-queue .seo-history th { font-size: .72rem; color: #aab2bd; font-weight: 500; }
  .seo-queue .seo-history td { font-size: .78rem; vertical-align: middle; }
  .seo-queue .seo-history th, .seo-queue .seo-history td { padding: .7rem .3rem; border-color: var(--seo-border); }
  .seo-queue .seo-history td:first-child { width: 48%; }
  .seo-queue .seo-history td:nth-child(2) { white-space: nowrap; font-weight: 650; }
  .seo-queue .seo-history .seo-note { margin-bottom: 0; }
  @media (max-width: 767px) {
    .seo-queue .seo-run-grid, .seo-queue .seo-detail-grid, .seo-queue .seo-checklist-grid, .seo-queue .seo-history-grid { grid-template-columns: 1fr; }
    .seo-queue .seo-score-card, .seo-queue .seo-checklist { padding: 1rem; }
    .seo-queue .seo-score-value { font-size: 2.65rem; }
    .seo-queue .seo-score-main { gap: 1rem; }
    .seo-queue .seo-status-totals { grid-template-columns: repeat(2,minmax(0,1fr)); }
    .seo-queue .seo-status-total strong, .seo-queue .seo-status-total span { display: inline; }
    .seo-queue .seo-status-total span { margin-left: .35rem; }
    .seo-queue .seo-run-numbers { grid-template-columns: repeat(2,minmax(0,1fr)); }
    .seo-queue .seo-issue { padding: 1rem; }
    .seo-queue .seo-issue-head { flex-direction: column; gap: .5rem; }
    .seo-queue .seo-filter-field { flex-basis: 100%; }
    .seo-queue .seo-filter .btn { flex: 1; }
  }
</style>

<section class="card shadow-0 mb-4">
  <div class="card-body seo-queue">
    <div class="d-flex flex-wrap justify-content-between gap-3 align-items-start">
      <div>
        <h1 class="h3 mb-2">SEO</h1>
        <p class="seo-subtitle mb-0">Acompanhe o que está certo, o que precisa de atenção e as correções do Road Runners e do Open Results.</p>
      </div>
      <div class="small text-muted">Revisão da fila<br><strong><cfoutput>#encodeForHtml(VARIABLES.seoQueueSnapshot.updatedLabel)#</cfoutput></strong></div>
    </div>
    <div class="mt-4"><cfinclude template="seo_report.cfm"/></div>

    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
      <h2 class="h5 mb-0">Fila de correções</h2>
      <span class="small text-muted"><cfoutput>#VARIABLES.seoQueueTotal# frentes · #VARIABLES.seoQueueOpenTotal# #VARIABLES.seoQueueOpenTotal EQ 1 ? 'pendente' : 'pendentes'# · #VARIABLES.seoQueueResolvedTotal# #VARIABLES.seoQueueResolvedTotal EQ 1 ? 'concluída' : 'concluídas'# · #VARIABLES.seoQueueHighPriorityTotal# #VARIABLES.seoQueueHighPriorityTotal EQ 1 ? 'pendente' : 'pendentes'# de prioridade alta</cfoutput></span>
    </div>
    <form class="seo-filter mb-3" method="get" action="/portal/seo/">
      <cfoutput><input type="hidden" name="verificacao" value="#encodeForHtmlAttribute(VARIABLES.seoScoreFilter)#"/></cfoutput>
      <div class="seo-filter-field">
        <label class="form-label" for="seo-site">Site</label>
        <select class="form-select" id="seo-site" name="site">
          <option value="all"<cfif VARIABLES.seoQueueSiteFilter EQ "all"> selected</cfif>>Todos os sites</option>
          <option value="roadrunners"<cfif VARIABLES.seoQueueSiteFilter EQ "roadrunners"> selected</cfif>>Road Runners</option>
          <option value="openresults"<cfif VARIABLES.seoQueueSiteFilter EQ "openresults"> selected</cfif>>Open Results</option>
        </select>
      </div>
      <div class="seo-filter-field">
        <label class="form-label" for="seo-priority">Prioridade</label>
        <select class="form-select" id="seo-priority" name="prioridade">
          <option value="all"<cfif VARIABLES.seoQueuePriorityFilter EQ "all"> selected</cfif>>Todas as prioridades</option>
          <option value="p1"<cfif VARIABLES.seoQueuePriorityFilter EQ "p1"> selected</cfif>>P1 · Alta</option>
          <option value="p2"<cfif VARIABLES.seoQueuePriorityFilter EQ "p2"> selected</cfif>>P2 · Correção técnica</option>
          <option value="p3"<cfif VARIABLES.seoQueuePriorityFilter EQ "p3"> selected</cfif>>P3 · Melhoria de estrutura</option>
          <option value="review"<cfif VARIABLES.seoQueuePriorityFilter EQ "review"> selected</cfif>>Decisão de política</option>
        </select>
      </div>
      <button class="btn btn-warning" type="submit">Filtrar</button>
      <a class="btn btn-link text-reset" href="<cfoutput>/portal/seo/?verificacao=#encodeForHtmlAttribute(VARIABLES.seoScoreFilter)#</cfoutput>">Limpar filtros da fila</a>
    </form>
    <p class="small text-muted mb-3" role="status"><cfoutput>Exibindo #arrayLen(VARIABLES.seoQueueItems)# de #VARIABLES.seoQueueTotal# frentes.</cfoutput></p>

    <cfif NOT arrayLen(VARIABLES.seoQueueItems)>
      <div class="alert alert-secondary mb-0">Nenhuma frente corresponde a esses filtros. Escolha outro site ou outra prioridade para consultar a fila.</div>
    <cfelse>
      <cfloop array="#VARIABLES.seoQueueItems#" index="seoItem">
        <cfoutput>
          <article class="seo-issue" id="#encodeForHtmlAttribute(seoItem.id)#">
            <div class="seo-issue-head">
              <div class="seo-issue-heading">
                <div class="seo-meta">
                  <span class="seo-label seo-priority-#encodeForHtmlAttribute(seoItem.priority)#">#encodeForHtml(seoItem.priorityLabel)#</span>
                  <cfloop array="#seoItem.sites#" index="seoSite"><span class="seo-label">#seoSite EQ 'roadrunners' ? 'Road Runners' : 'Open Results'#</span></cfloop>
                  <span class="small text-muted">#encodeForHtml(seoItem.id)#</span>
                </div>
                <h3>#encodeForHtml(seoItem.title)#</h3>
              </div>
              <span class="seo-state">#encodeForHtml(seoItem.stateLabel)#</span>
            </div>
            <p class="small mb-0">#encodeForHtml(seoItem.summary)#</p>
            <details>
              <summary>Ver evidência e critérios</summary>
              <dl class="seo-detail-grid">
                <div><dt>O que foi observado</dt><dd>#encodeForHtml(seoItem.evidence)#</dd></div>
                <div><dt>Por que tratar</dt><dd>#encodeForHtml(seoItem.impact)#</dd></div>
                <div><dt>Responsável pela frente</dt><dd>#encodeForHtml(seoItem.owner)#</dd></div>
                <div><dt>Critério de conclusão</dt><dd>#encodeForHtml(seoItem.acceptance)#</dd></div>
              </dl>
              <ul class="seo-urls" aria-label="URLs de referência">
                <cfloop array="#seoItem.urls#" index="seoLink"><li><a href="#encodeForHtmlAttribute(seoLink.url)#" target="_blank" rel="noopener noreferrer">#encodeForHtml(seoLink.label)# <i class="fa-solid fa-arrow-up-right-from-square ms-1" aria-hidden="true"></i></a><div class="seo-note">#encodeForHtml(seoLink.url)#</div></li></cfloop>
              </ul>
            </details>
          </article>
        </cfoutput>
      </cfloop>
    </cfif>
    <p class="seo-note mt-3 mb-0">As frentes agrupam avisos e falhas com a mesma causa. Uma correção só deve ser encerrada depois de publicada e conferida nas páginas afetadas.</p>
  </div>
</section>
