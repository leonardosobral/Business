<cfset VARIABLES.challengeCircuitTitle = VARIABLES.challengeTag EQ "catarinensetrailrun" ? "Catarinense Trail" : "Catarinense Rua"/>
<cfset VARIABLES.challengeCircuitAccent = VARIABLES.challengeTag EQ "catarinensetrailrun" ? "success" : "danger"/>
<cfparam name="URL.aba" default="#len(URL.medalha) ? 'medalhas' : 'ranking'#"/>
<cfparam name="URL.pagina" default="1"/>
<cfset URL.aba = lcase(trim(URL.aba))/>
<cfif NOT listFind("ranking,medalhas,etapas,regras",URL.aba)><cfset URL.aba="ranking"/></cfif>
<cfset VARIABLES.catarinenseGenderCounts={feminino=0,masculino=0,nao_informado=0}/>
<cfloop query="qBase">
  <cfswitch expression="#qBase.genero#">
    <cfcase value="FEMININO"><cfset VARIABLES.catarinenseGenderCounts.feminino++/></cfcase>
    <cfcase value="MASCULINO"><cfset VARIABLES.catarinenseGenderCounts.masculino++/></cfcase>
    <cfdefaultcase><cfset VARIABLES.catarinenseGenderCounts.nao_informado++/></cfdefaultcase>
  </cfswitch>
</cfloop>
<cfset VARIABLES.catarinenseGenderLabel=""/>
<cfset VARIABLES.catarinenseViewPending=0/>
<cfif URL.aba EQ "ranking">
  <cfif NOT listFind("feminino,masculino,nao_informado",URL.genero)>
    <cfset URL.genero=VARIABLES.catarinenseGenderCounts.feminino GT 0 ? 'feminino' : (VARIABLES.catarinenseGenderCounts.masculino GT 0 ? 'masculino' : (VARIABLES.catarinenseGenderCounts.nao_informado GT 0 ? 'nao_informado' : 'feminino'))/>
  </cfif>
  <cfset VARIABLES.catarinenseGenderValue=URL.genero EQ 'feminino' ? 'FEMININO' : (URL.genero EQ 'masculino' ? 'MASCULINO' : 'NAO INFORMADO')/>
  <cfset VARIABLES.catarinenseGenderLabel=URL.genero EQ 'feminino' ? 'feminino' : (URL.genero EQ 'masculino' ? 'masculino' : 'sem gênero informado')/>
  <!--- Filter before pagination; ranking_ordem already includes all tie-breaks. --->
  <cfquery name="qCatarinenseGenderView" dbtype="query">
    SELECT * FROM qStatsBase
    WHERE genero = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.catarinenseGenderValue#"/>
    ORDER BY ranking_ordem
  </cfquery>
  <cfset qStatsBase=qCatarinenseGenderView/>
  <cfloop query="qStatsBase"><cfif listFind('dados_pendentes,sorteio',qStatsBase.ranking_criterio)><cfset VARIABLES.catarinenseViewPending++/></cfif></cfloop>
