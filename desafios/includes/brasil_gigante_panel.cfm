<cfset VARIABLES.challengeCircuitExportUrl = "/desafios/includes/exportar_brasil_gigante.cfm?busca=#urlEncodedFormat(URL.busca)#&mandala=#urlEncodedFormat(URL.mandala)#&regiao=#urlEncodedFormat(URL.regiao)#&estado=#urlEncodedFormat(URL.estado)#&cidade=#urlEncodedFormat(URL.cidade)#"/>

<style>
  .cbg-dashboard-hero {
    background:
      radial-gradient(circle at 100% 0, rgba(250, 177, 32, .2), transparent 38%),
      linear-gradient(135deg, rgba(255, 255, 255, .08), rgba(255, 255, 255, .02));
    border: 1px solid rgba(255, 255, 255, .1);
    border-radius: 1rem;
  }

  .cbg-dashboard-metric {
    background: rgba(255, 255, 255, .04);
    border: 1px solid rgba(255, 255, 255, .08);
    border-radius: .8rem;
    min-height: 100%;
  }

  .cbg-dashboard-metric-value {
    font-size: 1.65rem;
    font-weight: 800;
    line-height: 1;
  }

  .cbg-dashboard-filter,
  .cbg-dashboard-ranking,
  .cbg-validation-panel {
    border: 1px solid rgba(255, 255, 255, .08);
    border-radius: 1rem;
    overflow: hidden;
  }

  .cbg-dashboard-stages {
    display: grid;
    gap: .5rem;
    grid-template-columns: repeat(8, minmax(105px, 1fr));
  }

  .cbg-dashboard-stage {
    background: rgba(255, 255, 255, .04);
    border: 1px solid rgba(255, 255, 255, .08);
    border-radius: .65rem;
    min-width: 0;
    padding: .6rem .7rem;
  }

  .cbg-dashboard-stage strong {
    display: block;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .cbg-dashboard-table th,
  .cbg-dashboard-table td {
    vertical-align: middle;
  }

  .cbg-dashboard-table .cbg-stage-result {
    min-width: 56px;
    text-align: center;
  }

  .cbg-dashboard-athlete {
    min-width: 245px;
  }

  .cbg-dashboard-avatar {
    border: 2px solid rgba(250, 177, 32, .65);
    height: 36px;
    object-fit: cover;
    width: 36px;
  }

  .cbg-dashboard-navigation {
    display: flex;
    flex-wrap: wrap;
    gap: .5rem;
  }

  .cbg-validation-card {
    background: rgba(255, 255, 255, .035);
    border: 1px solid rgba(255, 255, 255, .08);
    border-left: 4px solid rgba(255, 255, 255, .15);
    border-radius: .9rem;
    transition: border-color .2s ease, transform .2s ease, background .2s ease;
  }

  .cbg-validation-card:hover {
    background: rgba(255, 255, 255, .055);
    transform: translateY(-1px);
  }

  .cbg-validation-card--pendente { border-left-color: #ffc107; }
  .cbg-validation-card--aprovado { border-left-color: #20c997; }
  .cbg-validation-card--desaprovado { border-left-color: #dc3545; }

  .cbg-validation-filterbar {
    display: flex;
    flex-wrap: wrap;
    gap: .5rem;
    padding: .75rem;
    margin-bottom: 1rem;
    border-radius: .8rem;
    background: rgba(255, 255, 255, .03);
    border: 1px solid rgba(255, 255, 255, .07);
  }

  .cbg-validation-filter {
    display: inline-flex;
    align-items: center;
    gap: .45rem;
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: 999px;
    padding: .45rem .75rem;
    color: inherit;
    background: transparent;
    font-size: .78rem;
    font-weight: 700;
  }

  .cbg-validation-filter.is-active {
    color: #111;
    background: #ffc107;
    border-color: #ffc107;
  }

  .cbg-validation-status {
    display: inline-flex;
    align-items: center;
    gap: .4rem;
    border-radius: 999px;
    padding: .42rem .7rem;
    font-size: .72rem;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: .04em;
  }

  .cbg-validation-status--pendente { color: #ffe69c; background: rgba(255, 193, 7, .13); }
  .cbg-validation-status--aprovado { color: #75e6c0; background: rgba(32, 201, 151, .13); }
  .cbg-validation-status--desaprovado { color: #ff9ca6; background: rgba(220, 53, 69, .14); }

  .cbg-validation-summary {
    display: grid;
    grid-template-columns: minmax(0, 1.7fr) repeat(3, minmax(110px, .55fr));
    gap: .65rem;
    margin: .9rem 0;
  }

  .cbg-validation-summary-item {
    min-width: 0;
    padding: .65rem .75rem;
    border-radius: .65rem;
    background: rgba(0, 0, 0, .14);
  }

  .cbg-validation-summary-label {
    display: block;
    margin-bottom: .15rem;
    color: var(--mdb-secondary-color, rgba(255,255,255,.6));
    font-size: .66rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: .05em;
  }

  .cbg-validation-detail-grid {
    display: grid;
    grid-template-columns: minmax(0, 1.3fr) minmax(260px, .7fr);
    gap: 1rem;
    padding-top: .85rem;
    border-top: 1px solid rgba(255, 255, 255, .07);
  }

  .cbg-validation-actions {
    margin-top: 1rem;
    padding-top: .85rem;
    border-top: 1px solid rgba(255, 255, 255, .07);
  }

  @media (max-width: 767.98px) {
    .cbg-validation-summary { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .cbg-validation-summary-item:first-child { grid-column: 1 / -1; }
    .cbg-validation-detail-grid { grid-template-columns: 1fr; }
  }

  .cbg-validation-files {
    display: flex;
    flex-wrap: wrap;
    gap: .4rem;
  }

  @media (max-width: 1199.98px) {
    .cbg-dashboard-stages {
      grid-template-columns: repeat(4, minmax(0, 1fr));
    }
  }

  @media (max-width: 575.98px) {
    .cbg-dashboard-stages {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }
  }
</style>

<section class="cbg-dashboard">
  <cfif isDefined("URL.sucesso") AND URL.sucesso EQ "mandala_entregue">
    <div class="alert alert-success"><i class="fa-solid fa-award me-2"></i>Mandala marcada como entregue.</div>
  </cfif>

  <div class="cbg-dashboard-hero p-3 p-lg-4 mb-3">
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-4">
      <div>
        <div class="small text-uppercase text-muted fw-bold">Circuito de Maratonas</div>
        <h1 class="h3 mb-1"><cfif URL.tela EQ "validacoes">Validações documentais<cfelse>Participantes do Brasil Gigante</cfif></h1>
        <p class="text-muted mb-0"><cfif URL.tela EQ "validacoes">Analise os comprovantes enviados pelos atletas e registre participações reconhecidas manualmente.<cfelse>Ranking por etapas reconhecidas nas oito maratonas oficiais, com controle de entrega da mandala.</cfif></p>
      </div>
      <div class="cbg-dashboard-navigation">
        <a class="btn btn-sm <cfif URL.tela EQ 'participantes'>btn-warning<cfelse>btn-outline-secondary</cfif>" href="/desafios/circuitobrasilgigante/">
          <i class="fa-solid fa-users me-1"></i>Participantes
        </a>
        <a class="btn btn-sm <cfif URL.tela EQ 'validacoes'>btn-warning<cfelse>btn-outline-secondary</cfif>" href="/desafios/circuitobrasilgigante/?tela=validacoes">
          <i class="fa-solid fa-file-shield me-1"></i>Validações documentais
        </a>
        <cfif URL.tela EQ "participantes">
          <a class="btn btn-outline-success btn-sm" href="<cfoutput>#htmlEditFormat(VARIABLES.challengeCircuitExportUrl)#</cfoutput>">
            <i class="fa-solid fa-file-excel me-1"></i>Exportar lista
          </a>
        </cfif>
      </div>
    </div>

    <cfif URL.tela EQ "participantes">
      <div class="row g-2">
      <div class="col-6 col-lg">
        <div class="cbg-dashboard-metric p-3">
          <div class="cbg-dashboard-metric-value"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.inscritos, "9")#</cfoutput></div>
          <div class="small text-muted mt-1">Atletas inscritos</div>
        </div>
      </div>
      <div class="col-6 col-lg">
        <div class="cbg-dashboard-metric p-3">
          <div class="cbg-dashboard-metric-value"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.comResultado, "9")#</cfoutput></div>
          <div class="small text-muted mt-1">Com etapa reconhecida</div>
        </div>
      </div>
      <div class="col-6 col-lg">
        <a class="d-block h-100" href="./?mandala=proxima_etapa">
          <div class="cbg-dashboard-metric p-3">
            <div class="cbg-dashboard-metric-value text-info"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.proximaEtapa, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Mandala na próxima etapa</div>
          </div>
        </a>
      </div>
      <div class="col-6 col-lg">
        <a class="d-block h-100" href="./?mandala=imediata">
          <div class="cbg-dashboard-metric p-3">
            <div class="cbg-dashboard-metric-value text-warning"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.imediata, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Entrega imediata</div>
          </div>
        </a>
      </div>
      <div class="col-6 col-lg">
        <a class="d-block h-100" href="./?mandala=entregue">
          <div class="cbg-dashboard-metric p-3">
            <div class="cbg-dashboard-metric-value text-success"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.entregue, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Mandalas entregues</div>
          </div>
        </a>
      </div>
      </div>
    </cfif>
  </div>

  <cfif URL.tela EQ "validacoes">
    <cfinclude template="brasil_gigante_validacoes_panel.cfm"/>
  <cfelse>

  <div class="card cbg-dashboard-filter mb-3">
    <div class="card-body p-3">
      <form method="get" class="row g-2 align-items-end">
        <div class="col-12 col-lg-3">
          <label class="form-label">Atleta</label>
          <input class="form-control" type="search" name="busca" value="<cfoutput>#htmlEditFormat(URL.busca)#</cfoutput>" placeholder="Nome do atleta"/>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Mandala</label>
          <select class="form-select" name="mandala">
            <option value="">Todos os status</option>
            <option value="progresso" <cfif URL.mandala EQ "progresso">selected</cfif>>Em progresso</option>
            <option value="proxima_etapa" <cfif URL.mandala EQ "proxima_etapa">selected</cfif>>Próxima etapa</option>
            <option value="imediata" <cfif URL.mandala EQ "imediata">selected</cfif>>Entrega imediata</option>
            <option value="entregue" <cfif URL.mandala EQ "entregue">selected</cfif>>Entregue</option>
          </select>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Região</label>
          <select class="form-select" name="regiao">
            <option value="">Todas</option>
            <cfoutput query="qStatsRegiao">
              <option value="#htmlEditFormat(qStatsRegiao.regiao)#" <cfif URL.regiao EQ qStatsRegiao.regiao>selected</cfif>>#htmlEditFormat(qStatsRegiao.regiao)#</option>
            </cfoutput>
          </select>
        </div>
        <div class="col-6 col-lg-1">
          <label class="form-label">UF</label>
          <select class="form-select" name="estado">
            <option value="">Todas</option>
            <cfoutput query="qStatsEstado">
              <option value="#htmlEditFormat(qStatsEstado.estado)#" <cfif URL.estado EQ qStatsEstado.estado>selected</cfif>>#htmlEditFormat(qStatsEstado.estado)#</option>
            </cfoutput>
          </select>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Cidade</label>
          <select class="form-select" name="cidade">
            <option value="">Todas</option>
            <cfoutput query="qStatsCidade">
              <option value="#htmlEditFormat(qStatsCidade.cidade)#" <cfif URL.cidade EQ qStatsCidade.cidade>selected</cfif>>#htmlEditFormat(qStatsCidade.cidade)#/#htmlEditFormat(qStatsCidade.estado)#</option>
            </cfoutput>
          </select>
        </div>
        <div class="col-6 col-lg-2 d-flex gap-2">
          <button class="btn btn-warning flex-fill" type="submit">Filtrar</button>
          <a class="btn btn-outline-secondary" href="./" title="Limpar filtros"><i class="fa-solid fa-rotate-left"></i></a>
        </div>
      </form>
    </div>
  </div>

  <div class="cbg-dashboard-stages mb-3">
    <cfloop array="#VARIABLES.challengeCircuitEvents#" item="VARIABLES.challengeCircuitEvent">
      <div class="cbg-dashboard-stage" title="<cfoutput>#htmlEditFormat(VARIABLES.challengeCircuitEvent.nome)#</cfoutput>">
        <span class="small text-muted">E<cfoutput>#VARIABLES.challengeCircuitEvent.ordem# · #VARIABLES.challengeCircuitEvent.sigla#</cfoutput></span>
        <strong><cfoutput>#htmlEditFormat(VARIABLES.challengeCircuitEvent.nome)#</cfoutput></strong>
      </div>
    </cfloop>
  </div>

  <cfinclude template="brasil_gigante_table.cfm"/>
  </cfif>
</section>
