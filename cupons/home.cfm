<cfinclude template="includes/backend.cfm"/>

<!--- WIDGETS --->

<section class="mb-4">

  <div class="row gx-xl-3">

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-eye fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Inscrições</p>
              <h4 class="mb-0">
                <cfoutput>#LSNumberFormat(qAdCountViews.total, "9,999,999")#</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-dollar-sign fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Ticket Médio</p>
              <h4 class="mb-0">
                <cfoutput>#lsCurrencyFormat(qAdValorMedio.total)#</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-dollar-sign fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Vendas</p>
              <h4 class="mb-0">
                <cfoutput>#lsCurrencyFormat(qAdValorTotal.total)#</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
    
</section>

<!--- CONTEUDO--->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

            <h3>Cupons de Desconto</h3>

          <hr/>

          <!--- ABAS --->
          <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Performance de Vendas (<cfoutput>#qCuponsBase.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Influencers (<cfoutput>#qCuponsInflu.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Assessorias (<cfoutput>#qCuponsAssessoria.recordcount#</cfoutput>)</a>
            </li>
          </ul>

          <!--- CONTEUDO ABAS --->

          <div class="tab-content" id="ex1-content">

            <div class="tab-pane fade show active tableFixHead rounded" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Cupom</th>
                            <th class="text-end">Inscrições</th>
                            <th class="text-end">Vendas</th>
                            <th class="text-end">Ticket</th>
                            <th class="text-end">Ticket (repasse)</th>
                            <th class="text-end">Repasse</th>
                            <th class="text-end">Cashback</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCuponsBase">
                            <tr>
                                <td>#qCuponsBase.titulocupom# <cfif qCuponsBase.titulocupom CONTAINS "influ"><span class="badge badge-info">influ</span></cfif> <cfif qCuponsBase.titulocupom CONTAINS "cashback"><span class="badge badge-success">$$$</span></cfif></td>
                                <td class="text-end">#qCuponsBase.pedidos#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsBase.vendas)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsBase.ticket_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsBase.ticket_medio_repasse)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsBase.repasse)#</td>
                                <td class="text-end"><cfif qCuponsBase.titulocupom CONTAINS "cashback">#lsCurrencyFormat(qCuponsBase.cashback)#</cfif></td>
                            </tr>
                            <cfif isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qCuponsBase.titulocupom>
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


                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Cupom</th>
                            <th class="text-end">Inscrições</th>
                            <th class="text-end">Vendas</th>
                            <th class="text-end">Ticket</th>
                            <th class="text-end">Ticket (repasse)</th>
                            <th class="text-end">Repasse</th>
                            <th class="text-end">Cashback</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCuponsInflu">
                            <tr>
                                <td>#qCuponsInflu.titulocupom# <cfif qCuponsInflu.titulocupom CONTAINS "influ"><span class="badge badge-info">influ</span></cfif> <cfif qCuponsInflu.titulocupom CONTAINS "cashback"><span class="badge badge-success">$$$</span></cfif></td>
                                <td class="text-end">#qCuponsInflu.pedidos#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsInflu.vendas)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsInflu.ticket_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsInflu.ticket_medio_repasse)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsInflu.repasse)#</td>
                                <td class="text-end"><cfif qCuponsInflu.titulocupom CONTAINS "cashback">#lsCurrencyFormat(qCuponsInflu.cashback)#</cfif></td>
                            </tr>
                            <cfif isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qCuponsInflu.titulocupom>
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

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Cupom</th>
                            <th class="text-end">Inscrições</th>
                            <th class="text-end">Vendas</th>
                            <th class="text-end">Ticket</th>
                            <th class="text-end">Ticket (repasse)</th>
                            <th class="text-end">Repasse</th>
                            <th class="text-end">Cashback</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCuponsAssessoria">
                            <tr>
                                <td>#qCuponsAssessoria.titulocupom# <cfif qCuponsAssessoria.titulocupom CONTAINS "influ"><span class="badge badge-info">influ</span></cfif> <cfif qCuponsAssessoria.titulocupom CONTAINS "cashback"><span class="badge badge-success">$$$</span></cfif></td>
                                <td class="text-end">#qCuponsAssessoria.pedidos#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsAssessoria.vendas)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsAssessoria.ticket_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsAssessoria.ticket_medio_repasse)#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsAssessoria.repasse)#</td>
                                <td class="text-end"><cfif qCuponsAssessoria.titulocupom CONTAINS "cashback">#lsCurrencyFormat(qCuponsAssessoria.cashback)#</cfif></td>
                            </tr>
                            <cfif isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qCuponsAssessoria.titulocupom>
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

        </div>

      </div>

    </div>

  </div>

</section>

