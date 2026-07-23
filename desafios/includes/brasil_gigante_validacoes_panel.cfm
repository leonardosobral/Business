<section class="card cbg-validation-panel mb-3" id="validacoes-documentais">
  <header class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2 px-3 py-2">
    <div>
      <div class="fw-bold"><i class="fa-solid fa-file-shield me-2"></i>Validações documentais</div>
      <div class="small text-muted">Comprovantes enviados pelos atletas para conferência manual.</div>
    </div>
    <div class="d-flex gap-1">
      <span class="badge badge-warning"><cfoutput>#VARIABLES.cbgValidationPendingCount#</cfoutput> pendente(s)</span>
      <span class="badge badge-success"><cfoutput>#VARIABLES.cbgValidationApprovedCount#</cfoutput> aprovada(s)</span>
      <span class="badge badge-danger"><cfoutput>#VARIABLES.cbgValidationRejectedCount#</cfoutput> desaprovada(s)</span>
    </div>
  </header>

  <div class="card-body p-3">
    <cfif isDefined("URL.validacao")>
      <cfswitch expression="#URL.validacao#">
        <cfcase value="aprovada"><div class="alert alert-success">Documento aprovado e resultado manual criado.</div></cfcase>
        <cfcase value="resultado_vinculado"><div class="alert alert-success">Resultado oficial vinculado ao atleta e participação reconhecida.</div></cfcase>
        <cfcase value="desaprovada"><div class="alert alert-warning">Solicitação documental desaprovada.</div></cfcase>
        <cfcase value="resultado_existente"><div class="alert alert-danger">Aprovação bloqueada: o atleta já possui resultado reconhecido nessa etapa.</div></cfcase>
        <cfcase value="peito_existente"><div class="alert alert-danger">Aprovação bloqueada: o número de peito já pertence a outro resultado desse evento.</div></cfcase>
        <cfcase value="ja_analisada"><div class="alert alert-warning">Esta solicitação já foi analisada.</div></cfcase>
        <cfcase value="motivo_desaprovacao_obrigatorio"><div class="alert alert-warning">Informe o motivo da desaprovação com pelo menos 5 caracteres.</div></cfcase>
        <cfcase value="resultado_oficial_invalido"><div class="alert alert-danger">O resultado selecionado não corresponde à prova, ao ano e ao percurso da solicitação.</div></cfcase>
        <cfcase value="resultado_oficial_vinculado_outro"><div class="alert alert-danger">O resultado oficial selecionado já está vinculado a outro atleta.</div></cfcase>
        <cfcase value="sem_permissao"><div class="alert alert-danger">Somente ADMINs e DEVs podem aprovar ou desaprovar documentos.</div></cfcase>
        <cfcase value="solicitacao_invalida"><div class="alert alert-danger">A solicitação expirou ou contém dados inválidos. Atualize a página e tente novamente.</div></cfcase>
        <cfcase value="erro"><div class="alert alert-danger">Não foi possível concluir a análise. Nenhuma alteração foi gravada.</div></cfcase>
      </cfswitch>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.cbgValidationRequests)>
      <div class="text-muted">Nenhuma solicitação documental recebida.</div>
    <cfelse>
      <div class="cbg-validation-filterbar" role="group" aria-label="Filtrar validações por status">
        <button type="button" class="cbg-validation-filter is-active" data-cbg-validation-filter="todos"><i class="fa-solid fa-layer-group"></i>Todos <span class="badge bg-secondary"><cfoutput>#arrayLen(VARIABLES.cbgValidationRequests)#</cfoutput></span></button>
        <button type="button" class="cbg-validation-filter" data-cbg-validation-filter="pendente"><i class="fa-solid fa-clock text-warning"></i>Pendentes <span class="badge badge-warning"><cfoutput>#VARIABLES.cbgValidationPendingCount#</cfoutput></span></button>
        <button type="button" class="cbg-validation-filter" data-cbg-validation-filter="aprovado"><i class="fa-solid fa-circle-check text-success"></i>Aprovadas <span class="badge badge-success"><cfoutput>#VARIABLES.cbgValidationApprovedCount#</cfoutput></span></button>
        <button type="button" class="cbg-validation-filter" data-cbg-validation-filter="desaprovado"><i class="fa-solid fa-circle-xmark text-danger"></i>Negadas <span class="badge badge-danger"><cfoutput>#VARIABLES.cbgValidationRejectedCount#</cfoutput></span></button>
      </div>
      <div class="row g-3 cbg-validation-list">
        <cfloop array="#VARIABLES.cbgValidationRequests#" item="VARIABLES.cbgRequest" index="VARIABLES.cbgRequestIndex">
          <cfset VARIABLES.cbgStatusClass = VARIABLES.cbgRequest.status EQ "aprovado" ? "badge-success" : (VARIABLES.cbgRequest.status EQ "desaprovado" ? "badge-danger" : "badge-warning")/>
          <cfset VARIABLES.cbgStatusIcon = VARIABLES.cbgRequest.status EQ "aprovado" ? "fa-circle-check" : (VARIABLES.cbgRequest.status EQ "desaprovado" ? "fa-circle-xmark" : "fa-clock")/>
          <cfset VARIABLES.cbgRequestNeedsResult = VARIABLES.cbgRequest.status EQ "pendente" OR (VARIABLES.cbgRequest.status EQ "aprovado" AND NOT len(VARIABLES.cbgRequest.resultId & ""))/>
          <cfset VARIABLES.cbgRequestCanLinkOfficial = NOT len(VARIABLES.cbgRequest.resultId & "") AND listFindNoCase("pendente,desaprovado,aprovado", VARIABLES.cbgRequest.status)/>
          <div class="col-12 cbg-validation-list-item" data-validation-status="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.status)#</cfoutput>">
            <article class="cbg-validation-card cbg-validation-card--<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.status)#</cfoutput> p-3 p-lg-4">
              <div class="d-flex flex-wrap justify-content-between align-items-start gap-3">
                <div class="d-flex gap-3 align-items-center min-w-0">
                  <div class="rounded-circle d-flex align-items-center justify-content-center bg-body-tertiary flex-shrink-0" style="width:46px;height:46px"><i class="fa-solid fa-user-shield"></i></div>
                  <div class="min-w-0">
                  <div class="fw-bold fs-5 text-truncate"><cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.athleteName)#</cfoutput></div>
                  <div class="small text-muted"><cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.email)# · ID #VARIABLES.cbgRequest.userId#</cfoutput></div>
                  <cfif len(VARIABLES.cbgRequest.athleteTag)>
                    <a class="small" href="https://roadrunners.run/atleta/<cfoutput>#urlEncodedFormat(VARIABLES.cbgRequest.athleteTag)#</cfoutput>/" target="_blank" rel="noopener noreferrer">
                      <i class="fa-solid fa-user me-1"></i>Ver perfil no Road Runners
                    </a>
                  </cfif>
                  </div>
                </div>
                <span class="cbg-validation-status cbg-validation-status--<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.status)#</cfoutput>"><i class="fa-solid <cfoutput>#VARIABLES.cbgStatusIcon#</cfoutput>"></i><cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.status)#</cfoutput></span>
              </div>

              <div class="cbg-validation-summary">
                <div class="cbg-validation-summary-item"><span class="cbg-validation-summary-label">Prova</span><strong><cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.race)#</cfoutput></strong></div>
                <div class="cbg-validation-summary-item"><span class="cbg-validation-summary-label">Ano</span><strong><cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.year)#</cfoutput></strong></div>
                <div class="cbg-validation-summary-item"><span class="cbg-validation-summary-label">Número de peito</span><strong><cfoutput>#len(trim(VARIABLES.cbgRequest.bib & "")) ? htmlEditFormat(VARIABLES.cbgRequest.bib) : "—"#</cfoutput></strong></div>
                <div class="cbg-validation-summary-item"><span class="cbg-validation-summary-label">Enviada em</span><strong class="small"><cfoutput>#len(trim(VARIABLES.cbgRequest.sentAt & "")) ? htmlEditFormat(VARIABLES.cbgRequest.sentAt) : "—"#</cfoutput></strong></div>
              </div>

              <div class="cbg-validation-detail-grid">
                <div>
                  <span class="cbg-validation-summary-label">Justificativa do atleta</span>
                  <p class="small mb-0"><cfoutput>#len(trim(VARIABLES.cbgRequest.explanation & "")) ? htmlEditFormat(VARIABLES.cbgRequest.explanation) : "Nenhuma justificativa informada."#</cfoutput></p>
                  <cfif len(trim(VARIABLES.cbgRequest.officialUrl & ""))><a class="small d-inline-block mt-2" href="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.officialUrl)#</cfoutput>" target="_blank" rel="noopener noreferrer"><i class="fa-solid fa-arrow-up-right-from-square me-1"></i>Abrir resultado informado pelo atleta</a></cfif>
                </div>
                <div>
                  <span class="cbg-validation-summary-label">Documentos enviados</span>
                  <div class="cbg-validation-files">
                    <cfloop array="#VARIABLES.cbgRequest.files#" item="VARIABLES.cbgRequestFile">
                      <cfif len(VARIABLES.cbgRequestFile.url)><a class="btn btn-outline-secondary btn-sm" href="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequestFile.url)#</cfoutput>" target="_blank" rel="noopener noreferrer"><i class="fa-solid fa-paperclip me-1"></i><cfoutput>#htmlEditFormat(VARIABLES.cbgRequestFile.name)#</cfoutput></a></cfif>
                    </cfloop>
                    <cfif NOT arrayLen(VARIABLES.cbgRequest.files)><span class="small text-muted">Nenhum arquivo disponível.</span></cfif>
                  </div>
                </div>
              </div>
              <div class="small text-muted mt-3"><i class="fa-solid fa-fingerprint me-1"></i>Protocolo <cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.protocol)#</cfoutput><cfif len(VARIABLES.cbgRequest.resultId & "")> · Resultado ID <cfoutput>#VARIABLES.cbgRequest.resultId#</cfoutput></cfif><cfif VARIABLES.cbgRequest.approvalType EQ "resultado_oficial_vinculado"> · Resultado oficial vinculado<cfelseif VARIABLES.cbgRequest.approvalType EQ "resultado_manual_documental"> · Resultado manual documental</cfif></div>

              <cfif VARIABLES.cbgRequest.status EQ "aprovado" AND VARIABLES.cbgRequestNeedsResult>
                <div class="alert alert-warning py-2 small">Aprovação migrada sem resultado vinculado. Confira os dados para concluir a criação.</div>
              </cfif>
              <cfif VARIABLES.cbgRequest.status EQ "desaprovado" AND len(trim(VARIABLES.cbgRequest.rejectionReason & ""))>
                <div class="alert alert-danger py-2 small mt-3 mb-0"><strong><i class="fa-solid fa-message me-1"></i>Motivo da desaprovação:</strong> <cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.rejectionReason)#</cfoutput></div>
              </cfif>

              <cfif VARIABLES.cbgRequestNeedsResult OR VARIABLES.cbgRequestCanLinkOfficial>
                <cfif VARIABLES.cbgValidationCanDecide>
                  <div class="d-flex flex-wrap gap-2 cbg-validation-actions">
                    <cfif VARIABLES.cbgRequestNeedsResult>
                      <button class="btn btn-success btn-sm" type="button" data-mdb-ripple-init data-mdb-modal-init data-mdb-target="#cbgValidationModal<cfoutput>#VARIABLES.cbgRequestIndex#</cfoutput>" <cfif NOT arrayLen(VARIABLES.cbgRequest.events)>disabled title="Nenhum evento correspondente foi encontrado"</cfif>>
                        <i class="fa-solid fa-file-circle-check me-1"></i><cfif VARIABLES.cbgRequest.status EQ "aprovado">Criar resultado pendente<cfelse>Aprovar por documento</cfif>
                      </button>
                    </cfif>
                    <cfif VARIABLES.cbgRequestCanLinkOfficial>
                      <button class="btn btn-primary btn-sm" type="button" data-mdb-ripple-init data-mdb-modal-init data-mdb-target="#cbgOfficialResultModal<cfoutput>#VARIABLES.cbgRequestIndex#</cfoutput>">
                        <i class="fa-solid fa-link me-1"></i>Vincular resultado oficial
                      </button>
                    </cfif>
                    <cfif VARIABLES.cbgRequest.status EQ "pendente">
                      <button class="btn btn-outline-danger btn-sm" type="button" data-mdb-ripple-init data-mdb-modal-init data-mdb-target="#cbgRejectValidationModal<cfoutput>#VARIABLES.cbgRequestIndex#</cfoutput>"><i class="fa-solid fa-xmark me-1"></i>Desaprovar</button>
                    </cfif>
                  </div>
                <cfelse>
                  <div class="small text-muted">Aguardando decisão de um ADMIN.</div>
                </cfif>
              </cfif>
            </article>
          </div>

          <cfif VARIABLES.cbgRequestNeedsResult AND VARIABLES.cbgValidationCanDecide AND arrayLen(VARIABLES.cbgRequest.events)>
            <div class="modal fade" id="cbgValidationModal<cfoutput>#VARIABLES.cbgRequestIndex#</cfoutput>" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content">
                  <form method="post">
                    <div class="modal-header">
                      <h2 class="modal-title fs-5">Conferir e criar resultado manual</h2>
                      <button type="button" class="btn-close" data-mdb-ripple-init data-mdb-dismiss="modal" aria-label="Fechar"></button>
                    </div>
                    <div class="modal-body">
                      <div class="alert alert-warning small">Este resultado contará somente para o Circuito Brasil Gigante. Ele será identificado como validação documental, ficará fora do Open Results e aparecerá no perfil Road Runners como reconhecido manualmente.</div>
                      <div class="row g-3">
                        <div class="col-12">
                          <label class="form-label">Atleta/usuário</label>
                          <input class="form-control" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.athleteName)# · ID #VARIABLES.cbgRequest.userId# · #htmlEditFormat(VARIABLES.cbgRequest.email)#</cfoutput>" readonly/>
                        </div>
                        <div class="col-12">
                          <label class="form-label">Nome no resultado</label>
                          <input class="form-control" name="nome" maxlength="255" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.athleteName)#</cfoutput>" required/>
                        </div>
                        <div class="col-md-5">
                          <label class="form-label">Evento</label>
                          <select class="form-select" name="id_evento" required>
                            <cfloop array="#VARIABLES.cbgRequest.events#" item="VARIABLES.cbgRequestEvent">
                              <option value="<cfoutput>#VARIABLES.cbgRequestEvent.id#</cfoutput>"><cfoutput>#htmlEditFormat(VARIABLES.cbgRequestEvent.name)# · ID #VARIABLES.cbgRequestEvent.id#</cfoutput></option>
                            </cfloop>
                          </select>
                        </div>
                        <div class="col-md-5">
                          <label class="form-label">Número de peito</label>
                          <input class="form-control" type="number" min="1" step="1" name="num_peito" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.bib)#</cfoutput>" required/>
                        </div>
                        <div class="col-md-6">
                          <label class="form-label">Sexo</label>
                          <select class="form-select" name="sexo" required>
                            <option value="">Selecione</option>
                            <option value="F" <cfif VARIABLES.cbgRequest.sex EQ "F">selected</cfif>>Feminino</option>
                            <option value="M" <cfif VARIABLES.cbgRequest.sex EQ "M">selected</cfif>>Masculino</option>
                            <option value="X" <cfif VARIABLES.cbgRequest.sex EQ "X">selected</cfif>>Não informado</option>
                          </select>
                        </div>
                        <div class="col-md-6">
                          <label class="form-label">Data de nascimento</label>
                          <input class="form-control" type="date" name="data_nascimento" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.birthDate)#</cfoutput>"/>
                        </div>
                        <div class="col-md-4"><label class="form-label">Percurso</label><input class="form-control" value="42 km" readonly/></div>
                        <div class="col-md-4"><label class="form-label">Homologado</label><input class="form-control" value="Não" readonly/></div>
                        <div class="col-md-4"><label class="form-label">Concluinte</label><input class="form-control" value="Sim" readonly/></div>
                      </div>
                    </div>
                    <div class="modal-footer">
                      <input type="hidden" name="challenge_action" value="aprovar_validacao_documental"/>
                      <input type="hidden" name="challenge_medal_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.challengeMedalCsrf)#</cfoutput>"/>
                      <input type="hidden" name="id_usuario" value="<cfoutput>#VARIABLES.cbgRequest.userId#</cfoutput>"/>
                      <input type="hidden" name="protocolo" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.protocol)#</cfoutput>"/>
                      <button type="button" class="btn btn-outline-secondary" data-mdb-ripple-init data-mdb-dismiss="modal">Cancelar</button>
                      <button type="submit" class="btn btn-success"><i class="fa-solid fa-check me-1"></i>Confirmar aprovação</button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </cfif>

          <cfif VARIABLES.cbgRequest.status EQ "pendente" AND VARIABLES.cbgValidationCanDecide>
            <div class="modal fade" id="cbgRejectValidationModal<cfoutput>#VARIABLES.cbgRequestIndex#</cfoutput>" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                  <form method="post">
                    <div class="modal-header">
                      <h2 class="modal-title fs-5">Desaprovar validação documental</h2>
                      <button type="button" class="btn-close" data-mdb-ripple-init data-mdb-dismiss="modal" aria-label="Fechar"></button>
                    </div>
                    <div class="modal-body">
                      <p class="small text-muted">Informe por que os documentos de <strong><cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.athleteName)#</cfoutput></strong> não foram aceitos.</p>
                      <label class="form-label" for="cbgRejectionReason<cfoutput>#VARIABLES.cbgRequestIndex#</cfoutput>">Motivo da desaprovação</label>
                      <textarea class="form-control" id="cbgRejectionReason<cfoutput>#VARIABLES.cbgRequestIndex#</cfoutput>" name="motivo_desaprovacao" rows="4" minlength="5" maxlength="2000" required></textarea>
                      <div class="form-text">Esta observação ficará registrada no histórico da solicitação.</div>
                    </div>
                    <div class="modal-footer">
                      <input type="hidden" name="challenge_action" value="desaprovar_validacao_documental"/>
                      <input type="hidden" name="challenge_medal_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.challengeMedalCsrf)#</cfoutput>"/>
                      <input type="hidden" name="id_usuario" value="<cfoutput>#VARIABLES.cbgRequest.userId#</cfoutput>"/>
                      <input type="hidden" name="protocolo" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.protocol)#</cfoutput>"/>
                      <button type="button" class="btn btn-outline-secondary" data-mdb-ripple-init data-mdb-dismiss="modal">Cancelar</button>
                      <button type="submit" class="btn btn-danger"><i class="fa-solid fa-circle-xmark me-1"></i>Confirmar desaprovação</button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </cfif>

          <cfif VARIABLES.cbgRequestCanLinkOfficial AND VARIABLES.cbgValidationCanDecide>
            <div class="modal fade" id="cbgOfficialResultModal<cfoutput>#VARIABLES.cbgRequestIndex#</cfoutput>" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content">
                  <form method="post" onsubmit="return confirm('Vincular este resultado oficial ao atleta?');">
                    <div class="modal-header">
                      <h2 class="modal-title fs-5">Vincular resultado oficial existente</h2>
                      <button type="button" class="btn-close" data-mdb-ripple-init data-mdb-dismiss="modal" aria-label="Fechar"></button>
                    </div>
                    <div class="modal-body">
                      <div class="alert alert-info small">O registro oficial será preservado integralmente. Apenas o vínculo com o atleta será realizado; tempos, classificações, homologação e visibilidade no Open Results não serão alterados.</div>
                      <dl class="row small mb-3">
                        <dt class="col-sm-3">Atleta</dt><dd class="col-sm-9"><cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.athleteName)# · ID #VARIABLES.cbgRequest.userId#</cfoutput></dd>
                        <dt class="col-sm-3">Solicitação</dt><dd class="col-sm-9"><cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.race)# · #htmlEditFormat(VARIABLES.cbgRequest.year)# · Peito #htmlEditFormat(VARIABLES.cbgRequest.bib)#</cfoutput></dd>
                      </dl>
                      <div class="row g-2 align-items-end cbg-official-search"
                           data-search-url="/desafios/buscar_resultados_brasil_gigante.cfm"
                           data-user-id="<cfoutput>#VARIABLES.cbgRequest.userId#</cfoutput>"
                           data-protocol="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.protocol)#</cfoutput>"
                           data-csrf="<cfoutput>#htmlEditFormat(VARIABLES.challengeMedalCsrf)#</cfoutput>">
                        <div class="col-md-7">
                          <label class="form-label">Nome no resultado</label>
                          <input class="form-control cbg-official-search-name" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.athleteName)#</cfoutput>"/>
                        </div>
                        <div class="col-md-3">
                          <label class="form-label">Número de peito</label>
                          <input class="form-control cbg-official-search-bib" type="number" min="1" step="1" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.bib)#</cfoutput>"/>
                        </div>
                        <div class="col-md-2">
                          <label class="form-label">Ano</label>
                          <input class="form-control cbg-official-search-year" name="ano_resultado" type="number" min="1900" max="<cfoutput>#year(now())#</cfoutput>" step="1" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.year)#</cfoutput>" required/>
                        </div>
                        <div class="col-md-2 d-grid">
                          <button class="btn btn-outline-primary cbg-official-search-button" type="button"><i class="fa-solid fa-magnifying-glass me-1"></i>Buscar</button>
                        </div>
                        <div class="col-12">
                          <div class="small text-muted cbg-official-search-feedback mb-2"><cfif arrayLen(VARIABLES.cbgRequest.officialCandidates)>Sugestões encontradas automaticamente. Confira e selecione o resultado correto.<cfelse>Nenhuma sugestão automática encontrada. Altere o nome ou o peito e faça uma nova busca.</cfif></div>
                          <div class="list-group cbg-official-search-results">
                            <cfloop array="#VARIABLES.cbgRequest.officialCandidates#" item="VARIABLES.cbgOfficialCandidate" index="VARIABLES.cbgOfficialCandidateIndex">
                              <label class="list-group-item list-group-item-action d-flex gap-2 align-items-start">
                                <input class="form-check-input mt-1" type="radio" name="id_resultado" value="<cfoutput>#VARIABLES.cbgOfficialCandidate.id#</cfoutput>" <cfif VARIABLES.cbgOfficialCandidateIndex EQ 1>checked</cfif> required/>
                                <span class="small"><strong><cfoutput>#htmlEditFormat(VARIABLES.cbgOfficialCandidate.name)#</cfoutput></strong> · Peito <cfoutput>#htmlEditFormat(VARIABLES.cbgOfficialCandidate.bib)#</cfoutput> · Tempo <cfoutput>#htmlEditFormat(VARIABLES.cbgOfficialCandidate.time)#</cfoutput><br><span class="text-muted"><cfoutput>#htmlEditFormat(VARIABLES.cbgOfficialCandidate.eventName)# · Resultado ID #VARIABLES.cbgOfficialCandidate.id#</cfoutput></span></span>
                              </label>
                            </cfloop>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div class="modal-footer">
                      <input type="hidden" name="challenge_action" value="vincular_resultado_oficial"/>
                      <input type="hidden" name="challenge_medal_csrf" value="<cfoutput>#htmlEditFormat(VARIABLES.challengeMedalCsrf)#</cfoutput>"/>
                      <input type="hidden" name="id_usuario" value="<cfoutput>#VARIABLES.cbgRequest.userId#</cfoutput>"/>
                      <input type="hidden" name="protocolo" value="<cfoutput>#htmlEditFormat(VARIABLES.cbgRequest.protocol)#</cfoutput>"/>
                      <button type="button" class="btn btn-outline-secondary" data-mdb-ripple-init data-mdb-dismiss="modal">Cancelar</button>
                      <button type="submit" class="btn btn-primary cbg-official-link-submit" <cfif NOT arrayLen(VARIABLES.cbgRequest.officialCandidates)>disabled</cfif>><i class="fa-solid fa-link me-1"></i>Confirmar vínculo oficial</button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </cfif>
        </cfloop>
      </div>
      <div class="alert alert-secondary text-center mt-3 d-none cbg-validation-filter-empty">Nenhuma validação encontrada neste status.</div>
    </cfif>
  </div>
