<style>
  .agrega-review-page .agrega-review-event {
    border-top: 1px solid rgba(255,255,255,.08);
    display: grid;
    grid-template-columns: auto minmax(0, 1fr) auto;
    gap: .8rem;
    padding: .85rem 0;
    align-items: start;
  }
  .agrega-review-page .agrega-review-score {
    background: rgba(255,193,7,.14);
    border: 1px solid rgba(255,193,7,.45);
    color: #ffd76d;
    border-radius: 999px;
    padding: .18rem .5rem;
    white-space: nowrap;
  }
  .agrega-review-page .agrega-review-external-link {
    color: inherit;
    opacity: .72;
    text-decoration: none;
  }
  .agrega-review-page .agrega-review-external-link:hover { opacity: 1; color: #ffc107; }
  @media (max-width: 767px) {
    .agrega-review-page .agrega-review-event { grid-template-columns: 1fr; }
  }
</style>

<section class="agrega-review-page business-page pb-5">
  <div class="business-page-header pt-5 pb-3 d-flex flex-wrap justify-content-between align-items-end gap-3">
    <div>
      <div class="text-warning text-uppercase small fw-bold">Administração</div>
      <h1 class="business-page-title mb-1">Revisão de Agregadores</h1>
      <p class="text-muted mb-0">Agrupe edições anuais do mesmo evento por similaridade de nome e cidade, sem considerar datas.</p>
    </div>
    <a class="btn btn-outline-light btn-sm" href="/eventos/">Eventos</a>
  </div>

  <cfif len(VARIABLES.agregaReviewNotice)>
    <div class="alert alert-success"><cfoutput>#htmlEditFormat(VARIABLES.agregaReviewNotice)#</cfoutput></div>
  </cfif>
  <cfif len(VARIABLES.agregaReviewError)>
    <div class="alert alert-danger"><cfoutput>#htmlEditFormat(VARIABLES.agregaReviewError)#</cfoutput></div>
  </cfif>

  <cfif !VARIABLES.agregaReviewSchemaReady>
    <div class="alert alert-warning">
      Aplique o SQL <code>/administracao/agrega-revisao/agrega_review_schema.sql</code> antes de usar esta revisão.
    </div>
  <cfelse>
    <div class="foco-review-kpis agrega-review-kpis mb-4">
      <div class="agrega-review-kpi"><small>Para revisão</small><strong><cfoutput>#qAgregaReviewStats.review#</cfoutput></strong></div>
      <div class="agrega-review-kpi"><small>Aplicados</small><strong><cfoutput>#qAgregaReviewStats.applied#</cfoutput></strong></div>
      <div class="agrega-review-kpi"><small>Ignorados</small><strong><cfoutput>#qAgregaReviewStats.ignored#</cfoutput></strong></div>
    </div>

    <form class="card shadow-0 mb-4 business-page-card" method="post">
      <div class="card-body business-page-body row g-3 align-items-end">
        <input type="hidden" name="acao" value="gerar_sugestoes" />
        <div class="col-12 col-lg-5">
          <label class="form-label">Gerar sugestões</label>
          <div class="text-muted small">Compara eventos ativos da mesma cidade/UF, remove anos e edições do nome e não altera nenhum agregador automaticamente.</div>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Score mínimo</label>
          <input class="form-control" type="number" min="40" max="100" step="1" name="min_score" value="78" />
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Limite de eventos</label>
          <input class="form-control" type="number" min="100" max="12000" step="100" name="limite_eventos" value="5000" />
        </div>
        <div class="col-12 col-lg-3">
          <button class="btn btn-warning w-100" onclick="return confirm('Gerar novas sugestões de agregação? Nenhum evento será alterado agora.');">Gerar sugestões</button>
        </div>
      </div>
    </form>

    <form class="card shadow-0 mb-4 business-page-card" method="get">
      <div class="card-body business-page-body row g-3 align-items-end">
        <div class="col-12 col-lg-5">
          <label class="form-label">Evento, ID ou cidade</label>
          <input class="form-control" name="busca" value="<cfoutput>#htmlEditFormat(VARIABLES.agregaReviewSearch)#</cfoutput>" />
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Status</label>
          <select class="form-select" name="status">
            <option value="review" <cfif VARIABLES.agregaReviewStatus EQ "review">selected</cfif>>Para revisão</option>
            <option value="applied" <cfif VARIABLES.agregaReviewStatus EQ "applied">selected</cfif>>Aplicados</option>
            <option value="ignored" <cfif VARIABLES.agregaReviewStatus EQ "ignored">selected</cfif>>Ignorados</option>
            <option value="all" <cfif VARIABLES.agregaReviewStatus EQ "all">selected</cfif>>Todos</option>
          </select>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Ordenar por</label>
          <select class="form-select" name="ordenar">
            <option value="score" <cfif VARIABLES.agregaReviewOrder EQ "score">selected</cfif>>Score</option>
            <option value="nome" <cfif VARIABLES.agregaReviewOrder EQ "nome">selected</cfif>>Nome</option>
            <option value="atualizacao" <cfif VARIABLES.agregaReviewOrder EQ "atualizacao">selected</cfif>>Atualização</option>
          </select>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Direção</label>
          <select class="form-select" name="direcao">
            <option value="desc" <cfif VARIABLES.agregaReviewDirection EQ "desc">selected</cfif>>Maior primeiro</option>
            <option value="asc" <cfif VARIABLES.agregaReviewDirection EQ "asc">selected</cfif>>Menor primeiro</option>
          </select>
        </div>
        <div class="col-6 col-lg-1"><button class="btn btn-warning w-100">Filtrar</button></div>
      </div>
    </form>

    <cfif !qAgregaReviewGroups.recordcount OR VARIABLES.agregaReviewRenderableTotal EQ 0>
      <div class="alert alert-secondary">Nenhum grupo encontrado com os filtros atuais.</div>
    <cfelse>
      <div class="d-grid gap-3">
        <cfoutput query="qAgregaReviewGroups">
          <cfif structKeyExists(VARIABLES.agregaReviewActionableGroups, toString(qAgregaReviewGroups.id_evento_agrega_review_group))>
          <cfset VARIABLES.agregaReviewSuggestedAggregatorLabel = "" />
          <cfset VARIABLES.agregaReviewSuggestedAggregatorSearch = "" />
          <cfset VARIABLES.agregaReviewIsFocusedGroup = VARIABLES.agregaReviewFocusGroupId EQ val(qAgregaReviewGroups.id_evento_agrega_review_group) />
          <cfset VARIABLES.agregaReviewCurrentGroupKey = toString(qAgregaReviewGroups.id_evento_agrega_review_group) />
          <cfset VARIABLES.agregaReviewCurrentAggregatorOptions = {} />
          <cfset VARIABLES.agregaReviewAutoSelectedAggregatorId = 0 />
          <cfif structKeyExists(VARIABLES, "agregaReviewCurrentAggregatorsByGroup")
              AND structKeyExists(VARIABLES.agregaReviewCurrentAggregatorsByGroup, VARIABLES.agregaReviewCurrentGroupKey)>
            <cfset VARIABLES.agregaReviewCurrentAggregatorOptions = VARIABLES.agregaReviewCurrentAggregatorsByGroup[VARIABLES.agregaReviewCurrentGroupKey] />
          </cfif>
          <cfif val(qAgregaReviewGroups.suggested_id_agrega_evento) GT 0
              AND structKeyExists(VARIABLES.agregaReviewSuggestedAggregators, toString(qAgregaReviewGroups.suggested_id_agrega_evento))>
            <cfset VARIABLES.agregaReviewSuggestedAggregator = VARIABLES.agregaReviewSuggestedAggregators[toString(qAgregaReviewGroups.suggested_id_agrega_evento)] />
            <cfset VARIABLES.agregaReviewSuggestedAggregatorLabel = "###VARIABLES.agregaReviewSuggestedAggregator.id# - #VARIABLES.agregaReviewSuggestedAggregator.tipo# - #VARIABLES.agregaReviewSuggestedAggregator.nome#" />
            <cfset VARIABLES.agregaReviewSuggestedAggregatorSearch = VARIABLES.agregaReviewSuggestedAggregator.nome />
            <cfset VARIABLES.agregaReviewAutoSelectedAggregatorId = val(qAgregaReviewGroups.suggested_id_agrega_evento) />
          <cfelseif VARIABLES.agregaReviewIsFocusedGroup AND len(VARIABLES.agregaReviewAggregatorSearchTerm)>
            <cfset VARIABLES.agregaReviewSuggestedAggregatorSearch = VARIABLES.agregaReviewAggregatorSearchTerm />
          <cfelseif structCount(VARIABLES.agregaReviewCurrentAggregatorOptions) EQ 1>
            <cfloop collection="#VARIABLES.agregaReviewCurrentAggregatorOptions#" item="VARIABLES.agregaReviewOnlyCurrentAggregatorId">
              <cfset VARIABLES.agregaReviewOnlyCurrentAggregator = VARIABLES.agregaReviewCurrentAggregatorOptions[VARIABLES.agregaReviewOnlyCurrentAggregatorId] />
              <cfset VARIABLES.agregaReviewSuggestedAggregatorSearch = VARIABLES.agregaReviewOnlyCurrentAggregator.nome />
              <cfset VARIABLES.agregaReviewAutoSelectedAggregatorId = val(VARIABLES.agregaReviewOnlyCurrentAggregator.id) />
            </cfloop>
          </cfif>
          <article class="agrega-review-case">
            <div class="d-flex flex-wrap justify-content-between gap-3 mb-3">
              <div>
                <div class="small text-muted">Grupo ###id_evento_agrega_review_group# · #htmlEditFormat(cidade)#/#htmlEditFormat(estado)#</div>
                <h2 class="h5 mb-1">#htmlEditFormat(group_display_name)#</h2>
                <div class="small text-muted">
                  #candidate_count# eventos · Score máximo #numberFormat(max_score, "0.00")#
                  <cfif len(suggested_nome_evento_agregado & "")>
                    · Sugerido: #htmlEditFormat(suggested_tipo_agregacao)# - #htmlEditFormat(suggested_nome_evento_agregado)#
                  </cfif>
                </div>
              </div>
              <span class="badge badge-warning text-dark align-self-start">#htmlEditFormat(status)#</span>
            </div>

            <cfif status EQ "review">
              <div class="card shadow-0 border border-light border-opacity-10 mb-3">
                <div class="card-body">
                  <div class="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-3">
                    <div>
                      <div class="fw-semibold">Criar agregador para este grupo</div>
                      <div class="small text-muted">Use quando nenhum agregador existente representar essas edições. A criação não aplica o vínculo automaticamente.</div>
                    </div>
                  </div>

                  <form method="post" class="row g-3 align-items-end">
                    <input type="hidden" name="acao" value="criar_agregador" />
                    <input type="hidden" name="id_grupo" value="#id_evento_agrega_review_group#" />

                    <div class="col-12 col-xl-4">
                      <label class="form-label">Nome do agregador</label>
                      <input class="form-control" name="nome_evento_agregado" value="#htmlEditFormat(group_display_name)#" required />
                    </div>
                    <div class="col-6 col-xl-2">
                      <label class="form-label">Tipo</label>
                      <select class="form-select" name="tipo_agregacao" required>
                        <option value="">Selecione...</option>
                        <cfloop query="qAgregaReviewAggregatorTypes">
                          <option value="#htmlEditFormat(qAgregaReviewAggregatorTypes.tipo_agregacao)#" <cfif qAgregaReviewAggregatorTypes.tipo_agregacao EQ "corrida">selected</cfif>>#htmlEditFormat(qAgregaReviewAggregatorTypes.tipo_agregacao)#</option>
                        </cfloop>
                      </select>
                    </div>
                    <div class="col-6 col-xl-2">
                      <label class="form-label">Tag</label>
                      <input class="form-control" name="tag" placeholder="Opcional" />
                    </div>
                    <div class="col-6 col-xl-2">
                      <label class="form-label">Tema</label>
                      <select class="form-select" name="id_tema">
                        <cfloop query="qAgregaReviewThemes">
                          <option value="#qAgregaReviewThemes.id_tema#" <cfif qAgregaReviewThemes.id_tema EQ 1>selected</cfif>>###qAgregaReviewThemes.id_tema# - #htmlEditFormat(qAgregaReviewThemes.nome_tema)#</option>
                        </cfloop>
                      </select>
                    </div>
                    <div class="col-6 col-xl-1">
                      <label class="form-label">Divisão</label>
                      <select class="form-select" name="divisao">
                        <cfloop query="qAgregaReviewDivisions">
                          <option value="#htmlEditFormat(qAgregaReviewDivisions.divisao)#" <cfif qAgregaReviewDivisions.divisao EQ "distancia">selected</cfif>>#htmlEditFormat(qAgregaReviewDivisions.divisao)#</option>
                        </cfloop>
                      </select>
                    </div>
                    <div class="col-6 col-xl-1">
                      <label class="form-label">Ordem</label>
                      <input class="form-control" type="number" name="ordem" value="300" />
                    </div>
                    <div class="col-12">
                      <button class="btn btn-outline-warning btn-sm" onclick="return confirm('Criar este agregador e selecioná-lo para o grupo?');"><i class="fa-solid fa-plus me-1"></i> Criar agregador</button>
                    </div>
                  </form>
                </div>
              </div>
            </cfif>

            <form method="post">
              <input type="hidden" name="acao" value="aplicar_agregador" />
              <input type="hidden" name="id_grupo" value="#id_evento_agrega_review_group#" />

              <div class="row g-3 align-items-end mb-2">
                <div class="col-12 col-lg-7">
                  <label class="form-label">Agregador existente</label>
                  <div class="input-group">
                    <input
                      class="form-control agrega-review-aggregator-search"
                      type="search"
                      name="agregador_busca"
                      value="#htmlEditFormat(VARIABLES.agregaReviewSuggestedAggregatorSearch)#"
                      placeholder="Buscar por nome, tag ou ID"
                      data-target="agrega-review-aggregator-#id_evento_agrega_review_group#"
                      data-group-id="#id_evento_agrega_review_group#"
                      <cfif status NEQ "review">disabled</cfif>
                    />
                    <button
                      class="btn btn-outline-light agrega-review-aggregator-search-button"
                      type="button"
                      data-group-id="#id_evento_agrega_review_group#"
                      <cfif status NEQ "review">disabled</cfif>
                    >Buscar</button>
                  </div>
                  <select
                    class="form-select mt-2 agrega-review-aggregator-select"
                    id="agrega-review-aggregator-#id_evento_agrega_review_group#"
                    name="id_agrega_evento"
                    data-current-id="<cfif len(suggested_id_agrega_evento)>#suggested_id_agrega_evento#</cfif>"
                    data-current-label="#htmlEditFormat(VARIABLES.agregaReviewSuggestedAggregatorLabel)#"
                    <cfif status NEQ "review">disabled</cfif>
                  >
                    <option value="">Busque e selecione um agregador...</option>
                    <cfif len(VARIABLES.agregaReviewSuggestedAggregatorLabel)>
                      <option value="#suggested_id_agrega_evento#" selected>#htmlEditFormat(VARIABLES.agregaReviewSuggestedAggregatorLabel)#</option>
                    </cfif>
                    <cfif structCount(VARIABLES.agregaReviewCurrentAggregatorOptions)>
                      <cfloop collection="#VARIABLES.agregaReviewCurrentAggregatorOptions#" item="VARIABLES.agregaReviewCurrentAggregatorId">
                        <cfif val(VARIABLES.agregaReviewCurrentAggregatorId) NEQ val(qAgregaReviewGroups.suggested_id_agrega_evento)>
                          <cfset VARIABLES.agregaReviewCurrentAggregator = VARIABLES.agregaReviewCurrentAggregatorOptions[VARIABLES.agregaReviewCurrentAggregatorId] />
                          <cfset VARIABLES.agregaReviewCurrentAggregatorLabel = "###VARIABLES.agregaReviewCurrentAggregator.id# - #VARIABLES.agregaReviewCurrentAggregator.tipo# - #VARIABLES.agregaReviewCurrentAggregator.nome#" />
                          <option value="#VARIABLES.agregaReviewCurrentAggregator.id#" <cfif VARIABLES.agregaReviewAutoSelectedAggregatorId EQ val(VARIABLES.agregaReviewCurrentAggregator.id)>selected</cfif>>#htmlEditFormat(VARIABLES.agregaReviewCurrentAggregatorLabel)#</option>
                        </cfif>
                      </cfloop>
                    </cfif>
                    <cfif VARIABLES.agregaReviewIsFocusedGroup AND structCount(VARIABLES.agregaReviewSearchAggregators)>
                      <cfloop collection="#VARIABLES.agregaReviewSearchAggregators#" item="VARIABLES.agregaReviewSearchAggregatorId">
                        <cfif val(VARIABLES.agregaReviewSearchAggregatorId) NEQ val(qAgregaReviewGroups.suggested_id_agrega_evento)
                            AND NOT structKeyExists(VARIABLES.agregaReviewCurrentAggregatorOptions, toString(VARIABLES.agregaReviewSearchAggregatorId))>
                          <cfset VARIABLES.agregaReviewSearchAggregator = VARIABLES.agregaReviewSearchAggregators[VARIABLES.agregaReviewSearchAggregatorId] />
                          <cfset VARIABLES.agregaReviewSearchAggregatorLabel = "###VARIABLES.agregaReviewSearchAggregator.id# - #VARIABLES.agregaReviewSearchAggregator.tipo# - #VARIABLES.agregaReviewSearchAggregator.nome#" />
                          <cfif len(trim(VARIABLES.agregaReviewSearchAggregator.tag & ""))>
                            <cfset VARIABLES.agregaReviewSearchAggregatorLabel = VARIABLES.agregaReviewSearchAggregatorLabel & " - tag: " & VARIABLES.agregaReviewSearchAggregator.tag />
                          </cfif>
                          <option value="#VARIABLES.agregaReviewSearchAggregator.id#">#htmlEditFormat(VARIABLES.agregaReviewSearchAggregatorLabel)#</option>
                        </cfif>
                      </cfloop>
                    </cfif>
                  </select>
                  <div class="form-text text-muted">
                    <cfif VARIABLES.agregaReviewIsFocusedGroup AND len(VARIABLES.agregaReviewAggregatorSearchTerm) AND NOT structCount(VARIABLES.agregaReviewSearchAggregators)>
                      Nenhum agregador encontrado para "#htmlEditFormat(VARIABLES.agregaReviewAggregatorSearchTerm)#".
                    <cfelseif len(VARIABLES.agregaReviewSuggestedAggregatorLabel)>
                      Sugerido: #htmlEditFormat(VARIABLES.agregaReviewSuggestedAggregatorLabel)#
                    <cfelse>
                      Crie um agregador neste grupo ou busque um agregador existente por nome, tag ou ID.
                    </cfif>
                  </div>
                </div>
                <div class="col-12 col-lg-5">
                  <label class="form-label">Observação</label>
                  <input class="form-control" name="observacao" placeholder="Opcional" <cfif status NEQ "review">disabled</cfif> />
                </div>
              </div>

              <cfset VARIABLES.agregaReviewRenderedCandidates = 0 />
              <cfloop query="qAgregaReviewCandidates">
                <cfif qAgregaReviewCandidates.id_evento_agrega_review_group EQ qAgregaReviewGroups.id_evento_agrega_review_group>
                  <cfset VARIABLES.agregaReviewRenderedCandidates = VARIABLES.agregaReviewRenderedCandidates + 1 />
                  <cfset VARIABLES.agregaReviewRoadRunnersUrl = "" />
                  <cfif len(trim(qAgregaReviewCandidates.tag & ""))>
                    <cfset VARIABLES.agregaReviewRoadRunnersUrl = "https://roadrunners.run/evento/#urlEncodedFormat(trim(qAgregaReviewCandidates.tag & ""))#/" />
                  </cfif>
                  <div class="agrega-review-event">
                    <div>
                      <input class="form-check-input" type="checkbox" name="eventos" value="#qAgregaReviewCandidates.id_evento#" <cfif qAgregaReviewCandidates.status EQ "active" AND qAgregaReviewGroups.status EQ "review">checked<cfelse>disabled</cfif> />
                    </div>
                    <div>
                      <div class="d-flex flex-wrap gap-2 align-items-center">
                        <strong>
                          ###qAgregaReviewCandidates.id_evento# - #htmlEditFormat(qAgregaReviewCandidates.nome_evento)#
                          <cfif len(VARIABLES.agregaReviewRoadRunnersUrl)>
                            <a class="agrega-review-external-link ms-1" href="#htmlEditFormat(VARIABLES.agregaReviewRoadRunnersUrl)#" target="_blank" rel="noopener noreferrer" title="Abrir evento no Road Runners"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
                          </cfif>
                        </strong>
                        <span class="agrega-review-score">Score #numberFormat(qAgregaReviewCandidates.score, "0.00")#</span>
                        <cfif qAgregaReviewCandidates.status NEQ "active">
                          <span class="badge badge-secondary">#htmlEditFormat(qAgregaReviewCandidates.status)#</span>
                        </cfif>
                      </div>
                      <div class="small text-muted">
                        <cfif isDate(qAgregaReviewCandidates.data_inicial)>#lsDateFormat(qAgregaReviewCandidates.data_inicial, "dd/mm/yyyy")# · </cfif>
                        #htmlEditFormat(qAgregaReviewCandidates.cidade)#/#htmlEditFormat(qAgregaReviewCandidates.estado)#
                        <cfif len(qAgregaReviewCandidates.atual_nome_evento_agregado & "")>
                          · Atual: #htmlEditFormat(qAgregaReviewCandidates.atual_tipo_agregacao)# - #htmlEditFormat(qAgregaReviewCandidates.atual_nome_evento_agregado)#
                        <cfelse>
                          · Sem agregador
                        </cfif>
                      </div>
                    </div>
                    <div>
                      <cfif qAgregaReviewCandidates.status EQ "active" AND qAgregaReviewGroups.status EQ "review">
                        <button class="btn btn-outline-danger btn-sm" type="submit" onclick="this.form.acao.value='ignorar_candidato'; this.form.id_candidato.value='#qAgregaReviewCandidates.id_evento_agrega_review_candidate#'; return confirm('Ignorar este evento neste grupo?');">Ignorar</button>
                      </cfif>
                    </div>
                  </div>
                </cfif>
              </cfloop>

              <input type="hidden" name="id_candidato" value="" />
              <div class="d-flex flex-wrap gap-2 justify-content-between pt-3 border-top border-light border-opacity-10">
                <button class="btn btn-success btn-sm" <cfif status NEQ "review">disabled</cfif> onclick="this.form.acao.value='aplicar_agregador'; return confirm('Aplicar o agregador selecionado aos eventos marcados?');"><i class="fa-solid fa-object-group me-1"></i> Aplicar aos selecionados</button>
                <button class="btn btn-outline-danger btn-sm" type="submit" <cfif status NEQ "review">disabled</cfif> onclick="this.form.acao.value='ignorar_grupo'; return confirm('Ignorar todo este grupo de revisão?');"><i class="fa-solid fa-eye-slash me-1"></i> Ignorar grupo</button>
              </div>
            </form>
          </article>
          </cfif>
        </cfoutput>
      </div>
    </cfif>

    <cfif VARIABLES.agregaReviewTotalPages GT 1>
      <nav class="mt-4">
        <ul class="pagination pagination-sm">
          <cfloop from="1" to="#VARIABLES.agregaReviewTotalPages#" index="VARIABLES.agregaReviewPageIndex">
            <li class="page-item <cfif VARIABLES.agregaReviewPageIndex EQ VARIABLES.agregaReviewPage>active</cfif>">
              <a class="page-link" href="/administracao/agrega-revisao/?pagina=<cfoutput>#VARIABLES.agregaReviewPageIndex#&busca=#urlEncodedFormat(VARIABLES.agregaReviewSearch)#&status=#urlEncodedFormat(VARIABLES.agregaReviewStatus)#&ordenar=#urlEncodedFormat(VARIABLES.agregaReviewOrder)#&direcao=#urlEncodedFormat(VARIABLES.agregaReviewDirection)#</cfoutput>"><cfoutput>#VARIABLES.agregaReviewPageIndex#</cfoutput></a>
            </li>
          </cfloop>
        </ul>
      </nav>
    </cfif>
  </cfif>
</section>

<script>
(function () {
  function submitAggregatorSearch(input) {
    const groupId = input.dataset.groupId || '';
    const term = input.value.trim();
    const params = new URLSearchParams();

    if (!groupId) {
      return;
    }

    params.set('grupo', groupId);
    if (term) {
      params.set('agregador_busca', term);
    }

    window.location.href = '/administracao/agrega-revisao/?' + params.toString();
  }

  document.querySelectorAll('.agrega-review-aggregator-search').forEach(function (input) {
    input.addEventListener('keydown', function (event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        submitAggregatorSearch(input);
      }
    });
  });

  document.querySelectorAll('.agrega-review-aggregator-search-button').forEach(function (button) {
    button.addEventListener('click', function () {
      const form = button.closest('form');
      const input = form ? form.querySelector('.agrega-review-aggregator-search') : null;

      if (input) {
        submitAggregatorSearch(input);
      }
    });
  });
})();
</script>
