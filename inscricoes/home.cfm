<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<cfset VARIABLES.inscricoesTotalPedidos = 0/>
<cfset VARIABLES.inscricoesValorTotal = 0/>
<cfset VARIABLES.inscricoesTicketMedio = 0/>
<cfset VARIABLES.inscricoesInfluTotal = 0/>
<cfset VARIABLES.inscricoesAssessoriaTotal = 0/>
<cfif qAdCountViews.recordcount AND NOT isNull(qAdCountViews.total)>
    <cfset VARIABLES.inscricoesTotalPedidos = val(qAdCountViews.total)/>
</cfif>
<cfif qAdValorTotal.recordcount AND NOT isNull(qAdValorTotal.total)>
    <cfset VARIABLES.inscricoesValorTotal = val(qAdValorTotal.total)/>
</cfif>
<cfif qAdValorMedio.recordcount AND NOT isNull(qAdValorMedio.total)>
    <cfset VARIABLES.inscricoesTicketMedio = val(qAdValorMedio.total)/>
</cfif>
<cfif qCountCuponsInflu.recordcount AND NOT isNull(qCountCuponsInflu.total)>
    <cfset VARIABLES.inscricoesInfluTotal = val(qCountCuponsInflu.total)/>
</cfif>
<cfif qCountCuponsAssessoria.recordcount AND NOT isNull(qCountCuponsAssessoria.total)>
    <cfset VARIABLES.inscricoesAssessoriaTotal = val(qCountCuponsAssessoria.total)/>
</cfif>
<cfset VARIABLES.inscricoesHasLinkedEvents = NOT (VARIABLES.cuponsRestrictByConta AND VARIABLES.cuponsEventosContaIds EQ "0")/>
<cfset VARIABLES.inscricoesHasData = VARIABLES.inscricoesHasLinkedEvents AND qCuponsBase.recordcount GT 0 AND VARIABLES.inscricoesTotalPedidos GT 0/>

<!--- WIDGETS --->

<section class="business-page mb-4">
  <div class="business-kpi-grid">
    <div class="business-kpi">
      <small>Inscrições</small>
      <div class="business-kpi-value h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.inscricoesTotalPedidos, "9,999,999")#</cfoutput></div>
    </div>
    <div class="business-kpi">
      <small>Ticket médio</small>
      <div class="business-kpi-value h4 mb-0"><cfoutput>#lsCurrencyFormat(VARIABLES.inscricoesTicketMedio)#</cfoutput></div>
    </div>
    <div class="business-kpi">
      <small>Vendas</small>
      <div class="business-kpi-value h4 mb-0"><cfoutput>#lsCurrencyFormat(VARIABLES.inscricoesValorTotal)#</cfoutput></div>
    </div>
  </div>
</section>

<!--- CONTEUDO --->