</cfif>
<cfset VARIABLES.challengeCircuitExportUrl = "/desafios/includes/exportar_catarinense.cfm?desafio=#urlEncodedFormat(VARIABLES.challengeTag)#&busca=#urlEncodedFormat(URL.busca)#&genero=#urlEncodedFormat(URL.genero)#&medalha=#urlEncodedFormat(URL.medalha)#&regiao=#urlEncodedFormat(URL.regiao)#&estado=#urlEncodedFormat(URL.estado)#&cidade=#urlEncodedFormat(URL.cidade)#&periodo=#urlEncodedFormat(URL.periodo)#&preset=#urlEncodedFormat(URL.preset)#"/>
<cfset VARIABLES.catarinensePageSize=50/>
<cfset VARIABLES.catarinensePageCount=max(1,ceiling(qStatsBase.recordCount/VARIABLES.catarinensePageSize))/>
<cfset URL.pagina=min(VARIABLES.catarinensePageCount,max(1,int(val(URL.pagina))))/>
<cfset VARIABLES.catarinenseStartRow=(URL.pagina-1)*VARIABLES.catarinensePageSize+1/>
<cfset VARIABLES.catarinenseEndRow=min(qStatsBase.recordCount,VARIABLES.catarinenseStartRow+VARIABLES.catarinensePageSize-1)/>

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
  .catarinense-tabs { display:flex; gap:.5rem; overflow-x:auto; padding:.25rem 0 .75rem; }
  .catarinense-tabs a { color:inherit; white-space:nowrap; border-radius:.6rem; padding:.65rem 1rem; border:1px solid rgba(255,255,255,.12); }
  .catarinense-tabs a[aria-current="page"] { color:#222; background:#fab120; border-color:#fab120; font-weight:700; }
  .catarinense-dashboard a:focus-visible,.catarinense-dashboard summary:focus-visible { outline:3px solid #fab120; outline-offset:3px; }
  .catarinense-table-scroll { max-height:65vh; overflow:auto; }
  .catarinense-ranking-table thead th { position:sticky; top:0; z-index:3; background:var(--mdb-body-bg,#262626); }
  .catarinense-ranking-table .catarinense-athlete { position:sticky; left:0; z-index:1; background:var(--mdb-body-bg,#262626); max-width:320px; }
  .catarinense-ranking-table thead .catarinense-athlete { z-index:4; }
  .catarinense-tie-details { font-size:.78rem; margin-top:.35rem; }
  .catarinense-tie-details summary { cursor:pointer; color:#fab120; }
  .catarinense-tie-details dl { margin:.5rem 0 0; }
  .catarinense-tie-details dd { margin-bottom:.4rem; }
  .catarinense-pagination { display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:.75rem; padding:1rem; }
  .catarinense-rule-list li { padding:.4rem 0; }
  .catarinense-gender-card { border:1px solid rgba(255,255,255,.12); border-radius:.85rem; background:rgba(255,255,255,.03); padding:1rem; margin-bottom:1rem; }
  .catarinense-gender-switch { display:flex; flex-wrap:wrap; gap:.65rem; }
  .catarinense-gender-link { display:flex; align-items:center; justify-content:center; gap:.65rem; flex:1 1 120px; padding:.85rem 1rem; border:1px solid rgba(255,255,255,.18); border-radius:.7rem; color:inherit; font-weight:700; }
  .catarinense-gender-link:hover { border-color:#fab120; color:inherit; }
  .catarinense-gender-link[aria-current="page"] { background:#fab120; border-color:#fab120; color:#222; box-shadow:0 0 0 2px rgba(250,177,32,.15); }
  .catarinense-gender-count { padding:.15rem .5rem; border-radius:1rem; background:rgba(127,127,127,.16); font-size:.8rem; }
  .catarinense-gender-uninformed { flex-basis:100%; padding:.5rem 1rem; font-size:.85rem; font-weight:500; }

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
        <p class="text-muted mb-0">Quatro melhores pontuações · seis etapas · mandala com cinco conclusões. Classificação por gênero com os desempates do regulamento.</p>
      </div>
      <div class="d-flex flex-wrap gap-2">
        <a class="btn btn-outline-light btn-sm" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag EQ 'catarinensetrailrun' ? 'catarinensecorridaderua' : 'catarinensetrailrun',{aba=URL.aba,genero=URL.genero}))#</cfoutput>"><i class="fa-solid fa-arrow-right-arrow-left me-1"></i> Ir para <cfif VARIABLES.challengeTag EQ "catarinensetrailrun">Rua<cfelse>Trail</cfif></a>
        <a class="btn btn-outline-success btn-sm" href="<cfoutput>#encodeForHTMLAttribute(VARIABLES.challengeCircuitExportUrl)#</cfoutput>"><i class="fa-solid fa-file-excel me-1"></i> Exportar lista filtrada</a>
      </div>
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
        <a class="d-block h-100" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{aba='medalhas',medalha='proxima_etapa',pagina=1}))#</cfoutput>">
          <div class="catarinense-metric p-3">
            <div class="catarinense-metric-value text-info"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.proximaEtapa, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Medalha na próxima etapa</div>
          </div>
        </a>
      </div>
      <div class="col-6 col-lg">
        <a class="d-block h-100" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{aba='medalhas',medalha='imediata',pagina=1}))#</cfoutput>">
          <div class="catarinense-metric p-3">
            <div class="catarinense-metric-value text-warning"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.imediata, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Entrega imediata</div>
          </div>
        </a>
      </div>
      <div class="col-6 col-lg">
        <a class="d-block h-100" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{aba='medalhas',medalha='entregue',pagina=1}))#</cfoutput>">
          <div class="catarinense-metric p-3">
            <div class="catarinense-metric-value text-success"><cfoutput>#numberFormat(VARIABLES.challengeCircuitMetrics.entregue, "9")#</cfoutput></div>
            <div class="small text-muted mt-1">Medalhas entregues</div>
          </div>
        </a>
      </div>
    </div>
    <div class="small text-muted mt-3">Indicadores gerais do circuito; os filtros abaixo afetam a listagem e a exportação.</div>
  </div>

  <nav class="catarinense-tabs" aria-label="Seções do circuito">
    <cfloop array="#[{key='ranking',label='Ranking',icon='fa-ranking-star'},{key='medalhas',label='Medalhas',icon='fa-medal'},{key='etapas',label='Etapas',icon='fa-flag-checkered'},{key='regras',label='Regras',icon='fa-scale-balanced'}]#" item="VARIABLES.catarinenseTab">
      <a href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{aba=VARIABLES.catarinenseTab.key,pagina=1}))#</cfoutput>" <cfif URL.aba EQ VARIABLES.catarinenseTab.key>aria-current="page"</cfif>><i class="fa-solid <cfoutput>#VARIABLES.catarinenseTab.icon#</cfoutput> me-2" aria-hidden="true"></i><cfoutput>#VARIABLES.catarinenseTab.label#</cfoutput></a>
    </cfloop>
  </nav>
  <cfif URL.aba EQ "ranking">
    <div class="catarinense-gender-card">
      <nav class="catarinense-gender-switch" aria-label="Escolher ranking por gênero">
        <cfloop array="#[{key='feminino',label='Feminino',icon='fa-venus'},{key='masculino',label='Masculino',icon='fa-mars'}]#" item="VARIABLES.catarinenseGender">
          <a data-catarinense-gender="<cfoutput>#VARIABLES.catarinenseGender.key#</cfoutput>" class="catarinense-gender-link" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{genero=VARIABLES.catarinenseGender.key,pagina=1}))#</cfoutput>" <cfif URL.genero EQ VARIABLES.catarinenseGender.key>aria-current="page"</cfif>>
            <i class="fa-solid <cfoutput>#VARIABLES.catarinenseGender.icon#</cfoutput>" aria-hidden="true"></i><span><cfoutput>#VARIABLES.catarinenseGender.label#</cfoutput></span><span class="catarinense-gender-count"><cfoutput>#VARIABLES.catarinenseGenderCounts[VARIABLES.catarinenseGender.key]#</cfoutput></span>
          </a>
        </cfloop>
        <cfif VARIABLES.catarinenseGenderCounts.nao_informado GT 0 OR URL.genero EQ 'nao_informado'>
          <a data-catarinense-gender="nao_informado" class="catarinense-gender-link catarinense-gender-uninformed" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{genero='nao_informado',pagina=1}))#</cfoutput>" <cfif URL.genero EQ 'nao_informado'>aria-current="page"</cfif>>Não informado <span class="catarinense-gender-count"><cfoutput>#VARIABLES.catarinenseGenderCounts.nao_informado#</cfoutput></span></a>
        </cfif>
      </nav>
      <p class="small text-muted mt-2 mb-0">Classificação já ordenada após os desempates do regulamento. Contagens de inscritos no circuito; os filtros afetam a listagem.</p>
    </div>
  </cfif>
  <cfif VARIABLES.catarinenseViewPending GT 0 AND URL.aba EQ "ranking">
    <div class="alert alert-warning d-flex flex-wrap align-items-center justify-content-between gap-2"><span><i class="fa-solid fa-triangle-exclamation me-2" aria-hidden="true"></i><cfoutput>#VARIABLES.catarinenseViewPending#</cfoutput> atleta(s) neste ranking com desempate pendente. Consulte “Ver desempate” na ficha da linha.</span><a class="text-reset text-decoration-underline" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{aba='regras',pagina=1}))#</cfoutput>">Entender os critérios</a></div>
  </cfif>

  <cfif listFind("ranking,medalhas",URL.aba)>
  <div class="card catarinense-filter-card mb-3">
    <div class="card-body p-3">
      <form method="get" class="row g-2 align-items-end">
        <input type="hidden" name="aba" value="<cfoutput>#encodeForHTMLAttribute(URL.aba)#</cfoutput>"/>
        <cfif URL.aba EQ 'ranking'><input type="hidden" name="genero" value="<cfoutput>#encodeForHTMLAttribute(URL.genero)#</cfoutput>"/></cfif>
        <cfif len(URL.regiao)><input type="hidden" name="regiao" value="<cfoutput>#encodeForHTMLAttribute(URL.regiao)#</cfoutput>"/></cfif>
        <cfif len(URL.periodo)><input type="hidden" name="periodo" value="<cfoutput>#encodeForHTMLAttribute(URL.periodo)#</cfoutput>"/></cfif>
        <cfif len(URL.preset)><input type="hidden" name="preset" value="<cfoutput>#encodeForHTMLAttribute(URL.preset)#</cfoutput>"/></cfif>
        <div class="col-12 col-lg-<cfif URL.aba EQ 'ranking'>4<cfelse>3</cfif>">
          <label class="form-label" for="catarinense-busca">Atleta</label>
          <input id="catarinense-busca" class="form-control" type="search" name="busca" value="<cfoutput>#encodeForHTMLAttribute(URL.busca)#</cfoutput>" placeholder="Nome do atleta"/>
        </div>
        <cfif URL.aba NEQ 'ranking'><div class="col-6 col-lg-2">
          <label class="form-label" for="catarinense-genero">Gênero</label>
          <select id="catarinense-genero" class="form-select" name="genero">
            <option value="">Todos</option>
            <option value="feminino" <cfif URL.genero EQ "feminino">selected</cfif>>Feminino</option>
            <option value="masculino" <cfif URL.genero EQ "masculino">selected</cfif>>Masculino</option>
            <option value="nao_informado" <cfif URL.genero EQ "nao_informado">selected</cfif>>Não informado</option>
          </select>
        </div></cfif>
        <div class="col-6 col-lg-2">
          <label class="form-label" for="catarinense-medalha">Medalha</label>
          <select id="catarinense-medalha" class="form-select" name="medalha">
            <option value="">Todos os status</option>
            <option value="progresso" <cfif URL.medalha EQ "progresso">selected</cfif>>Em progresso</option>
            <option value="proxima_etapa" <cfif URL.medalha EQ "proxima_etapa">selected</cfif>>Próxima etapa</option>
            <option value="imediata" <cfif URL.medalha EQ "imediata">selected</cfif>>Entrega imediata</option>
            <option value="entregue" <cfif URL.medalha EQ "entregue">selected</cfif>>Entregue</option>
          </select>
        </div>
        <div class="col-6 col-lg-<cfif URL.aba EQ 'ranking'>2<cfelse>1</cfif>">
          <label class="form-label" for="catarinense-estado">UF</label>
          <select id="catarinense-estado" class="form-select" name="estado">
            <option value="">Todas</option>
            <cfoutput query="qStatsEstado">
              <option value="#encodeForHTMLAttribute(qStatsEstado.estado)#" <cfif URL.estado EQ qStatsEstado.estado>selected</cfif>>#encodeForHTML(qStatsEstado.estado)#</option>
            </cfoutput>
          </select>
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label" for="catarinense-cidade">Cidade</label>
          <select id="catarinense-cidade" class="form-select" name="cidade">
            <option value="">Todas</option>
            <cfoutput query="qStatsCidade">
              <cfif len(trim(qStatsCidade.cidade & ""))>
              <option value="#encodeForHTMLAttribute(qStatsCidade.cidade)#" <cfif URL.cidade EQ qStatsCidade.cidade>selected</cfif>>#encodeForHTML(qStatsCidade.cidade)#/#encodeForHTML(qStatsCidade.estado)#</option>
              </cfif>
            </cfoutput>
          </select>
        </div>
        <div class="col-6 col-lg-2 d-flex gap-2">
          <button class="btn btn-warning flex-fill" type="submit">Filtrar</button>
          <a class="btn btn-outline-secondary" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,{aba=URL.aba,genero=URL.aba EQ 'ranking' ? URL.genero : ''}))#</cfoutput>" title="Limpar filtros" aria-label="Limpar filtros"><i class="fa-solid fa-rotate-left"></i></a>
        </div>
      </form>
    </div>
  </div>
  </cfif>

  <cfif URL.aba EQ "etapas">
  <p class="text-muted">As colunas E1–E6 seguem estas etapas. A última etapa usada no desempate é sempre a E6, não a última prova disputada pelo atleta.</p>
  <div class="catarinense-stage-legend mb-3">
    <cfoutput query="qCatarinenseEvents">
      <a class="catarinense-stage-item" href="https://roadrunners.run/evento/#urlEncodedFormat(qCatarinenseEvents.event_tag)#/" target="_blank" rel="noopener noreferrer" title="#encodeForHTMLAttribute(qCatarinenseEvents.nome_evento)#">
        <span class="small text-muted">E#qCatarinenseEvents.event_order# · #numberFormat(qCatarinenseEvents.percurso, "9")# km</span>
        <strong class="catarinense-stage-name">#encodeForHTML(qCatarinenseEvents.nome_evento)#</strong>
        <span class="small text-muted"><cfif isDate(qCatarinenseEvents.data_inicial)>#dateFormat(qCatarinenseEvents.data_inicial, "dd/mm/yyyy")#<cfelse>Data a confirmar</cfif></span>
      </a>
    </cfoutput>
  </div>
  </cfif>

  <cfif URL.aba EQ "regras">
    <div class="card catarinense-ranking-card"><div class="card-body p-3 p-lg-4">
      <h2 class="h5">Como a classificação é calculada</h2>
      <p>São consideradas as quatro melhores pontuações entre seis etapas, separadamente por gênero. Apenas resultados concluídos e homologados entram no cálculo; resultados duplicados não multiplicam pontos. As pontuações cadastradas são preservadas.</p>
      <h3 class="h6 mt-4">Desempate, nesta ordem</h3>
      <ol class="catarinense-rule-list">
        <li><strong>Maior idade:</strong> data de nascimento mais antiga, informada na inscrição; na ausência, usa-se a data do perfil. Em empate de pontos, atletas sem nascimento válido ficam após os atletas com nascimento válido. Se vários estiverem sem nascimento, os critérios seguintes desempatarão entre eles.</li>
        <li><strong>Mais melhores colocações:</strong> quantidade de 1º lugares, depois 2º, 3º e assim por diante, em todas as etapas concluídas — não apenas nas quatro pontuações aproveitadas.</li>
        <li><strong>Melhor colocação na 6ª etapa:</strong> quem concluiu a etapa final tem precedência sobre quem não a disputou. Uma colocação ausente em um resultado existente é um dado pendente.</li>
        <li><strong>Melhor média percentual:</strong> média de <code>100 × tempo do atleta ÷ tempo do vencedor da categoria</code> nas etapas disputadas. O menor percentual é melhor; 100% equivale ao vencedor. Categoria, gênero e distância da etapa são respeitados. A exibição é arredondada, mas o desempate utiliza a precisão do cálculo.</li>
        <li><strong>Sorteio oficial:</strong> se tudo continuar igual, a decisão fica pendente da organização. Nome e ID apenas organizam a exibição dos empatados; não são critérios esportivos.</li>
      </ol>
      <div class="alert alert-info mb-0">Nascimento ausente ou inválido não bloqueia o ranking: o atleta fica por último neste critério, dentro do mesmo gênero e pontuação. Quando faltar outro dado necessário, o grupo afetado recebe uma faixa de posições provisória; não pulamos o critério incompleto para aplicar os seguintes.</div>
      <h3 class="h6 mt-4">Mandala e dados das etapas</h3>
      <p class="mb-0">Mandala com cinco conclusões em seis etapas. Com quatro, o atleta aparece como “Próxima etapa”.<cfif VARIABLES.challengeTag EQ "catarinensetrailrun"> O percurso de Timbó é de <strong>6 km</strong>, conforme confirmação da organização.</cfif></p>
    </div></div>
  </cfif>

  <cfif listFind("ranking,medalhas",URL.aba)>
  <cfif NOT qStatsBase.recordcount>
    <div class="alert alert-secondary">Nenhum atleta encontrado com os filtros selecionados.</div>
  <cfelse>
    <cfset VARIABLES.qCatarinenseRanking = qStatsBase/>
    <cfset VARIABLES.catarinenseRankingTitle = URL.aba EQ "medalhas" ? "Entrega de medalhas" : "Ranking " & VARIABLES.catarinenseGenderLabel/>
    <cfset VARIABLES.catarinenseRankingIcon = URL.aba EQ "medalhas" ? "fa-medal" : "fa-ranking-star"/>
    <cfinclude template="catarinense_table.cfm"/>
  </cfif>
  </cfif>
</section>