</section>

<script>
document.addEventListener('click', function (event) {
  const filterButton = event.target.closest('[data-cbg-validation-filter]');
  if (!filterButton) return;

  const panel = filterButton.closest('.cbg-validation-panel');
  const selectedStatus = filterButton.dataset.cbgValidationFilter;
  let visibleCount = 0;

  panel.querySelectorAll('[data-cbg-validation-filter]').forEach(function (button) {
    button.classList.toggle('is-active', button === filterButton);
  });
  panel.querySelectorAll('.cbg-validation-list-item').forEach(function (item) {
    const visible = selectedStatus === 'todos' || item.dataset.validationStatus === selectedStatus;
    item.classList.toggle('d-none', !visible);
    if (visible) visibleCount += 1;
  });
  panel.querySelector('.cbg-validation-filter-empty').classList.toggle('d-none', visibleCount > 0);
});

document.addEventListener('click', async function (event) {
  const button = event.target.closest('.cbg-official-search-button');
  if (!button) return;

  const search = button.closest('.cbg-official-search');
  const name = search.querySelector('.cbg-official-search-name').value.trim();
  const bib = search.querySelector('.cbg-official-search-bib').value.trim();
  const year = search.querySelector('.cbg-official-search-year').value.trim();
  const feedback = search.querySelector('.cbg-official-search-feedback');
  const results = search.querySelector('.cbg-official-search-results');
  const submit = search.closest('form').querySelector('.cbg-official-link-submit');
  const params = new URLSearchParams({
    tela: 'validacoes',
    cbg_result_search: '1',
    id_usuario: search.dataset.userId,
    protocolo: search.dataset.protocol,
    csrf: search.dataset.csrf,
    nome: name,
    num_peito: bib,
    ano: year
  });

  button.disabled = true;
  submit.disabled = true;
  feedback.textContent = 'Buscando resultados oficiais...';
  results.replaceChildren();

  try {
    const response = await fetch(search.dataset.searchUrl + '?' + params.toString(), {
      headers: {'Accept': 'application/json'},
      credentials: 'same-origin'
    });
    const payload = await response.json();
    const success = payload.success ?? payload.SUCCESS ?? false;
    const foundResults = payload.results ?? payload.RESULTS ?? [];
    const message = payload.message ?? payload.MESSAGE ?? '';
    if (!response.ok || !success) throw new Error(message || 'Não foi possível realizar a busca.');

    if (!foundResults.length) {
      feedback.textContent = 'Nenhum resultado encontrado. Revise o nome ou o número de peito e tente novamente.';
      return;
    }

    let hasSelectableResult = false;
    foundResults.forEach(function (rawItem) {
      const item = {
        id: rawItem.id ?? rawItem.ID ?? '',
        name: rawItem.name ?? rawItem.NAME ?? '',
        bib: rawItem.bib ?? rawItem.BIB ?? '',
        time: rawItem.time ?? rawItem.TIME ?? '',
        eventName: rawItem.eventName ?? rawItem.EVENTNAME ?? '',
        linkedUserId: Number(rawItem.linkedUserId ?? rawItem.LINKEDUSERID ?? 0),
        provisionalLink: rawItem.provisionalLink ?? rawItem.PROVISIONALLINK ?? false,
        distance: rawItem.distance ?? rawItem.DISTANCE ?? ''
      };
      const label = document.createElement('label');
      label.className = 'list-group-item list-group-item-action d-flex gap-2 align-items-start';
      const radio = document.createElement('input');
      radio.className = 'form-check-input mt-1';
      radio.type = 'radio';
      radio.name = 'id_resultado';
      radio.value = item.id;
      radio.required = true;
      radio.disabled = item.linkedUserId > 0;
      radio.checked = !hasSelectableResult && !radio.disabled;
      if (radio.checked) hasSelectableResult = true;
      const text = document.createElement('span');
      text.className = 'small';
      const title = document.createElement('strong');
      title.textContent = item.name;
      const detail = document.createTextNode(' · Peito ' + (item.bib || '-') + ' · ' + (item.distance || '-') + ' km · Tempo ' + (item.time || '-'));
      const meta = document.createElement('span');
      meta.className = 'text-muted';
      meta.textContent = item.eventName + ' · Resultado ID ' + item.id + (item.linkedUserId > 0 ? ' · Já vinculado ao usuário ID ' + item.linkedUserId : (item.provisionalLink ? ' · Vínculo provisório ID 0 — pode ser substituído' : ' · Disponível para vínculo'));
      text.append(title, detail, document.createElement('br'), meta);
      label.append(radio, text);
      results.append(label);
    });
    submit.disabled = !hasSelectableResult;
    feedback.textContent = hasSelectableResult
      ? foundResults.length + ' resultado(s) encontrado(s). O primeiro disponível foi sugerido; confira antes de confirmar.'
      : foundResults.length + ' resultado(s) encontrado(s), mas todos já estão vinculados a outros usuários.';
  } catch (error) {
    feedback.textContent = error.message || 'Não foi possível realizar a busca.';
  } finally {
    button.disabled = false;
  }
});
</script>
