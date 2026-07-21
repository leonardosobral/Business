<cfset VARIABLES.challengeCircuitTitle = VARIABLES.challengeTag EQ "catarinensetrailrun" ? "Catarinense Trail" : "Catarinense Rua"/>
<cfset VARIABLES.challengeCircuitAccent = VARIABLES.challengeTag EQ "catarinensetrailrun" ? "success" : "danger"/>
<cfset VARIABLES.challengeCircuitExportUrl = "/desafios/includes/exportar_catarinense.cfm?desafio=#urlEncodedFormat(VARIABLES.challengeTag)#&busca=#urlEncodedFormat(URL.busca)#&genero=#urlEncodedFormat(URL.genero)#&medalha=#urlEncodedFormat(URL.medalha)#&regiao=#urlEncodedFormat(URL.regiao)#&estado=#urlEncodedFormat(URL.estado)#&cidade=#urlEncodedFormat(URL.cidade)#"/>

<style>
  .catarinense-hero {
    background:
      radial-gradient(circle at 100% 0, rgba(250, 177, 32, .18), transparent 38%),
      linear-gradient(135deg, rgba(255, 255, 255, .08), rgba(255, 255, 255, .02));
    border: 1px solid rgba(255, 255, 255, .1);
    border-radius: 1rem;
  }

  .catarinense-metric {
    background: rgba(255, 255, 255, .04);
    border: 1px solid rgba(255, 255, 255, .08);
    border-radius: .8rem;
    min-height: 100%;
  }

  .catarinense-metric-value {
    font-size: 1.65rem;
    font-weight: 800;
    line-height: 1;
  }

  .catarinense-filter-card,
  .catarinense-ranking-card {
    border: 1px solid rgba(255, 255, 255, .08);
    border-radius: 1rem;
    overflow: hidden;
  }

  .catarinense-stage-legend {
    display: grid;
    gap: .5rem;
    grid-template-columns: repeat(6, minmax(130px, 1fr));
  }

  .catarinense-stage-item {
    background: rgba(255, 255, 255, .04);
    border: 1px solid rgba(255, 255, 255, .08);
    border-radius: .65rem;
    color: inherit;
    min-width: 0;
    padding: .6rem .7rem;
  }

  .catarinense-stage-item:hover {
    border-color: rgba(250, 177, 32, .65);
  }

  .catarinense-stage-name {
    display: block;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .catarinense-ranking-table th,
  .catarinense-ranking-table td {
    vertical-align: middle;
  }

  .catarinense-ranking-table .stage-score {
    min-width: 58px;
    text-align: center;
  }

  .catarinense-athlete {
    min-width: 240px;
  }

  .catarinense-avatar {
    border: 2px solid rgba(250, 177, 32, .65);
    height: 36px;
    object-fit: cover;
    width: 36px;
  }

  @media (max-width: 991.98px) {
    .catarinense-stage-legend {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }
  }
</style>

<section class="catarinense-dashboard">
  <cfif isDefined("URL.sucesso") AND URL.sucesso EQ "medalha_entregue">
    <div class="alert alert-success"><i class="fa-solid fa-medal me-2"></i>Medalha marcada como entregue.</div>
  </cfif>

  <div class="catarinense-hero p-3 p-lg-4 mb-3">
    <div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-4">
      <div>
        <div class="small text-uppercase text-muted fw-bold">Circuito Catarinense 2026</div>
        <h1 class="h3 mb-1"><cfoutput>#VARIABLES.challengeCircuitTitle#</cfoutput></h1>
        <p class="text-muted mb-0">Ranking por resultados reconhecidos, pontuação oficial por etapa e controle de entrega de medalhas. O total considera as quatro melhores pontuações entre as seis etapas.</p>
      </div>
      <a class="btn btn-outline-success btn-sm" href="<cfoutput>#htmlEditFormat(VARIABLES.challengeCircuitExportUrl)#</cfoutput>">
        <i class="fa-solid fa-file-excel me-1"></i> Exportar lista filtrada
      </a>
    </div>

    <div class="row g-2">
      <div class="col-6 col-lg">
        <div class="catarinense-metric p-3">
          <div class="catarinense-metric-value"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.inscritos, "9")#</cfoutput></div>
          <div class="small text-muted mt-1">Inscritos</div>
        </div>
      </div>
      <div class="col-6 col-lg">
        <div class="catarinense-metric p-3">
          <div class="catarinense-metric-value"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.comResultado, "9")#</cfoutput></div>
          <div class="small text-muted mt-1">Com etapa reconhecida</div>
        </div>
      </div>
      <div class="col-6 col-lg">
        <a class="d-block h-100" href="./?medalha=proxima_etapa">
          <div class="catarinense-metric p-3">
            <div class="catarinense-metric-value text-info"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.proximaEtapa, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Medalha na próxima etapa</div>
          </div>
        </a>
      </div>
      <div class="col-6 col-lg">
        <a class="d-block h-100" href="./?medalha=imediata">
          <div class="catarinense-metric p-3">
            <div class="catarinense-metric-value text-warning"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.imediata, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Entrega imediata</div>
          </div>
        </a>
      </div>
      <div class="col-6 col-lg">
        <a class="d-block h-100" href="./?medalha=entregue">
          <div class="catarinense-metric p-3">
            <div class="catarinense-metric-value text-success"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.entregue, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Medalhas entregues</div>
          </div>
        </a>
      </div>
    </div>
  </div>

  <div class="card catarinense-filter-card mb-3">
    <div class="card-body p-3">
      <form method="get" class="row g-2 align-items-end">
        <div class="col-12 col-lg-3">
          <label class="form-label">Atleta</label>
          <input class="form-control" type="search" name="busca" value="<cfoutput>#htmlEditFormat(URL.busca)#</cfoutput>" placeholder="Nome do atleta"/>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Gênero</label>
          <select class="form-select" name="genero">
            <option value="">Todos</option>
            <option value="feminino" <cfif URL.genero EQ "feminino">selected</cfif>>Feminino</option>
            <option value="masculino" <cfif URL.genero EQ "masculino">selected</cfif>>Masculino</option>
            <option value="nao_informado" <cfif URL.genero EQ "nao_informado">selected</cfif>>Não informado</option>
          </select>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">Medalha</label>
          <select class="form-select" name="medalha">
            <option value="">Todos os status</option>
            <option value="progresso" <cfif URL.medalha EQ "progresso">selected</cfif>>Em progresso</option>
            <option value="proxima_etapa" <cfif URL.medalha EQ "proxima_etapa">selected</cfif>>Próxima etapa</option>
            <option value="imediata" <cfif URL.medalha EQ "imediata">selected</cfif>>Entrega imediata</option>
            <option value="entregue" <cfif URL.medalha EQ "entregue">selected</cfif>>Entregue</option>
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

  <div class="catarinense-stage-legend mb-3">
    <cfoutput query="qCatarinenseEvents">
      <a class="catarinense-stage-item" href="https://roadrunners.run/evento/#urlEncodedFormat(qCatarinenseEvents.event_tag)#/" target="_blank" rel="noopener noreferrer" title="#htmlEditFormat(qCatarinenseEvents.nome_evento)#">
        <span class="small text-muted">E#qCatarinenseEvents.event_order# · #numberFormat(qCatarinenseEvents.percurso, "9")# km</span>
        <strong class="catarinense-stage-name">#htmlEditFormat(qCatarinenseEvents.nome_evento)#</strong>
        <span class="small text-muted"><cfif isDate(qCatarinenseEvents.data_inicial)>#dateFormat(qCatarinenseEvents.data_inicial, "dd/mm/yyyy")#<cfelse>Data a confirmar</cfif></span>
      </a>
    </cfoutput>
  </div>

  <cfif NOT qStatsBase.recordcount>
    <div class="alert alert-secondary">Nenhum atleta encontrado com os filtros selecionados.</div>
  <cfelse>
    <div class="d-grid gap-3">
      <cfif NOT len(URL.genero) OR URL.genero EQ "feminino">
        <cfset VARIABLES.qCatarinenseRanking = qCatarinenseFemale/>
        <cfset VARIABLES.catarinenseRankingTitle = "Feminino"/>
        <cfset VARIABLES.catarinenseRankingIcon = "fa-venus"/>
        <cfinclude template="catarinense_table.cfm"/>
      </cfif>
      <cfif NOT len(URL.genero) OR URL.genero EQ "masculino">
        <cfset VARIABLES.qCatarinenseRanking = qCatarinenseMale/>
        <cfset VARIABLES.catarinenseRankingTitle = "Masculino"/>
        <cfset VARIABLES.catarinenseRankingIcon = "fa-mars"/>
        <cfinclude template="catarinense_table.cfm"/>
      </cfif>
      <cfif (NOT len(URL.genero) OR URL.genero EQ "nao_informado") AND qCatarinenseUninformed.recordcount>
        <cfset VARIABLES.qCatarinenseRanking = qCatarinenseUninformed/>
        <cfset VARIABLES.catarinenseRankingTitle = "Gênero não informado"/>
        <cfset VARIABLES.catarinenseRankingIcon = "fa-circle-question"/>
        <cfinclude template="catarinense_table.cfm"/>
      </cfif>
    </div>
  </cfif>
</section>
