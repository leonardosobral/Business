<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
  <cfheader statuscode="403" statustext="Forbidden"/>
  <cfabort/>
</cfif>
<cfif structKeyExists(CGI, "request_method") AND compareNoCase(CGI.request_method, "GET") NEQ 0>
  <cfheader statuscode="405" statustext="Method Not Allowed"/>
  <cfheader name="Allow" value="GET"/>
  <cfabort/>
</cfif>

<div class="seo-report">
  <div class="seo-section-head">
    <h2 class="h5 mb-0">Auditorias por site</h2>
    <span class="seo-label">Nota técnica interna · 0 a 100</span>
  </div>
  <div class="seo-run-grid">
    <cfloop array="#VARIABLES.seoScoreSnapshot.sites#" index="seoScoreSite">
      <cfoutput>
        <section class="seo-run seo-score-card" data-seo-site="#encodeForHtmlAttribute(seoScoreSite.id)#" aria-label="Auditoria #encodeForHtmlAttribute(seoScoreSite.label)#">
          <div class="d-flex flex-wrap align-items-center justify-content-between gap-2">
            <h3 class="h5 mb-0">#encodeForHtml(seoScoreSite.label)#</h3>
            <span class="seo-label #seoScoreSite.discoveryComplete ? 'seo-complete' : 'seo-partial'#">#seoScoreSite.discoveryComplete ? 'Descoberta completa dos sitemaps' : 'Cobertura incompleta'#</span>
          </div>
          <p class="seo-note mt-2 mb-0">Auditoria: #encodeForHtml(seoScoreSite.auditLabel)#</p>
          <div class="seo-score-main">
            <div class="seo-score-number" aria-label="Nota #encodeForHtmlAttribute(seoScoreSite.scoreLabel)# de 100">
              <span class="seo-score-value">#encodeForHtml(seoScoreSite.scoreLabel)#</span><span class="seo-score-max">/100</span>
            </div>
            <div class="seo-score-copy">
              <strong>Nota da amostra auditada</strong>
              <p class="seo-note mb-0 mt-1">#encodeForHtml(seoScoreSite.scopeLabel)#</p>
            </div>
          </div>
          <ul class="seo-status-totals" aria-label="Resultado das verificações de #encodeForHtmlAttribute(seoScoreSite.label)#">
            <cfloop array="#VARIABLES.seoScoreStatuses#" index="seoScoreStatus">
              <li class="seo-status-total seo-status-#encodeForHtmlAttribute(seoScoreStatus.id)#"><strong>#seoScoreSite.counts[seoScoreStatus.id]#</strong><span><span class="d-inline" aria-hidden="true">#encodeForHtml(seoScoreStatus.icon)#</span> #encodeForHtml(seoScoreStatus.label)#</span></li>
            </cfloop>
          </ul>
          <p class="seo-note mb-0">Contagens de critérios, incluindo verificações fora da nota. Evidências avaliadas nos critérios pontuados: #encodeForHtml(seoScoreSite.coverageLabel)#.</p>
          <dl class="seo-run-numbers">
            <div><dt>Páginas analisadas</dt><dd>#replace(numberFormat(seoScoreSite.inspected, ','), ',', '.', 'all')#</dd></div>
            <div><dt>URLs coletadas</dt><dd>#replace(numberFormat(seoScoreSite.discovered, ','), ',', '.', 'all')#</dd></div>
            <div><dt>Falhas na coleta</dt><dd>#seoScoreSite.operationalErrors#</dd></div>
            <div><dt>Avisos nas páginas</dt><dd>#seoScoreSite.warnings#</dd></div>
          </dl>
          <p class="seo-note mb-2">#encodeForHtml(seoScoreSite.coverageNote)#</p>
          <p class="seo-note mb-0">#seoScoreSite.pageErrors# #seoScoreSite.pageErrors EQ 1 ? 'erro' : 'erros'# nas páginas analisadas.</p>
        </section>
      </cfoutput>
    </cfloop>
  </div>
  <p class="seo-note seo-report-note mb-0">A nota representa a auditoria na data indicada. Correções verificadas depois dessa coleta aparecem na fila abaixo e só alteram a nota após uma nova auditoria. Recarregar a tela não executa uma coleta. A amostra não permite concluir que todo o site está correto.</p>

  <details class="seo-method">
    <summary>Como a pontuação é calculada</summary>
    <div class="seo-method-body">
      <cfoutput>
        <p><strong>#encodeForHtml(VARIABLES.seoScoreSnapshot.methodLabel)#</strong> · #encodeForHtml(VARIABLES.seoScoreSnapshot.methodVersion)#</p>
        <p>#encodeForHtml(VARIABLES.seoScoreSnapshot.formula)#</p>
        <p>#encodeForHtml(VARIABLES.seoScoreSnapshot.methodNote)#</p>
      </cfoutput>
      <p>Cada critério assume o pior resultado observado: correto vale 100% do peso, atenção vale 50% e erro vale 0%. Critérios sem medição ficam fora do cálculo. Os pesos aparecem em cada verificação.</p>
      <p>Esta é uma estimativa interna de condições técnicas, sem equivalência com a nota do WooRank, do Semrush ou do Google. Não mede posição na busca. Presença no sitemap, HTTP 200 e canonical declarado não comprovam indexação.</p>
    </div>
  </details>

  <div class="seo-section-head">
    <div>
      <h2 class="h5 mb-1">Relatório de verificações</h2>
      <p class="seo-note mb-0">Os acertos também ficam registrados. Abra uma verificação para consultar contagens, limites e exemplos.</p>
    </div>
  </div>
  <form class="seo-filter mb-3" method="get" action="/portal/seo/">
    <cfoutput>
      <input type="hidden" name="site" value="#encodeForHtmlAttribute(VARIABLES.seoQueueSiteFilter)#"/>
      <input type="hidden" name="prioridade" value="#encodeForHtmlAttribute(VARIABLES.seoQueuePriorityFilter)#"/>
    </cfoutput>
    <div class="seo-filter-field">
      <label class="form-label" for="seo-check-status">Filtrar verificações</label>
      <select class="form-select" id="seo-check-status" name="verificacao">
        <option value="all"<cfif VARIABLES.seoScoreFilter EQ 'all'> selected</cfif>>Todas as verificações</option>
        <cfloop array="#VARIABLES.seoScoreStatuses#" index="seoScoreStatus">
          <cfoutput><option value="#encodeForHtmlAttribute(seoScoreStatus.id)#"<cfif VARIABLES.seoScoreFilter EQ seoScoreStatus.id> selected</cfif>>#encodeForHtml(seoScoreStatus.label)#</option></cfoutput>
        </cfloop>
      </select>
    </div>
    <button class="btn btn-warning" type="submit">Aplicar às verificações</button>
  </form>
  <p class="seo-note mb-3" role="status"><cfoutput>Exibindo #VARIABLES.seoScoreVisibleTotal# #VARIABLES.seoScoreVisibleTotal EQ 1 ? 'verificação' : 'verificações'#.</cfoutput> Este filtro altera apenas as listas abaixo; as notas, os totais por site e a fila de correções permanecem independentes.</p>

  <div class="seo-checklist-grid">
    <cfloop array="#VARIABLES.seoScoreSnapshot.sites#" index="seoScoreSite">
      <cfoutput>
        <section class="seo-checklist" data-seo-site="#encodeForHtmlAttribute(seoScoreSite.id)#" aria-label="Verificações de #encodeForHtmlAttribute(seoScoreSite.label)#">
          <div class="seo-checklist-heading">
            <h3 class="h6 mb-0">#encodeForHtml(seoScoreSite.label)#</h3>
            <span class="seo-note">#seoScoreSite.visibleCount# de #arrayLen(seoScoreSite.criteria)# verificações</span>
          </div>
          <cfif NOT seoScoreSite.visibleCount>
            <p class="seo-note mb-0">Nenhuma verificação deste site corresponde ao filtro selecionado.</p>
          <cfelse>
            <cfloop array="#VARIABLES.seoScoreStatuses#" index="seoScoreStatus">
              <cfset seoReportGroupCount = 0/>
              <cfloop array="#seoScoreSite.visibleCriteria#" index="seoCriterion">
                <cfif seoCriterion.status EQ seoScoreStatus.id><cfset seoReportGroupCount++/></cfif>
              </cfloop>
              <cfif seoReportGroupCount GT 0>
                <div class="seo-check-group seo-status-#encodeForHtmlAttribute(seoScoreStatus.id)#">
                  <h4 class="seo-check-group-title"><span aria-hidden="true">#encodeForHtml(seoScoreStatus.icon)#</span> #encodeForHtml(seoScoreStatus.label)# · #seoReportGroupCount#</h4>
                  <cfloop array="#seoScoreSite.visibleCriteria#" index="seoCriterion">
                    <cfif seoCriterion.status EQ seoScoreStatus.id>
                      <details class="seo-check seo-status-#encodeForHtmlAttribute(seoCriterion.status)#" data-seo-check="#encodeForHtmlAttribute(seoCriterion.id)#" data-seo-status="#encodeForHtmlAttribute(seoCriterion.status)#">
                        <summary>
                          <span class="seo-check-icon" aria-hidden="true">#encodeForHtml(seoCriterion.icon)#</span>
                          <span class="seo-check-summary">
                            <strong>#encodeForHtml(seoCriterion.label)#</strong>
                            <span class="seo-check-summary-meta">
                              <span class="seo-status-text">#encodeForHtml(seoCriterion.statusLabel)#</span>
                              <span class="seo-note"><cfif seoCriterion.weight GT 0>Peso #seoCriterion.weight#<cfelse>Fora da nota</cfif></span>
                              <cfif seoCriterion.partial><span class="seo-note">Medição parcial</span></cfif>
                            </span>
                          </span>
                          <span class="seo-check-chevron" aria-hidden="true">›</span>
                        </summary>
                        <div class="seo-check-body">
                          <p>#encodeForHtml(seoCriterion.note)#</p>
                          <cfif seoCriterion.total GT 0>
                            <div class="seo-check-counts" aria-label="Contagem das observações">
                              <cfloop array="#VARIABLES.seoScoreStatuses#" index="seoCaseStatus">
                                <span class="seo-status-#encodeForHtmlAttribute(seoCaseStatus.id)#">#seoCriterion[seoCaseStatus.id]# #encodeForHtml(lCase(seoCaseStatus.label))#</span>
                              </cfloop>
                            </div>
                            <p class="seo-note mb-0">#seoCriterion.known# de #seoCriterion.total# observações com resultado conhecido para este critério.<cfif seoCriterion.weight EQ 0> Verificação informativa, sem efeito na pontuação.</cfif></p>
                          </cfif>
                          <cfloop array="#VARIABLES.seoScoreStatuses#" index="seoCaseStatus">
                            <cfif arrayLen(seoCriterion.cases[seoCaseStatus.id]) GT 0>
                              <div class="seo-check-cases seo-status-#encodeForHtmlAttribute(seoCaseStatus.id)#">
                                <strong>#encodeForHtml(seoCaseStatus.label)# · exemplos da auditoria</strong>
                                <ul class="seo-urls">
                                  <cfloop from="1" to="#min(3, arrayLen(seoCriterion.cases[seoCaseStatus.id]))#" index="seoCaseIndex">
                                    <cfset seoCaseUrl = seoCriterion.cases[seoCaseStatus.id][seoCaseIndex]/>
                                    <li><a href="#encodeForHtmlAttribute(seoCaseUrl)#" target="_blank" rel="noopener noreferrer">#encodeForHtml(seoCaseUrl)# <span aria-hidden="true">↗</span><span class="visually-hidden"> (abre em nova aba)</span></a></li>
                                  </cfloop>
                                </ul>
                              </div>
                            </cfif>
                          </cfloop>
                        </div>
                      </details>
                    </cfif>
                  </cfloop>
                </div>
              </cfif>
            </cfloop>
          </cfif>
        </section>
      </cfoutput>
    </cfloop>
  </div>

  <div class="seo-section-head mt-4 mb-0">
    <div>
      <h2 class="h5 mb-1">Histórico da pontuação</h2>
      <p class="seo-note mb-0">A evolução só é comparada entre auditorias com o mesmo método e uma amostra comparável.</p>
    </div>
  </div>
  <div class="seo-history-grid">
    <cfloop array="#VARIABLES.seoScoreSnapshot.sites#" index="seoScoreSite">
      <cfoutput>
        <section class="seo-history" data-seo-site="#encodeForHtmlAttribute(seoScoreSite.id)#" aria-label="Histórico de #encodeForHtmlAttribute(seoScoreSite.label)#">
          <h3 class="h6 mb-0">#encodeForHtml(seoScoreSite.label)#</h3>
          <table class="table table-sm">
            <caption class="visually-hidden">Histórico da nota técnica de #encodeForHtml(seoScoreSite.label)#</caption>
            <thead><tr><th scope="col">Auditoria</th><th scope="col">Nota</th><th scope="col">Evolução</th></tr></thead>
            <tbody>
              <cfloop array="#seoScoreSite.history#" index="seoHistoryPoint">
                <tr><td>#encodeForHtml(seoHistoryPoint.auditLabel)#</td><td>#encodeForHtml(seoHistoryPoint.scoreLabel)# / 100</td><td>#encodeForHtml(seoHistoryPoint.deltaLabel)#</td></tr>
              </cfloop>
            </tbody>
          </table>
          <p class="seo-note">#encodeForHtml(seoScoreSite.historyNote)#</p>
        </section>
      </cfoutput>
    </cfloop>
  </div>
</div>