<section class="business-page">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0 business-page-card">

        <div class="card-body business-page-body">

          <div class="business-page-header d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
            <div>
              <h3 class="business-page-title mb-1">Inscrições</h3>
              <p class="text-muted mb-0">Acompanhe inscrições, vendas e desempenho de cupons dos eventos vinculados à conta.</p>
            </div>
            <div class="business-page-actions">
              <a class="btn btn-sm btn-outline-warning" href="/eventos/">Eventos</a>
              <a class="btn btn-sm btn-outline-light" href="/suporte/">Suporte</a>
            </div>
          </div>

          <cfif NOT VARIABLES.inscricoesHasLinkedEvents>
            <div class="business-empty-state mb-4" role="status">
              <div class="business-label mb-1">Primeiro evento</div>
              <h4 class="mb-2">Vincule uma prova antes de consultar inscrições</h4>
              <p class="text-muted mb-3">As inscrições aparecem depois que a prova é aprovada para a sua conta e os dados da operação ficam disponíveis.</p>
              <div class="business-step-grid mb-3">
                <div class="business-step is-current">
                  <div class="business-step-top">
                    <span class="business-step-marker">1</span>
                    <span class="business-step-status">Próximo</span>
                  </div>
                  <h5 class="mb-2">Solicitar vínculo</h5>
                  <p class="text-muted mb-0">Busque a prova pelo link, tag, ID ou nome.</p>
                  <div class="business-step-action">
                    <a class="btn btn-sm btn-warning w-100" href="/eventos/#primeiro-evento">Ir para Eventos</a>
                  </div>
                </div>
                <div class="business-step is-muted">
                  <div class="business-step-top">
                    <span class="business-step-marker">2</span>
                    <span class="business-step-status">Depois</span>
                  </div>
                  <h5 class="mb-2">Aguardar liberação</h5>
                  <p class="text-muted mb-0">A aprovação conecta a prova aos recursos da conta.</p>
                </div>
                <div class="business-step is-muted">
                  <div class="business-step-top">
                    <span class="business-step-marker">3</span>
                    <span class="business-step-status">Depois</span>
                  </div>
                  <h5 class="mb-2">Voltar aqui</h5>
                  <p class="text-muted mb-0">Use esta tela para acompanhar vendas, ticket e cupons.</p>
                </div>
              </div>
              <div class="business-empty-actions">
                <a class="btn btn-warning" href="/eventos/#primeiro-evento">Solicitar evento</a>
                <a class="btn btn-outline-light" href="/suporte/">Pedir ajuda</a>
              </div>
            </div>
          <cfelseif NOT VARIABLES.inscricoesHasData>
            <div class="business-empty-state mb-4" role="status">
              <div class="business-label mb-1">Dados em preparação</div>
              <h4 class="mb-2">Ainda não há inscrições liberadas para estes eventos</h4>
              <p class="text-muted mb-3">O vínculo do evento existe, mas a base de inscrições ainda não retornou registros para a conta.</p>
              <div class="business-empty-actions">
                <a class="btn btn-warning" href="/eventos/">Revisar eventos</a>
                <a class="btn btn-outline-light" href="/suporte/">Falar com suporte</a>
              </div>
            </div>
          </cfif>

          <cfif VARIABLES.inscricoesHasData>

          <!--- ABAS --->
          <ul class="nav business-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Performance <span class="business-tab-count"><cfoutput>#qCuponsBase.recordcount#</cfoutput></span></a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Influencers <span class="business-tab-count"><cfoutput>#qCuponsInflu.recordcount#</cfoutput></span></a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Assessorias <span class="business-tab-count"><cfoutput>#qCuponsAssessoria.recordcount#</cfoutput></span></a>
            </li>
          </ul>

          <!--- CONTEUDO ABAS --->

          <div class="tab-content" id="ex1-content">

            <div class="tab-pane fade show active tableFixHead rounded" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <table class="table table-sm table-striped table-hover business-table">
                      <thead>
                        <tr>
                            <th>Cupom</th>
                            <th class="text-end">Inscrições</th>
                            <th class="text-end">%</th>
                            <th class="text-end">Vendas</th>
                            <th class="text-end">Líquido</th>
                            <th class="text-end">Ticket</th>
                            <th class="text-end">Líquido</th>
                            <th class="text-end">Cashback</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCuponsBase">
                            <cfset VARIABLES.inscricoesLinhaPercentual = 0/>
                            <cfif VARIABLES.inscricoesTotalPedidos GT 0>
                                <cfset VARIABLES.inscricoesLinhaPercentual = (qCuponsBase.pedidos * 100) / VARIABLES.inscricoesTotalPedidos/>
                            </cfif>
                            <tr>
                                <td>#qCuponsBase.titulocupom# <cfif qCuponsBase.titulocupom CONTAINS "influ"><span class="badge badge-info">influ</span></cfif> <cfif qCuponsBase.titulocupom CONTAINS "cashback"><span class="badge badge-success">$$$</span></cfif></td>
                                <td class="text-end">#qCuponsBase.pedidos#</td>
                                <td class="text-end">#lsNumberFormat(VARIABLES.inscricoesLinhaPercentual, "9.9")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsBase.vendas)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsBase.repasse)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsBase.ticket_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsBase.ticket_medio_repasse)#</td>
                                <td class="text-end"><cfif qCuponsBase.titulocupom CONTAINS "cashback">#lsCurrencyFormat(qCuponsBase.cashback)#</cfif></td>
                            </tr>
                            <cfif VARIABLES.cuponsCanOperate AND isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qCuponsBase.titulocupom>
                                <tr>
                                    <td colspan="9" class="p-3">
                                        <!--- EDITAR CAMPANHA --->
                                        <cfset VARIABLES.campanha = QueryGetRow(qEventosAds, qEventosAds.currentRow)>
                                        <h5 class="mb-3">Editar Campanha</h5>
                                        <a href="./"><h5 class="mb-3 float-end">X</h5></a>
                                        <cfinclude template="includes/form_campanha.cfm"/>
                                    </td>
                                </tr>
                            </cfif>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-2" role="tabpanel" aria-labelledby="ex1-tab-2">

                <!---cfif NOT isDefined("URL.acao") AND NOT isDefined("URL.campanha")>

                    <cfinclude template="includes/form_campanha.cfm"/>

                </cfif--->


                  <table class="table table-sm table-striped table-hover business-table">
                      <thead>
                        <tr>
                            <th>Cupom</th>
                            <th class="text-end">Inscrições</th>
                            <th class="text-end">%</th>
                            <th class="text-end">Vendas</th>
                            <th class="text-end">Líquido</th>
                            <th class="text-end">Ticket</th>
                            <th class="text-end">Líquido</th>
                            <th class="text-end">Cashback</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCuponsInflu">
                            <cfset VARIABLES.inscricoesLinhaPercentual = 0/>
                            <cfif VARIABLES.inscricoesInfluTotal GT 0>
                                <cfset VARIABLES.inscricoesLinhaPercentual = (qCuponsInflu.pedidos * 100) / VARIABLES.inscricoesInfluTotal/>
                            </cfif>
                            <tr>
                                <td>#qCuponsInflu.titulocupom# <cfif qCuponsInflu.titulocupom CONTAINS "influ"><span class="badge badge-info">influ</span></cfif> <cfif qCuponsInflu.titulocupom CONTAINS "cashback"><span class="badge badge-success">$$$</span></cfif></td>
                                <td class="text-end">#qCuponsInflu.pedidos#</td>
                                <td class="text-end">#lsNumberFormat(VARIABLES.inscricoesLinhaPercentual, "9.9")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsInflu.vendas)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsInflu.repasse)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsInflu.ticket_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsInflu.ticket_medio_repasse)#</td>
                                <td class="text-end"><cfif qCuponsInflu.titulocupom CONTAINS "cashback">#lsCurrencyFormat(qCuponsInflu.cashback)#</cfif></td>
                            </tr>
                            <cfif VARIABLES.cuponsCanOperate AND isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qCuponsInflu.titulocupom>
                                <tr>
                                    <td colspan="9" class="p-3">
                                        <!--- EDITAR CAMPANHA --->
                                        <cfset VARIABLES.campanha = QueryGetRow(qEventosAds, qEventosAds.currentRow)>
                                        <h5 class="mb-3">Editar Campanha</h5>
                                        <a href="./"><h5 class="mb-3 float-end">X</h5></a>
                                        <cfinclude template="includes/form_campanha.cfm"/>
                                    </td>
                                </tr>
                            </cfif>
                        </cfoutput>
                      </tbody>
                  </table>


            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

                  <table class="table table-sm table-striped table-hover business-table">
                      <thead>
                        <tr>
                            <th>Cupom</th>
                            <th class="text-end">Inscrições</th>
                            <th class="text-end">%</th>
                            <th class="text-end">Vendas</th>
                            <th class="text-end">Líquido</th>
                            <th class="text-end">Ticket</th>
                            <th class="text-end">Líquido</th>
                            <th class="text-end">Cashback</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCuponsAssessoria">
                            <cfset VARIABLES.inscricoesLinhaPercentual = 0/>
                            <cfif VARIABLES.inscricoesAssessoriaTotal GT 0>
                                <cfset VARIABLES.inscricoesLinhaPercentual = (qCuponsAssessoria.pedidos * 100) / VARIABLES.inscricoesAssessoriaTotal/>
                            </cfif>
                            <tr>
                                <td>#qCuponsAssessoria.titulocupom# <cfif qCuponsAssessoria.titulocupom CONTAINS "influ"><span class="badge badge-info">influ</span></cfif> <cfif qCuponsAssessoria.titulocupom CONTAINS "cashback"><span class="badge badge-success">$$$</span></cfif></td>
                                <td class="text-end">#qCuponsAssessoria.pedidos#</td>
                                <td class="text-end">#lsNumberFormat(VARIABLES.inscricoesLinhaPercentual, "9.9")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsAssessoria.vendas)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsAssessoria.repasse)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsAssessoria.ticket_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsAssessoria.ticket_medio_repasse)#</td>
                                <td class="text-end"><cfif qCuponsAssessoria.titulocupom CONTAINS "cashback">#lsCurrencyFormat(qCuponsAssessoria.cashback)#</cfif></td>
                            </tr>
                            <cfif VARIABLES.cuponsCanOperate AND isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qCuponsAssessoria.titulocupom>
                                <tr>
                                    <td colspan="9" class="p-3">
                                        <!--- EDITAR CAMPANHA --->
                                        <cfset VARIABLES.campanha = QueryGetRow(qEventosAds, qEventosAds.currentRow)>
                                        <h5 class="mb-3">Editar Campanha</h5>
                                        <a href="./"><h5 class="mb-3 float-end">X</h5></a>
                                        <cfinclude template="includes/form_campanha.cfm"/>
                                    </td>
                                </tr>
                            </cfif>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

          </div>

          </cfif>

        </div>

      </div>

    </div>

  </div>

</section>
