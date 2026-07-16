<cfinclude template="../includes/agenda_management_backend.cfm"/>

<cfset VARIABLES.agendaShowEditor = len(trim(URL.nova)) GT 0 OR qAgendaManagementEdit.recordcount GT 0 OR FORM.acao EQ "salvar_agenda"/>
<cfset VARIABLES.agendaBaseUrl = agendaServiceBuildBaseUrl()/>

<style>
  .agenda-shell {
    --agenda-accent: #fab120;
    --agenda-border: rgba(255, 255, 255, .1);
  }

  .agenda-panel {
    background: linear-gradient(145deg, rgba(255, 255, 255, .045), rgba(255, 255, 255, .012));
    border: 1px solid var(--agenda-border);
    border-radius: 1rem;
  }

  .agenda-kicker {
    color: var(--agenda-accent);
    font-size: .72rem;
    font-weight: 800;
    letter-spacing: .08em;
    text-transform: uppercase;
  }

  .agenda-status {
    border: 1px solid currentColor;
    border-radius: 999px;
    display: inline-flex;
    font-size: .68rem;
    font-weight: 800;
    letter-spacing: .04em;
    padding: .22rem .55rem;
    text-transform: uppercase;
  }

  .agenda-status.is-active { color: #60d394; }
  .agenda-status.is-draft { color: #c9c9c9; }
  .agenda-status.is-paused { color: #fab120; }
  .agenda-status.is-archived { color: #ff7b7b; }

  .agenda-rule {
    align-items: center;
    background: rgba(250, 177, 32, .09);
    border: 1px solid rgba(250, 177, 32, .22);
    border-radius: 999px;
    display: inline-flex;
    gap: .45rem;
    padding: .35rem .4rem .35rem .65rem;
  }

  .agenda-rule form { line-height: 1; }

  .agenda-preview {
    --agenda-preview-card: #1b2027;
    --agenda-preview-card-2: #232a33;
    --agenda-preview-text: #f7f8fa;
    --agenda-preview-muted: #aeb7c2;
    --agenda-preview-border: rgba(255, 255, 255, .1);
    --agenda-preview-chip: rgba(255, 255, 255, .07);
    --agenda-preview-date: #fab120;
    --agenda-preview-date-text: #171717;
    --agenda-preview-font: "Trebuchet MS", "Avenir Next", sans-serif;
    --agenda-preview-card-radius: .95rem;
    --agenda-preview-date-radius: .75rem;
    color: var(--agenda-preview-text);
    margin-inline: auto;
    max-width: 680px;
    min-width: min(280px, 100%);
  }

  .agenda-preview.is-light {
    --agenda-preview-card: rgba(255, 255, 255, .96);
    --agenda-preview-card-2: rgba(247, 248, 250, .96);
    --agenda-preview-text: #171a1f;
    --agenda-preview-muted: #5f6874;
    --agenda-preview-border: rgba(17, 24, 39, .14);
    --agenda-preview-chip: rgba(17, 24, 39, .07);
  }

  .agenda-preview[data-card-font="verdana"] { --agenda-preview-font: Verdana, Geneva, sans-serif; }
  .agenda-preview[data-card-font="georgia"] { --agenda-preview-font: Georgia, "Times New Roman", serif; }
  .agenda-preview[data-card-font="tahoma"] { --agenda-preview-font: Tahoma, Geneva, sans-serif; }
  .agenda-preview[data-card-font="monospace"] { --agenda-preview-font: "Courier New", Courier, monospace; }
  .agenda-preview[data-card-radius="medio"] { --agenda-preview-card-radius: .625rem; --agenda-preview-date-radius: .5rem; }
  .agenda-preview[data-card-radius="suave"] { --agenda-preview-card-radius: .3125rem; --agenda-preview-date-radius: .25rem; }
  .agenda-preview[data-card-radius="reto"] { --agenda-preview-card-radius: 0; --agenda-preview-date-radius: 0; }

  .agenda-preview .text-muted { color: var(--agenda-preview-muted) !important; }

  .agenda-preview-card {
    background: linear-gradient(135deg, var(--agenda-preview-card-2), var(--agenda-preview-card));
    border: 1px solid var(--agenda-preview-border);
    border-radius: var(--agenda-preview-card-radius);
    color: var(--agenda-preview-text);
    display: grid;
    font-family: var(--agenda-preview-font);
    gap: .9rem;
    grid-template-columns: 64px minmax(0, 1fr);
    margin-bottom: .75rem;
    padding: .9rem;
    text-decoration: none;
  }

  .agenda-preview-card:hover,
  .agenda-preview-card:focus-visible {
    border-color: var(--agenda-preview-date);
    color: var(--agenda-preview-text);
    outline: 0;
  }

  .agenda-preview-date {
    align-self: start;
    background: var(--agenda-preview-date);
    border-radius: var(--agenda-preview-date-radius);
    color: var(--agenda-preview-date-text);
    line-height: 1;
    padding: .55rem .25rem;
    text-align: center;
  }

  .agenda-preview-date strong { display: block; font-size: 1.35rem; }
  .agenda-preview-date span { font-size: .68rem; font-weight: 800; text-transform: uppercase; }

  .agenda-distance {
    background: var(--agenda-preview-chip);
    border-radius: 999px;
    color: var(--agenda-preview-text);
    display: inline-flex;
    font-size: .72rem;
    margin: .2rem .2rem 0 0;
    padding: .25rem .48rem;
  }

  .agenda-code {
    background: #101318;
    border: 1px solid var(--agenda-border);
    border-radius: .75rem;
    color: #d9e1ea;
    font-family: "IBM Plex Mono", "Courier New", monospace;
    font-size: .75rem;
    min-height: 96px;
    resize: vertical;
  }

  .agenda-table th { white-space: nowrap; }
  .agenda-table td { vertical-align: middle; }
  .agenda-event-name { min-width: 240px; }

  .agenda-editor-head {
    background:
      radial-gradient(circle at 92% 12%, rgba(250, 177, 32, .2), transparent 34%),
      linear-gradient(145deg, rgba(255, 255, 255, .06), rgba(255, 255, 255, .015));
    overflow: hidden;
  }

  .agenda-editor-title {
    max-width: 760px;
  }

  .agenda-steps {
    display: grid;
    gap: .65rem;
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .agenda-step {
    align-items: center;
    background: rgba(255, 255, 255, .035);
    border: 1px solid var(--agenda-border);
    border-radius: .8rem;
    color: inherit;
    display: flex;
    gap: .65rem;
    min-width: 0;
    padding: .7rem .8rem;
    text-decoration: none;
  }

  .agenda-step:hover {
    border-color: rgba(250, 177, 32, .5);
    color: inherit;
  }

  .agenda-step.is-current {
    background: rgba(250, 177, 32, .1);
    border-color: rgba(250, 177, 32, .5);
  }

  .agenda-step.is-disabled {
    opacity: .45;
    pointer-events: none;
  }

  .agenda-step-number {
    align-items: center;
    background: rgba(255, 255, 255, .08);
    border-radius: 50%;
    display: inline-flex;
    flex: 0 0 30px;
    font-size: .75rem;
    font-weight: 800;
    height: 30px;
    justify-content: center;
  }

  .agenda-step.is-current .agenda-step-number {
    background: var(--agenda-accent);
    color: #161616;
  }

  .agenda-step strong,
  .agenda-step small { display: block; }
  .agenda-step small { color: rgba(255, 255, 255, .55); font-size: .7rem; }

  .agenda-form-section + .agenda-form-section {
    border-top: 1px solid var(--agenda-border);
    margin-top: 1.5rem;
    padding-top: 1.5rem;
  }

  .agenda-section-icon {
    align-items: center;
    background: rgba(250, 177, 32, .12);
    border-radius: .7rem;
    color: var(--agenda-accent);
    display: inline-flex;
    flex: 0 0 38px;
    height: 38px;
    justify-content: center;
  }

  .agenda-choice-grid {
    display: grid;
    gap: .75rem;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .agenda-choice {
    cursor: pointer;
    display: block;
    margin: 0;
    position: relative;
  }

  .agenda-choice input {
    opacity: 0;
    position: absolute;
  }

  .agenda-choice-content {
    background: rgba(255, 255, 255, .025);
    border: 1px solid var(--agenda-border);
    border-radius: .8rem;
    display: block;
    min-height: 100%;
    padding: .9rem;
    transition: border-color .15s ease, background .15s ease;
  }

  .agenda-choice input:checked + .agenda-choice-content {
    background: rgba(250, 177, 32, .09);
    border-color: rgba(250, 177, 32, .65);
    box-shadow: inset 3px 0 0 var(--agenda-accent);
  }

  .agenda-choice input:focus-visible + .agenda-choice-content {
    outline: 2px solid var(--agenda-accent);
    outline-offset: 2px;
  }

  .agenda-owner-search,
  .agenda-subpanel {
    background: rgba(255, 255, 255, .025);
    border: 1px solid var(--agenda-border);
    border-radius: .8rem;
    padding: 1rem;
  }

  .agenda-disclosure {
    border: 1px solid var(--agenda-border);
    border-radius: .8rem;
    overflow: hidden;
  }

  .agenda-disclosure > summary {
    align-items: center;
    cursor: pointer;
    display: flex;
    font-weight: 700;
    gap: .6rem;
    justify-content: space-between;
    list-style: none;
    padding: .85rem 1rem;
  }

  .agenda-disclosure > summary::-webkit-details-marker { display: none; }
  .agenda-disclosure > summary::after { content: "+"; color: var(--agenda-accent); font-size: 1.2rem; }
  .agenda-disclosure[open] > summary::after { content: "-"; }
  .agenda-disclosure-body { border-top: 1px solid var(--agenda-border); padding: 1rem; }

  .agenda-savebar {
    align-items: center;
    background: rgba(16, 19, 24, .92);
    border: 1px solid var(--agenda-border);
    border-radius: .9rem;
    bottom: 1rem;
    display: flex;
    gap: 1rem;
    justify-content: space-between;
    margin-top: 1.5rem;
    padding: .75rem;
    position: sticky;
    z-index: 5;
  }

  .agenda-empty {
    border: 1px dashed rgba(255, 255, 255, .16);
    border-radius: .8rem;
    color: rgba(255, 255, 255, .58);
    padding: 1.25rem;
    text-align: center;
  }

  [data-agenda-rule-panel][hidden] { display: none !important; }

  .agenda-color-control {
    align-items: center;
    display: flex;
    gap: .75rem;
  }

  .agenda-color-control input[type="color"] {
    background: transparent;
    border: 0;
    cursor: pointer;
    flex: 0 0 54px;
    height: 48px;
    padding: 0;
  }
  #agendaSettings,
  #agendaComposition,
  #agendaPublish { scroll-margin-top: 5rem; }

  @media (max-width: 575.98px) {
    .agenda-preview-card { grid-template-columns: 54px minmax(0, 1fr); }
    .agenda-preview-date strong { font-size: 1.15rem; }
    .agenda-steps,
    .agenda-choice-grid { grid-template-columns: 1fr; }
    .agenda-step small { display: none; }
    .agenda-savebar { align-items: stretch; flex-direction: column; }
    .agenda-savebar .btn { width: 100%; }
  }
</style>

<section class="agenda-shell pb-5">
  <cfif NOT VARIABLES.agendaShowEditor>
  <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-4">
    <div>
      <div class="agenda-kicker mb-1">Ferramentas</div>
      <h2 class="mb-1">Agendas de eventos</h2>
      <p class="text-muted mb-0">Crie listas editoriais ou dinamicas e distribua eventos do Road Runners por XML e embed responsivo.</p>
    </div>
    <cfif VARIABLES.agendaManagementTablesReady>
      <a class="btn btn-warning" href="./?nova=1"><i class="fa-solid fa-plus me-2"></i>Nova agenda</a>
    </cfif>
  </div>
  </cfif>

  <cfif NOT VARIABLES.agendaManagementTablesReady>
    <div class="alert alert-warning">
      A estrutura das Agendas ainda nao foi aplicada. Execute
      <a href="/portal/agendas/agenda_schema.sql" target="_blank" rel="noopener">/portal/agendas/agenda_schema.sql</a>
      no banco e recarregue esta pagina.
    </div>
  <cfelse>
    <cfif len(VARIABLES.agendaManagementAlert.message)>
      <cfoutput><div class="alert alert-#VARIABLES.agendaManagementAlert.type#">#htmlEditFormat(VARIABLES.agendaManagementAlert.message)#</div></cfoutput>
    </cfif>

    <cfif NOT VARIABLES.agendaShowEditor>
    <div class="row g-3 mb-4">
      <div class="col-6 col-xl">
        <div class="agenda-panel p-3 h-100"><div class="small text-muted text-uppercase">Agendas</div><div class="h3 mb-0"><cfoutput>#LSNumberFormat(qAgendaManagementStats.total)#</cfoutput></div></div>
      </div>
      <div class="col-6 col-xl">
        <div class="agenda-panel p-3 h-100"><div class="small text-muted text-uppercase">Ativas</div><div class="h3 mb-0 text-success"><cfoutput>#LSNumberFormat(qAgendaManagementStats.ativas)#</cfoutput></div></div>
      </div>
      <div class="col-6 col-xl">
        <div class="agenda-panel p-3 h-100"><div class="small text-muted text-uppercase">Manuais</div><div class="h3 mb-0"><cfoutput>#LSNumberFormat(qAgendaManagementStats.manuais)#</cfoutput></div></div>
      </div>
      <div class="col-6 col-xl">
        <div class="agenda-panel p-3 h-100"><div class="small text-muted text-uppercase">Dinamicas</div><div class="h3 mb-0"><cfoutput>#LSNumberFormat(qAgendaManagementStats.dinamicas)#</cfoutput></div></div>
      </div>
      <div class="col-12 col-xl">
        <div class="agenda-panel p-3 h-100"><div class="small text-muted text-uppercase">Acessos em 30 dias</div><div class="h3 mb-0"><cfoutput>#LSNumberFormat(qAgendaManagementStats.acessos_30d, "9,999,999")#</cfoutput></div></div>
      </div>
    </div>
    </cfif>

    <cfif VARIABLES.agendaShowEditor>
      <cfset VARIABLES.agendaFormId = qAgendaManagementEdit.recordcount ? qAgendaManagementEdit.id_agenda[1] : 0/>
      <cfset VARIABLES.agendaFormName = qAgendaManagementEdit.recordcount ? qAgendaManagementEdit.nome[1] : (isDefined("FORM.nome") ? FORM.nome : "")/>
      <cfset VARIABLES.agendaFormDescription = qAgendaManagementEdit.recordcount ? agendaServiceQueryValue(qAgendaManagementEdit, "descricao", 1) : (isDefined("FORM.descricao") ? FORM.descricao : "")/>
      <cfset VARIABLES.agendaFormOwnerId = VARIABLES.agendaManagementCanManageAll
          ? (qAgendaManagementEdit.recordcount ? qAgendaManagementEdit.id_usuario[1] : (isDefined("FORM.id_usuario") AND isNumeric(FORM.id_usuario) ? val(FORM.id_usuario) : 0))
          : VARIABLES.agendaManagementActorId/>
      <cfset VARIABLES.agendaFormMode = qAgendaManagementEdit.recordcount ? qAgendaManagementEdit.modo[1] : (isDefined("FORM.modo") ? FORM.modo : "manual")/>
      <cfset VARIABLES.agendaFormHost = qAgendaManagementEdit.recordcount ? qAgendaManagementEdit.dominio_permitido[1] : (isDefined("FORM.dominio_permitido") ? FORM.dominio_permitido : "")/>
      <cfset VARIABLES.agendaFormSubdomains = qAgendaManagementEdit.recordcount ? agendaServiceNormalizeBoolean(qAgendaManagementEdit.permitir_subdominios[1]) : isDefined("FORM.permitir_subdominios")/>
      <cfset VARIABLES.agendaFormLimit = qAgendaManagementEdit.recordcount ? qAgendaManagementEdit.limite_eventos[1] : (isDefined("FORM.limite_eventos") ? FORM.limite_eventos : 20)/>
      <cfset VARIABLES.agendaFormOrder = qAgendaManagementEdit.recordcount ? qAgendaManagementEdit.ordenacao[1] : (isDefined("FORM.ordenacao") ? FORM.ordenacao : "data")/>
      <cfset VARIABLES.agendaFormTheme = qAgendaManagementEdit.recordcount ? agendaServiceNormalizeTheme(agendaServiceQueryValue(qAgendaManagementEdit, "tema_embed", 1)) : agendaServiceNormalizeTheme(isDefined("FORM.tema_embed") ? FORM.tema_embed : "escuro")/>
      <cfset VARIABLES.agendaFormDateColor = qAgendaManagementEdit.recordcount ? agendaServiceNormalizeHexColor(agendaServiceQueryValue(qAgendaManagementEdit, "cor_card_data", 1)) : agendaServiceNormalizeHexColor(isDefined("FORM.cor_card_data") ? FORM.cor_card_data : "fab120")/>
      <cfset VARIABLES.agendaFormCardFont = qAgendaManagementEdit.recordcount ? agendaServiceNormalizeCardFont(agendaServiceQueryValue(qAgendaManagementEdit, "fonte_cards", 1)) : agendaServiceNormalizeCardFont(isDefined("FORM.fonte_cards") ? FORM.fonte_cards : "trebuchet")/>
      <cfset VARIABLES.agendaFormCardRadius = qAgendaManagementEdit.recordcount ? agendaServiceNormalizeCardRadius(agendaServiceQueryValue(qAgendaManagementEdit, "raio_cards", 1)) : agendaServiceNormalizeCardRadius(isDefined("FORM.raio_cards") ? FORM.raio_cards : "atual")/>
      <cfset VARIABLES.agendaFormDateTextColor = agendaServiceContrastColor(VARIABLES.agendaFormDateColor)/>
      <cfset VARIABLES.agendaFormStatus = qAgendaManagementEdit.recordcount ? qAgendaManagementEdit.status[1] : (isDefined("FORM.status") ? FORM.status : "rascunho")/>
      <cfset VARIABLES.agendaFormAction = VARIABLES.agendaFormId GT 0 ? "./?agenda_id=" & VARIABLES.agendaFormId : "./"/>

      <cfset VARIABLES.agendaEditorStatusClass = VARIABLES.agendaFormStatus EQ "ativa" ? "is-active" : (VARIABLES.agendaFormStatus EQ "rascunho" ? "is-draft" : (VARIABLES.agendaFormStatus EQ "pausada" ? "is-paused" : "is-archived"))/>

      <div class="agenda-panel agenda-editor-head p-3 p-lg-4 mb-3">
        <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-start gap-3 mb-4">
          <div class="agenda-editor-title">
            <div class="d-flex align-items-center gap-2 mb-2">
              <a class="btn btn-sm btn-outline-light" href="./" title="Voltar para agendas"><i class="fa-solid fa-arrow-left"></i></a>
              <span class="agenda-status <cfoutput>#VARIABLES.agendaEditorStatusClass#</cfoutput>"><cfoutput>#htmlEditFormat(VARIABLES.agendaFormStatus)#</cfoutput></span>
              <cfif VARIABLES.agendaFormId GT 0><span class="small text-muted"><cfoutput>Agenda ## #VARIABLES.agendaFormId#</cfoutput></span></cfif>
            </div>
            <div class="agenda-kicker"><cfif VARIABLES.agendaFormId GT 0>Editor de agenda<cfelse>Nova agenda</cfif></div>
            <h3 class="mb-1"><cfif len(VARIABLES.agendaFormName)><cfoutput>#htmlEditFormat(VARIABLES.agendaFormName)#</cfoutput><cfelse>Configure sua nova agenda</cfif></h3>
            <p class="text-muted mb-0">Defina o conteudo, confira a previa e publique nos sites autorizados.</p>
          </div>
          <cfif VARIABLES.agendaFormId GT 0>
            <a class="btn btn-outline-warning" href="#agendaPublish"><i class="fa-solid fa-code me-2"></i>Ver integracoes</a>
          </cfif>
        </div>

        <div class="agenda-steps">
          <a class="agenda-step is-current" href="#agendaSettings"><span class="agenda-step-number">1</span><span><strong>Configuracao</strong><small>Identidade e formato</small></span></a>
          <a class="agenda-step <cfif VARIABLES.agendaFormId LTE 0>is-disabled</cfif>" href="#agendaComposition"><span class="agenda-step-number">2</span><span><strong>Conteudo</strong><small>Eventos ou regras</small></span></a>
          <a class="agenda-step <cfif VARIABLES.agendaFormId LTE 0>is-disabled</cfif>" href="#agendaPublish"><span class="agenda-step-number">3</span><span><strong>Publicacao</strong><small>Previa e codigos</small></span></a>
        </div>
      </div>

      <div class="agenda-panel p-3 p-lg-4 mb-4" id="agendaSettings">
        <cfif VARIABLES.agendaManagementCanManageAll>
        <div class="d-flex align-items-start gap-3 mb-3">
          <span class="agenda-section-icon"><i class="fa-solid fa-user"></i></span>
          <div><div class="agenda-kicker">Proprietario</div><h4 class="mb-1">A quem pertence esta agenda?</h4><p class="text-muted mb-0">Busque por nome, e-mail ou ID e escolha o usuario responsavel.</p></div>
        </div>

        <cfoutput>
          <form method="get" action="./" class="agenda-owner-search row g-2 align-items-end mb-3">
            <cfif VARIABLES.agendaFormId GT 0><input type="hidden" name="agenda_id" value="#VARIABLES.agendaFormId#"/><cfelse><input type="hidden" name="nova" value="1"/></cfif>
            <div class="col-12 col-lg-9">
              <label class="form-label" for="agendaOwnerSearch">Buscar usuario</label>
              <div class="input-group"><span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span><input class="form-control" id="agendaOwnerSearch" type="search" name="owner_search" value="#htmlEditFormat(URL.owner_search)#" placeholder="Ex.: Maria, maria@email.com ou 142"/></div>
            </div>
            <div class="col-12 col-lg-3"><button class="btn btn-outline-warning w-100" type="submit">Buscar</button></div>
          </form>
        </cfoutput>
        </cfif>

        <form method="post" action="<cfoutput>#htmlEditFormat(VARIABLES.agendaFormAction)#</cfoutput>">
          <input type="hidden" name="acao" value="salvar_agenda"/>
          <input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.agendaManagementCsrfToken#</cfoutput>"/>
          <input type="hidden" name="agenda_id" value="<cfoutput>#VARIABLES.agendaFormId#</cfoutput>"/>

          <cfif VARIABLES.agendaManagementCanManageAll>
          <div class="mb-4">
            <label class="form-label" for="agendaOwner">Usuario selecionado</label>
            <select class="form-select" id="agendaOwner" name="id_usuario" required>
              <option value="">Busque e selecione um usuario</option>
              <cfif qAgendaManagementEdit.recordcount>
                <cfoutput><option value="#qAgendaManagementEdit.id_usuario#" selected>## #qAgendaManagementEdit.id_usuario# - #htmlEditFormat(qAgendaManagementEdit.usuario_nome)# - #htmlEditFormat(qAgendaManagementEdit.usuario_email)#</option></cfoutput>
              </cfif>
              <cfoutput query="qAgendaManagementOwnerSearch">
                <cfif NOT qAgendaManagementEdit.recordcount OR qAgendaManagementOwnerSearch.id NEQ qAgendaManagementEdit.id_usuario>
                  <option value="#qAgendaManagementOwnerSearch.id#" <cfif qAgendaManagementOwnerSearch.id EQ VARIABLES.agendaFormOwnerId>selected</cfif>>## #qAgendaManagementOwnerSearch.id# - #htmlEditFormat(qAgendaManagementOwnerSearch.name)# - #htmlEditFormat(qAgendaManagementOwnerSearch.email)#</option>
                </cfif>
              </cfoutput>
            </select>
            <cfif len(trim(URL.owner_search)) AND NOT qAgendaManagementOwnerSearch.recordcount><div class="form-text text-warning">Nenhum usuario encontrado. Tente outro nome, e-mail ou ID.</div></cfif>
          </div>
          <cfelse>
            <input type="hidden" name="id_usuario" value="<cfoutput>#VARIABLES.agendaManagementActorId#</cfoutput>"/>
          </cfif>

          <div class="agenda-form-section">
            <div class="d-flex align-items-start gap-3 mb-3">
              <span class="agenda-section-icon"><i class="fa-solid fa-pen-to-square"></i></span>
              <div><div class="agenda-kicker">Identificacao</div><h4 class="mb-1">Como esta agenda sera apresentada?</h4><p class="text-muted mb-0">Use um nome claro para identifica-la no Business e nos feeds.</p></div>
            </div>
            <div class="row g-3">
              <div class="col-12 col-lg-8">
                <label class="form-label" for="agendaName">Nome da agenda</label>
                <input class="form-control form-control-lg" id="agendaName" type="text" name="nome" maxlength="160" required placeholder="Ex.: Corridas de rua em Santa Catarina" value="<cfoutput>#htmlEditFormat(VARIABLES.agendaFormName)#</cfoutput>"/>
              </div>
              <div class="col-12 col-lg-4">
                <label class="form-label" for="agendaStatus">Status</label>
                <select class="form-select form-select-lg" id="agendaStatus" name="status">
                  <option value="rascunho" <cfif VARIABLES.agendaFormStatus EQ "rascunho">selected</cfif>>Rascunho</option>
                  <option value="ativa" <cfif VARIABLES.agendaFormStatus EQ "ativa">selected</cfif>>Ativa</option>
                  <option value="pausada" <cfif VARIABLES.agendaFormStatus EQ "pausada">selected</cfif>>Pausada</option>
                  <option value="arquivada" <cfif VARIABLES.agendaFormStatus EQ "arquivada">selected</cfif>>Arquivada</option>
                </select>
              </div>
              <div class="col-12">
                <label class="form-label" for="agendaDescription">Descricao <span class="text-muted">(opcional)</span></label>
                <textarea class="form-control" id="agendaDescription" name="descricao" rows="2" placeholder="Explique rapidamente o objetivo desta agenda"><cfoutput>#htmlEditFormat(VARIABLES.agendaFormDescription)#</cfoutput></textarea>
              </div>
            </div>
          </div>

          <div class="agenda-form-section">
            <div class="d-flex align-items-start gap-3 mb-3">
              <span class="agenda-section-icon"><i class="fa-solid fa-list-check"></i></span>
              <div><div class="agenda-kicker">Selecao</div><h4 class="mb-1">Como os eventos entram na agenda?</h4><p class="text-muted mb-0">Escolha eventos individualmente ou deixe filtros atualizarem a lista automaticamente.</p></div>
            </div>
            <div class="row g-3">
              <div class="col-12">
                <div class="agenda-choice-grid h-100">
                  <label class="agenda-choice"><input type="radio" name="modo" value="manual" <cfif VARIABLES.agendaFormMode EQ "manual">checked</cfif>/><span class="agenda-choice-content"><span class="fw-bold d-block"><i class="fa-solid fa-hand-pointer text-warning me-2"></i>Escolher eventos</span><span class="small text-muted">Voce busca e adiciona cada evento manualmente.</span></span></label>
                  <label class="agenda-choice"><input type="radio" name="modo" value="dinamica" <cfif VARIABLES.agendaFormMode EQ "dinamica">checked</cfif>/><span class="agenda-choice-content"><span class="fw-bold d-block"><i class="fa-solid fa-wand-magic-sparkles text-warning me-2"></i>Usar filtros</span><span class="small text-muted">Novos eventos entram automaticamente pelas regras.</span></span></label>
                </div>
              </div>
            </div>
          </div>

          <div class="agenda-form-section">
            <div class="d-flex align-items-start gap-3 mb-3">
              <span class="agenda-section-icon"><i class="fa-solid fa-shield-halved"></i></span>
              <div><div class="agenda-kicker">Publicacao</div><h4 class="mb-1">Onde esta agenda podera aparecer?</h4><p class="text-muted mb-0">A API e o embed aceitarao requisicoes somente do dominio autorizado.</p></div>
            </div>
            <div class="row g-3 align-items-start">
              <div class="col-12 col-lg-8">
                <label class="form-label" for="agendaDomain">Dominio permitido</label>
                <div class="input-group input-group-lg"><span class="input-group-text"><i class="fa-solid fa-globe"></i></span><input class="form-control" id="agendaDomain" type="text" name="dominio_permitido" required placeholder="exemplo.com.br" value="<cfoutput>#htmlEditFormat(VARIABLES.agendaFormHost)#</cfoutput>"/></div>
                <div class="form-text">Informe somente o dominio, sem https:// ou caminhos.</div>
              </div>
              <div class="col-12 col-lg-4">
                <div class="form-check form-switch mt-lg-4 pt-lg-2">
                  <input class="form-check-input" type="checkbox" role="switch" name="permitir_subdominios" value="1" id="agendaAllowSubdomains" <cfif VARIABLES.agendaFormSubdomains>checked</cfif>/>
                  <label class="form-check-label" for="agendaAllowSubdomains">Permitir subdominios</label>
                  <div class="form-text">Ex.: blog.exemplo.com.br</div>
                </div>
              </div>
            </div>

            <div class="agenda-subpanel mt-3">
              <div class="d-flex align-items-start gap-3 mb-3">
                <span class="agenda-section-icon"><i class="fa-solid fa-palette"></i></span>
                <div><h5 class="mb-1">Aparencia do embed</h5><p class="small text-muted mb-0">O fundo externo permanece transparente; o tema ajusta cards, textos e bordas para a pagina de destino.</p></div>
              </div>
              <div class="row g-3 align-items-end">
                <div class="col-12 col-xl-7">
                  <label class="form-label">Tema dos cards</label>
                  <div class="agenda-choice-grid">
                    <label class="agenda-choice"><input type="radio" name="tema_embed" value="claro" data-agenda-theme-input <cfif VARIABLES.agendaFormTheme EQ "claro">checked</cfif>/><span class="agenda-choice-content"><span class="fw-bold d-block"><i class="fa-regular fa-sun text-warning me-2"></i>Claro</span><span class="small text-muted">Cards claros e textos escuros.</span></span></label>
                    <label class="agenda-choice"><input type="radio" name="tema_embed" value="escuro" data-agenda-theme-input <cfif VARIABLES.agendaFormTheme EQ "escuro">checked</cfif>/><span class="agenda-choice-content"><span class="fw-bold d-block"><i class="fa-regular fa-moon text-warning me-2"></i>Escuro</span><span class="small text-muted">Cards escuros e textos claros.</span></span></label>
                  </div>
                </div>
                <div class="col-12 col-xl-5">
                  <label class="form-label" for="agendaDateColor">Cor do card da data</label>
                  <div class="agenda-color-control">
                    <input type="color" id="agendaDateColor" name="cor_card_data" value="<cfoutput>#htmlEditFormat(VARIABLES.agendaFormDateColor)#</cfoutput>" data-agenda-date-color/>
                    <div><strong data-agenda-date-color-value><cfoutput>#htmlEditFormat(uCase(VARIABLES.agendaFormDateColor))#</cfoutput></strong><div class="small text-muted">O texto ganha contraste automaticamente.</div></div>
                  </div>
                </div>
                <div class="col-12 col-md-6">
                  <label class="form-label" for="agendaCardFont">Fonte dos cards dos eventos</label>
                  <select class="form-select" id="agendaCardFont" name="fonte_cards" data-agenda-card-font>
                    <option value="trebuchet" <cfif VARIABLES.agendaFormCardFont EQ "trebuchet">selected</cfif>>Trebuchet - padrao Road Runners</option>
                    <option value="verdana" <cfif VARIABLES.agendaFormCardFont EQ "verdana">selected</cfif>>Verdana</option>
                    <option value="georgia" <cfif VARIABLES.agendaFormCardFont EQ "georgia">selected</cfif>>Georgia</option>
                    <option value="tahoma" <cfif VARIABLES.agendaFormCardFont EQ "tahoma">selected</cfif>>Tahoma</option>
                    <option value="monospace" <cfif VARIABLES.agendaFormCardFont EQ "monospace">selected</cfif>>Monoespacada</option>
                  </select>
                </div>
                <div class="col-12 col-md-6">
                  <label class="form-label" for="agendaCardRadius">Cantos dos cards</label>
                  <select class="form-select" id="agendaCardRadius" name="raio_cards" data-agenda-card-radius>
                    <option value="atual" <cfif VARIABLES.agendaFormCardRadius EQ "atual">selected</cfif>>Atual - 16 px</option>
                    <option value="medio" <cfif VARIABLES.agendaFormCardRadius EQ "medio">selected</cfif>>Medio - 10 px</option>
                    <option value="suave" <cfif VARIABLES.agendaFormCardRadius EQ "suave">selected</cfif>>Suave - 5 px</option>
                    <option value="reto" <cfif VARIABLES.agendaFormCardRadius EQ "reto">selected</cfif>>Canto reto - 0 px</option>
                  </select>
                </div>
              </div>
            </div>

            <details class="agenda-disclosure mt-3">
              <summary><span><i class="fa-solid fa-sliders me-2 text-warning"></i>Opcoes avancadas</span><span class="small text-muted fw-normal">Limite e ordenacao</span></summary>
              <div class="agenda-disclosure-body">
                <div class="row g-3">
                  <div class="col-12 col-md-6">
                    <label class="form-label" for="agendaLimit">Quantidade maxima de eventos</label>
                    <input class="form-control" id="agendaLimit" type="number" name="limite_eventos" min="1" max="100" value="<cfoutput>#VARIABLES.agendaFormLimit#</cfoutput>"/>
                  </div>
                  <div class="col-12 col-md-6" data-agenda-manual-order>
                    <label class="form-label" for="agendaOrder">Ordenacao</label>
                    <select class="form-select" id="agendaOrder" name="ordenacao">
                      <option value="data" <cfif VARIABLES.agendaFormOrder EQ "data">selected</cfif>>Por data do evento</option>
                      <option value="manual" <cfif VARIABLES.agendaFormOrder EQ "manual">selected</cfif>>Ordem definida por mim</option>
                    </select>
                  </div>
                </div>
              </div>
            </details>
          </div>

          <div class="agenda-savebar">
            <div class="small text-muted"><cfif VARIABLES.agendaFormId GT 0>As alteracoes entram em vigor depois de salvar.<cfelse>Primeiro salve a agenda; depois voce adicionara eventos ou regras.</cfif></div>
            <button class="btn btn-warning px-4" type="submit"><i class="fa-solid fa-check me-2"></i><cfif VARIABLES.agendaFormId GT 0>Salvar alteracoes<cfelse>Salvar e continuar</cfif></button>
          </div>
        </form>
      </div>

      <cfif qAgendaManagementEdit.recordcount>
        <cfif qAgendaManagementEdit.modo EQ "manual">
          <div class="agenda-panel p-3 p-lg-4 mb-4" id="agendaComposition">
            <div class="d-flex align-items-start gap-3 mb-4">
              <span class="agenda-section-icon"><i class="fa-solid fa-calendar-plus"></i></span>
              <div><div class="agenda-kicker">Conteudo da agenda</div><h4 class="mb-1">Escolha os eventos</h4><p class="text-muted mb-0">Busque, selecione e adicione um ou varios eventos de uma vez.</p></div>
            </div>

            <cfoutput>
              <form method="get" action="./" class="agenda-subpanel mb-4">
                <input type="hidden" name="agenda_id" value="#qAgendaManagementEdit.id_agenda#"/>
                <input type="hidden" name="buscar_eventos" value="1"/>
                <div class="row g-2 align-items-end">
                  <div class="col-12 col-lg-7"><label class="form-label" for="agendaEventSearch">Nome ou ID do evento</label><div class="input-group"><span class="input-group-text"><i class="fa-solid fa-magnifying-glass"></i></span><input class="form-control" id="agendaEventSearch" name="evento_busca" value="#htmlEditFormat(URL.evento_busca)#" placeholder="Digite parte do nome ou o ID"/></div></div>
                  <div class="col-12 col-sm-7 col-lg-3"><label class="form-label">Periodo</label><select class="form-select" name="evento_visao"><option value="todos" <cfif URL.evento_visao EQ "todos">selected</cfif>>Todos</option><option value="futuros" <cfif URL.evento_visao EQ "futuros">selected</cfif>>Proximos eventos</option><option value="resultados" <cfif URL.evento_visao EQ "resultados">selected</cfif>>Com resultados</option></select></div>
                  <div class="col-12 col-sm-5 col-lg-2"><button class="btn btn-warning w-100" type="submit">Buscar</button></div>
                </div>
                <details class="agenda-disclosure mt-3" <cfif len(URL.evento_agregador & URL.evento_distancia & URL.evento_estado & URL.evento_cidade & URL.evento_tipo)>open</cfif>>
                  <summary><span><i class="fa-solid fa-filter me-2 text-warning"></i>Mais filtros</span><span class="small text-muted fw-normal">Agregador, local, distancia e tipo</span></summary>
                  <div class="agenda-disclosure-body"><div class="row g-3">
                    <div class="col-12 col-lg-5"><label class="form-label">Agregador de edicoes</label><input class="form-control" name="evento_agregador" value="#htmlEditFormat(URL.evento_agregador)#" placeholder="Nome ou ID do agregador"/></div>
                    <div class="col-6 col-lg-3"><label class="form-label">Distancia (km)</label><input class="form-control" type="number" step="0.001" min="0" name="evento_distancia" value="#htmlEditFormat(URL.evento_distancia)#"/></div>
                    <div class="col-6 col-lg-2"><label class="form-label">Estado</label><select class="form-select" name="evento_estado"><option value="">Todos</option>
            </cfoutput>
                  <cfoutput query="qAgendaManagementStates"><option value="#estado#" <cfif estado EQ URL.evento_estado>selected</cfif>>#estado#</option></cfoutput>
            <cfoutput>
                    </select></div>
                    <div class="col-12 col-lg-4"><label class="form-label">Cidade</label><input class="form-control" name="evento_cidade" value="#htmlEditFormat(URL.evento_cidade)#" placeholder="Nome da cidade"/></div>
                    <div class="col-12 col-lg-4"><label class="form-label">Tipo</label><select class="form-select" name="evento_tipo"><option value="">Todos</option>
            </cfoutput>
                  <cfoutput query="qAgendaManagementTypes"><option value="#tipo_corrida#" <cfif tipo_corrida EQ URL.evento_tipo>selected</cfif>>#htmlEditFormat(tipo_corrida)#</option></cfoutput>
            <cfoutput>
                    </select></div>
                  </div></div>
                </details>
              </form>
            </cfoutput>

            <cfif len(trim(URL.buscar_eventos))>
              <cfif qAgendaManagementEventSearch.recordcount>
                <form method="post" action="./?agenda_id=<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>">
                  <input type="hidden" name="acao" value="adicionar_eventos"/>
                  <input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.agendaManagementCsrfToken#</cfoutput>"/>
                  <input type="hidden" name="agenda_id" value="<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>"/>
                  <div class="table-responsive mb-3">
                    <table class="table table-sm agenda-table">
                      <thead><tr><th><input class="form-check-input" type="checkbox" data-agenda-select-all/></th><th>Evento</th><th>Data</th><th>Distancias</th><th>Agregador</th></tr></thead>
                      <tbody>
                        <cfoutput query="qAgendaManagementEventSearch">
                          <cfset VARIABLES.agendaSearchCity = agendaServiceQueryValue(qAgendaManagementEventSearch, "cidade", currentRow) & ""/>
                          <cfset VARIABLES.agendaSearchState = agendaServiceQueryValue(qAgendaManagementEventSearch, "estado", currentRow) & ""/>
                          <cfset VARIABLES.agendaSearchAggregator = agendaServiceQueryValue(qAgendaManagementEventSearch, "agregador_nome", currentRow) & ""/>
                          <tr>
                            <td><input class="form-check-input" type="checkbox" name="evento_ids" value="#id_evento#" data-agenda-event-checkbox <cfif agendaServiceNormalizeBoolean(ja_adicionado)>disabled</cfif>/></td>
                            <td class="agenda-event-name"><div class="fw-semibold">#htmlEditFormat(nome_evento)#</div><div class="small text-muted">## #id_evento# - #htmlEditFormat(VARIABLES.agendaSearchCity)#<cfif len(VARIABLES.agendaSearchState)>/#htmlEditFormat(VARIABLES.agendaSearchState)#</cfif><cfif agendaServiceNormalizeBoolean(ja_adicionado)> - ja adicionado</cfif></div></td>
                            <td class="text-nowrap">#dateFormat(data_inicial, "dd/mm/yyyy")#</td>
                            <td>#htmlEditFormat(distancias)#</td>
                            <td>#htmlEditFormat(VARIABLES.agendaSearchAggregator)#</td>
                          </tr>
                        </cfoutput>
                      </tbody>
                    </table>
                  </div>
                  <button class="btn btn-warning" type="submit"><i class="fa-solid fa-plus me-2"></i>Adicionar selecionados</button>
                </form>
              <cfelse>
                <div class="alert alert-secondary">Nenhum evento corresponde aos filtros informados.</div>
              </cfif>
            </cfif>

            <hr class="my-4"/>
            <div class="d-flex justify-content-between align-items-center gap-3 mb-2"><h5 class="mb-0">Eventos na agenda</h5><span class="badge bg-secondary"><cfoutput>#qAgendaManagementSelectedEvents.recordcount#</cfoutput> selecionado(s)</span></div>
            <cfif qAgendaManagementSelectedEvents.recordcount>
              <div class="table-responsive">
                <table class="table table-sm agenda-table mb-0">
                  <thead><tr><th>Ordem</th><th>Evento</th><th>Data</th><th>Tipo</th><th class="text-end">Acoes</th></tr></thead>
                  <tbody>
                    <cfoutput query="qAgendaManagementSelectedEvents">
                      <cfset VARIABLES.agendaSelectedCity = agendaServiceQueryValue(qAgendaManagementSelectedEvents, "cidade", currentRow) & ""/>
                      <cfset VARIABLES.agendaSelectedState = agendaServiceQueryValue(qAgendaManagementSelectedEvents, "estado", currentRow) & ""/>
                      <tr>
                        <td>#ordem#</td>
                        <td class="agenda-event-name"><a href="https://roadrunners.run/evento/#urlEncodedFormat(tag)#/" target="_blank" rel="noopener" class="fw-semibold">#htmlEditFormat(nome_evento)# <i class="fa-solid fa-arrow-up-right-from-square ms-1 small"></i></a><div class="small text-muted">## #id_evento# - #htmlEditFormat(VARIABLES.agendaSelectedCity)#<cfif len(VARIABLES.agendaSelectedState)>/#htmlEditFormat(VARIABLES.agendaSelectedState)#</cfif></div></td>
                        <td>#dateFormat(data_inicial, "dd/mm/yyyy")#</td>
                        <td>#htmlEditFormat(tipo_corrida)#</td>
                        <td class="text-end text-nowrap">
                          <form method="post" action="./?agenda_id=#qAgendaManagementEdit.id_agenda#" class="d-inline"><input type="hidden" name="acao" value="mover_evento"/><input type="hidden" name="csrf_token" value="#VARIABLES.agendaManagementCsrfToken#"/><input type="hidden" name="agenda_id" value="#qAgendaManagementEdit.id_agenda#"/><input type="hidden" name="id_evento" value="#id_evento#"/><input type="hidden" name="direcao" value="cima"/><button class="btn btn-sm btn-link text-light px-1" title="Mover para cima"><i class="fa-solid fa-arrow-up"></i></button></form>
                          <form method="post" action="./?agenda_id=#qAgendaManagementEdit.id_agenda#" class="d-inline"><input type="hidden" name="acao" value="mover_evento"/><input type="hidden" name="csrf_token" value="#VARIABLES.agendaManagementCsrfToken#"/><input type="hidden" name="agenda_id" value="#qAgendaManagementEdit.id_agenda#"/><input type="hidden" name="id_evento" value="#id_evento#"/><input type="hidden" name="direcao" value="baixo"/><button class="btn btn-sm btn-link text-light px-1" title="Mover para baixo"><i class="fa-solid fa-arrow-down"></i></button></form>
                          <form method="post" action="./?agenda_id=#qAgendaManagementEdit.id_agenda#" class="d-inline" onsubmit="return confirm('Remover este evento da agenda?');"><input type="hidden" name="acao" value="remover_evento"/><input type="hidden" name="csrf_token" value="#VARIABLES.agendaManagementCsrfToken#"/><input type="hidden" name="agenda_id" value="#qAgendaManagementEdit.id_agenda#"/><input type="hidden" name="id_evento" value="#id_evento#"/><button class="btn btn-sm btn-link text-danger px-1" title="Remover"><i class="fa-solid fa-trash"></i></button></form>
                        </td>
                      </tr>
                    </cfoutput>
                  </tbody>
                </table>
              </div>
            <cfelse><div class="agenda-empty"><i class="fa-regular fa-calendar-plus d-block fs-3 mb-2"></i>Nenhum evento adicionado. Use a busca acima para montar a agenda.</div></cfif>
          </div>
        <cfelse>
          <div class="agenda-panel p-3 p-lg-4 mb-4" id="agendaComposition">
            <div class="d-flex align-items-start gap-3 mb-3">
              <span class="agenda-section-icon"><i class="fa-solid fa-wand-magic-sparkles"></i></span>
              <div><div class="agenda-kicker">Conteudo da agenda</div><h4 class="mb-1">Defina as regras automaticas</h4><p class="text-muted mb-0">A agenda sera atualizada sempre que um evento atender a estas regras.</p></div>
            </div>

            <div class="agenda-subpanel mb-4">
              <div class="small text-muted text-uppercase fw-bold mb-2">Regras em uso</div>
              <div class="d-flex flex-wrap gap-2">
                <cfoutput query="qAgendaManagementFilters">
                  <span class="agenda-rule"><strong>#uCase(htmlEditFormat(campo))#:</strong> #htmlEditFormat(valor_exibicao)#
                    <form method="post" action="./?agenda_id=#qAgendaManagementEdit.id_agenda#"><input type="hidden" name="acao" value="remover_filtro"/><input type="hidden" name="csrf_token" value="#VARIABLES.agendaManagementCsrfToken#"/><input type="hidden" name="agenda_id" value="#qAgendaManagementEdit.id_agenda#"/><input type="hidden" name="id_agenda_filtro" value="#id_agenda_filtro#"/><button type="submit" class="btn btn-sm btn-link text-danger p-0" title="Remover regra"><i class="fa-solid fa-circle-xmark"></i></button></form>
                  </span>
                </cfoutput>
                <cfif NOT qAgendaManagementFilters.recordcount><span class="text-muted"><i class="fa-solid fa-circle-info me-1"></i>Sem regras, todos os eventos do periodo escolhido entram na agenda.</span></cfif>
              </div>
            </div>

            <div class="row g-3 align-items-end mb-3">
              <div class="col-12 col-lg-5">
                <label class="form-label" for="agendaRuleType">Adicionar uma regra por</label>
                <select class="form-select form-select-lg" id="agendaRuleType" data-agenda-rule-selector>
                  <option value="estado">Estado</option>
                  <option value="cidade">Cidade</option>
                  <option value="distancia">Distancia</option>
                  <option value="tipo">Tipo de evento</option>
                  <option value="agregador" <cfif len(trim(URL.agregador_filtro_busca))>selected</cfif>>Agregador de edicoes</option>
                </select>
              </div>
              <div class="col-12 col-lg-7"><div class="small text-muted"><strong>Como funciona:</strong> opcoes do mesmo tipo usam OU. Tipos diferentes usam E.</div></div>
            </div>

            <div class="agenda-subpanel" data-agenda-rule-panel="estado" <cfif len(trim(URL.agregador_filtro_busca))>hidden</cfif>>
              <form method="post" action="./?agenda_id=<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>" class="row g-2 align-items-end">
                <input type="hidden" name="acao" value="adicionar_filtro"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.agendaManagementCsrfToken#</cfoutput>"/><input type="hidden" name="agenda_id" value="<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>"/><input type="hidden" name="campo" value="estado"/>
                <div class="col-12 col-lg-9"><label class="form-label">Estado</label><select class="form-select" name="valor_texto" required><option value="">Selecione um estado</option><cfoutput query="qAgendaManagementStates"><option value="#estado#">#estado#</option></cfoutput></select></div>
                <div class="col-12 col-lg-3"><button class="btn btn-warning w-100" type="submit"><i class="fa-solid fa-plus me-2"></i>Adicionar regra</button></div>
              </form>
            </div>

            <div class="agenda-subpanel" data-agenda-rule-panel="cidade" hidden>
              <form method="post" action="./?agenda_id=<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>" class="row g-2 align-items-end">
                <input type="hidden" name="acao" value="adicionar_filtro"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.agendaManagementCsrfToken#</cfoutput>"/><input type="hidden" name="agenda_id" value="<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>"/><input type="hidden" name="campo" value="cidade"/>
                <div class="col-12 col-lg-9"><label class="form-label">Nome exato da cidade</label><input class="form-control" name="valor_texto" required placeholder="Ex.: Florianopolis"/></div>
                <div class="col-12 col-lg-3"><button class="btn btn-warning w-100" type="submit"><i class="fa-solid fa-plus me-2"></i>Adicionar regra</button></div>
              </form>
            </div>

            <div class="agenda-subpanel" data-agenda-rule-panel="distancia" hidden>
              <form method="post" action="./?agenda_id=<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>" class="row g-2 align-items-end">
                <input type="hidden" name="acao" value="adicionar_filtro"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.agendaManagementCsrfToken#</cfoutput>"/><input type="hidden" name="agenda_id" value="<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>"/><input type="hidden" name="campo" value="distancia"/>
                <div class="col-12 col-lg-9"><label class="form-label">Distancia em quilometros</label><div class="input-group"><input class="form-control" type="number" min="0.001" step="0.001" name="valor_numero" required placeholder="Ex.: 21.097"/><span class="input-group-text">km</span></div></div>
                <div class="col-12 col-lg-3"><button class="btn btn-warning w-100" type="submit"><i class="fa-solid fa-plus me-2"></i>Adicionar regra</button></div>
              </form>
            </div>

            <div class="agenda-subpanel" data-agenda-rule-panel="tipo" hidden>
              <form method="post" action="./?agenda_id=<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>" class="row g-2 align-items-end">
                <input type="hidden" name="acao" value="adicionar_filtro"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.agendaManagementCsrfToken#</cfoutput>"/><input type="hidden" name="agenda_id" value="<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>"/><input type="hidden" name="campo" value="tipo"/>
                <div class="col-12 col-lg-9"><label class="form-label">Tipo de evento</label><select class="form-select" name="valor_texto" required><option value="">Selecione um tipo</option><cfoutput query="qAgendaManagementTypes"><option value="#tipo_corrida#">#htmlEditFormat(tipo_corrida)#</option></cfoutput></select></div>
                <div class="col-12 col-lg-3"><button class="btn btn-warning w-100" type="submit"><i class="fa-solid fa-plus me-2"></i>Adicionar regra</button></div>
              </form>
            </div>

            <div class="agenda-subpanel" data-agenda-rule-panel="agregador" <cfif NOT len(trim(URL.agregador_filtro_busca))>hidden</cfif>>
              <cfoutput><form method="get" action="./" class="row g-2 align-items-end mb-3"><input type="hidden" name="agenda_id" value="#qAgendaManagementEdit.id_agenda#"/><div class="col-12 col-lg-9"><label class="form-label">Buscar agregador</label><input class="form-control" name="agregador_filtro_busca" value="#htmlEditFormat(URL.agregador_filtro_busca)#" placeholder="Nome ou ID do agregador"/></div><div class="col-12 col-lg-3"><button class="btn btn-outline-light w-100" type="submit"><i class="fa-solid fa-magnifying-glass me-2"></i>Buscar</button></div></form></cfoutput>
              <cfif qAgendaManagementAggregatorSearch.recordcount>
                <form method="post" action="./?agenda_id=<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>" class="row g-2 align-items-end">
                  <input type="hidden" name="acao" value="adicionar_filtro"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.agendaManagementCsrfToken#</cfoutput>"/><input type="hidden" name="agenda_id" value="<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>"/><input type="hidden" name="campo" value="agregador"/>
                  <div class="col-12 col-lg-9"><label class="form-label">Agregador encontrado</label><select class="form-select" name="valor_id" required><cfoutput query="qAgendaManagementAggregatorSearch"><option value="#id_agrega_evento#">## #id_agrega_evento# - #htmlEditFormat(nome_evento_agregado)# (#htmlEditFormat(tipo_agregacao)#)</option></cfoutput></select></div>
                  <div class="col-12 col-lg-3"><button class="btn btn-warning w-100" type="submit"><i class="fa-solid fa-plus me-2"></i>Adicionar regra</button></div>
                </form>
              <cfelseif len(trim(URL.agregador_filtro_busca))>
                <div class="small text-warning">Nenhum agregador encontrado para esta busca.</div>
              </cfif>
            </div>
          </div>
        </cfif>

        <div class="row g-4 mb-4" id="agendaPublish">
          <div class="col-12 col-xl-7">
            <div class="agenda-panel p-3 p-lg-4 h-100">
              <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-3">
                <div><div class="agenda-kicker">Previa</div><h4 class="mb-1">Cards do embed</h4><div class="small text-muted"><cfoutput>#qAgendaManagementPreview.recordcount#</cfoutput> evento(s) nesta visualizacao</div></div>
                <div class="btn-group align-self-start"><cfoutput><a class="btn btn-sm <cfif VARIABLES.agendaManagementPreviewView EQ 'futuros'>btn-warning<cfelse>btn-outline-light</cfif>" href="./?agenda_id=#qAgendaManagementEdit.id_agenda#&preview_visao=futuros">Futuros</a><a class="btn btn-sm <cfif VARIABLES.agendaManagementPreviewView EQ 'resultados'>btn-warning<cfelse>btn-outline-light</cfif>" href="./?agenda_id=#qAgendaManagementEdit.id_agenda#&preview_visao=resultados">Resultados</a></cfoutput></div>
              </div>
              <div class="agenda-preview <cfif VARIABLES.agendaFormTheme EQ 'claro'>is-light</cfif>" data-agenda-preview data-card-font="<cfoutput>#htmlEditFormat(VARIABLES.agendaFormCardFont)#</cfoutput>" data-card-radius="<cfoutput>#htmlEditFormat(VARIABLES.agendaFormCardRadius)#</cfoutput>" style="--agenda-preview-date: <cfoutput>#htmlEditFormat(VARIABLES.agendaFormDateColor)#</cfoutput>; --agenda-preview-date-text: <cfoutput>#htmlEditFormat(VARIABLES.agendaFormDateTextColor)#</cfoutput>;">
                <cfoutput query="qAgendaManagementPreview">
                  <cfset VARIABLES.previewDistances = agendaServiceDisplayDistances(isJSON(distancias_json & "") ? deserializeJSON(distancias_json & "") : [])/>
                  <cfset VARIABLES.agendaPreviewCity = agendaServiceQueryValue(qAgendaManagementPreview, "cidade", currentRow) & ""/>
                  <cfset VARIABLES.agendaPreviewState = agendaServiceQueryValue(qAgendaManagementPreview, "estado", currentRow) & ""/>
                  <a class="agenda-preview-card" href="https://roadrunners.run/evento/#urlEncodedFormat(tag)#/" target="_blank" rel="noopener">
                    <div class="agenda-preview-date"><strong>#dateFormat(data_final, "dd")#</strong><span>#agendaServiceMonthAbbreviationPtBr(data_final)# #dateFormat(data_final, "yyyy")#</span></div>
                    <div class="min-w-0"><div class="fw-bold text-truncate">#htmlEditFormat(nome_evento)#</div><div class="small text-muted"><i class="fa-solid fa-location-dot me-1"></i>#htmlEditFormat(VARIABLES.agendaPreviewCity)#<cfif len(VARIABLES.agendaPreviewState)> - #htmlEditFormat(VARIABLES.agendaPreviewState)#</cfif></div><cfif arrayLen(VARIABLES.previewDistances)><div class="mt-2"><cfloop array="#VARIABLES.previewDistances#" index="previewDistance"><span class="agenda-distance">#int(previewDistance.distancia)# #htmlEditFormat(previewDistance.unidade)#</span></cfloop></div></cfif></div>
                  </a>
                </cfoutput>
                <cfif NOT qAgendaManagementPreview.recordcount><div class="text-center text-muted py-5">Nenhum evento corresponde a esta visualizacao.</div></cfif>
              </div>
            </div>
          </div>

          <div class="col-12 col-xl-5">
            <div class="agenda-panel p-3 p-lg-4 h-100">
              <div class="agenda-kicker">Publicacao</div>
              <h4 class="mb-1">Compartilhar a agenda</h4>
              <p class="text-muted">Escolha o formato que o site de destino precisa e copie o codigo pronto.</p>
              <cfif qAgendaManagementEdit.status NEQ "ativa"><div class="alert alert-warning py-2">Ative a agenda para liberar os endpoints publicos.</div></cfif>

              <cfset VARIABLES.agendaCodeView = agendaServiceNormalizeView(URL.codigo_visao, "futuros")/>
              <div class="btn-group mb-3">
                <cfoutput><a class="btn btn-sm <cfif VARIABLES.agendaCodeView EQ 'futuros'>btn-warning<cfelse>btn-outline-light</cfif>" href="./?agenda_id=#qAgendaManagementEdit.id_agenda#&codigo_visao=futuros">Codigo para futuros</a><a class="btn btn-sm <cfif VARIABLES.agendaCodeView EQ 'resultados'>btn-warning<cfelse>btn-outline-light</cfif>" href="./?agenda_id=#qAgendaManagementEdit.id_agenda#&codigo_visao=resultados">Codigo para resultados</a></cfoutput>
              </div>

              <cfset VARIABLES.agendaEmbedTarget = "rr-agenda-" & qAgendaManagementEdit.id_agenda/>
              <cfset VARIABLES.agendaEmbedSnippet = '<div id="' & VARIABLES.agendaEmbedTarget & '"></div>' & chr(10) & '<script async src="' & VARIABLES.agendaBaseUrl & '/api/portal/agendas/embed.js" data-agenda="' & qAgendaManagementEdit.chave_publica & '" data-view="' & VARIABLES.agendaCodeView & '" data-target="' & VARIABLES.agendaEmbedTarget & '"></script>'/>
              <cfset VARIABLES.agendaXmlToken = len(VARIABLES.agendaManagementNewFeedToken) ? VARIABLES.agendaManagementNewFeedToken : "TOKEN_GERADO_AO_ROTACIONAR"/>
              <cfset VARIABLES.agendaXmlUrl = VARIABLES.agendaBaseUrl & "/api/portal/agendas/feed.cfm?agenda=" & qAgendaManagementEdit.chave_publica & "&visao=" & VARIABLES.agendaCodeView & "&token=" & VARIABLES.agendaXmlToken/>
              <cfset VARIABLES.agendaJsonUrl = VARIABLES.agendaBaseUrl & "/api/portal/agendas/?agenda=" & qAgendaManagementEdit.chave_publica & "&visao=" & VARIABLES.agendaCodeView/>

              <div class="d-grid gap-2">
                <details class="agenda-disclosure" open>
                  <summary><span><i class="fa-solid fa-code me-2 text-warning"></i>Embed para sites</span><span class="small text-muted fw-normal">HTML + JavaScript</span></summary>
                  <div class="agenda-disclosure-body">
                    <p class="small text-muted">Use para exibir os cards responsivos diretamente em uma pagina.</p>
                    <textarea class="form-control agenda-code mb-2" id="agendaEmbedCode" readonly><cfoutput>#htmlEditFormat(VARIABLES.agendaEmbedSnippet)#</cfoutput></textarea>
                    <button class="btn btn-sm btn-warning" type="button" data-copy-target="agendaEmbedCode"><i class="fa-regular fa-copy me-2"></i>Copiar embed</button>
                  </div>
                </details>

                <details class="agenda-disclosure" <cfif len(VARIABLES.agendaManagementNewFeedToken)>open</cfif>>
                  <summary><span><i class="fa-solid fa-rss me-2 text-warning"></i>Feed XML</span><span class="small text-muted fw-normal">Integracoes e agregadores</span></summary>
                  <div class="agenda-disclosure-body">
                    <textarea class="form-control agenda-code mb-2" id="agendaXmlCode" readonly><cfoutput>#htmlEditFormat(VARIABLES.agendaXmlUrl)#</cfoutput></textarea>
                    <div class="d-flex flex-wrap gap-2 mb-2">
                      <button class="btn btn-sm btn-outline-warning" type="button" data-copy-target="agendaXmlCode"><i class="fa-regular fa-copy me-2"></i>Copiar XML</button>
                      <form method="post" action="./?agenda_id=<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>" onsubmit="return confirm('A credencial anterior deixara de funcionar. Continuar?');"><input type="hidden" name="acao" value="rotacionar_credencial"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.agendaManagementCsrfToken#</cfoutput>"/><input type="hidden" name="agenda_id" value="<cfoutput>#qAgendaManagementEdit.id_agenda#</cfoutput>"/><button class="btn btn-sm btn-outline-danger" type="submit"><i class="fa-solid fa-rotate me-2"></i>Gerar nova credencial</button></form>
                    </div>
                    <cfif len(VARIABLES.agendaManagementNewFeedToken)><div class="alert alert-success py-2 small mb-0">Copie esta URL agora. O token nao sera exibido novamente.</div><cfelse><div class="small text-muted">Gere uma credencial para obter uma URL XML utilizavel.</div></cfif>
                  </div>
                </details>

                <details class="agenda-disclosure">
                  <summary><span><i class="fa-solid fa-file-code me-2 text-warning"></i>Endpoint JSON</span><span class="small text-muted fw-normal">Uso por desenvolvedores</span></summary>
                  <div class="agenda-disclosure-body">
                    <input class="form-control agenda-code min-h-0" id="agendaJsonCode" readonly value="<cfoutput>#htmlEditFormat(VARIABLES.agendaJsonUrl)#</cfoutput>"/>
                    <button class="btn btn-sm btn-outline-warning mt-2" type="button" data-copy-target="agendaJsonCode"><i class="fa-regular fa-copy me-2"></i>Copiar JSON</button>
                  </div>
                </details>
              </div>

              <hr/>
              <div class="row g-2 text-center">
                <div class="col"><div class="small text-muted">Acessos</div><div class="h5"><cfoutput>#LSNumberFormat(qAgendaManagementAccessStats.total)#</cfoutput></div></div>
                <div class="col"><div class="small text-muted">Permitidos</div><div class="h5 text-success"><cfoutput>#LSNumberFormat(qAgendaManagementAccessStats.permitidos)#</cfoutput></div></div>
                <div class="col"><div class="small text-muted">Negados</div><div class="h5 text-danger"><cfoutput>#LSNumberFormat(qAgendaManagementAccessStats.negados)#</cfoutput></div></div>
              </div>
            </div>
          </div>
        </div>

        <cfif qAgendaManagementRecentAccess.recordcount>
          <details class="agenda-panel agenda-disclosure mb-4">
            <summary><span><span class="agenda-kicker d-block">Auditoria</span>Acessos recentes</span><span class="badge bg-secondary"><cfoutput>#qAgendaManagementRecentAccess.recordcount#</cfoutput></span></summary>
            <div class="agenda-disclosure-body table-responsive">
              <table class="table table-sm agenda-table mb-0">
                <thead><tr><th>Data</th><th>Formato</th><th>Visao</th><th>Dominio</th><th>IP</th><th>HTTP</th><th>Eventos</th><th>Tempo</th></tr></thead>
                <tbody>
                  <cfoutput query="qAgendaManagementRecentAccess">
                    <cfset VARIABLES.agendaAccessView = agendaServiceQueryValue(qAgendaManagementRecentAccess, "visao", currentRow) & ""/>
                    <cfset VARIABLES.agendaAccessHost = agendaServiceQueryValue(qAgendaManagementRecentAccess, "dominio_requisitante", currentRow) & ""/>
                    <cfset VARIABLES.agendaAccessIp = agendaServiceQueryValue(qAgendaManagementRecentAccess, "endereco_ip", currentRow) & ""/>
                    <cfset VARIABLES.agendaAccessDuration = agendaServiceQueryValue(qAgendaManagementRecentAccess, "duracao_ms", currentRow) & ""/>
                    <tr>
                      <td class="text-nowrap">#dateFormat(data_acesso, "dd/mm/yyyy")# #timeFormat(data_acesso, "HH:nn:ss")#</td>
                      <td>#uCase(htmlEditFormat(formato))#</td>
                      <td>#htmlEditFormat(VARIABLES.agendaAccessView)#</td>
                      <td>#htmlEditFormat(VARIABLES.agendaAccessHost)#</td>
                      <td>#htmlEditFormat(VARIABLES.agendaAccessIp)#</td>
                      <td><span class="badge <cfif status_http GTE 200 AND status_http LT 400>bg-success<cfelse>bg-danger</cfif>">#status_http#</span></td>
                      <td>#eventos_retornados#</td>
                      <td><cfif len(VARIABLES.agendaAccessDuration)>#VARIABLES.agendaAccessDuration# ms<cfelse>-</cfif></td>
                    </tr>
                  </cfoutput>
                </tbody>
              </table>
            </div>
          </details>
        </cfif>
      </cfif>
    </cfif>

    <cfif NOT VARIABLES.agendaShowEditor>
    <div class="agenda-panel p-3 p-lg-4">
      <div class="d-flex justify-content-between align-items-center mb-3"><div><div class="agenda-kicker">Gerenciamento</div><h4 class="mb-0">Agendas cadastradas</h4></div></div>
      <cfif qAgendaManagementList.recordcount>
        <div class="table-responsive">
          <table class="table agenda-table mb-0">
            <thead><tr><th>ID</th><th>Agenda</th><th>Proprietario</th><th>Modo</th><th>Dominio</th><th>Itens</th><th>Acessos</th><th>Status</th><th class="text-end">Acao</th></tr></thead>
            <tbody>
              <cfoutput query="qAgendaManagementList">
                <cfset VARIABLES.agendaStatusClass = status EQ "ativa" ? "is-active" : (status EQ "rascunho" ? "is-draft" : (status EQ "pausada" ? "is-paused" : "is-archived"))/>
                <tr>
                  <td class="text-nowrap">## #id_agenda#</td>
                  <td class="agenda-event-name"><a href="./?agenda_id=#id_agenda#" class="fw-semibold">#htmlEditFormat(nome)#</a><div class="small text-muted">v#versao#</div></td>
                  <td><div>#htmlEditFormat(usuario_nome)#</div><div class="small text-muted">## #id_usuario# - #htmlEditFormat(usuario_email)#</div></td>
                  <td><span class="badge <cfif modo EQ 'dinamica'>bg-info text-dark<cfelse>bg-secondary</cfif>">#modo#</span></td>
                  <td><div>#htmlEditFormat(dominio_permitido)#</div><cfif agendaServiceNormalizeBoolean(permitir_subdominios)><div class="small text-muted">inclui subdominios</div></cfif></td>
                  <td><cfif modo EQ "manual">#total_eventos# evento(s)<cfelse>#total_filtros# regra(s)</cfif></td>
                  <td>#LSNumberFormat(total_acessos, "9,999,999")#</td>
                  <td><span class="agenda-status #VARIABLES.agendaStatusClass#">#status#</span></td>
                  <td class="text-end"><a class="btn btn-sm btn-outline-warning" href="./?agenda_id=#id_agenda#" title="Editar"><i class="fa-solid fa-pen"></i></a></td>
                </tr>
              </cfoutput>
            </tbody>
          </table>
        </div>
      <cfelse><div class="text-muted">Nenhuma agenda cadastrada.</div></cfif>
    </div>
    </cfif>
  </cfif>
</section>

<script>
document.querySelectorAll('[data-copy-target]').forEach(function (button) {
  button.addEventListener('click', function () {
    var target = document.getElementById(button.getAttribute('data-copy-target'));
    if (!target) return;
    var value = typeof target.value === 'string' ? target.value : target.textContent;
    navigator.clipboard.writeText(value).then(function () {
      var original = button.innerHTML;
      button.innerHTML = '<i class="fa-solid fa-check me-2"></i>Copiado';
      setTimeout(function () { button.innerHTML = original; }, 1400);
    });
  });
});

var agendaRuleSelector = document.querySelector('[data-agenda-rule-selector]');
if (agendaRuleSelector) {
  var showAgendaRulePanel = function () {
    document.querySelectorAll('[data-agenda-rule-panel]').forEach(function (panel) {
      panel.hidden = panel.getAttribute('data-agenda-rule-panel') !== agendaRuleSelector.value;
    });
  };
  agendaRuleSelector.addEventListener('change', showAgendaRulePanel);
  showAgendaRulePanel();
}

var agendaModeInputs = document.querySelectorAll('input[name="modo"]');
var agendaManualOrder = document.querySelector('[data-agenda-manual-order]');
if (agendaModeInputs.length && agendaManualOrder) {
  var updateAgendaModeFields = function () {
    var selectedMode = document.querySelector('input[name="modo"]:checked');
    agendaManualOrder.hidden = selectedMode && selectedMode.value !== 'manual';
  };
  agendaModeInputs.forEach(function (input) { input.addEventListener('change', updateAgendaModeFields); });
  updateAgendaModeFields();
}

var agendaPreview = document.querySelector('[data-agenda-preview]');
var agendaThemeInputs = document.querySelectorAll('[data-agenda-theme-input]');
var agendaDateColor = document.querySelector('[data-agenda-date-color]');
var agendaDateColorValue = document.querySelector('[data-agenda-date-color-value]');
var agendaCardFont = document.querySelector('[data-agenda-card-font]');
var agendaCardRadius = document.querySelector('[data-agenda-card-radius]');
if (agendaPreview) {
  agendaThemeInputs.forEach(function (input) {
    input.addEventListener('change', function () {
      agendaPreview.classList.toggle('is-light', input.checked && input.value === 'claro');
    });
  });

  if (agendaDateColor) {
    agendaDateColor.addEventListener('input', function () {
      var color = agendaDateColor.value;
      var red = parseInt(color.slice(1, 3), 16);
      var green = parseInt(color.slice(3, 5), 16);
      var blue = parseInt(color.slice(5, 7), 16);
      var luminance = (red * 299 + green * 587 + blue * 114) / 1000;
      agendaPreview.style.setProperty('--agenda-preview-date', color);
      agendaPreview.style.setProperty('--agenda-preview-date-text', luminance >= 145 ? '#171717' : '#ffffff');
      if (agendaDateColorValue) agendaDateColorValue.textContent = color.toUpperCase();
    });
  }

  if (agendaCardFont) {
    agendaCardFont.addEventListener('change', function () {
      agendaPreview.setAttribute('data-card-font', agendaCardFont.value);
    });
  }

  if (agendaCardRadius) {
    agendaCardRadius.addEventListener('change', function () {
      agendaPreview.setAttribute('data-card-radius', agendaCardRadius.value);
    });
  }
}

var selectAll = document.querySelector('[data-agenda-select-all]');
if (selectAll) {
  selectAll.addEventListener('change', function () {
    document.querySelectorAll('[data-agenda-event-checkbox]:not(:disabled)').forEach(function (checkbox) {
      checkbox.checked = selectAll.checked;
    });
  });
}
</script>
