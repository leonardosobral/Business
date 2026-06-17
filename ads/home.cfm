<!--- BACKEND --->

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

    <div class="col mb-3 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body p-3">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-ticket fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-3">
              <p class="text-muted mb-1">Saldo</p>
              <h4 class="mb-0">
                <cfif VARIABLES.adsVoucherColumnsReady AND qAdVoucherCredit.recordcount>
                  <cfoutput>#lsCurrencyFormat(VARIABLES.adsCreditBalance)#</cfoutput>
                <cfelse>
                  -
                </cfif>
              </h4>
              <cfif VARIABLES.adsVoucherColumnsReady AND qAdVoucherCredit.recordcount>
                <div class="small text-muted">
                  <cfoutput>#lsCurrencyFormat(VARIABLES.adsCreditSpent)# usados de #lsCurrencyFormat(VARIABLES.adsCreditTotal)#</cfoutput>
                </div>
              </cfif>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
    
</section>

<cfif VARIABLES.adsVoucherColumnsReady>
  <section class="mb-4">
    <div class="card shadow-0">
      <div class="card-body">
        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
          <div>
            <h5 class="mb-1">Credito de ads</h5>
            <p class="text-muted mb-0">Extrato resumido dos vouchers resgatados e do consumo registrado.</p>
          </div>
          <div class="text-lg-end">
            <div class="small text-muted">Saldo disponivel</div>
            <h4 class="mb-0"><cfoutput>#lsCurrencyFormat(VARIABLES.adsCreditBalance)#</cfoutput></h4>
          </div>
        </div>

        <div class="row gx-xl-4">
          <div class="col-lg-5 mb-4 mb-lg-0">
            <h6 class="mb-3">Vouchers resgatados</h6>
            <cfif qAdCreditVouchers.recordcount>
              <div class="table-responsive">
                <table class="table table-sm table-striped mb-0">
                  <thead>
                    <tr>
                      <th>Codigo</th>
                      <th class="text-end">Credito</th>
                      <th>Resgate</th>
                    </tr>
                  </thead>
                  <tbody>
                    <cfoutput query="qAdCreditVouchers">
                      <tr>
                        <td>
                          <strong>#htmlEditFormat(qAdCreditVouchers.codigo)#</strong>
                          <cfif len(trim(qAdCreditVouchers.nome_conta))>
                            <div class="small text-muted">#htmlEditFormat(qAdCreditVouchers.nome_conta)#</div>
                          </cfif>
                        </td>
                        <td class="text-end">#lsCurrencyFormat(qAdCreditVouchers.credito_disponivel)#</td>
                        <td>
                          <cfif isDate(qAdCreditVouchers.data_resgate)>
                            #lsDateFormat(qAdCreditVouchers.data_resgate, "dd/mm/yyyy")#
                          <cfelse>
                            -
                          </cfif>
                        </td>
                      </tr>
                    </cfoutput>
                  </tbody>
                </table>
              </div>
            <cfelse>
              <div class="alert alert-light mb-0" role="alert">Nenhum voucher resgatado para esta visao.</div>
            </cfif>
          </div>

          <div class="col-lg-7">
            <h6 class="mb-3">Consumo por campanha</h6>
            <cfif qAdCreditSpendByCampaign.recordcount>
              <div class="table-responsive">
                <table class="table table-sm table-striped mb-0">
                  <thead>
                    <tr>
                      <th>Evento</th>
                      <th class="text-end">Views</th>
                      <th class="text-end">Clicks</th>
                      <th class="text-end">CPC medio</th>
                      <th class="text-end">Custo</th>
                    </tr>
                  </thead>
                  <tbody>
                    <cfoutput query="qAdCreditSpendByCampaign">
                      <tr>
                        <td>
                          #htmlEditFormat(qAdCreditSpendByCampaign.nome_evento)#
                          <cfif isDate(qAdCreditSpendByCampaign.ultimo_consumo)>
                            <div class="small text-muted">Ultimo consumo em #lsDateFormat(qAdCreditSpendByCampaign.ultimo_consumo, "dd/mm/yyyy")#</div>
                          </cfif>
                        </td>
                        <td class="text-end">#LSNumberFormat(qAdCreditSpendByCampaign.views, "9,999,999")#</td>
                        <td class="text-end">#LSNumberFormat(qAdCreditSpendByCampaign.clicks, "9,999,999")#</td>
                        <td class="text-end">#lsCurrencyFormat(qAdCreditSpendByCampaign.cpc_medio)#</td>
                        <td class="text-end">#lsCurrencyFormat(qAdCreditSpendByCampaign.custo_total)#</td>
                      </tr>
                    </cfoutput>
                  </tbody>
                </table>
              </div>
            <cfelse>
              <div class="alert alert-light mb-0" role="alert">Ainda nao ha consumo registrado para esta visao.</div>
            </cfif>
          </div>
        </div>
      </div>
    </div>
  </section>
</cfif>

<!--- CONTEUDO --->

<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body">

          <div class="bg-light bg-opacity-10 rounded p-3">

            <!--- INCLUIR CAMPANHA --->

            <h3>Turbinar Evento</h3>

            <cfif isDefined("URL.erro") AND URL.erro EQ "sem_credito">
                <div class="alert alert-warning" role="alert">
                    Esta conta nao possui saldo de credito disponivel para criar uma campanha.
                </div>
            <cfelseif isDefined("URL.erro") AND URL.erro EQ "credito_insuficiente">
                <div class="alert alert-warning" role="alert">
                    O limite da campanha ultrapassa o saldo de credito disponivel da conta.
                </div>
            </cfif>

            <cfif VARIABLES.adsCanOperate AND NOT isDefined("URL.acao") AND NOT isDefined("URL.campanha")>

                <cfif VARIABLES.adsRestrictByConta
                    AND VARIABLES.adsVoucherColumnsReady
                    AND VARIABLES.adsCreditBalance LTE 0>
                    <div class="alert alert-info mb-0" role="alert">
                        Solicite ou resgate um voucher de credito antes de criar uma campanha.
                    </div>
                <cfelse>
                    <cfinclude template="includes/form_campanha.cfm"/>
                </cfif>

            <cfelseif NOT VARIABLES.adsCanOperate>

                <div class="alert alert-info mb-0" role="alert">Seu acesso permite visualizar campanhas desta conta, mas nao criar ou alterar turbinados.</div>

            </cfif>

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
                                    <cfif VARIABLES.adsCanOperate>
                                    <cfif qEventosAds.status EQ 1><a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=status_campanha&status=2"><icon class="fa fa-thumbs-up"></icon></a></cfif>
                                    <cfif qEventosAds.status GT 1>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=status_campanha&status=3"><icon class="fa fa-pause"></icon></a>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=status_campanha&status=4"><icon class="fa fa-archive"></icon></a>
                                    </cfif>
                                    <a href="/ads/?campanha=#qEventosAds.id_ad_evento#&acao=editar"><icon class="fa fa-edit"></icon></a>
                                    </cfif>
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
                            <cfif VARIABLES.adsCanOperate AND isDefined("URL.acao") AND URL.acao EQ "editar" AND isDefined("URL.campanha") and URL.campanha EQ qEventosAds.id_ad_evento>
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
