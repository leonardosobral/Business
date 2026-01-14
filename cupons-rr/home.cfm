<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- WIDGETS

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
              <p class="text-muted mb-1">Views</p>
              <h4 class="mb-0">
                <cfoutput>#LSNumberFormat(qAdCountViews.total, "9,999,999")#</cfoutput>
              </h4>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col mb-3 d-none d-xl-block mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-hand-pointer fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Clicks</p>
              <h4 class="mb-0">
                <cfoutput>#LSNumberFormat(qAdCountClicks.total, "9,999,999")#</cfoutput>
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
              <p class="text-muted mb-1">CPC Médio</p>
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
              <p class="text-muted mb-1">Investimento</p>
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

 --->

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <div class="bg-light bg-opacity-10 rounded p-3">

            <!--- INCLUIR CAMPANHA --->

            <h3>Cupons de Desconto Road Runners</h3>

            <cfif NOT isDefined("URL.acao") AND NOT isDefined("URL.campanha")>

                <cfinclude template="includes/form_campanha.cfm"/>

            </cfif>

          </div>

          <hr/>

          <!--- ABAS --->
          <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Cupons (<cfoutput>#qCupons.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Cupons de Provas (<cfoutput>#qEventosCupons.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Cupons de Circuitos (<cfoutput>#qCircuitosCupons.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-4" data-mdb-pill-init href="#ex1-pills-4" role="tab"
                 aria-controls="ex1-pills-4" aria-selected="false">Cupons de Páginas (<cfoutput>#qPaginasCupons.recordcount#</cfoutput>)</a>
            </li>
          </ul>

          <!--- CONTEUDO ABAS --->
          <div class="tab-content" id="ex1-content">

            <div class="tab-pane fade show active tableFixHead rounded" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Cupom</th>
                            <th>Parceiro</th>
                            <th class="text-end">Desconto</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCupons">
                            <tr>
                                <td>
                                    <!---cfif qCupons.ativo EQ 1><a href="/cupons-rr/?campanha=#qCupons.id_cupom#&acao=status_campanha&status=2"><icon class="fa fa-thumbs-up"></icon></a></cfif>
                                    <cfif qCupons.ativo GT 1>
                                    <a href="/cupons-rr/?campanha=#qCupons.id_cupom#&acao=status_campanha&status=3"><icon class="fa fa-pause"></icon></a>
                                    <a href="/cupons-rr/?campanha=#qCupons.id_cupom#&acao=status_campanha&status=4"><icon class="fa fa-archive"></icon></a>
                                    </cfif--->
                                    <a href="/cupons-rr/?campanha=#qCupons.id_cupom#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td>#qCupons.cupom# <cfif len(trim(qCupons.data_expiracao)) AND qCupons.data_expiracao LT now()><span class="badge badge-warning">expirado #lsDateFormat(qCupons.data_expiracao, "dd/mm/yyyy")#</span></cfif></td>
                                <td>#qCupons.parceiro#</td>
                                <td class="text-end">#qCupons.condicoes#</td>
                                <!---td><small>#qCupons.descricao#</small></td--->
                            </tr>
                            <cfif isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qCupons.id_cupom>
                                <tr>
                                    <td colspan="9" class="p-3">
                                        <!--- EDITAR CAMPANHA --->
                                        <cfset VARIABLES.campanha = QueryGetRow(qCupons, qCupons.currentRow)>
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

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Evento</th>
                            <th>Cupom</th>
                            <th class="text-end">Início</th>
                            <th class="text-end">Validade</th>
                            <th class="text-end">Desconto</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosCupons">
                            <tr>
                                <td><a href=""><icon class="fa fa-edit"></icon></a> </td>
                                <td>#qEventosCupons.nome_evento#</td>
                                <td>#qEventosCupons.cupom# <cfif len(trim(qEventosCupons.data_expiracao)) AND qEventosCupons.data_expiracao LT now()><span class="badge badge-warning">expirado #lsDateFormat(qEventosCupons.data_expiracao, "dd/mm/yyyy")#</span></cfif></td>
                                <td class="text-end">#lsDateFormat(qEventosCupons.data_validade_inicio, "dd/mm/yyyy")#</td>
                                <td class="text-end">#lsDateFormat(qEventosCupons.data_validade_fim, "dd/mm/yyyy")#</td>
                                <td class="text-end">#qEventosCupons.condicoes#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>


            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Circuito</th>
                            <th>Cupom</th>
                            <th class="text-end">Início</th>
                            <th class="text-end">Validade</th>
                            <th class="text-end">Desconto</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCircuitosCupons">
                            <tr>
                                <td><a href=""><icon class="fa fa-edit"></icon></a> </td>
                                <td>#qCircuitosCupons.nome_evento_agregado#</td>
                                <td>#qCircuitosCupons.cupom# <cfif len(trim(qCircuitosCupons.data_expiracao)) AND qCircuitosCupons.data_expiracao LT now()><span class="badge badge-warning">expirado #lsDateFormat(qCircuitosCupons.data_expiracao, "dd/mm/yyyy")#</span></cfif></td>
                                <td class="text-end">#lsDateFormat(qCircuitosCupons.data_validade_inicio, "dd/mm/yyyy")#</td>
                                <td class="text-end">#lsDateFormat(qCircuitosCupons.data_validade_fim, "dd/mm/yyyy")#</td>
                                <td class="text-end">#qCircuitosCupons.condicoes#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>


            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-4" role="tabpanel" aria-labelledby="ex1-tab-4">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Página</th>
                            <th>Cupom</th>
                            <th>Parceiro</th>
                            <th class="text-end">Início</th>
                            <th class="text-end">Validade</th>
                            <th class="text-end">Desconto</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qPaginasCupons">
                            <tr>
                                <td><a href=""><icon class="fa fa-edit"></icon></a> </td>
                                <td>#qPaginasCupons.nome#</td>
                                <td>#qPaginasCupons.cupom# <cfif len(trim(qPaginasCupons.data_expiracao)) AND qPaginasCupons.data_expiracao LT now()><span class="badge badge-warning">expirado #lsDateFormat(qPaginasCupons.data_expiracao, "dd/mm/yyyy")#</span></cfif></td>
                                <td>#qPaginasCupons.parceiro#</td>
                                <td class="text-end">#lsDateFormat(qPaginasCupons.data_cadastro, "dd/mm/yyyy")#</td>
                                <td class="text-end">#lsDateFormat(qPaginasCupons.data_expiracao, "dd/mm/yyyy")#</td>
                                <td class="text-end">#qPaginasCupons.condicoes#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <!---

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qCuponsFinalizados">
                            <tr>
                                <td>#qCuponsFinalizados.nome_evento#</td>
                                <td class="text-end">#lsCurrencyFormat(qCuponsFinalizados.cpc_max)#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            --->

          </div>

        </div>

      </div>

    </div>

  </div>

</section>

