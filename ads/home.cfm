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

<!--- CONTEUDO--->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <div class="bg-light bg-opacity-10 rounded p-3">

            <!--- INCLUIR CAMPANHA --->

            <h3>Turbinar Evento</h3>

            <cfinclude template="includes/form_campanha.cfm"/>

            </div>

          <hr/>

          <!--- ABAS --->
          <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Ativos (<cfoutput>#qEventosAds.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Pausados (<cfoutput>#qEventosAdsPausados.recordcount#</cfoutput>)</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Finalizados (<cfoutput>#qEventosAdsFinalizados.recordcount#</cfoutput>)</a>
            </li>
          </ul>

          <!--- CONTEUDO ABAS --->
          <div class="tab-content" id="ex1-content">

            <div class="tab-pane fade show active tableFixHead rounded" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th></th>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAds">
                            <tr>
                                <td>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=status_campanha&status=3"><icon class="fa fa-pause"></icon></a>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=status_campanha&status=4"><icon class="fa fa-archive"></icon></a>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                </td>
                                <td <cfif qEventosAds.data_final LT now()>class="text-danger"</cfif>>#lsDateFormat(qEventosAds.data_final, "dd/mm/yyyy")# - #qEventosAds.nome_evento# <cfif qEventosAds.status EQ 1><span class="badge badge-success">em aprovação</span></cfif></td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAds.qualidade#</td--->
                                <td class="text-end">#qEventosAds.ad_rank#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAds.views, "9,999,999")#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAds.clicks, "9,999,999")#</td>
                                <td class="text-end">#lsNumberFormat(len(trim(qEventosAds.clicks)) AND qEventosAds.clicks NEQ 0 ? qEventosAds.clicks*100/qEventosAds.views : 0, "9.99")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAds.custo_total)#</td>
                            </tr>
                            <cfif isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qEventosAds.id_ad_evento>
                                <tr>
                                    <td colspan="9" class="p-3">
                                        <!--- EDITAR CAMPANHA --->
                                        <cfset VARIABLES.campanha = QueryGetRow(qEventosAds, qEventosAds.currentRow)>
                                        <h5 class="mb-3">Editar Campanha</h5>
                                        <h5 class="mb-3 float-end">X</h5>
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
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAdsPausados">
                            <tr>
                                <td><a href=""><icon class="fa fa-pause"></icon></a> </td>
                                <td <cfif qEventosAdsPausados.data_final LT now()>class="text-danger"</cfif>>#qEventosAdsPausados.nome_evento#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAdsPausados.qualidade#</td--->
                                <td class="text-end">#qEventosAdsPausados.ad_rank#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsPausados.views, "9,999,999")#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsPausados.clicks, "9,999,999")#</td>
                                <td class="text-end">#lsNumberFormat(len(trim(qEventosAdsPausados.clicks)) AND qEventosAdsPausados.clicks NEQ 0 ? qEventosAdsPausados.clicks*100/qEventosAdsPausados.views : 0, "9.99")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsPausados.custo_total)#</td>
                            </tr>
                        </cfoutput>
                      </tbody>
                  </table>

            </div>

            <div class="tab-pane fade tableFixHead rounded" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">

                  <table class="table table-sm table-striped table-hover">
                      <thead>
                        <tr>
                            <th>Evento</th>
                            <th class="text-end">CPC max</th>
                            <!---th class="text-end">Qualidade</th--->
                            <th class="text-end">Ad Rank</th>
                            <th class="text-end">Views</th>
                            <th class="text-end">Clicks</th>
                            <th class="text-end">Taxa</th>
                            <th class="text-end">CPC médio</th>
                            <th class="text-end">Custo</th>
                        </tr>
                      </thead>
                      <tbody>
                        <cfoutput query="qEventosAdsFinalizados">
                            <tr>
                                <td>#qEventosAdsFinalizados.nome_evento#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.cpc_max)#</td>
                                <!---td class="text-end">#qEventosAdsFinalizados.qualidade#</td--->
                                <td class="text-end">#qEventosAdsFinalizados.ad_rank#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsFinalizados.views, "9,999,999")#</td>
                                <td class="text-end">#LSNumberFormat(qEventosAdsFinalizados.clicks, "9,999,999")#</td>
                                <td class="text-end">#lsNumberFormat(len(trim(qEventosAdsFinalizados.clicks)) AND qEventosAdsFinalizados.clicks NEQ 0 ? qEventosAdsFinalizados.clicks*100/qEventosAdsFinalizados.views : 0, "9.99")#%</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.cpc_medio)#</td>
                                <td class="text-end">#lsCurrencyFormat(qEventosAdsFinalizados.custo_total)#</td>
                            </tr>
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

