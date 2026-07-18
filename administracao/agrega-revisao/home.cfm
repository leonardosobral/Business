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
  .agrega-review-page .agrega-review-manual-table td,
  .agrega-review-page .agrega-review-manual-table th { vertical-align: middle; }
  .agrega-review-page .agrega-review-manual-table .agrega-review-manual-event { min-width: 280px; }
  .agrega-review-page .agrega-review-manual-selection {
    background: rgba(255,193,7,.08);
    border: 1px solid rgba(255,193,7,.25);
    border-radius: .65rem;
  }
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

    <cfif VARIABLES.agregaReviewFocusGroupId LTE 0>
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

    <div class="card shadow-0 mb-4 business-page-card">
      <div class="card-body business-page-body">
        <div class="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-3">
          <div>
            <h2 class="h6 mb-1">Criar grupo manual</h2>
            <div class="text-muted small">Busque eventos pelo nome e selecione as edições que devem entrar em uma nova revisão. A cidade ajuda a refinar, mas é opcional.</div>
          </div>
          <span class="badge badge-warning text-dark">Sem aguardar o cron</span>
        </div>

        <form method="get" class="row g-3 align-items-end">
          <div class="col-12 col-lg-6">
            <label class="form-label" for="agrega-review-manual-name">Nome do evento</label>
            <input
              class="form-control"
              id="agrega-review-manual-name"
              name="manual_nome"
              value="<cfoutput>#htmlEditFormat(VARIABLES.agregaReviewManualName)#</cfoutput>"
              minlength="2"
              placeholder="Ex.: Maratona de Floripa"
              required
            />
          </div>
          <div class="col-12 col-lg-4">
            <label class="form-label" for="agrega-review-manual-city">Cidade <span class="text-muted">(opcional)</span></label>
            <input
              class="form-control"
              id="agrega-review-manual-city"
              name="manual_cidade"
              value="<cfoutput>#htmlEditFormat(VARIABLES.agregaReviewManualCity)#</cfoutput>"
              placeholder="Ex.: Florianópolis"
            />
          </div>
          <div class="col-12 col-lg-2">
            <button class="btn btn-outline-warning w-100" type="submit"><i class="fa-solid fa-magnifying-glass me-1"></i> Buscar</button>
          </div>
        </form>

        <cfif len(VARIABLES.agregaReviewManualSearchError)>
          <div class="alert alert-warning mt-3 mb-0"><cfoutput>#htmlEditFormat(VARIABLES.agregaReviewManualSearchError)#</cfoutput></div>
        <cfelseif len(VARIABLES.agregaReviewManualName) GTE 2 AND NOT qAgregaReviewManualEvents.recordcount>
          <div class="alert alert-secondary mt-3 mb-0">Nenhum evento ativo foi encontrado com esses critérios.</div>
        </cfif>
      </div>
    </div>

    <cfif qAgregaReviewManualEvents.recordcount>
      <form class="card shadow-0 mb-4 business-page-card" method="post" id="agrega-review-manual-form">
        <input type="hidden" name="acao" value="criar_grupo_manual" />
        <input type="hidden" name="manual_nome" value="<cfoutput>#htmlEditFormat(VARIABLES.agregaReviewManualName)#</cfoutput>" />
        <input type="hidden" name="manual_cidade" value="<cfoutput>#htmlEditFormat(VARIABLES.agregaReviewManualCity)#</cfoutput>" />

        <div class="card-body business-page-body">
          <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
            <div>
              <h2 class="h6 mb-1">Eventos encontrados</h2>
              <div class="text-muted small"><cfoutput>#qAgregaReviewManualEvents.recordcount#</cfoutput> resultado(s), limitados aos primeiros <cfoutput>#VARIABLES.agregaReviewManualSearchLimit#</cfoutput>.</div>
            </div>
            <label class="form-check mb-0">
              <input class="form-check-input" type="checkbox" id="agrega-review-manual-select-all" />
              <span class="form-check-label">Selecionar disponíveis</span>
            </label>
          </div>

          <div class="table-responsive">
            <table class="table table-sm align-middle agrega-review-manual-table mb-0">
              <thead>
                <tr>
                  <th style="width: 42px;" aria-label="Selecionar"></th>
                  <th>Evento</th>
                  <th>Cidade/UF</th>
                  <th>Agregador atual</th>
                  <th>Revisão</th>
                </tr>
              </thead>
              <tbody>
                <cfoutput query="qAgregaReviewManualEvents">
                  <cfset VARIABLES.agregaReviewManualPending = val(qAgregaReviewManualEvents.pending_group_id) GT 0 />
                  <cfset VARIABLES.agregaReviewManualPublicUrl = "" />
                  <cfif len(trim(qAgregaReviewManualEvents.tag & ""))>
                    <cfset VARIABLES.agregaReviewManualPublicUrl = "https://roadrunners.run/evento/#urlEncodedFormat(trim(qAgregaReviewManualEvents.tag & ""))#/" />
                  </cfif>
                  <tr>
                    <td>
                      <input
                        class="form-check-input agrega-review-manual-checkbox"
                        type="checkbox"
                        name="eventos"
                        value="#qAgregaReviewManualEvents.id_evento#"
                        <cfif VARIABLES.agregaReviewManualPending>disabled</cfif>
                        aria-label="Selecionar evento #qAgregaReviewManualEvents.id_evento#"
                      />
                    </td>
                    <td class="agrega-review-manual-event">
                      <div class="fw-semibold">
                        ###qAgregaReviewManualEvents.id_evento# - #htmlEditFormat(qAgregaReviewManualEvents.nome_evento)#
                        <cfif len(VARIABLES.agregaReviewManualPublicUrl)>
                          <a class="agrega-review-external-link ms-1" href="#htmlEditFormat(VARIABLES.agregaReviewManualPublicUrl)#" target="_blank" rel="noopener noreferrer" title="Abrir evento no Road Runners"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
                        </cfif>
                      </div>
                      <div class="small text-muted"><cfif isDate(qAgregaReviewManualEvents.data_inicial)>#lsDateFormat(qAgregaReviewManualEvents.data_inicial, "dd/mm/yyyy")#<cfelse>Sem data informada</cfif></div>
                    </td>
                    <td>
                      <cfif len(trim(qAgregaReviewManualEvents.cidade & ""))>
                        #htmlEditFormat(qAgregaReviewManualEvents.cidade)#<cfif len(trim(qAgregaReviewManualEvents.estado & ""))>/#htmlEditFormat(qAgregaReviewManualEvents.estado)#</cfif>
                      <cfelse>
                        -
                      </cfif>
                    </td>
                    <td>
                      <cfif val(qAgregaReviewManualEvents.id_agrega_evento) GT 0>
                        <span class="small">###qAgregaReviewManualEvents.id_agrega_evento# - #htmlEditFormat(qAgregaReviewManualEvents.atual_nome_evento_agregado)#</span>
                      <cfelse>
                        <span class="text-muted">Sem agregador</span>
                      </cfif>
                    </td>
                    <td>
                      <cfif VARIABLES.agregaReviewManualPending>
                        <a class="btn btn-outline-secondary btn-sm" href="/administracao/agrega-revisao/?grupo=#qAgregaReviewManualEvents.pending_group_id#" title="#htmlEditFormat(qAgregaReviewManualEvents.pending_group_name)#">Grupo ###qAgregaReviewManualEvents.pending_group_id#</a>
                      <cfelse>
                        <span class="badge badge-success">Disponível</span>
                      </cfif>
                    </td>
                  </tr>
                </cfoutput>
              </tbody>
            </table>
          </div>

          <div class="agrega-review-manual-selection d-flex flex-wrap justify-content-between align-items-center gap-3 mt-3 p-3">
            <div><strong id="agrega-review-manual-count">0</strong> evento(s) selecionado(s). Escolha pelo menos 2.</div>
            <button class="btn btn-warning" id="agrega-review-manual-submit" type="submit" disabled onclick="return confirm('Criar um grupo de revisão com os eventos selecionados?');"><i class="fa-solid fa-layer-group me-1"></i> Criar grupo para revisão</button>
          </div>
        </div>
      </form>
    </cfif>

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
    </cfif>

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
          <cfset VARIABLES.agregaReviewAutoSelectedAggregatorName = "" />
          <cfset VARIABLES.agregaReviewAutoSelectedAggregatorType = "" />
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
            <cfset VARIABLES.agregaReviewAutoSelectedAggregatorName = VARIABLES.agregaReviewSuggestedAggregator.nome />
            <cfset VARIABLES.agregaReviewAutoSelectedAggregatorType = VARIABLES.agregaReviewSuggestedAggregator.tipo />
          <cfelseif VARIABLES.agregaReviewIsFocusedGroup AND len(VARIABLES.agregaReviewAggregatorSearchTerm)>
            <cfset VARIABLES.agregaReviewSuggestedAggregatorSearch = VARIABLES.agregaReviewAggregatorSearchTerm />
          <cfelseif structCount(VARIABLES.agregaReviewCurrentAggregatorOptions) EQ 1>
            <cfloop collection="#VARIABLES.agregaReviewCurrentAggregatorOptions#" item="VARIABLES.agregaReviewOnlyCurrentAggregatorId">
              <cfset VARIABLES.agregaReviewOnlyCurrentAggregator = VARIABLES.agregaReviewCurrentAggregatorOptions[VARIABLES.agregaReviewOnlyCurrentAggregatorId] />
              <cfset VARIABLES.agregaReviewSuggestedAggregatorSearch = VARIABLES.agregaReviewOnlyCurrentAggregator.nome />
              <cfset VARIABLES.agregaReviewAutoSelectedAggregatorId = val(VARIABLES.agregaReviewOnlyCurrentAggregator.id) />
              <cfset VARIABLES.agregaReviewAutoSelectedAggregatorName = VARIABLES.agregaReviewOnlyCurrentAggregator.nome />
              <cfset VARIABLES.agregaReviewAutoSelectedAggregatorType = VARIABLES.agregaReviewOnlyCurrentAggregator.tipo />
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

            <cfif status EQ "review" AND val(suggested_id_agrega_evento) LTE 0>
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

            <cfif status EQ "review" AND VARIABLES.agregaReviewIsFocusedGroup AND val(suggested_id_agrega_evento) GT 0>
              <div class="card shadow-0 border border-warning border-opacity-25 mb-3">
                <div class="card-body">
                  <div class="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-3">
                    <div>
                      <div class="fw-semibold">Buscar outras edições no banco</div>
                      <div class="small text-muted">Esta consulta não usa o limite da geração de sugestões. Os eventos selecionados entram neste grupo antes da aplicação do agregador.</div>
                    </div>
                    <span class="badge badge-warning text-dark">Agregador ###suggested_id_agrega_evento#</span>
                  </div>

                  <form method="get" class="row g-2 align-items-end mb-3">
                    <input type="hidden" name="grupo" value="#id_evento_agrega_review_group#" />
                    <div class="col-12 col-lg-9">
                      <label class="form-label">Nome do evento</label>
                      <input
                        class="form-control"
                        type="search"
                        name="evento_busca"
                        minlength="2"
                        value="#htmlEditFormat(VARIABLES.agregaReviewEventSearchInput)#"
                        placeholder="Nome do agregador ou parte do nome do evento"
                        required
                      />
                    </div>
                    <div class="col-12 col-lg-3">
                      <button class="btn btn-outline-warning w-100" type="submit"><i class="fa-solid fa-magnifying-glass me-1"></i> Buscar eventos</button>
                    </div>
                  </form>

                  <cfif VARIABLES.agregaReviewEventSearchRequested AND NOT qAgregaReviewEventSearch.recordcount>
                    <div class="alert alert-secondary mb-0">Nenhum outro evento ativo foi encontrado para esta busca.</div>
                  <cfelseif VARIABLES.agregaReviewEventSearchRequested>
                    <form method="post" class="agrega-review-additional-form">
                      <input type="hidden" name="acao" value="adicionar_candidatos_grupo" />
                      <input type="hidden" name="id_grupo" value="#id_evento_agrega_review_group#" />

                      <div class="table-responsive">
                        <table class="table table-sm align-middle agrega-review-manual-table mb-0">
                          <thead>
                            <tr>
                              <th style="width: 42px;" aria-label="Selecionar"></th>
                              <th>Evento encontrado</th>
                              <th>Cidade/UF</th>
                              <th>Agregador atual</th>
                              <th>Situação</th>
                            </tr>
                          </thead>
                          <tbody>
                            <cfloop query="qAgregaReviewEventSearch">
                              <cfset VARIABLES.agregaReviewAdditionalPending = val(qAgregaReviewEventSearch.pending_group_id) GT 0 />
                              <cfset VARIABLES.agregaReviewAdditionalAlreadyLinked = val(qAgregaReviewEventSearch.id_agrega_evento) EQ val(qAgregaReviewGroups.suggested_id_agrega_evento) />
                              <cfset VARIABLES.agregaReviewAdditionalAvailable = NOT VARIABLES.agregaReviewAdditionalPending AND NOT VARIABLES.agregaReviewAdditionalAlreadyLinked />
                              <cfset VARIABLES.agregaReviewAdditionalNameScorePreview = agregaReviewTokenScore(VARIABLES.agregaReviewEventSearchTargetName, qAgregaReviewEventSearch.nome_evento) />
                              <cfset VARIABLES.agregaReviewAdditionalCityScorePreview = 0 />
                              <cfif len(agregaReviewNormalizeText(qAgregaReviewGroups.cidade))
                                  AND agregaReviewNormalizeText(qAgregaReviewGroups.cidade) EQ agregaReviewNormalizeText(qAgregaReviewEventSearch.cidade)
                                  AND uCase(trim(qAgregaReviewGroups.estado)) EQ uCase(trim(qAgregaReviewEventSearch.estado))>
                                <cfset VARIABLES.agregaReviewAdditionalCityScorePreview = 100 />
                              </cfif>
                              <cfset VARIABLES.agregaReviewAdditionalScorePreview = round(((VARIABLES.agregaReviewAdditionalNameScorePreview * 0.80) + (VARIABLES.agregaReviewAdditionalCityScorePreview * 0.20)) * 100) / 100 />
                              <cfset VARIABLES.agregaReviewAdditionalPublicUrl = "" />
                              <cfif len(trim(qAgregaReviewEventSearch.tag & ""))>
                                <cfset VARIABLES.agregaReviewAdditionalPublicUrl = "https://roadrunners.run/evento/#urlEncodedFormat(trim(qAgregaReviewEventSearch.tag & ""))#/" />
                              </cfif>

                              <tr>
                                <td>
                                  <input
                                    class="form-check-input agrega-review-additional-checkbox"
                                    type="checkbox"
                                    name="eventos_adicionais"
                                    value="#qAgregaReviewEventSearch.id_evento#"
                                    <cfif NOT VARIABLES.agregaReviewAdditionalAvailable>disabled</cfif>
                                    aria-label="Adicionar evento #qAgregaReviewEventSearch.id_evento# ao grupo"
                                  />
                                </td>
                                <td class="agrega-review-manual-event">
                                  <div class="d-flex flex-wrap align-items-center gap-2">
                                    <strong>
                                      ###qAgregaReviewEventSearch.id_evento# - #htmlEditFormat(qAgregaReviewEventSearch.nome_evento)#
                                      <cfif len(VARIABLES.agregaReviewAdditionalPublicUrl)>
                                        <a class="agrega-review-external-link ms-1" href="#htmlEditFormat(VARIABLES.agregaReviewAdditionalPublicUrl)#" target="_blank" rel="noopener noreferrer" title="Abrir evento no Road Runners"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>
                                      </cfif>
                                    </strong>
                                    <span class="agrega-review-score">Score #numberFormat(VARIABLES.agregaReviewAdditionalScorePreview, "0.00")#</span>
                                  </div>
                                  <div class="small text-muted"><cfif isDate(qAgregaReviewEventSearch.data_inicial)>#lsDateFormat(qAgregaReviewEventSearch.data_inicial, "dd/mm/yyyy")#<cfelse>Sem data informada</cfif></div>
                                </td>
                                <td>
                                  <cfif len(trim(qAgregaReviewEventSearch.cidade & ""))>
                                    #htmlEditFormat(qAgregaReviewEventSearch.cidade)#<cfif len(trim(qAgregaReviewEventSearch.estado & ""))>/#htmlEditFormat(qAgregaReviewEventSearch.estado)#</cfif>
                                  <cfelse>
                                    -
                                  </cfif>
                                </td>
                                <td>
                                  <cfif val(qAgregaReviewEventSearch.id_agrega_evento) GT 0>
                                    <span class="small">###qAgregaReviewEventSearch.id_agrega_evento# - #htmlEditFormat(qAgregaReviewEventSearch.atual_nome_evento_agregado)#</span>
                                  <cfelse>
                                    <span class="text-muted">Sem agregador</span>
                                  </cfif>
                                </td>
                                <td>
                                  <cfif VARIABLES.agregaReviewAdditionalAlreadyLinked>
                                    <span class="badge badge-success">Já vinculado</span>
                                  <cfelseif VARIABLES.agregaReviewAdditionalPending>
                                    <a class="btn btn-outline-secondary btn-sm" href="/administracao/agrega-revisao/?grupo=#qAgregaReviewEventSearch.pending_group_id#" title="#htmlEditFormat(qAgregaReviewEventSearch.pending_group_name)#">Revisão ###qAgregaReviewEventSearch.pending_group_id#</a>
                                  <cfelse>
                                    <span class="badge badge-warning text-dark">Disponível</span>
                                  </cfif>
                                </td>
                              </tr>
                            </cfloop>
                          </tbody>
                        </table>
                      </div>

                      <div class="agrega-review-manual-selection d-flex flex-wrap justify-content-between align-items-center gap-3 mt-3 p-3">
                        <div><strong class="agrega-review-additional-count">0</strong> evento(s) selecionado(s).</div>
                        <button class="btn btn-warning agrega-review-additional-submit" type="submit" disabled onclick="return confirm('Adicionar os eventos selecionados a este grupo de revisão?');"><i class="fa-solid fa-plus me-1"></i> Adicionar ao grupo</button>
                      </div>
                    </form>
                  </cfif>
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
                    <option value="" data-aggregator-name="" data-aggregator-type="">Busque e selecione um agregador...</option>
                    <cfif len(VARIABLES.agregaReviewSuggestedAggregatorLabel)>
                      <option value="#suggested_id_agrega_evento#" data-aggregator-name="#htmlEditFormat(VARIABLES.agregaReviewSuggestedAggregator.nome)#" data-aggregator-type="#htmlEditFormat(VARIABLES.agregaReviewSuggestedAggregator.tipo)#" selected>#htmlEditFormat(VARIABLES.agregaReviewSuggestedAggregatorLabel)#</option>
                    </cfif>
                    <cfif structCount(VARIABLES.agregaReviewCurrentAggregatorOptions)>
                      <cfloop collection="#VARIABLES.agregaReviewCurrentAggregatorOptions#" item="VARIABLES.agregaReviewCurrentAggregatorId">
                        <cfif val(VARIABLES.agregaReviewCurrentAggregatorId) NEQ val(qAgregaReviewGroups.suggested_id_agrega_evento)>
                          <cfset VARIABLES.agregaReviewCurrentAggregator = VARIABLES.agregaReviewCurrentAggregatorOptions[VARIABLES.agregaReviewCurrentAggregatorId] />
                          <cfset VARIABLES.agregaReviewCurrentAggregatorLabel = "###VARIABLES.agregaReviewCurrentAggregator.id# - #VARIABLES.agregaReviewCurrentAggregator.tipo# - #VARIABLES.agregaReviewCurrentAggregator.nome#" />
                          <option value="#VARIABLES.agregaReviewCurrentAggregator.id#" data-aggregator-name="#htmlEditFormat(VARIABLES.agregaReviewCurrentAggregator.nome)#" data-aggregator-type="#htmlEditFormat(VARIABLES.agregaReviewCurrentAggregator.tipo)#" <cfif VARIABLES.agregaReviewAutoSelectedAggregatorId EQ val(VARIABLES.agregaReviewCurrentAggregator.id)>selected</cfif>>#htmlEditFormat(VARIABLES.agregaReviewCurrentAggregatorLabel)#</option>
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
                          <option value="#VARIABLES.agregaReviewSearchAggregator.id#" data-aggregator-name="#htmlEditFormat(VARIABLES.agregaReviewSearchAggregator.nome)#" data-aggregator-type="#htmlEditFormat(VARIABLES.agregaReviewSearchAggregator.tipo)#">#htmlEditFormat(VARIABLES.agregaReviewSearchAggregatorLabel)#</option>
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

              <div class="row g-3 mb-3">
                <div class="col-12 col-lg-8">
                  <label class="form-label" for="agrega-review-final-name-#id_evento_agrega_review_group#">Nome final do agregador</label>
                  <input
                    class="form-control agrega-review-aggregator-final-name"
                    id="agrega-review-final-name-#id_evento_agrega_review_group#"
                    name="nome_agregador_aplicacao"
                    value="#htmlEditFormat(VARIABLES.agregaReviewAutoSelectedAggregatorName)#"
                    placeholder="Ex.: Circuito das Estações - Florianópolis"
                    <cfif status NEQ "review">disabled</cfif>
                  />
                  <div class="form-text text-muted">Você pode acrescentar cidade, estado ou outra identificação antes de aplicar.</div>
                </div>
                <div class="col-12 col-lg-4">
                  <label class="form-label" for="agrega-review-final-type-#id_evento_agrega_review_group#">Tipo final do agregador</label>
                  <select
                    class="form-select agrega-review-aggregator-final-type"
                    id="agrega-review-final-type-#id_evento_agrega_review_group#"
                    name="tipo_agregador_aplicacao"
                    <cfif status NEQ "review">disabled</cfif>
                  >
                    <option value="">Selecione...</option>
                    <cfloop query="qAgregaReviewAggregatorTypes">
                      <option value="#htmlEditFormat(qAgregaReviewAggregatorTypes.tipo_agregacao)#" <cfif qAgregaReviewAggregatorTypes.tipo_agregacao EQ VARIABLES.agregaReviewAutoSelectedAggregatorType>selected</cfif>>#htmlEditFormat(qAgregaReviewAggregatorTypes.tipo_agregacao)#</option>
                    </cfloop>
                  </select>
                  <div class="form-text text-muted">A alteração atualizará o tipo do agregador selecionado.</div>
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
                <button class="btn btn-success btn-sm" <cfif status NEQ "review">disabled</cfif> onclick="this.form.acao.value='aplicar_agregador'; return confirm('Salvar o nome e o tipo finais e aplicar o agregador aos eventos marcados?');"><i class="fa-solid fa-object-group me-1"></i> Aplicar aos selecionados</button>
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
  const manualForm = document.getElementById('agrega-review-manual-form');

  if (manualForm) {
    const manualCheckboxes = Array.from(manualForm.querySelectorAll('.agrega-review-manual-checkbox:not(:disabled)'));
    const manualSelectAll = document.getElementById('agrega-review-manual-select-all');
    const manualCount = document.getElementById('agrega-review-manual-count');
    const manualSubmit = document.getElementById('agrega-review-manual-submit');

    function syncManualSelection() {
      const selected = manualCheckboxes.filter(function (checkbox) {
        return checkbox.checked;
      }).length;

      manualCount.textContent = String(selected);
      manualSubmit.disabled = selected < 2;

      if (manualSelectAll) {
        manualSelectAll.checked = manualCheckboxes.length > 0 && selected === manualCheckboxes.length;
        manualSelectAll.indeterminate = selected > 0 && selected < manualCheckboxes.length;
      }
    }

    manualCheckboxes.forEach(function (checkbox) {
      checkbox.addEventListener('change', syncManualSelection);
    });

    if (manualSelectAll) {
      manualSelectAll.disabled = manualCheckboxes.length === 0;
      manualSelectAll.addEventListener('change', function () {
        manualCheckboxes.forEach(function (checkbox) {
          checkbox.checked = manualSelectAll.checked;
        });
        syncManualSelection();
      });
    }

    syncManualSelection();
  }

  document.querySelectorAll('.agrega-review-additional-form').forEach(function (form) {
    const checkboxes = Array.from(form.querySelectorAll('.agrega-review-additional-checkbox:not(:disabled)'));
    const count = form.querySelector('.agrega-review-additional-count');
    const submit = form.querySelector('.agrega-review-additional-submit');

    function syncAdditionalSelection() {
      const selected = checkboxes.filter(function (checkbox) {
        return checkbox.checked;
      }).length;

      count.textContent = String(selected);
      submit.disabled = selected < 1;
    }

    checkboxes.forEach(function (checkbox) {
      checkbox.addEventListener('change', syncAdditionalSelection);
    });

    syncAdditionalSelection();
  });

  document.querySelectorAll('.agrega-review-aggregator-select').forEach(function (select) {
    const form = select.closest('form');
    const finalNameInput = form ? form.querySelector('.agrega-review-aggregator-final-name') : null;
    const finalTypeInput = form ? form.querySelector('.agrega-review-aggregator-final-type') : null;

    if (!finalNameInput || !finalTypeInput) {
      return;
    }

    function syncAggregatorFields() {
      const selectedOption = select.options[select.selectedIndex];
      finalNameInput.value = selectedOption ? (selectedOption.dataset.aggregatorName || '') : '';
      finalTypeInput.value = selectedOption ? (selectedOption.dataset.aggregatorType || '') : '';
    }

    select.addEventListener('change', syncAggregatorFields);

    if (!finalNameInput.value.trim() || !finalTypeInput.value) {
      syncAggregatorFields();
    }
  });

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
