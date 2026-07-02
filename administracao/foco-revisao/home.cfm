<style>
  .foco-review-page .foco-review-candidate {
    border-top: 1px solid rgba(255,255,255,.08);
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: 1rem;
    padding: .9rem 0;
  }
  .foco-review-page .foco-review-flags { display: flex; flex-wrap: wrap; gap: .35rem; }
  .foco-review-page .foco-review-flag { border: 1px solid rgba(255,255,255,.14); border-radius: 999px; font-size: .72rem; padding: .15rem .45rem; }
  .foco-review-page .foco-review-flag.is-match { border-color: rgba(25,135,84,.7); color: #75d6a5; }
  .foco-review-page .foco-review-score-high { background: rgba(25,135,84,.18); color: #75d6a5; border: 1px solid rgba(25,135,84,.45); }
  .foco-review-page .foco-review-score-mid { background: rgba(255,193,7,.16); color: #ffd76d; border: 1px solid rgba(255,193,7,.42); }
  .foco-review-page .foco-review-score-low { background: rgba(220,53,69,.16); color: #ff9aa8; border: 1px solid rgba(220,53,69,.42); }
  .foco-review-page .foco-review-external-link {
    color: inherit;
    opacity: .72;
    text-decoration: none;
  }
  .foco-review-page:focus { outline: none; }
  .foco-review-page .foco-review-external-link:hover { opacity: 1; color: #ffc107; }
  @media (max-width: 767px) {
    .foco-review-page .foco-review-candidate { grid-template-columns: 1fr; }
  }
</style>

<section class="foco-review-page business-page pb-5" id="focoReviewShortcutScope" tabindex="-1">
  <div class="business-page-header pt-5 pb-3 d-flex flex-wrap justify-content-between align-items-end gap-3">
    <div>
      <div class="text-warning text-uppercase small fw-bold">Administração</div>
      <h1 class="business-page-title mb-1">Revisão Foco Radical</h1>
      <p class="text-muted mb-0">Valide candidatos ambíguos antes de criar vínculos visíveis no site.</p>
      <div class="small text-muted mt-2">
        Atalhos: <kbd>V</kbd> vincula a primeira galeria acionável · <kbd>I</kbd> ignora a primeira galeria acionável
      </div>
    </div>
    <a class="btn btn-outline-light btn-sm" href="/administracao/cron-jobs/">Cron Jobs</a>
  </div>

  <cfif len(VARIABLES.focoReviewNotice)>
    <div class="alert alert-success"><cfoutput>#htmlEditFormat(VARIABLES.focoReviewNotice)#</cfoutput></div>
  </cfif>
  <cfif len(VARIABLES.focoReviewError)>
    <div class="alert alert-danger">
      <cfoutput>
        <div class="fw-bold">#htmlEditFormat(VARIABLES.focoReviewError)#</div>
        <cfif VARIABLES.focoReviewConflictEventId GT 0>
          <cfset VARIABLES.focoReviewConflictRoadRunnersUrl = len(VARIABLES.focoReviewConflictEventTag)
            ? "https://roadrunners.run/evento/#urlEncodedFormat(VARIABLES.focoReviewConflictEventTag)#/"
            : "" />
          <cfset VARIABLES.focoReviewConflictFocoUrl = "" />
          <cfif len(VARIABLES.focoReviewConflictCompetitionPath)>
            <cfif findNoCase("http", VARIABLES.focoReviewConflictCompetitionPath) EQ 1>
              <cfset VARIABLES.focoReviewConflictFocoUrl = VARIABLES.focoReviewConflictCompetitionPath />
            <cfelseif left(VARIABLES.focoReviewConflictCompetitionPath, 1) EQ "/">
              <cfset VARIABLES.focoReviewConflictFocoUrl = "https://www.focoradical.com.br#VARIABLES.focoReviewConflictCompetitionPath#" />
            <cfelse>
              <cfset VARIABLES.focoReviewConflictFocoUrl = "https://www.focoradical.com.br/prova/#urlEncodedFormat(VARIABLES.focoReviewConflictCompetitionPath)#" />
            </cfif>
          <cfelseif len(VARIABLES.focoReviewConflictCompetitionId)>
            <cfset VARIABLES.focoReviewConflictFocoUrl = "https://www.focoradical.com.br/competition/upload-selfie?competition_id=#urlEncodedFormat(VARIABLES.focoReviewConflictCompetitionId)#" />
          </cfif>
          <div class="mt-2">
            Vinculada atualmente ao evento
            <strong>###VARIABLES.focoReviewConflictEventId# - #htmlEditFormat(VARIABLES.focoReviewConflictEventName)#</strong>
            <cfif len(VARIABLES.focoReviewConflictRoadRunnersUrl)>
              <a class="foco-review-external-link ms-1" href="#htmlEditFormat(VARIABLES.focoReviewConflictRoadRunnersUrl)#" target="_blank" rel="noopener noreferrer" title="Abrir evento no Road Runners"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
            </cfif>
            <cfif len(VARIABLES.focoReviewConflictFocoUrl)>
              <a class="foco-review-external-link ms-1" href="#htmlEditFormat(VARIABLES.focoReviewConflictFocoUrl)#" target="_blank" rel="noopener noreferrer" title="Abrir evento na Foco Radical"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
            </cfif>.
          </div>
          <form method="post" class="d-flex flex-wrap gap-2 align-items-center mt-3" onsubmit="return confirm('Desvincular esta competição Foco do evento informado? Esta ação remove o badge Foco e recoloca o evento anterior para reprocessamento.');">
            <input type="hidden" name="acao" value="desvincular_foco" />
            <input type="hidden" name="id_evento_conflito" value="#VARIABLES.focoReviewConflictEventId#" />
            <input type="hidden" name="competition_id" value="#htmlEditFormat(VARIABLES.focoReviewConflictCompetitionId)#" />
            <input class="form-control form-control-sm flex-grow-1" style="min-width:240px" name="observacao" placeholder="Observação sobre a desvinculação" />
            <button class="btn btn-outline-light btn-sm"><i class="fa-solid fa-link-slash me-1"></i> Desvincular</button>
          </form>
        </cfif>
      </cfoutput>
    </div>
  </cfif>
  <cfif !VARIABLES.focoReviewSchemaReady>
    <div class="alert alert-warning">Aplique novamente <code>/api/foco/jobs/foco_match_schema.sql</code> no banco RunnerHub.</div>
  <cfelse>
    <div class="foco-review-kpis mb-4">
      <div class="foco-review-kpi"><small>Para revisão</small><strong><cfoutput>#qFocoReviewStats.review#</cfoutput></strong></div>
      <div class="foco-review-kpi"><small>Conflitos</small><strong><cfoutput>#qFocoReviewStats.conflict#</cfoutput></strong></div>
      <div class="foco-review-kpi"><small>Vinculados</small><strong><cfoutput>#qFocoReviewStats.linked#</cfoutput></strong></div>
      <div class="foco-review-kpi"><small>Descartados</small><strong><cfoutput>#qFocoReviewStats.dismissed#</cfoutput></strong></div>
    </div>

    <form class="card shadow-0 mb-4 business-page-card" method="get">
      <div class="card-body business-page-body row g-3 align-items-end">
        <div class="col-12 col-lg-5">
          <label class="form-label">Evento, ID ou competição</label>
          <input class="form-control" name="busca" value="<cfoutput>#htmlEditFormat(VARIABLES.focoReviewSearch)#</cfoutput>" />
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Status</label>
          <select class="form-select" name="status">
            <option value="review" <cfif VARIABLES.focoReviewStatus EQ "review">selected</cfif>>Para revisão</option>
            <option value="conflict" <cfif VARIABLES.focoReviewStatus EQ "conflict">selected</cfif>>Conflitos</option>
            <option value="linked" <cfif VARIABLES.focoReviewStatus EQ "linked">selected</cfif>>Vinculados</option>
            <option value="dismissed" <cfif VARIABLES.focoReviewStatus EQ "dismissed">selected</cfif>>Descartados</option>
            <option value="all" <cfif VARIABLES.focoReviewStatus EQ "all">selected</cfif>>Todos</option>
          </select>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Ordenar por</label>
          <select class="form-select" name="ordenar">
            <option value="atualizacao" <cfif VARIABLES.focoReviewOrder EQ "atualizacao">selected</cfif>>Atualização</option>
            <option value="score" <cfif VARIABLES.focoReviewOrder EQ "score">selected</cfif>>Score</option>
          </select>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Direção</label>
          <select class="form-select" name="direcao">
            <option value="desc" <cfif VARIABLES.focoReviewDirection EQ "desc">selected</cfif>>Maior primeiro</option>
            <option value="asc" <cfif VARIABLES.focoReviewDirection EQ "asc">selected</cfif>>Menor primeiro</option>
          </select>
        </div>
        <div class="col-6 col-lg-1"><button class="btn btn-warning w-100">Filtrar</button></div>
      </div>
    </form>

    <div class="d-grid gap-3">
      <cfoutput query="qFocoReviewItems">
        <cfset VARIABLES.focoReviewRoadRunnersUrl = len(trim(tag & ""))
          ? "https://roadrunners.run/evento/#urlEncodedFormat(trim(tag & ""))#/"
          : "" />
        <article class="foco-review-case">
          <div class="d-flex flex-wrap justify-content-between gap-3 mb-2">
            <div>
              <div class="small text-muted">Evento ###id_evento#</div>
              <h2 class="h5 mb-1">
                #htmlEditFormat(nome_evento)#
                <cfif len(VARIABLES.focoReviewRoadRunnersUrl)>
                  <a class="foco-review-external-link ms-1" href="#htmlEditFormat(VARIABLES.focoReviewRoadRunnersUrl)#" target="_blank" rel="noopener noreferrer" title="Abrir evento no Road Runners"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
                </cfif>
              </h2>
              <div class="small text-muted">#lsDateFormat(data_inicial, "dd/mm/yyyy")#<cfif data_inicial NEQ data_final> a #lsDateFormat(data_final, "dd/mm/yyyy")#</cfif> · #htmlEditFormat(cidade)#/#htmlEditFormat(estado)# · Maior score #numberFormat(max_score, "0.00")#</div>
            </div>
            <span class="badge badge-warning text-dark align-self-start">#htmlEditFormat(status)#</span>
          </div>

          <cfset VARIABLES.focoReviewRenderedLinkedGalleries = 0 />
          <cfloop query="qFocoReviewLinkedGalleries">
            <cfif qFocoReviewLinkedGalleries.id_evento EQ qFocoReviewItems.id_evento>
              <cfset VARIABLES.focoReviewRenderedLinkedGalleries++ />
              <cfset VARIABLES.focoReviewLinkedFocoUrl = "" />
              <cfif len(trim(qFocoReviewLinkedGalleries.competition_path & ""))>
                <cfif findNoCase("http", trim(qFocoReviewLinkedGalleries.competition_path & "")) EQ 1>
                  <cfset VARIABLES.focoReviewLinkedFocoUrl = trim(qFocoReviewLinkedGalleries.competition_path & "") />
                <cfelseif left(trim(qFocoReviewLinkedGalleries.competition_path & ""), 1) EQ "/">
                  <cfset VARIABLES.focoReviewLinkedFocoUrl = "https://www.focoradical.com.br#trim(qFocoReviewLinkedGalleries.competition_path & "")#" />
                <cfelse>
                  <cfset VARIABLES.focoReviewLinkedFocoUrl = "https://www.focoradical.com.br/prova/#urlEncodedFormat(trim(qFocoReviewLinkedGalleries.competition_path & ""))#" />
                </cfif>
              <cfelseif len(trim(qFocoReviewLinkedGalleries.competition_id & ""))>
                <cfset VARIABLES.focoReviewLinkedFocoUrl = "https://www.focoradical.com.br/competition/upload-selfie?competition_id=#urlEncodedFormat(trim(qFocoReviewLinkedGalleries.competition_id & ""))#" />
              </cfif>

              <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 rounded border border-success border-opacity-25 bg-success bg-opacity-10 px-3 py-2 mb-2">
                <div class="small">
                  <span class="badge badge-success me-2">Galeria vinculada</span>
                  <strong>#htmlEditFormat(qFocoReviewLinkedGalleries.competition_name)#</strong>
                  <cfif len(VARIABLES.focoReviewLinkedFocoUrl)>
                    <a class="foco-review-external-link ms-1" href="#htmlEditFormat(VARIABLES.focoReviewLinkedFocoUrl)#" target="_blank" rel="noopener noreferrer" title="Abrir evento na Foco Radical"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
                  </cfif>
                  <span class="text-muted ms-2">
                    Foco ###htmlEditFormat(qFocoReviewLinkedGalleries.competition_id)#
                    <cfif isDate(qFocoReviewLinkedGalleries.competition_date)> · #lsDateFormat(qFocoReviewLinkedGalleries.competition_date, "dd/mm/yyyy")#</cfif>
                    <cfif len(trim(qFocoReviewLinkedGalleries.place & "")) OR len(trim(qFocoReviewLinkedGalleries.uf & ""))> · #htmlEditFormat(qFocoReviewLinkedGalleries.place)#/#htmlEditFormat(qFocoReviewLinkedGalleries.uf)#</cfif>
                    <cfif len(trim(qFocoReviewLinkedGalleries.score & ""))> · Score #numberFormat(qFocoReviewLinkedGalleries.score, "0.00")#</cfif>
                  </span>
                </div>
                <form method="post" onsubmit="return confirm('Desvincular esta galeria Foco deste evento Road Runners?');">
                  <input type="hidden" name="acao" value="desvincular_foco" />
                  <input type="hidden" name="id_evento_conflito" value="#qFocoReviewLinkedGalleries.id_evento#" />
                  <input type="hidden" name="competition_id" value="#htmlEditFormat(qFocoReviewLinkedGalleries.competition_id)#" />
                  <button class="btn btn-outline-light btn-sm"><i class="fa-solid fa-link-slash me-1"></i> Desvincular</button>
                </form>
              </div>
            </cfif>
          </cfloop>

          <cfset VARIABLES.focoReviewRenderedCandidates = 0 />
          <cfloop query="qFocoReviewCandidates">
            <cfif qFocoReviewCandidates.id_evento EQ qFocoReviewItems.id_evento>
              <cfset VARIABLES.focoReviewRenderedCandidates++ />
              <cfset VARIABLES.focoReviewScore = val(qFocoReviewCandidates.score) />
              <cfset VARIABLES.focoReviewScoreManualEligible = VARIABLES.focoReviewScore GTE 60 />
              <cfset VARIABLES.focoReviewScoreHighConfidence = VARIABLES.focoReviewScore GTE 85 />
              <cfset VARIABLES.focoReviewCandidateFocoUrl = "" />
              <cfif len(trim(qFocoReviewCandidates.competition_path & ""))>
                <cfif findNoCase("http", trim(qFocoReviewCandidates.competition_path & "")) EQ 1>
                  <cfset VARIABLES.focoReviewCandidateFocoUrl = trim(qFocoReviewCandidates.competition_path & "") />
                <cfelseif left(trim(qFocoReviewCandidates.competition_path & ""), 1) EQ "/">
                  <cfset VARIABLES.focoReviewCandidateFocoUrl = "https://www.focoradical.com.br#trim(qFocoReviewCandidates.competition_path & "")#" />
                <cfelse>
                  <cfset VARIABLES.focoReviewCandidateFocoUrl = "https://www.focoradical.com.br/prova/#urlEncodedFormat(trim(qFocoReviewCandidates.competition_path & ""))#" />
                </cfif>
              <cfelseif len(trim(qFocoReviewCandidates.competition_id & ""))>
                <cfset VARIABLES.focoReviewCandidateFocoUrl = "https://www.focoradical.com.br/competition/upload-selfie?competition_id=#urlEncodedFormat(trim(qFocoReviewCandidates.competition_id & ""))#" />
              </cfif>
              <div class="foco-review-candidate">
                <div>
                  <div class="d-flex flex-wrap gap-2 align-items-center mb-1">
                    <strong>
                      #htmlEditFormat(qFocoReviewCandidates.competition_name)#
                      <cfif len(VARIABLES.focoReviewCandidateFocoUrl)>
                        <a class="foco-review-external-link ms-1" href="#htmlEditFormat(VARIABLES.focoReviewCandidateFocoUrl)#" target="_blank" rel="noopener noreferrer" title="Abrir evento na Foco Radical"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
                      </cfif>
                    </strong>
                    <span class="badge <cfif VARIABLES.focoReviewScoreHighConfidence>foco-review-score-high<cfelseif VARIABLES.focoReviewScoreManualEligible>foco-review-score-mid<cfelse>foco-review-score-low</cfif>">
                      Score #numberFormat(qFocoReviewCandidates.score, "0.00")#
                      <cfif VARIABLES.focoReviewScoreHighConfidence> · Alta confiança<cfelseif VARIABLES.focoReviewScoreManualEligible> · Revisão manual<cfelse> · Baixa confiança</cfif>
                    </span>
                    <cfif qFocoReviewCandidates.is_linked>
                      <span class="badge badge-success">Já vinculada</span>
                    </cfif>
                  </div>
                  <div class="small text-muted mb-2">Foco ###htmlEditFormat(qFocoReviewCandidates.competition_id)# · <cfif isDate(qFocoReviewCandidates.competition_date)>#lsDateFormat(qFocoReviewCandidates.competition_date, "dd/mm/yyyy")#<cfelse>Data não informada</cfif> · #htmlEditFormat(qFocoReviewCandidates.place)#/#htmlEditFormat(qFocoReviewCandidates.uf)#</div>
                  <div class="foco-review-flags">
                    <span class="foco-review-flag <cfif qFocoReviewCandidates.exact_name>is-match</cfif>">Nome</span>
                    <span class="foco-review-flag <cfif qFocoReviewCandidates.exact_date>is-match</cfif>">Data</span>
                    <span class="foco-review-flag <cfif qFocoReviewCandidates.exact_place>is-match</cfif>">Cidade</span>
                    <span class="foco-review-flag <cfif qFocoReviewCandidates.exact_uf>is-match</cfif>">UF</span>
                  </div>
                </div>
                <cfif qFocoReviewCandidates.is_linked>
                  <div class="small text-success text-end">Galeria já vinculada.</div>
                <cfelseif listFindNoCase("review,conflict,linked", qFocoReviewItems.status) AND VARIABLES.focoReviewScoreManualEligible>
                  <div class="d-flex flex-column gap-2">
                    <form method="post" class="d-flex flex-column gap-2" data-foco-shortcut-action="vincular" onsubmit="return confirm('Vincular esta competição ao evento?');">
                      <input type="hidden" name="acao" value="vincular" />
                      <input type="hidden" name="id_evento" value="#qFocoReviewItems.id_evento#" />
                      <input type="hidden" name="competition_id" value="#htmlEditFormat(qFocoReviewCandidates.competition_id)#" />
                      <button class="btn btn-success btn-sm"><i class="fa-solid fa-link me-1"></i> Vincular galeria</button>
                    </form>
                    <form method="post" class="d-flex flex-column gap-2" data-foco-shortcut-action="ignorar" onsubmit="return confirm('Ignorar este candidato Foco para este evento?');">
                      <input type="hidden" name="acao" value="ignorar_candidato" />
                      <input type="hidden" name="id_evento" value="#qFocoReviewItems.id_evento#" />
                      <input type="hidden" name="competition_id" value="#htmlEditFormat(qFocoReviewCandidates.competition_id)#" />
                      <button class="btn btn-outline-danger btn-sm"><i class="fa-solid fa-eye-slash me-1"></i> Ignorar</button>
                    </form>
                  </div>
                <cfelseif listFindNoCase("review,conflict,linked", qFocoReviewItems.status)>
                  <div class="d-flex flex-column gap-2">
                    <div class="small text-danger text-end">Abaixo de 60 pontos: não vincular.</div>
                    <form method="post" class="d-flex flex-column gap-2" data-foco-shortcut-action="ignorar" onsubmit="return confirm('Ignorar este candidato Foco para este evento?');">
                      <input type="hidden" name="acao" value="ignorar_candidato" />
                      <input type="hidden" name="id_evento" value="#qFocoReviewItems.id_evento#" />
                      <input type="hidden" name="competition_id" value="#htmlEditFormat(qFocoReviewCandidates.competition_id)#" />
                      <button class="btn btn-outline-danger btn-sm"><i class="fa-solid fa-eye-slash me-1"></i> Ignorar</button>
                    </form>
                  </div>
                </cfif>
              </div>
            </cfif>
          </cfloop>

          <cfif !VARIABLES.focoReviewRenderedCandidates>
            <div class="text-muted small py-3">Nenhum candidato armazenado para este caso.</div>
          </cfif>

          <cfif listFindNoCase("review,conflict", qFocoReviewItems.status)>
            <form method="post" class="d-flex flex-wrap gap-2 align-items-center border-top pt-3 mt-2" onsubmit="return confirm('Descartar este caso da fila de revisão?');">
              <input type="hidden" name="acao" value="descartar" />
              <input type="hidden" name="id_evento" value="#qFocoReviewItems.id_evento#" />
              <input class="form-control form-control-sm flex-grow-1" style="min-width:220px" name="observacao" placeholder="Observação opcional" />
              <button class="btn btn-outline-danger btn-sm"><i class="fa-solid fa-ban me-1"></i> Descartar</button>
            </form>
          </cfif>
        </article>
      </cfoutput>

      <cfif !qFocoReviewItems.recordcount>
        <div class="card shadow-0"><div class="card-body text-center text-muted py-5">Nenhum caso encontrado neste filtro.</div></div>
      </cfif>
    </div>

    <cfif VARIABLES.focoReviewTotalPages GT 1>
      <nav class="mt-4"><ul class="pagination pagination-sm justify-content-end">
        <cfloop from="1" to="#VARIABLES.focoReviewTotalPages#" index="focoReviewPageNumber">
          <cfoutput><li class="page-item <cfif focoReviewPageNumber EQ VARIABLES.focoReviewPage>active</cfif>"><a class="page-link" href="./?pagina=#focoReviewPageNumber#&status=#urlEncodedFormat(VARIABLES.focoReviewStatus)#&busca=#urlEncodedFormat(VARIABLES.focoReviewSearch)#&ordenar=#urlEncodedFormat(VARIABLES.focoReviewOrder)#&direcao=#urlEncodedFormat(VARIABLES.focoReviewDirection)#">#focoReviewPageNumber#</a></li></cfoutput>
        </cfloop>
      </ul></nav>
    </cfif>
  </cfif>
</section>

<script>
(function () {
  function focusShortcutScope(force) {
    const scope = document.getElementById('focoReviewShortcutScope');

    if (!scope || (!force && isTypingTarget(document.activeElement))) {
      return;
    }

    if (force && isTypingTarget(document.activeElement)) {
      document.activeElement.blur();
    }

    try {
      scope.focus({ preventScroll: true });
    } catch (error) {
      scope.focus();
    }

    if (document.activeElement !== scope && document.body) {
      document.body.setAttribute('tabindex', '-1');

      try {
        document.body.focus({ preventScroll: true });
      } catch (error) {
        document.body.focus();
      }
    }
  }

  function isTypingTarget(element) {
    if (!element) {
      return false;
    }

    const tagName = (element.tagName || '').toLowerCase();
    return tagName === 'input' || tagName === 'textarea' || tagName === 'select' || element.isContentEditable;
  }

  function submitFirstVisibleAction(action) {
    const forms = document.querySelectorAll('form[data-foco-shortcut-action="' + action + '"]');

    for (const form of forms) {
      const rect = form.getBoundingClientRect();
      const isVisible = rect.width > 0 && rect.height > 0;

      if (!isVisible) {
        continue;
      }

      const button = form.querySelector('button:not([disabled])');

      if (button) {
        button.click();
        window.setTimeout(function () {
          focusShortcutScope(true);
        }, 250);
        return true;
      }
    }

    return false;
  }

  function handleShortcutKey(event) {
    if (event.defaultPrevented || event.focoReviewShortcutHandled || event.ctrlKey || event.metaKey || event.altKey || event.shiftKey || isTypingTarget(event.target)) {
      return;
    }

    const key = (event.key || '').toLowerCase();
    let handled = false;

    if (key === 'v') {
      handled = submitFirstVisibleAction('vincular');
    } else if (key === 'i') {
      handled = submitFirstVisibleAction('ignorar');
    }

    if (handled) {
      event.focoReviewShortcutHandled = true;
      event.preventDefault();
      event.stopPropagation();
    }
  }

  window.addEventListener('keydown', handleShortcutKey, true);
  document.addEventListener('keydown', handleShortcutKey, true);

  window.addEventListener('pageshow', function () {
    [0, 80, 250, 600, 1200].forEach(function (delay) {
      window.setTimeout(function () {
        focusShortcutScope(true);
      }, delay);
    });
  });

  window.addEventListener('focus', function () {
    window.setTimeout(function () {
      focusShortcutScope(true);
    }, 80);
  });

  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) {
      window.setTimeout(focusShortcutScope, 80);
    }
  });
})();
</script>
